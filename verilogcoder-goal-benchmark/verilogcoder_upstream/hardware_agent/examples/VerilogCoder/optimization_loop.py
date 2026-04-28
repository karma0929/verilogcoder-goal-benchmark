from __future__ import annotations

import csv
import json
import os
import re
import shutil
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional, Tuple

from hardware_agent.examples.VerilogCoder.openroad_eval import OpenROADEvaluator
from hardware_agent.examples.VerilogCoder.verilogcoder import VerilogCoder


TARGETS = ("area", "perf", "power")
SUPPORTED_TARGETS = ("baseline", "area", "perf", "power")

TARGET_INSTRUCTION_SUFFIX = {
    "area": (
        "Primary objective: minimize place area.\n"
        "Secondary objectives: minimize synth area, keep worst slack non-negative, and reduce HPWL.\n"
        "Return only synthesizable SystemVerilog code for TopModule."
    ),
    "perf": (
        "Primary objective: maximize worst slack and reduce critical combinational depth.\n"
        "Secondary objectives: keep TNS at 0, reduce place area, and reduce HPWL.\n"
        "Return only synthesizable SystemVerilog code for TopModule."
    ),
    "power": (
        "Primary objective: minimize synth area as a proxy for power.\n"
        "Secondary objectives: minimize place area and HPWL while keeping worst slack non-negative and TNS at 0 if possible.\n"
        "Return only synthesizable SystemVerilog code for TopModule."
    ),
}


@dataclass
class OptimizationLoopConfig:
    max_iterations: int = 3
    baseline_max_iterations: int = 3
    no_improvement_limit: int = 1
    functional_failure_limit: int = 2
    min_area_improvement_um2: float = 1.0
    min_slack_improvement_ns: float = 0.01
    min_power_proxy_improvement_um2: float = 0.5
    run_openroad: bool = True
    use_reference_baseline: bool = True


def _read_text(path: Path) -> str:
    return path.read_text()


def _write_json(path: Path, payload: Dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True))


def _write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)


def _copy_file(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)


def _summarize_metrics(metrics: Optional[Dict[str, Optional[float]]]) -> Dict[str, Optional[float]]:
    if not metrics:
        return {}
    keys = ["synth_area_um2", "place_area_um2", "worst_slack_ns", "tns_ns", "final_hpwl_um"]
    return {key: metrics.get(key) for key in keys}


def _format_metric_value(value: Optional[float], unit: str) -> str:
    if value is None:
        return "N/A"
    return f"{value:.3f} {unit}".rstrip()


def _parse_verification_report(report: str) -> Dict[str, Any]:
    compiled = "[Compiled Success]" in report
    functional = "[Function Check Success]" in report
    return {
        "compiled_success": compiled,
        "functional_success": compiled and functional,
        "raw_report": report,
    }


def _classify_verification_failure(verification: Dict[str, Any]) -> str:
    if verification.get("functional_success"):
        return "pass"
    report = verification.get("raw_report", "") or ""
    if "[Interface Check Failed]" in report:
        return "interface_fail"
    if "could not be parsed into the expected candidate file set" in report:
        return "generation_parse_fail"
    if verification.get("compiled_success") is False:
        return "compile_fail"
    return "functional_fail"


def _timing_clean(metrics: Optional[Dict[str, Optional[float]]]) -> bool:
    if not metrics:
        return False
    worst_slack = metrics.get("worst_slack_ns")
    tns = metrics.get("tns_ns")
    return worst_slack is not None and worst_slack >= 0 and tns is not None and abs(tns) < 1e-9


def _has_any_metric(metrics: Optional[Dict[str, Optional[float]]]) -> bool:
    if not metrics:
        return False
    return any(value is not None for value in metrics.values())


def _cmp_optional(a: Optional[float], b: Optional[float], prefer: str, tolerance: float = 1e-9) -> int:
    if a is None and b is None:
        return 0
    if a is None:
        return -1
    if b is None:
        return 1

    if prefer == "min":
        if a < b - tolerance:
            return 1
        if a > b + tolerance:
            return -1
        return 0

    if a > b + tolerance:
        return 1
    if a < b - tolerance:
        return -1
    return 0


def compare_metrics(mode: str, lhs: Optional[Dict[str, Optional[float]]], rhs: Optional[Dict[str, Optional[float]]]) -> int:
    if lhs is None and rhs is None:
        return 0
    if lhs is None:
        return -1
    if rhs is None:
        return 1

    comparisons: Iterable[tuple[str, str]]
    if mode == "baseline":
        comparisons = (
            ("place_area_um2", "min"),
            ("synth_area_um2", "min"),
            ("worst_slack_ns", "max"),
            ("final_hpwl_um", "min"),
        )
    elif mode == "area":
        comparisons = (
            ("place_area_um2", "min"),
            ("synth_area_um2", "min"),
            ("worst_slack_ns", "max"),
            ("final_hpwl_um", "min"),
        )
    elif mode == "perf":
        comparisons = (
            ("worst_slack_ns", "max"),
            ("tns_ns", "max"),  # closer to 0, with typical non-positive values
            ("place_area_um2", "min"),
            ("final_hpwl_um", "min"),
        )
    else:
        comparisons = (
            ("synth_area_um2", "min"),
            ("place_area_um2", "min"),
            ("final_hpwl_um", "min"),
            ("worst_slack_ns", "max"),
        )

    if mode == "power":
        if _timing_clean(lhs) and not _timing_clean(rhs):
            return 1
        if _timing_clean(rhs) and not _timing_clean(lhs):
            return -1

    for metric_name, prefer in comparisons:
        cmp_result = _cmp_optional(lhs.get(metric_name), rhs.get(metric_name), prefer)
        if cmp_result != 0:
            return cmp_result
    return 0


def meaningful_improvement(
    mode: str,
    current_metrics: Optional[Dict[str, Optional[float]]],
    previous_best_metrics: Optional[Dict[str, Optional[float]]],
    config: OptimizationLoopConfig,
) -> bool:
    if current_metrics is None or previous_best_metrics is None:
        return True

    if mode == "area":
        current = current_metrics.get("place_area_um2")
        previous = previous_best_metrics.get("place_area_um2")
        return current is not None and previous is not None and (previous - current) >= config.min_area_improvement_um2

    if mode == "perf":
        current = current_metrics.get("worst_slack_ns")
        previous = previous_best_metrics.get("worst_slack_ns")
        return current is not None and previous is not None and (current - previous) >= config.min_slack_improvement_ns

    current = current_metrics.get("synth_area_um2")
    previous = previous_best_metrics.get("synth_area_um2")
    return current is not None and previous is not None and (previous - current) >= config.min_power_proxy_improvement_um2


def reference_beaten(mode: str, current_metrics: Optional[Dict[str, Optional[float]]], reference_metrics: Optional[Dict[str, Optional[float]]]) -> bool:
    if not _has_any_metric(current_metrics) or not _has_any_metric(reference_metrics):
        return False
    return compare_metrics(mode, current_metrics, reference_metrics) >= 0


def build_feedback_prompt(
    base_prompt: str,
    target: str,
    iteration: int,
    verification: Dict[str, Any],
    previous_metrics: Optional[Dict[str, Optional[float]]],
    best_metrics: Optional[Dict[str, Optional[float]]],
    reference_metrics: Optional[Dict[str, Optional[float]]],
    use_reference_baseline: bool,
) -> str:
    guidance = ""
    if verification.get("functional_success"):
        if target == "area":
            previous_place = previous_metrics.get("place_area_um2") if previous_metrics else None
            ref_place = reference_metrics.get("place_area_um2") if reference_metrics else None
            if use_reference_baseline:
                guidance = (
                    f"Previous candidate passed functionality but placement area is {_format_metric_value(previous_place, 'um^2')} "
                    f"and reference placement area is {_format_metric_value(ref_place, 'um^2')}. "
                    "Generate a functionally equivalent TopModule with less logic duplication, simpler control logic, and lower implementation area."
                )
            else:
                guidance = (
                    f"Previous candidate passed functionality and placement area is {_format_metric_value(previous_place, 'um^2')}. "
                    "Generate a functionally equivalent TopModule with less logic duplication, simpler control logic, and lower implementation area than your previous best."
                )
        elif target == "perf":
            previous_slack = previous_metrics.get("worst_slack_ns") if previous_metrics else None
            ref_slack = reference_metrics.get("worst_slack_ns") if reference_metrics else None
            if use_reference_baseline:
                guidance = (
                    f"Previous candidate passed functionality but worst slack is {_format_metric_value(previous_slack, 'ns')} "
                    f"and reference worst slack is {_format_metric_value(ref_slack, 'ns')}. "
                    "Generate a functionally equivalent TopModule with shallower critical combinational paths and reduced logic depth."
                )
            else:
                guidance = (
                    f"Previous candidate passed functionality and worst slack is {_format_metric_value(previous_slack, 'ns')}. "
                    "Generate a functionally equivalent TopModule with shallower critical combinational paths and improved timing versus your previous best."
                )
        else:
            previous_synth = previous_metrics.get("synth_area_um2") if previous_metrics else None
            ref_synth = reference_metrics.get("synth_area_um2") if reference_metrics else None
            if use_reference_baseline:
                guidance = (
                    f"Previous candidate passed functionality but synth area is {_format_metric_value(previous_synth, 'um^2')} "
                    f"and reference synth area is {_format_metric_value(ref_synth, 'um^2')}. "
                    "Generate a functionally equivalent TopModule with lower logic complexity, lower area proxy for power, and fewer unnecessary switching opportunities."
                )
            else:
                guidance = (
                    f"Previous candidate passed functionality and synth area is {_format_metric_value(previous_synth, 'um^2')}. "
                    "Generate a functionally equivalent TopModule with lower logic complexity and fewer unnecessary switching opportunities versus your previous best."
                )
    else:
        failure_category = verification.get("failure_category") or _classify_verification_failure(verification)
        report_tail = verification.get("raw_report", "")[-1500:]
        if failure_category == "interface_fail":
            guidance = (
                "Previous candidate failed strict interface validation before simulation. "
                "Keep TopModule port names and bit-widths exactly unchanged, then fix RTL behavior.\n"
                f"Interface validation excerpt:\n{report_tail}"
            )
        elif failure_category == "compile_fail":
            guidance = (
                "Previous candidate failed compile/elaboration. "
                "Fix syntax/elaboration errors first without changing module interface.\n"
                f"Compile feedback excerpt:\n{report_tail}"
            )
        elif failure_category == "generation_parse_fail":
            guidance = (
                "Previous candidate output format could not be parsed into expected files. "
                "Return valid candidate RTL in required format and preserve interface.\n"
                f"Parser feedback excerpt:\n{report_tail}"
            )
        else:
            guidance = (
                "Previous candidate did not pass functional verification. Preserve the required behavior, fix the functional bug first, "
                "and avoid changing the module interface.\n"
                f"Verification feedback excerpt:\n{report_tail}"
            )

    feedback = {
        "target_optimization_mode": target,
        "iteration": iteration,
        "previous_metrics": _summarize_metrics(previous_metrics),
        "best_metrics_so_far": _summarize_metrics(best_metrics),
        "reference_metrics": _summarize_metrics(reference_metrics) if use_reference_baseline else {},
        "reference_baseline_enabled": use_reference_baseline,
        "previous_functional_success": verification.get("functional_success", False),
        "failure_category": verification.get("failure_category", _classify_verification_failure(verification)),
        "guidance": guidance,
    }
    return f"{base_prompt.rstrip()}\n\n[Optimization Feedback]\n{json.dumps(feedback, indent=2, sort_keys=True)}\n"


class BenchmarkProblem:
    def __init__(self, benchmark_dir: Path, dataset_dir: Path) -> None:
        self.benchmark_dir = benchmark_dir
        self.dataset_dir = dataset_dir
        self.problem_name = benchmark_dir.name
        self.problem_label = self.problem_name[:1].upper() + self.problem_name[1:]

    def _dataset_file(self, suffix: str) -> Path:
        return self.dataset_dir / f"{self.problem_label}_{suffix}"

    def _find_first_existing(self, candidates: Iterable[Path]) -> Path:
        candidate_list = list(candidates)
        for candidate in candidate_list:
            if candidate.exists():
                return candidate
        raise RuntimeError(f"Could not find required file for {self.problem_name}. Searched: {candidate_list}")

    def _read_first_existing(self, candidates: Iterable[Path]) -> str:
        return _read_text(self._find_first_existing(candidates))

    def _load_json_first_existing(self, candidates: Iterable[Path]) -> Optional[Dict[str, Any]]:
        for candidate in candidates:
            if candidate.exists():
                return json.loads(_read_text(candidate))
        return None

    def _testbench_requires_reference_module(self, testbench_text: str) -> bool:
        if "module RefModule" in testbench_text:
            return False
        return bool(re.search(r"\bRefModule\b", testbench_text))

    def _load_explicit_filelist(self, filelist_candidates: Iterable[Path]) -> Optional[List[Path]]:
        filelist_path = next((candidate for candidate in filelist_candidates if candidate.exists()), None)
        if filelist_path is None:
            return None

        resolved_paths: List[Path] = []
        seen: set[Path] = set()
        for raw_line in _read_text(filelist_path).splitlines():
            stripped = raw_line.strip()
            if not stripped or stripped.startswith("#"):
                continue
            candidate = Path(stripped)
            if not candidate.is_absolute():
                candidate = (self.benchmark_dir / candidate).resolve()
            else:
                candidate = candidate.resolve()
            if candidate in seen:
                continue
            resolved_paths.append(candidate)
            seen.add(candidate)
        return resolved_paths

    def get_testbench_path(self) -> Path:
        return self._find_first_existing(
            (
                self.benchmark_dir / "tb" / "tb.sv",
                self.benchmark_dir / "src" / "tb.sv",
                self.benchmark_dir / "test" / "tb.sv",
                self.benchmark_dir / "tb.sv",
                self._dataset_file("test.sv"),
            )
        )

    def _parse_range_width(self, range_text: Optional[str]) -> Optional[int]:
        if not range_text:
            return 1
        match = re.match(r"\[\s*(\d+)\s*:\s*(\d+)\s*\]", range_text.strip())
        if not match:
            return None
        msb = int(match.group(1))
        lsb = int(match.group(2))
        return abs(msb - lsb) + 1

    def _parse_tb_logic_declarations(self, testbench_text: str) -> Dict[str, Dict[str, Any]]:
        signal_map: Dict[str, Dict[str, Any]] = {}
        decl_pattern = re.compile(r"\blogic\s*(\[[^\]]+\])?\s*([^;]+);")
        for raw_line in testbench_text.splitlines():
            line = re.sub(r"//.*$", "", raw_line).strip()
            if not line:
                continue
            match = decl_pattern.search(line)
            if not match:
                continue
            range_text = match.group(1).strip() if match.group(1) else None
            width = self._parse_range_width(range_text)
            names_blob = match.group(2)
            for token in names_blob.split(","):
                token = token.strip()
                if not token:
                    continue
                name_match = re.match(r"([A-Za-z_][A-Za-z0-9_$]*)", token)
                if not name_match:
                    continue
                name = name_match.group(1)
                signal_map[name] = {
                    "width": width,
                    "range": range_text,
                }
        return signal_map

    def get_expected_topmodule_interface(self) -> Dict[str, Dict[str, Any]]:
        testbench_text = _read_text(self.get_testbench_path())
        top_module = self.get_candidate_output_contract()["top_module"]
        inst_pattern = re.compile(rf"\b{re.escape(top_module)}\s+\w+\s*\((.*?)\);", flags=re.DOTALL)
        inst_match = inst_pattern.search(testbench_text)
        if not inst_match:
            return {}

        connection_blob = inst_match.group(1)
        conn_pattern = re.compile(r"\.(\w+)\s*\(\s*([A-Za-z_][A-Za-z0-9_$]*)\s*\)")
        decl_map = self._parse_tb_logic_declarations(testbench_text)
        interface_map: Dict[str, Dict[str, Any]] = {}
        for port_name, signal_name in conn_pattern.findall(connection_blob):
            signal_info = decl_map.get(signal_name, {})
            interface_map[port_name] = {
                "tb_signal": signal_name,
                "expected_width": signal_info.get("width"),
                "expected_range": signal_info.get("range"),
            }
        return interface_map

    def get_strict_interface_instruction(self) -> str:
        interface_map = self.get_expected_topmodule_interface()
        if not interface_map:
            return ""

        lines = []
        for port_name in sorted(interface_map.keys()):
            expected_range = interface_map[port_name].get("expected_range")
            if expected_range:
                width_str = expected_range
            else:
                width = interface_map[port_name].get("expected_width")
                width_str = "1-bit" if width == 1 else "unknown-width"
            lines.append(f"- {port_name}: {width_str}")

        return (
            "\n\n[Strict Interface Contract]\n"
            "Your generated TopModule must keep the exact port names and widths below.\n"
            "Do not rename ports. Do not add/remove ports. Do not change bit-widths.\n"
            + "\n".join(lines)
            + "\n"
        )

    def get_reference_module_path(self, require_refmodule: bool = False) -> Optional[Path]:
        fallback_reference_path = None
        for candidate in (
            self._dataset_file("ref.sv"),
            self.benchmark_dir / "ref" / "top_ref.sv",
            self.benchmark_dir / "ref" / "ref.sv",
            self.benchmark_dir / "src" / "ref_original.sv",
            self.benchmark_dir / "src" / "top_ref.sv",
        ):
            if candidate.exists():
                reference_text = _read_text(candidate)
                if not require_refmodule or "module RefModule" in reference_text:
                    return candidate
                if fallback_reference_path is None:
                    fallback_reference_path = candidate
        return fallback_reference_path

    def get_reference_module(self, require_refmodule: bool = False) -> Optional[str]:
        reference_path = self.get_reference_module_path(require_refmodule=require_refmodule)
        if reference_path is None:
            return None
        return _read_text(reference_path)

    def get_candidate_output_contract(self) -> Dict[str, Any]:
        raw_contract = self._load_json_first_existing(
            (
                self.benchmark_dir / "candidate_contract.json",
                self.benchmark_dir / "src" / "candidate_contract.json",
            )
        ) or {}
        mode = str(raw_contract.get("mode", "single")).strip().lower()
        if mode not in {"single", "multi"}:
            raise RuntimeError(f"Invalid candidate contract mode '{mode}' for {self.problem_name}.")

        top_module = str(raw_contract.get("top_module", "TopModule")).strip() or "TopModule"
        raw_files = raw_contract.get("files") or []
        files: List[Dict[str, Any]] = []
        for index, raw_file in enumerate(raw_files):
            if isinstance(raw_file, str):
                file_name = raw_file.strip()
                module_name = Path(file_name).stem
                entry = {
                    "name": file_name,
                    "module": module_name,
                    "required": True,
                    "primary_top": (index == 0),
                }
            elif isinstance(raw_file, dict):
                file_name = str(raw_file.get("name", "")).strip()
                if not file_name:
                    raise RuntimeError(f"Candidate contract has empty file name for {self.problem_name}.")
                entry = {
                    "name": file_name,
                    "module": str(raw_file.get("module", Path(file_name).stem)).strip(),
                    "required": bool(raw_file.get("required", True)),
                    "primary_top": bool(raw_file.get("primary_top", False)),
                }
            else:
                raise RuntimeError(f"Unsupported candidate contract file entry '{raw_file}' for {self.problem_name}.")
            files.append(entry)

        if not files:
            files = [
                {
                    "name": "rtl.sv",
                    "module": top_module,
                    "required": True,
                    "primary_top": True,
                }
            ]

        primary_file = str(raw_contract.get("primary_top_file", "")).strip()
        if primary_file:
            for file_info in files:
                file_info["primary_top"] = (file_info["name"] == primary_file)
        if not any(file_info.get("primary_top") for file_info in files):
            files[0]["primary_top"] = True

        enforce_structured = bool(raw_contract.get("enforce_structured_output", mode == "multi"))
        return {
            "mode": mode,
            "top_module": top_module,
            "files": files,
            "primary_top_file": next(file_info["name"] for file_info in files if file_info.get("primary_top")),
            "enforce_structured_output": enforce_structured,
        }

    def get_candidate_file_specs(self) -> List[Dict[str, Any]]:
        return list(self.get_candidate_output_contract()["files"])

    def get_primary_candidate_file_spec(self) -> Dict[str, Any]:
        for file_info in self.get_candidate_file_specs():
            if file_info.get("primary_top"):
                return file_info
        return self.get_candidate_file_specs()[0]

    def get_candidate_file_names(self) -> List[str]:
        return [file_info["name"] for file_info in self.get_candidate_file_specs()]

    def get_verification_support_rtl_paths(self) -> List[Path]:
        explicit_paths = self._load_explicit_filelist(
            (
                self.benchmark_dir / "src" / "verify_support_files.txt",
                self.benchmark_dir / "src" / "verify_filelist.txt",
                self.benchmark_dir / "src" / "rtl_filelist.txt",
            )
        )
        if explicit_paths is not None:
            return explicit_paths

        src_dir = self.benchmark_dir / "src"
        if not src_dir.is_dir():
            return []

        support_paths: List[Path] = []
        for extension in ("*.sv", "*.v"):
            for candidate in sorted(src_dir.glob(extension), key=lambda path: path.name):
                content = _read_text(candidate)
                if "module TopModule" in content:
                    continue
                if "module RefModule" in content:
                    continue
                support_paths.append(candidate.resolve())
        return support_paths

    def get_openroad_support_rtl_paths(self) -> List[Path]:
        explicit_paths = self._load_explicit_filelist(
            (
                self.benchmark_dir / "src" / "openroad_support_files.txt",
            )
        )
        if explicit_paths is not None:
            return explicit_paths
        return self.get_verification_support_rtl_paths()

    def get_openroad_reference_file_paths(self) -> List[Path]:
        explicit_paths = self._load_explicit_filelist(
            (
                self.benchmark_dir / "src" / "openroad_ref_files.txt",
            )
        )
        if explicit_paths is not None:
            return explicit_paths
        reference_top = self.get_openroad_reference_top_path()
        if reference_top is None:
            return []
        return [reference_top]

    def get_generation_output_instruction(self) -> str:
        contract = self.get_candidate_output_contract()
        if contract["mode"] == "single":
            return ""
        file_lines = "\n".join([f"- {file_info['name']}" for file_info in contract["files"]])
        return (
            "\n\n[Candidate Output Contract]\n"
            "You are generating a multi-file candidate RTL implementation.\n"
            "Return all required files in this exact machine-readable format:\n"
            "FILE: <filename>\n"
            "```verilog\n"
            "<content>\n"
            "```\n"
            "Use exactly these filenames:\n"
            f"{file_lines}\n"
            "Do not omit any required file. Do not add unexpected filenames."
        )

    def get_openroad_reference_top_path(self) -> Optional[Path]:
        direct_top_candidates = (
            self.benchmark_dir / "src" / "top_ref_synth.sv",
            self.benchmark_dir / "src" / "top.sv",
            self.benchmark_dir / "src" / "top_ref_top.sv",
        )
        for candidate in direct_top_candidates:
            if candidate.exists():
                return candidate

        topmodule_candidates = (
            self.benchmark_dir / "src" / "ref_original.sv",
            self.benchmark_dir / "src" / "top_ref.sv",
            self.benchmark_dir / "ref" / "top_ref.sv",
            self._dataset_file("ref.sv"),
        )
        for candidate in topmodule_candidates:
            if candidate.exists() and "module TopModule" in _read_text(candidate):
                return candidate
        return None

    def validate_loaded_sources(self) -> None:
        testbench_path = self.get_testbench_path()
        testbench_text = _read_text(testbench_path)
        if not testbench_text.strip():
            raise RuntimeError(f"Loaded benchmark testbench is empty: {testbench_path}")
        if "module tb" not in testbench_text:
            raise RuntimeError(f"Loaded benchmark testbench does not contain 'module tb': {testbench_path}")

        requires_refmodule = self._testbench_requires_reference_module(testbench_text)
        reference_path = self.get_reference_module_path(require_refmodule=requires_refmodule)
        if requires_refmodule and reference_path is None:
            raise RuntimeError(
                f"Testbench requires RefModule but no reference RTL was found for {self.problem_name}. "
                f"Searched benchmark/dataset reference files under {self.benchmark_dir} and {self.dataset_dir}."
            )
        if reference_path is not None and not _read_text(reference_path).strip():
            raise RuntimeError(f"Loaded reference RTL is empty: {reference_path}")

        for support_path in self.get_verification_support_rtl_paths():
            if not support_path.exists():
                raise RuntimeError(f"Verification support RTL file not found: {support_path}")
            support_text = _read_text(support_path)
            if not support_text.strip():
                raise RuntimeError(f"Verification support RTL file is empty: {support_path}")

        contract = self.get_candidate_output_contract()
        seen_names: set[str] = set()
        for file_info in contract["files"]:
            file_name = str(file_info.get("name", "")).strip()
            if not file_name:
                raise RuntimeError(f"Candidate contract has an empty filename entry for {self.problem_name}.")
            if file_name in seen_names:
                raise RuntimeError(f"Candidate contract has duplicate filename '{file_name}' for {self.problem_name}.")
            seen_names.add(file_name)

    def get_testbench_for_verification(self) -> str:
        testbench = _read_text(self.get_testbench_path())
        requires_refmodule = self._testbench_requires_reference_module(testbench)
        if not requires_refmodule:
            return testbench

        ref_module = self.get_reference_module(require_refmodule=True)
        if ref_module:
            return testbench.rstrip() + "\n\n" + ref_module.rstrip() + "\n"
        return testbench

    def verification_requires_reference_module(self) -> bool:
        testbench = _read_text(self.get_testbench_path())
        return self._testbench_requires_reference_module(testbench)

    def get_testbench(self) -> str:
        # Backward-compatible alias for existing call sites.
        return self.get_testbench_for_verification()

    def get_prompt(self, target: str) -> str:
        if target not in SUPPORTED_TARGETS:
            raise ValueError(f"Unsupported target '{target}'. Supported targets: {SUPPORTED_TARGETS}")

        if target == "baseline":
            for candidate in (
                self.benchmark_dir / "prompt_baseline.txt",
                self.benchmark_dir / "prompt" / "prompt_baseline.txt",
                self.benchmark_dir / "prompts" / "prompt_baseline.txt",
                self.benchmark_dir / "prompt.txt",
                self.benchmark_dir / "prompts" / "prompt.txt",
                self.benchmark_dir / "prompts" / "original.txt",
                self.benchmark_dir / "prompt" / "prompt_original.txt",
                self._dataset_file("prompt.txt"),
            ):
                if candidate.exists():
                    return _read_text(candidate).rstrip() + self.get_generation_output_instruction() + "\n"
            raise FileNotFoundError(f"Could not find baseline prompt for {self.problem_name}")

        target_candidates = {
            "area": ["area"],
            "perf": ["perf", "performance"],
            "power": ["power"],
        }[target]

        direct_prompt_candidates = []
        for target_name in target_candidates:
            direct_prompt_candidates.extend(
                [
                    self.benchmark_dir / f"prompt_{target_name}.txt",
                    self.benchmark_dir / "prompt" / f"prompt_{target_name}.txt",
                    self.benchmark_dir / "prompts" / f"prompt_{target_name}.txt",
                ]
            )

        for candidate in direct_prompt_candidates:
            if candidate.exists():
                prompt_text = _read_text(candidate).rstrip()
                # Some optimization prompts only say "same functionality as original.txt".
                # Expand original spec inline so downstream agents always have concrete behavior.
                lower_prompt = prompt_text.lower()
                if "original.txt" in lower_prompt and "same functionality" in lower_prompt:
                    original_spec = self._load_original_spec_text()
                    if original_spec:
                        prompt_text = (
                            f"{prompt_text}\n\n"
                            "[Resolved Original Specification]\n"
                            f"{original_spec.rstrip()}\n"
                        )
                return prompt_text + self.get_generation_output_instruction() + "\n"

        for candidate in (
            self.benchmark_dir / "prompt.txt",
            self.benchmark_dir / "prompts" / "prompt.txt",
            self.benchmark_dir / "prompts" / "original.txt",
            self.benchmark_dir / "prompt" / "prompt_original.txt",
            self._dataset_file("prompt.txt"),
        ):
            if candidate.exists():
                base_prompt = _read_text(candidate).rstrip()
                return f"{base_prompt}\n\n[Optimization Goal]\n{TARGET_INSTRUCTION_SUFFIX[target]}\n" + self.get_generation_output_instruction() + "\n"

        raise FileNotFoundError(f"Could not find prompt for {self.problem_name} target {target}")

    def _load_original_spec_text(self) -> Optional[str]:
        for candidate in (
            self.benchmark_dir / "prompts" / "original.txt",
            self.benchmark_dir / "prompt" / "prompt_original.txt",
            self.benchmark_dir / "prompt.txt",
            self.benchmark_dir / "prompts" / "prompt.txt",
            self._dataset_file("prompt.txt"),
        ):
            if candidate.exists():
                return _read_text(candidate)
        return None


class OptimizationLoopController:
    def __init__(
        self,
        coder: VerilogCoder,
        evaluator: OpenROADEvaluator,
        benchmark_root: str,
        dataset_root: str,
        config: Optional[OptimizationLoopConfig] = None,
    ) -> None:
        self.coder = coder
        self.evaluator = evaluator
        self.benchmark_root = Path(benchmark_root).expanduser().resolve()
        self.dataset_root = Path(dataset_root).expanduser().resolve()
        self.config = config or OptimizationLoopConfig()

    def _persist_best(self, target_dir: Path, best_result: Dict[str, Any]) -> None:
        rtl_path = Path(best_result["iter_dir"]) / "rtl.sv"
        if rtl_path.exists():
            shutil.copyfile(rtl_path, target_dir / "best.sv")
        generated_dir = Path(best_result["iter_dir"]) / "generated"
        if generated_dir.is_dir():
            best_generated_dir = target_dir / "best_generated"
            if best_generated_dir.exists():
                shutil.rmtree(best_generated_dir)
            shutil.copytree(generated_dir, best_generated_dir)
        _write_json(target_dir / "best.json", best_result)

    def _parse_file_blocks(self, rtl_text: str) -> Dict[str, str]:
        blocks: Dict[str, str] = {}
        pattern = re.compile(
            r"(?ms)^\s*FILE:\s*([A-Za-z0-9_.\-/]+)\s*\n(.*?)(?=^\s*FILE:\s*[A-Za-z0-9_.\-/]+\s*$|\Z)"
        )
        for match in pattern.finditer(rtl_text):
            file_name = match.group(1).strip()
            body = match.group(2).strip()
            fenced_match = re.match(r"(?is)^```(?:systemverilog|verilog)?\s*\n(.*)\n```$", body)
            if fenced_match:
                body = fenced_match.group(1).strip()
            blocks[file_name] = body
        return blocks

    def _extract_module_blocks(self, rtl_text: str) -> Dict[str, str]:
        module_blocks: Dict[str, str] = {}
        pattern = re.compile(r"(?is)\bmodule\s+([A-Za-z_][A-Za-z0-9_]*)\b.*?\bendmodule\b")
        for match in pattern.finditer(rtl_text):
            module_name = match.group(1)
            module_blocks[module_name] = match.group(0).strip()
        return module_blocks

    def _extract_topmodule_port_map(self, rtl_text: str, top_module_name: str) -> Dict[str, Dict[str, Any]]:
        module_block_pattern = re.compile(
            rf"(?is)\bmodule\s+{re.escape(top_module_name)}\b.*?\bendmodule\b"
        )
        module_block_match = module_block_pattern.search(rtl_text)
        if not module_block_match:
            return {}
        module_block = module_block_match.group(0)

        header_blob = module_block
        module_pattern = re.compile(rf"(?is)\bmodule\s+{re.escape(top_module_name)}\b(.*?)\);")
        module_match = module_pattern.search(module_block)
        if module_match:
            header_blob = module_match.group(1)
        port_map: Dict[str, Dict[str, Any]] = {}
        decl_pattern = re.compile(r"^\s*(input|output)\s+(.*)$")

        def _parse_decl(direction: str, rest: str) -> Tuple[Optional[int], Optional[str], List[str]]:
            rest = re.sub(r"\b(?:logic|wire|reg|signed)\b", " ", rest)
            range_match = re.search(r"(\[[^\]]+\])", rest)
            range_text_local = range_match.group(1).strip() if range_match else None
            width_local: Optional[int] = None
            if range_text_local:
                width_match = re.match(r"\[\s*(\d+)\s*:\s*(\d+)\s*\]", range_text_local)
                if width_match:
                    msb = int(width_match.group(1))
                    lsb = int(width_match.group(2))
                    width_local = abs(msb - lsb) + 1
            else:
                width_local = 1
            rest_clean = rest.replace(range_text_local, " ") if range_text_local else rest
            names_local: List[str] = []
            for token in rest_clean.split(","):
                name_match = re.search(r"([A-Za-z_][A-Za-z0-9_$]*)", token)
                if name_match:
                    names_local.append(name_match.group(1))
            return width_local, range_text_local, names_local

        # First pass: line-oriented ANSI style
        for raw_line in header_blob.splitlines():
            line = re.sub(r"//.*$", "", raw_line).strip()
            if not line:
                continue
            match = decl_pattern.match(line)
            if not match:
                continue
            direction = match.group(1).strip()
            width, range_text, names = _parse_decl(direction, match.group(2))
            for name in names:
                port_map[name] = {
                    "direction": direction,
                    "width": width,
                    "range": range_text,
                }
        if port_map:
            return port_map

        # Second pass: single-line ANSI style
        flat_header = re.sub(r"//.*$", "", header_blob.replace("\n", " "))
        current_direction: Optional[str] = None
        current_range: Optional[str] = None
        current_width: Optional[int] = None
        for raw_segment in flat_header.split(","):
            segment = raw_segment.strip().strip("()")
            if not segment:
                continue
            dir_match = re.search(r"\b(input|output)\b", segment)
            if dir_match:
                current_direction = dir_match.group(1)
                if re.search(r"(\[[^\]]+\])", segment) is None:
                    current_range = None
                    current_width = 1
            if current_direction is None:
                continue

            range_match = re.search(r"(\[[^\]]+\])", segment)
            if range_match:
                current_range = range_match.group(1).strip()
                width_match = re.match(r"\[\s*(\d+)\s*:\s*(\d+)\s*\]", current_range)
                if width_match:
                    msb = int(width_match.group(1))
                    lsb = int(width_match.group(2))
                    current_width = abs(msb - lsb) + 1
                else:
                    current_width = None
            elif current_range is None:
                current_width = 1

            cleaned = re.sub(r"\b(input|output|logic|wire|reg|signed)\b", " ", segment)
            if current_range:
                cleaned = cleaned.replace(current_range, " ")
            name_tokens = re.findall(r"([A-Za-z_][A-Za-z0-9_$]*)", cleaned)
            if not name_tokens:
                continue
            for name in name_tokens:
                port_map[name] = {
                    "direction": current_direction,
                    "width": current_width,
                    "range": current_range,
                }
        if port_map:
            return port_map

        # Fallback: support ANSI-noncompliant style where ports are declared inside module body.
        for raw_line in module_block.splitlines():
            line = re.sub(r"//.*$", "", raw_line).strip()
            if not line:
                continue
            match = decl_pattern.match(line)
            if not match:
                continue
            direction = match.group(1).strip()
            rest = match.group(2)
            rest = re.sub(r"\b(?:logic|wire|reg|signed)\b", " ", rest)
            range_match = re.search(r"(\[[^\]]+\])", rest)
            range_text = range_match.group(1).strip() if range_match else None
            width = None
            if range_text:
                width_match = re.match(r"\[\s*(\d+)\s*:\s*(\d+)\s*\]", range_text)
                if width_match:
                    msb = int(width_match.group(1))
                    lsb = int(width_match.group(2))
                    width = abs(msb - lsb) + 1
            else:
                width = 1
            rest_clean = rest.replace(range_text, " ") if range_text else rest
            for token in rest_clean.split(","):
                name_match = re.search(r"([A-Za-z_][A-Za-z0-9_$]*)", token)
                if not name_match:
                    continue
                name = name_match.group(1)
                port_map[name] = {
                    "direction": direction,
                    "width": width,
                    "range": range_text,
                }
        return port_map

    def _validate_candidate_interface(
        self,
        primary_candidate_content: str,
        top_module_name: str,
        expected_interface: Dict[str, Dict[str, Any]],
    ) -> Tuple[bool, str]:
        if not expected_interface:
            return True, ""

        generated_ports = self._extract_topmodule_port_map(primary_candidate_content, top_module_name)
        if not generated_ports:
            return False, f"Module '{top_module_name}' header/ports could not be parsed from generated RTL."

        expected_port_names = set(expected_interface.keys())
        generated_port_names = set(generated_ports.keys())

        missing_ports = sorted(expected_port_names - generated_port_names)
        extra_ports = sorted(generated_port_names - expected_port_names)
        width_mismatches: List[str] = []
        for port_name in sorted(expected_port_names & generated_port_names):
            expected_width = expected_interface[port_name].get("expected_width")
            generated_width = generated_ports[port_name].get("width")
            if expected_width is not None and generated_width is not None and expected_width != generated_width:
                width_mismatches.append(
                    f"{port_name}: expected {expected_width} bits, got {generated_width} bits"
                )

        if not missing_ports and not extra_ports and not width_mismatches:
            return True, ""

        detail_lines = []
        if missing_ports:
            detail_lines.append("Missing ports: " + ", ".join(missing_ports))
        if extra_ports:
            detail_lines.append("Unexpected ports: " + ", ".join(extra_ports))
        if width_mismatches:
            detail_lines.append("Width mismatches: " + "; ".join(width_mismatches))
        return False, " | ".join(detail_lines)

    def _parse_generated_candidate_files(
        self,
        problem: BenchmarkProblem,
        completed_verilog: str,
    ) -> Tuple[bool, Dict[str, str], Dict[str, Any]]:
        contract = problem.get_candidate_output_contract()
        expected_specs = problem.get_candidate_file_specs()
        expected_names = [spec["name"] for spec in expected_specs]
        expected_set = set(expected_names)
        parse_debug: Dict[str, Any] = {
            "contract_mode": contract["mode"],
            "expected_files": expected_names,
            "parse_mode": None,
            "error": "",
        }

        if contract["mode"] == "single":
            primary_name = contract["primary_top_file"]
            parse_debug["parse_mode"] = "single"
            return True, {primary_name: completed_verilog.strip()}, parse_debug

        file_blocks = self._parse_file_blocks(completed_verilog)
        if file_blocks:
            parse_debug["parse_mode"] = "file_blocks"
            unknown_names = sorted([name for name in file_blocks.keys() if name not in expected_set])
            if unknown_names:
                parse_debug["error"] = f"Unexpected generated filenames: {unknown_names}"
                return False, {}, parse_debug
            missing_required = [
                spec["name"]
                for spec in expected_specs
                if spec.get("required", True) and (spec["name"] not in file_blocks or not file_blocks[spec["name"]].strip())
            ]
            if missing_required:
                parse_debug["error"] = f"Missing required generated files: {missing_required}"
                return False, {}, parse_debug
            normalized = {name: file_blocks.get(name, "").strip() for name in expected_names if name in file_blocks}
            primary_file = contract["primary_top_file"]
            top_module = contract["top_module"]
            primary_text = normalized.get(primary_file, "")
            if not re.search(rf"\bmodule\s+{re.escape(top_module)}\b", primary_text):
                parse_debug["error"] = (
                    f"Primary generated file '{primary_file}' does not contain module '{top_module}'."
                )
                return False, {}, parse_debug
            return True, normalized, parse_debug

        if contract.get("enforce_structured_output", False):
            parse_debug["parse_mode"] = "module_extract_fallback"
            parse_debug["warning"] = (
                "Expected FILE: <filename> structured multi-file output, but no file blocks were found. "
                "Falling back to module extraction."
            )
        else:
            parse_debug["parse_mode"] = "module_extract"
        module_blocks = self._extract_module_blocks(completed_verilog)
        generated_files: Dict[str, str] = {}
        missing_required_modules: List[str] = []
        for spec in expected_specs:
            module_name = str(spec.get("module", "")).strip()
            file_name = spec["name"]
            if not module_name:
                if spec.get("required", True):
                    missing_required_modules.append(file_name)
                continue
            module_text = module_blocks.get(module_name)
            if module_text:
                generated_files[file_name] = module_text
            elif spec.get("required", True):
                missing_required_modules.append(file_name)
        if missing_required_modules:
            parse_debug["error"] = (
                "Failed to derive all required candidate files from module extraction. "
                f"Missing: {missing_required_modules}. "
                "Provide explicit FILE: <name> blocks or include required modules in the generated RTL."
            )
            return False, {}, parse_debug
        primary_file = contract["primary_top_file"]
        top_module = contract["top_module"]
        primary_text = generated_files.get(primary_file, "")
        if not re.search(rf"\bmodule\s+{re.escape(top_module)}\b", primary_text):
            parse_debug["error"] = (
                f"Primary generated file '{primary_file}' does not contain module '{top_module}'."
            )
            return False, {}, parse_debug
        return True, generated_files, parse_debug

    def get_generated_candidate_paths(
        self,
        iter_dir: Path,
        problem: BenchmarkProblem,
        generated_files: Dict[str, str],
    ) -> List[Path]:
        contract = problem.get_candidate_output_contract()
        if contract["mode"] == "single":
            return [iter_dir / "rtl.sv"]
        generated_root = iter_dir / "generated"
        ordered_paths: List[Path] = []
        for spec in problem.get_candidate_file_specs():
            file_name = spec["name"]
            if file_name in generated_files:
                ordered_paths.append(generated_root / file_name)
        return ordered_paths

    def get_primary_generated_top_path(self, iter_dir: Path, problem: BenchmarkProblem) -> Path:
        contract = problem.get_candidate_output_contract()
        if contract["mode"] == "single":
            return iter_dir / "rtl.sv"
        return (iter_dir / "generated" / contract["primary_top_file"]).resolve()

    def write_generated_candidate_files(
        self,
        iter_dir: Path,
        problem: BenchmarkProblem,
        completed_verilog: str,
    ) -> Tuple[List[Path], str, Dict[str, Any]]:
        parse_ok, generated_files, parse_debug = self._parse_generated_candidate_files(problem, completed_verilog)
        if not parse_ok:
            return [], "", {"parse_success": False, **parse_debug}

        contract = problem.get_candidate_output_contract()
        if contract["mode"] == "single":
            primary_content = generated_files[contract["primary_top_file"]].strip()
            _write_text(iter_dir / "rtl.sv", primary_content + "\n")
            return [iter_dir / "rtl.sv"], primary_content, {"parse_success": True, **parse_debug}

        generated_root = iter_dir / "generated"
        generated_root.mkdir(parents=True, exist_ok=True)
        ordered_paths = self.get_generated_candidate_paths(iter_dir, problem, generated_files)
        for path in ordered_paths:
            file_name = str(path.relative_to(generated_root))
            content = generated_files.get(file_name, "").strip()
            _write_text(path, content + "\n")

        primary_name = contract["primary_top_file"]
        primary_content = generated_files.get(primary_name, "").strip()
        _write_text(iter_dir / "rtl.sv", primary_content + "\n")
        return ordered_paths, primary_content, {
            "parse_success": True,
            **parse_debug,
            "generated_files": [str(path.relative_to(iter_dir)) for path in ordered_paths],
            "primary_top_file": primary_name,
        }

    def _build_iteration_row(self, problem_name: str, target: str, result: Dict[str, Any], is_best: bool) -> Dict[str, Any]:
        metrics = result.get("metrics") or {}
        verification = result.get("verification") or {}
        return {
            "problem_name": problem_name,
            "target": target,
            "iteration": result.get("iteration"),
            "functional_success": verification.get("functional_success"),
            "openroad_returncode": (result.get("openroad_eval") or {}).get("orfs_returncode"),
            "metrics_may_be_stale": (result.get("openroad_eval") or {}).get("metrics_may_be_stale"),
            "synth_area_um2": metrics.get("synth_area_um2"),
            "place_area_um2": metrics.get("place_area_um2"),
            "worst_slack_ns": metrics.get("worst_slack_ns"),
            "tns_ns": metrics.get("tns_ns"),
            "final_hpwl_um": metrics.get("final_hpwl_um"),
            "stop_reason": result.get("stop_reason"),
            "is_best": is_best,
        }

    def _write_failure_debug_artifacts(
        self,
        iter_dir: Path,
        verify_result: Dict[str, Any],
        verification_exception: Optional[Exception],
    ) -> None:
        work_paths = self.coder.verilog_tools.get_work_paths()
        compile_input_path = Path(work_paths["test_sv"])
        compile_input_exists = compile_input_path.exists()
        if compile_input_exists:
            _write_text(iter_dir / "compile_input_test.sv", _read_text(compile_input_path))
        wave_path = Path(work_paths["wave"])
        if wave_path.exists():
            shutil.copyfile(wave_path, iter_dir / "wave.vcd")

        module_tb_detected = False
        if compile_input_exists:
            module_tb_detected = "module tb" in _read_text(compile_input_path)

        debug_payload = {
            "functional_success": verify_result.get("functional_success", False),
            "exception": str(verification_exception) if verification_exception is not None else "",
            "module_tb_detected": module_tb_detected,
            "paths_used": {
                "workdir": self.coder.verilog_tools.workdir,
                "test_sv": work_paths.get("test_sv"),
                "test_vpp": self.coder.verilog_tools.test_vpp_file_path,
                "verilog": work_paths.get("verilog"),
                "wave": work_paths.get("wave"),
                "extra_compile_verilog_paths": work_paths.get("extra_compile_verilog_paths", []),
            },
            "compile_argv": work_paths.get("last_compile_argv", []),
        }
        _write_json(iter_dir / "debug.json", debug_payload)

    def run_problem(self, problem_name: str, targets: Iterable[str] = TARGETS) -> Dict[str, Any]:
        benchmark_dir = self.benchmark_root / problem_name
        if not benchmark_dir.is_dir():
            raise FileNotFoundError(f"Benchmark dir not found: {benchmark_dir}")

        problem = BenchmarkProblem(benchmark_dir=benchmark_dir, dataset_dir=self.dataset_root)
        problem.validate_loaded_sources()
        optimization_root = benchmark_dir / "optimization_runs"
        optimization_root.mkdir(parents=True, exist_ok=True)
        candidate_contract = problem.get_candidate_output_contract()

        reference_orfs_files = [str(path) for path in problem.get_openroad_reference_file_paths()]
        run_reference_openroad = bool(
            self.config.use_reference_baseline and self.config.run_openroad and len(reference_orfs_files) > 0
        )
        if self.config.use_reference_baseline:
            reference_eval = self.evaluator.evaluate(
                problem_name=problem_name,
                version="ref",
                top_verilog_src=reference_orfs_files[0] if len(reference_orfs_files) > 0 else None,
                candidate_verilog_srcs=reference_orfs_files,
                support_verilog_srcs=[],
                top_module_name=candidate_contract["top_module"],
                run_orfs=run_reference_openroad,
                copy_artifacts_dir=str(optimization_root / "ref_openroad_artifacts"),
            )
        else:
            reference_eval = {
                "problem_name": problem_name,
                "version": "ref",
                "run_orfs": False,
                "status": "skipped_reference_baseline_disabled",
                "metrics": {},
                "metrics_may_be_stale": False,
                "candidate_rtl_files": reference_orfs_files,
                "support_rtl_files": [],
                "primary_top_module": candidate_contract["top_module"],
            }
        _write_json(optimization_root / "ref_metrics.json", reference_eval)

        summary: Dict[str, Any] = {
            "problem_name": problem_name,
            "benchmark_dir": str(benchmark_dir),
            "optimization_root": str(optimization_root),
            "reference": reference_eval,
            "reference_usage": {
                "required_for_generation": False,
                "required_for_functional_verification": problem.verification_requires_reference_module(),
                "used_for_openroad_baseline": bool(self.config.use_reference_baseline and len(reference_orfs_files) > 0),
                "reference_baseline_enabled": bool(self.config.use_reference_baseline),
                "openroad_reference_files": reference_orfs_files,
            },
            "targets": {},
            "final_candidates": {},
            "config": asdict(self.config),
            "candidate_contract": candidate_contract,
        }
        csv_rows: list[Dict[str, Any]] = []
        overall_iteration_history: Dict[str, Any] = {"problem_name": problem_name, "targets": {}}
        best_by_target: Dict[str, Any] = {"problem_name": problem_name, "targets": {}}
        testbench = problem.get_testbench_for_verification()
        strict_interface_instruction = problem.get_strict_interface_instruction()
        expected_interface = problem.get_expected_topmodule_interface()
        verification_support_paths = [str(path) for path in problem.get_verification_support_rtl_paths()]
        openroad_support_paths = [str(path) for path in problem.get_openroad_support_rtl_paths()]

        normalized_targets = list(targets)
        for target in normalized_targets:
            if target not in SUPPORTED_TARGETS:
                raise ValueError(f"Unsupported target '{target}'. Supported targets: {SUPPORTED_TARGETS}")

        for target in normalized_targets:
            target_dir = optimization_root / target
            target_dir.mkdir(parents=True, exist_ok=True)

            best_result: Optional[Dict[str, Any]] = None
            best_metrics: Optional[Dict[str, Optional[float]]] = None
            previous_best_metrics: Optional[Dict[str, Optional[float]]] = None
            history: list[Dict[str, Any]] = []
            no_improvement_count = 0
            functional_failures = 0

            target_max_iterations = (
                self.config.baseline_max_iterations if target == "baseline" else self.config.max_iterations
            )
            for iteration in range(target_max_iterations):
                iter_dir = target_dir / f"iter_{iteration}"
                iter_dir.mkdir(parents=True, exist_ok=True)

                base_prompt = problem.get_prompt(target)
                if iteration == 0:
                    prompt_text = base_prompt
                else:
                    prompt_text = build_feedback_prompt(
                        base_prompt=base_prompt,
                        target=target,
                        iteration=iteration,
                        verification=history[-1]["verification"],
                        previous_metrics=history[-1].get("metrics"),
                        best_metrics=best_metrics,
                        reference_metrics=reference_eval.get("metrics"),
                        use_reference_baseline=self.config.use_reference_baseline,
                    )

                if strict_interface_instruction:
                    prompt_text = prompt_text.rstrip() + strict_interface_instruction
                _write_text(iter_dir / "prompt.txt", prompt_text)

                task_id = f"{problem_name}_{target}_iter{iteration}"
                self.coder.verilog_tools.reset()
                success = self.coder.write_Verilog_module(
                    cur_task_id=task_id,
                    spec=prompt_text,
                    golden_test_bench=testbench,
                    benchmark_support_rtl_paths=verification_support_paths,
                    plan_filename="",
                    have_plans=False,
                    skip_kg_plan=True,
                )

                completed_verilog = (self.coder.verilog_tools.completed_verilog or "").strip()
                candidate_paths, primary_candidate_content, candidate_parse = self.write_generated_candidate_files(
                    iter_dir=iter_dir,
                    problem=problem,
                    completed_verilog=completed_verilog,
                )
                primary_candidate_path = self.get_primary_generated_top_path(iter_dir, problem)
                candidate_path_strings = [str(path) for path in candidate_paths]
                primary_candidate_path_string = str(primary_candidate_path)
                other_candidate_paths = [str(path) for path in candidate_paths if str(path) != primary_candidate_path_string]

                verify_result: Dict[str, Any]
                verification_exception: Optional[Exception] = None
                if candidate_parse.get("parse_success"):
                    interface_ok, interface_error = self._validate_candidate_interface(
                        primary_candidate_content=primary_candidate_content,
                        top_module_name=candidate_contract["top_module"],
                        expected_interface=expected_interface,
                    )
                    if not interface_ok:
                        verify_result = {
                            "compiled_success": False,
                            "functional_success": False,
                            "generation_success": success,
                            "module_available": True,
                            "raw_report": (
                                "[Interface Check Failed] Generated TopModule interface does not match testbench expectation.\n"
                                + interface_error
                            ),
                        }
                    else:
                        try:
                            compile_extra_paths = []
                            for compile_path in [*verification_support_paths, *other_candidate_paths]:
                                if compile_path not in compile_extra_paths:
                                    compile_extra_paths.append(compile_path)
                            self.coder.verilog_tools.load_test_bench(
                                task_id=task_id,
                                spec=prompt_text,
                                test_bench=testbench,
                                write_file=False,
                                extra_compile_verilog_paths=compile_extra_paths,
                            )
                            verify_report = self.coder.verilog_tools.verilog_simulation_tool(
                                completed_verilog=primary_candidate_content
                            )
                            verify_result = _parse_verification_report(verify_report)
                            verify_result["generation_success"] = success
                            verify_result["module_available"] = True
                            if os.path.exists(self.coder.verilog_tools.wave_vcd_file_path):
                                shutil.copyfile(self.coder.verilog_tools.wave_vcd_file_path, iter_dir / "wave.vcd")
                        except Exception as exc:
                            verification_exception = exc
                            verify_result = {
                                "compiled_success": False,
                                "functional_success": False,
                                "generation_success": success,
                                "module_available": True,
                                "raw_report": f"Verification raised an exception: {exc}",
                            }
                elif completed_verilog:
                    verify_result = {
                        "compiled_success": False,
                        "functional_success": False,
                        "generation_success": success,
                        "module_available": True,
                        "raw_report": "Generated RTL could not be parsed into the expected candidate file set. "
                        + str(candidate_parse.get("error", "")),
                    }
                else:
                    verify_result = {
                        "compiled_success": False,
                        "functional_success": False,
                        "generation_success": success,
                        "module_available": False,
                        "raw_report": "No completed RTL was available after the VerilogCoder run.",
                    }
                verify_result["generation_parse"] = candidate_parse
                verify_result["candidate_files"] = candidate_path_strings
                verify_result["candidate_primary_top_file"] = primary_candidate_path_string
                verify_result["support_files"] = list(verification_support_paths)
                verify_result["compile_argv"] = list(self.coder.verilog_tools.last_compile_argv)
                verify_result["failure_category"] = _classify_verification_failure(verify_result)
                _write_json(iter_dir / "verify.json", verify_result)

                iteration_result: Dict[str, Any] = {
                    "iteration": iteration,
                    "iter_dir": str(iter_dir),
                    "verification": verify_result,
                    "metrics": None,
                    "openroad_eval": None,
                    "stop_reason": None,
                    "candidate_files": candidate_path_strings,
                    "candidate_primary_top_file": primary_candidate_path_string,
                }

                if not verify_result["functional_success"]:
                    self._write_failure_debug_artifacts(iter_dir, verify_result, verification_exception)
                    debug_artifacts = getattr(self.coder, "last_debug_artifacts", {}) or {}
                    last_submitted_rtl = debug_artifacts.get("last_submitted_rtl", "")
                    if last_submitted_rtl:
                        _write_text(iter_dir / "last_submitted_rtl.sv", last_submitted_rtl + "\n")
                    _write_json(iter_dir / "debug_attempts.json", {"debug_attempts": debug_artifacts.get("debug_attempts", [])})
                    _write_json(iter_dir / "mismatch_history.json", {"mismatch_history": debug_artifacts.get("mismatch_history", [])})
                    skipped_openroad_eval = {
                        "problem_name": problem_name,
                        "version": target,
                        "run_orfs": False,
                        "status": "skipped_functional_failure",
                        "metrics": {},
                        "metrics_may_be_stale": False,
                        "candidate_rtl_files": candidate_path_strings,
                        "support_rtl_files": list(openroad_support_paths),
                        "primary_top_module": candidate_contract["top_module"],
                    }
                    iteration_result["openroad_eval"] = skipped_openroad_eval
                    iteration_result["metrics"] = {}
                    _write_json(iter_dir / "openroad_eval.json", skipped_openroad_eval)
                    _write_json(iter_dir / "metrics.json", {})
                    functional_failures += 1
                    if functional_failures >= self.config.functional_failure_limit:
                        iteration_result["stop_reason"] = "functional_failure_limit"
                    elif target == "baseline" and iteration == target_max_iterations - 1:
                        iteration_result["stop_reason"] = "functional_failure_baseline"
                    else:
                        iteration_result["stop_reason"] = "functional_retry"
                    history.append(iteration_result)
                    csv_rows.append(self._build_iteration_row(problem_name, target, iteration_result, False))
                    if iteration_result["stop_reason"] == "functional_failure_limit":
                        break
                    continue

                try:
                    openroad_eval = self.evaluator.evaluate(
                        problem_name=problem_name,
                        version=target,
                        top_verilog_src=primary_candidate_path_string,
                        candidate_verilog_srcs=candidate_path_strings,
                        support_verilog_srcs=openroad_support_paths,
                        top_module_name=candidate_contract["top_module"],
                        run_orfs=self.config.run_openroad,
                        copy_artifacts_dir=str(iter_dir / "openroad_artifacts"),
                    )
                except FileNotFoundError as exc:
                    # Keep optimization loop robust when ORFS design scaffolding is absent.
                    openroad_eval = {
                        "problem_name": problem_name,
                        "version": target,
                        "run_orfs": False,
                        "status": "skipped_openroad_missing_design_dir",
                        "metrics": {},
                        "metrics_may_be_stale": False,
                        "candidate_rtl_files": candidate_path_strings,
                        "support_rtl_files": list(openroad_support_paths),
                        "primary_top_module": candidate_contract["top_module"],
                        "error": str(exc),
                    }
                metrics = openroad_eval.get("metrics")
                iteration_result["openroad_eval"] = openroad_eval
                iteration_result["metrics"] = metrics
                _write_json(iter_dir / "openroad_eval.json", openroad_eval)
                _write_json(iter_dir / "metrics.json", metrics or {})

                current_is_better = compare_metrics(target, metrics, best_metrics) > 0
                if best_result is None or current_is_better:
                    previous_best_metrics = best_metrics
                    best_result = iteration_result
                    best_metrics = metrics
                    if previous_best_metrics is not None and meaningful_improvement(target, best_metrics, previous_best_metrics, self.config):
                        no_improvement_count = 0
                    elif previous_best_metrics is not None:
                        no_improvement_count += 1
                else:
                    no_improvement_count += 1

                if openroad_eval.get("metrics_may_be_stale"):
                    iteration_result["stop_reason"] = "openroad_failed_saved_run_stale"
                elif target == "baseline":
                    iteration_result["stop_reason"] = "baseline_complete"
                elif self.config.use_reference_baseline and reference_beaten(target, metrics, reference_eval.get("metrics")):
                    iteration_result["stop_reason"] = "reference_beaten"
                elif no_improvement_count >= self.config.no_improvement_limit:
                    iteration_result["stop_reason"] = "no_improvement"
                elif iteration == target_max_iterations - 1:
                    iteration_result["stop_reason"] = "max_iterations"
                else:
                    iteration_result["stop_reason"] = "continue"

                history.append(iteration_result)
                csv_rows.append(
                    self._build_iteration_row(
                        problem_name,
                        target,
                        iteration_result,
                        best_result is iteration_result,
                    )
                )

                if iteration_result["stop_reason"] != "continue":
                    break

            if best_result is not None:
                self._persist_best(target_dir, best_result)
                best_by_target["targets"][target] = best_result
            else:
                best_by_target["targets"][target] = None

            target_summary = {
                "best_result": best_result,
                "iteration_history": history,
                "locally_optimal": bool(
                    best_result
                    and best_result.get("stop_reason")
                    in (
                        {"reference_beaten", "no_improvement", "max_iterations", "baseline_complete"}
                        if self.config.use_reference_baseline
                        else {"no_improvement", "max_iterations", "baseline_complete"}
                    )
                ),
            }
            summary["targets"][target] = target_summary
            overall_iteration_history["targets"][target] = history
            summary["final_candidates"][target] = {
                "metrics": best_result.get("metrics") if best_result else None,
                "best_iteration": best_result.get("iteration") if best_result else None,
                "stop_reason": best_result.get("stop_reason") if best_result else None,
                "locally_optimal": target_summary["locally_optimal"],
            }
            _write_json(target_dir / "iteration_history.json", {"problem_name": problem_name, "target": target, "history": history})

        _write_json(optimization_root / "iteration_history.json", overall_iteration_history)
        _write_json(optimization_root / "best.json", best_by_target)
        _write_json(optimization_root / "summary.json", summary)

        csv_path = optimization_root / "summary.csv"
        fieldnames = [
            "problem_name",
            "target",
            "iteration",
            "functional_success",
            "openroad_returncode",
            "metrics_may_be_stale",
            "synth_area_um2",
            "place_area_um2",
            "worst_slack_ns",
            "tns_ns",
            "final_hpwl_um",
            "stop_reason",
            "is_best",
        ]
        with csv_path.open("w", newline="") as csv_file:
            writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(csv_rows)

        _copy_file(optimization_root / "summary.json", benchmark_dir / "summary.json")
        _copy_file(csv_path, benchmark_dir / "summary.csv")

        return summary
