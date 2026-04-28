from __future__ import annotations

import os
import re
import shutil
import subprocess
from pathlib import Path
from typing import Any, Dict, List, Optional


class OpenROADEvaluator:
    """Prepare ORFS design inputs, optionally run the flow, and parse saved-run metrics."""

    _FLOAT_RE = r"(-?\d+(?:\.\d+)?)"

    def __init__(
        self,
        orfs_flow_dir: str,
        platform: str = "nangate45",
        make_command: Optional[list[str]] = None,
    ) -> None:
        self.orfs_flow_dir = Path(orfs_flow_dir).expanduser().resolve()
        self.platform = platform
        self.designs_root = self.orfs_flow_dir / "designs" / platform
        self.saved_runs_root = self.orfs_flow_dir / "saved_runs"
        self.make_command = make_command or ["make"]

    def _copy_file_if_exists(self, source: Optional[Path], destination_root: Path) -> Optional[str]:
        if source is None or not source.exists():
            return None
        destination_root.mkdir(parents=True, exist_ok=True)
        target = destination_root / source.name
        shutil.copy2(source, target)
        return str(target)

    def _normalize_problem_name(self, problem_name: str) -> str:
        match = re.match(r"(prob\d+)", problem_name)
        if not match:
            raise ValueError(
                f"Could not derive ORFS problem key from '{problem_name}'. Expected names like prob105_rotate100."
            )
        return match.group(1)

    def _design_stem(self, problem_name: str, version: str) -> str:
        return f"{self._normalize_problem_name(problem_name)}_{version}"

    def get_design_dir(self, problem_name: str, version: str) -> Path:
        return self.designs_root / self._design_stem(problem_name, version)

    def get_saved_run_dir(self, problem_name: str, version: str) -> Path:
        return self.saved_runs_root / self._design_stem(problem_name, version)

    def _first_executable(self, candidates: list[str | None]) -> Optional[str]:
        for candidate in candidates:
            if not candidate:
                continue
            candidate_path = Path(candidate).expanduser()
            if candidate_path.is_absolute():
                resolved = candidate_path.resolve()
                if resolved.exists() and os.access(resolved, os.X_OK):
                    return str(resolved)
                continue
            resolved = shutil.which(str(candidate_path))
            if resolved and os.access(resolved, os.X_OK):
                return str(Path(resolved).resolve())
        return None

    def discover_tool_paths(self) -> Dict[str, Optional[str]]:
        default_openroad = self.orfs_flow_dir.parent / "tools" / "install" / "OpenROAD" / "bin" / "openroad"
        default_opensta = self.orfs_flow_dir.parent / "tools" / "install" / "OpenROAD" / "bin" / "sta"
        default_yosys = self.orfs_flow_dir.parent / "tools" / "install" / "yosys" / "bin" / "yosys"
        default_klayout = self.orfs_flow_dir.parent / "tools" / "install" / "klayout" / "klayout"

        return {
            "YOSYS_EXE": self._first_executable([os.environ.get("YOSYS_EXE"), "yosys", str(default_yosys)]),
            "OPENROAD_EXE": self._first_executable([os.environ.get("OPENROAD_EXE"), "openroad", str(default_openroad)]),
            "OPENSTA_EXE": self._first_executable([os.environ.get("OPENSTA_EXE"), "sta", str(default_opensta)]),
            "KLAYOUT_CMD": self._first_executable([os.environ.get("KLAYOUT_CMD"), "klayout", str(default_klayout)]),
            "DOCKER_EXE": self._first_executable([os.environ.get("DOCKER_EXE"), "docker"]),
        }

    def _run_cmd(self, cmd: list[str], cwd: Path) -> Dict[str, object]:
        env = os.environ.copy()
        tool_paths = self.discover_tool_paths()
        for env_name in ("YOSYS_EXE", "OPENROAD_EXE", "OPENSTA_EXE", "KLAYOUT_CMD"):
            if tool_paths.get(env_name) and not env.get(env_name):
                env[env_name] = str(tool_paths[env_name])
        proc = subprocess.run(
            cmd,
            cwd=str(cwd),
            capture_output=True,
            text=True,
            check=False,
            env=env,
        )
        return {
            "returncode": proc.returncode,
            "stdout": proc.stdout,
            "stderr": proc.stderr,
            "cmd": cmd,
            "cwd": str(cwd),
            "tool_paths": tool_paths,
        }

    def _parse_make_exports(self, config_path: Path) -> Dict[str, str]:
        exports: Dict[str, str] = {}
        for raw_line in config_path.read_text().splitlines():
            line = raw_line.strip()
            if not line.startswith("export "):
                continue
            match = re.match(r"export\s+([A-Za-z0-9_]+)\s*=\s*(.*)$", line)
            if not match:
                continue
            exports[match.group(1)] = match.group(2).strip()
        return exports

    def _resolve_flow_relative(self, value: str, base_dir: Path) -> Path:
        candidate = Path(value).expanduser()
        if candidate.is_absolute():
            return candidate.resolve()
        return (base_dir / candidate).resolve()

    def _dedupe_path_strings(self, paths: List[str]) -> List[str]:
        deduped: List[str] = []
        for raw_path in paths:
            normalized = str(Path(raw_path).expanduser().resolve())
            if normalized not in deduped:
                deduped.append(normalized)
        return deduped

    def _detect_wrapper_module_name(self, wrapper_path: Path) -> Optional[str]:
        match = re.search(r"\bmodule\s+([A-Za-z_][A-Za-z0-9_]*)\b", wrapper_path.read_text())
        if not match:
            return None
        return match.group(1)

    def _detect_instantiated_module_name(self, wrapper_path: Path) -> Optional[str]:
        match = re.search(
            r"^\s*(?!module\b)([A-Za-z_][A-Za-z0-9_]*)\s+[A-Za-z_][A-Za-z0-9_]*\s*\(",
            wrapper_path.read_text(),
            flags=re.MULTILINE,
        )
        if not match:
            return None
        return match.group(1)

    def _extract_sdc_current_design(self, sdc_path: Path) -> Optional[str]:
        match = re.search(r"^\s*current_design\s+([A-Za-z_][A-Za-z0-9_]*)", sdc_path.read_text(), flags=re.MULTILINE)
        if not match:
            return None
        return match.group(1)

    def _extract_sdc_clk_port(self, sdc_path: Path) -> Optional[str]:
        text = sdc_path.read_text()
        direct_match = re.search(r"^\s*set\s+clk_port_name\s+([A-Za-z_][A-Za-z0-9_]*)", text, flags=re.MULTILINE)
        if direct_match:
            return direct_match.group(1)
        clock_match = re.search(r"create_clock\s+.*\[\s*get_ports\s+([A-Za-z_][A-Za-z0-9_]*)\s*\]", text)
        if clock_match:
            return clock_match.group(1)
        return None

    def _has_module_definition(self, rtl_path: Path, module_name: str) -> bool:
        pattern = rf"\bmodule\s+{re.escape(module_name)}\b"
        return re.search(pattern, rtl_path.read_text()) is not None

    def validate_design_setup(
        self,
        problem_name: str,
        version: str,
        top_verilog_src: str | None = None,
        verilog_srcs: Optional[List[str]] = None,
        top_module_name: str = "TopModule",
        wrapper_template_dir: str | None = None,
    ) -> Dict[str, object]:
        design_dir = Path(wrapper_template_dir).expanduser().resolve() if wrapper_template_dir else self.get_design_dir(problem_name, version)
        config_path = design_dir / "config.mk"
        wrapper_path = design_dir / "wrapper.sv"
        sdc_path = design_dir / "constraint.sdc"

        exports = self._parse_make_exports(config_path) if config_path.exists() else {}
        design_name = exports.get("DESIGN_NAME")
        verilog_files = exports.get("VERILOG_FILES", "")
        rtl_candidates = [token for token in verilog_files.split() if token and not token.endswith("wrapper.sv")]

        resolved_rtl_paths: List[Path] = []
        if verilog_srcs:
            for src in self._dedupe_path_strings(verilog_srcs):
                resolved_rtl_paths.append(Path(src))
        elif top_verilog_src:
            resolved_rtl_paths.append(Path(top_verilog_src).expanduser().resolve())
        elif rtl_candidates:
            for token in rtl_candidates:
                resolved_rtl_paths.append(self._resolve_flow_relative(token, self.orfs_flow_dir))

        wrapper_module = self._detect_wrapper_module_name(wrapper_path) if wrapper_path.exists() else None
        instantiated_module = self._detect_instantiated_module_name(wrapper_path) if wrapper_path.exists() else None
        sdc_current_design = self._extract_sdc_current_design(sdc_path) if sdc_path.exists() else None
        sdc_clk_port = self._extract_sdc_clk_port(sdc_path) if sdc_path.exists() else None

        wrapper_text = wrapper_path.read_text() if wrapper_path.exists() else ""
        wrapper_has_clk_port = bool(re.search(r"\binput\b[^;]*\bclk\b", wrapper_text))
        rtl_has_topmodule = any(
            rtl_path.exists() and self._has_module_definition(rtl_path, top_module_name)
            for rtl_path in resolved_rtl_paths
        )
        rtl_paths_exist = all(path.exists() for path in resolved_rtl_paths) if resolved_rtl_paths else False

        tool_paths = self.discover_tool_paths()
        yosys_exe = tool_paths.get("YOSYS_EXE")
        yosys_cmd = None
        yosys_returncode = None
        yosys_stdout_tail = ""
        yosys_stderr_tail = ""
        yosys_success = False
        if yosys_exe and wrapper_path.exists() and rtl_paths_exist and design_name:
            yosys_read_files = " ".join([str(wrapper_path), *[str(path) for path in resolved_rtl_paths]])
            yosys_cmd = [
                yosys_exe,
                "-p",
                f"read_verilog -sv {yosys_read_files}; hierarchy -check -top {design_name}; proc; opt; stat",
            ]
            proc = subprocess.run(yosys_cmd, cwd=str(self.orfs_flow_dir), capture_output=True, text=True, check=False)
            yosys_returncode = proc.returncode
            yosys_stdout_tail = proc.stdout[-4000:]
            yosys_stderr_tail = proc.stderr[-4000:]
            yosys_success = proc.returncode == 0

        docker_available = bool(tool_paths.get("DOCKER_EXE"))
        checks = {
            "design_dir_exists": design_dir.is_dir(),
            "config_exists": config_path.exists(),
            "wrapper_exists": wrapper_path.exists(),
            "constraint_exists": sdc_path.exists(),
            "design_name_present": bool(design_name),
            "wrapper_module_matches_design_name": bool(design_name and wrapper_module == design_name),
            "wrapper_instantiates_topmodule": instantiated_module == top_module_name,
            "rtl_file_discovered": rtl_paths_exist,
            "rtl_defines_topmodule": rtl_has_topmodule,
            "sdc_current_design_matches_design_name": bool(design_name and sdc_current_design == design_name),
            "sdc_has_create_clock": bool(sdc_path.exists() and "create_clock" in sdc_path.read_text()),
            "sdc_clk_port_is_clk": sdc_clk_port == "clk",
            "wrapper_has_clk_port": wrapper_has_clk_port,
            "yosys_available": bool(yosys_exe),
            "yosys_synth_sanity": yosys_success,
            # Allow Docker-based ORFS runs when local binaries are absent.
            "openroad_available": bool(tool_paths.get("OPENROAD_EXE")) or docker_available,
            "opensta_available": bool(tool_paths.get("OPENSTA_EXE")) or docker_available,
            "klayout_available": bool(tool_paths.get("KLAYOUT_CMD")) or docker_available,
        }

        failure_messages = []
        if not checks["openroad_available"]:
            failure_messages.append("Missing OPENROAD_EXE. Install OpenROAD and export OPENROAD_EXE to the openroad binary.")
        if not checks["opensta_available"]:
            failure_messages.append("Missing OPENSTA_EXE. Install OpenSTA or provide the sta binary from an OpenROAD install.")
        if not checks["klayout_available"]:
            failure_messages.append("Missing KLAYOUT_CMD. Install KLayout and export KLAYOUT_CMD to the klayout executable.")
        if not checks["yosys_available"]:
            failure_messages.append("Missing YOSYS_EXE. Install Yosys and export YOSYS_EXE to the yosys executable.")
        if checks["yosys_available"] and not checks["yosys_synth_sanity"]:
            failure_messages.append("Yosys failed the wrapper+RTL sanity synthesis step. Inspect yosys_stdout_tail and yosys_stderr_tail.")

        return {
            "problem_name": problem_name,
            "version": version,
            "design_dir": str(design_dir),
            "design_name": design_name,
            "config_path": str(config_path),
            "wrapper_path": str(wrapper_path),
            "constraint_path": str(sdc_path),
            "resolved_rtl_path": str(resolved_rtl_paths[-1]) if resolved_rtl_paths else None,
            "resolved_rtl_paths": [str(path) for path in resolved_rtl_paths],
            "wrapper_module_name": wrapper_module,
            "wrapper_instantiated_module": instantiated_module,
            "requested_top_module": top_module_name,
            "sdc_current_design": sdc_current_design,
            "sdc_clk_port": sdc_clk_port,
            "tool_paths": tool_paths,
            "checks": checks,
            "success": all(checks.values()),
            "failure_messages": failure_messages,
            "yosys_cmd": yosys_cmd,
            "yosys_returncode": yosys_returncode,
            "yosys_stdout_tail": yosys_stdout_tail,
            "yosys_stderr_tail": yosys_stderr_tail,
        }

    def _write_generated_config(self, design_dir: Path, verilog_file_paths: List[Path]) -> Path:
        config_path = design_dir / "config.mk"
        if not config_path.exists():
            raise FileNotFoundError(f"config.mk not found: {config_path}")

        wrapper_path = design_dir / "wrapper.sv"
        if not wrapper_path.exists():
            raise FileNotFoundError(f"wrapper.sv not found: {wrapper_path}")

        config_text = config_path.read_text()
        flow_wrapper = os.path.relpath(wrapper_path, self.orfs_flow_dir)
        flow_generated_files = " ".join([os.path.relpath(path, self.orfs_flow_dir) for path in verilog_file_paths])
        new_verilog_files = f"export VERILOG_FILES    = {flow_wrapper} {flow_generated_files}".strip()

        if re.search(r"^export\s+VERILOG_FILES\s*=.*$", config_text, flags=re.MULTILINE):
            config_text = re.sub(
                r"^export\s+VERILOG_FILES\s*=.*$",
                new_verilog_files,
                config_text,
                flags=re.MULTILINE,
            )
        else:
            config_text += "\n" + new_verilog_files + "\n"

        generated_config = design_dir / "config.generated.mk"
        generated_config.write_text(config_text)
        return generated_config

    def prepare_design_inputs(
        self,
        problem_name: str,
        version: str,
        candidate_verilog_srcs: List[str],
        support_verilog_srcs: Optional[List[str]] = None,
        wrapper_template_dir: Optional[str] = None,
    ) -> Dict[str, Any]:
        design_dir = Path(wrapper_template_dir).expanduser().resolve() if wrapper_template_dir else self.get_design_dir(problem_name, version)
        if not design_dir.is_dir():
            raise FileNotFoundError(f"Design dir not found: {design_dir}")

        candidate_srcs = [Path(path).expanduser().resolve() for path in self._dedupe_path_strings(candidate_verilog_srcs)]
        if not candidate_srcs:
            raise ValueError("candidate_verilog_srcs must contain at least one source file.")
        for src_path in candidate_srcs:
            if not src_path.exists():
                raise FileNotFoundError(f"Generated verilog not found: {src_path}")

        support_srcs = [Path(path).expanduser().resolve() for path in self._dedupe_path_strings(support_verilog_srcs or [])]
        for src_path in support_srcs:
            if not src_path.exists():
                raise FileNotFoundError(f"Support verilog not found: {src_path}")

        generated_root = design_dir / "generated_candidate"
        generated_root.mkdir(parents=True, exist_ok=True)
        bundled_files: List[Path] = []
        bundled_candidate_files: List[str] = []
        bundled_support_files: List[str] = []

        for idx, src_path in enumerate(candidate_srcs):
            target_name = f"candidate_{idx:02d}_{src_path.name}"
            target_path = generated_root / target_name
            shutil.copyfile(src_path, target_path)
            bundled_files.append(target_path)
            bundled_candidate_files.append(str(target_path))

        for idx, src_path in enumerate(support_srcs):
            target_name = f"support_{idx:02d}_{src_path.name}"
            target_path = generated_root / target_name
            shutil.copyfile(src_path, target_path)
            bundled_files.append(target_path)
            bundled_support_files.append(str(target_path))

        generated_config = self._write_generated_config(design_dir, bundled_files)
        return {
            "design_dir": str(design_dir),
            "generated_src": str(Path(bundled_candidate_files[0]).resolve()),
            "candidate_sources": [str(path) for path in candidate_srcs],
            "support_sources": [str(path) for path in support_srcs],
            "bundled_candidate_files": bundled_candidate_files,
            "bundled_support_files": bundled_support_files,
            "orfs_verilog_files": [str(path) for path in bundled_files],
            "generated_config": str(generated_config),
        }

    def _resolve_candidate_file(self, root: Path, candidates: list[str]) -> Optional[Path]:
        for candidate in candidates:
            path = root / candidate
            if path.exists():
                return path
        return None

    def _locate_metric_files(self, saved_run_dir: Path) -> Dict[str, Optional[Path]]:
        metric_files = {
            "synth_stat": self._resolve_candidate_file(
                saved_run_dir,
                ["reports/base/synth_stat.txt", "reports/synth_stat.txt"],
            ),
            "place_log": self._resolve_candidate_file(
                saved_run_dir,
                ["logs/base/3_5_place_dp.log", "logs/3_5_place_dp.log"],
            ),
            "global_place_rpt": self._resolve_candidate_file(
                saved_run_dir,
                ["reports/base/3_global_place.rpt", "reports/3_global_place.rpt"],
            ),
        }

        for key, suffix in {
            "synth_stat": "synth_stat.txt",
            "place_log": "3_5_place_dp.log",
            "global_place_rpt": "3_global_place.rpt",
        }.items():
            if metric_files[key] is not None:
                continue
            matches = sorted(saved_run_dir.rglob(suffix))
            metric_files[key] = matches[0] if matches else None

        return metric_files

    def _extract_metric(self, text: str, pattern: str) -> Optional[float]:
        match = re.search(pattern, text, flags=re.MULTILINE)
        if not match:
            return None
        return float(match.group(1))

    def _parse_metrics(self, saved_run_dir: Path) -> Dict[str, Optional[float]]:
        if not saved_run_dir.exists():
            return {
                "synth_area_um2": None,
                "place_area_um2": None,
                "worst_slack_ns": None,
                "tns_ns": None,
                "final_hpwl_um": None,
            }

        files = self._locate_metric_files(saved_run_dir)

        synth_text = files["synth_stat"].read_text() if files["synth_stat"] else ""
        place_text = files["place_log"].read_text() if files["place_log"] else ""
        global_place_text = files["global_place_rpt"].read_text() if files["global_place_rpt"] else ""

        return {
            "synth_area_um2": self._extract_metric(
                synth_text,
                rf"Chip area for module .*:\s*{self._FLOAT_RE}",
            ),
            "place_area_um2": self._extract_metric(
                place_text,
                rf"Design area\s+{self._FLOAT_RE}\s+um\^2",
            ),
            "worst_slack_ns": self._extract_metric(
                global_place_text,
                rf"(?:worst slack|max slack|wns max)\s+{self._FLOAT_RE}",
            ),
            "tns_ns": self._extract_metric(
                global_place_text,
                rf"tns max\s+{self._FLOAT_RE}",
            ),
            "final_hpwl_um": self._extract_metric(
                place_text,
                rf"Final HPWL\s+{self._FLOAT_RE}\s+u",
            ),
        }

    def _copy_metric_sources(self, saved_run_dir: Path, destination_dir: Optional[str]) -> Dict[str, Optional[str]]:
        if destination_dir is None:
            return {}

        files = self._locate_metric_files(saved_run_dir)
        dest = Path(destination_dir).expanduser().resolve()
        dest.mkdir(parents=True, exist_ok=True)

        copied_files: Dict[str, Optional[str]] = {}
        for name, source in files.items():
            if source is None or not source.exists():
                copied_files[name] = None
                continue
            target = dest / source.name
            shutil.copy2(source, target)
            copied_files[name] = str(target)
        return copied_files

    def _snapshot_key_artifacts(
        self,
        saved_run_dir: Path,
        prepared_design: Dict[str, Any],
        destination_dir: Optional[str],
    ) -> Dict[str, Optional[str]]:
        if destination_dir is None:
            return {}

        destination_root = Path(destination_dir).expanduser().resolve()
        destination_root.mkdir(parents=True, exist_ok=True)

        artifact_candidates = {
            "generated_src": prepared_design.get("generated_src"),
            "generated_config": prepared_design.get("generated_config"),
            "design_config": str((Path(prepared_design["design_dir"]) / "config.mk").resolve())
            if prepared_design.get("design_dir")
            else None,
            "design_wrapper": str((Path(prepared_design["design_dir"]) / "wrapper.sv").resolve())
            if prepared_design.get("design_dir")
            else None,
            "synth_stat": str(self._locate_metric_files(saved_run_dir).get("synth_stat"))
            if saved_run_dir.exists()
            else None,
            "place_log": str(self._locate_metric_files(saved_run_dir).get("place_log"))
            if saved_run_dir.exists()
            else None,
            "global_place_rpt": str(self._locate_metric_files(saved_run_dir).get("global_place_rpt"))
            if saved_run_dir.exists()
            else None,
        }

        extra_saved_run_suffixes = {
            "synth_log": "logs/base/1_synth.log",
            "clock_period": "results/base/clock_period.txt",
            "yosys_netlist": "results/base/1_2_yosys.v",
            "place_odb": "results/base/3_5_place_dp.odb",
            "global_place_log": "logs/base/3_3_place_gp.log",
        }
        for artifact_name, suffix in extra_saved_run_suffixes.items():
            candidate = saved_run_dir / suffix
            if candidate.exists():
                artifact_candidates[artifact_name] = str(candidate)

        copied: Dict[str, Optional[str]] = {}
        for artifact_name, source_str in artifact_candidates.items():
            source = Path(source_str).expanduser().resolve() if source_str and source_str != "None" else None
            copied[artifact_name] = self._copy_file_if_exists(source, destination_root)
        return copied

    def evaluate(
        self,
        problem_name: str,
        version: str,
        top_verilog_src: str | None = None,
        candidate_verilog_srcs: Optional[List[str]] = None,
        support_verilog_srcs: Optional[List[str]] = None,
        top_module_name: str = "TopModule",
        wrapper_template_dir: str | None = None,
        source_filename_in_config: str | None = None,
        run_orfs: bool = False,
        copy_artifacts_dir: str | None = None,
    ) -> Dict[str, object]:
        """
        Evaluate a benchmark candidate.

        When run_orfs is False, metrics are parsed from existing saved_runs only.
        When run_orfs is True, a generated candidate is copied into the design dir,
        ORFS is invoked, and the resulting saved_runs directory is parsed.
        """

        del source_filename_in_config  # Kept for backward compatibility.
        candidate_verilog_srcs = list(candidate_verilog_srcs or [])
        support_verilog_srcs = list(support_verilog_srcs or [])
        if not candidate_verilog_srcs and top_verilog_src is not None:
            candidate_verilog_srcs = [top_verilog_src]
        candidate_verilog_srcs = self._dedupe_path_strings(candidate_verilog_srcs)
        support_verilog_srcs = self._dedupe_path_strings(support_verilog_srcs)

        saved_run_dir = self.get_saved_run_dir(problem_name, version)
        run_ret: Dict[str, object] = {"returncode": None, "stdout": "", "stderr": "", "cmd": None, "cwd": None}
        prepared_design: Dict[str, Any] = {}
        saved_run_existed_before = saved_run_dir.exists()
        pre_orfs_validation: Dict[str, object] = {}

        if run_orfs:
            if len(candidate_verilog_srcs) == 0:
                raise ValueError("candidate_verilog_srcs (or top_verilog_src) is required when run_orfs=True")

            prepared_design = self.prepare_design_inputs(
                problem_name=problem_name,
                version=version,
                candidate_verilog_srcs=candidate_verilog_srcs,
                support_verilog_srcs=support_verilog_srcs,
                wrapper_template_dir=wrapper_template_dir,
            )
            pre_orfs_validation = self.validate_design_setup(
                problem_name=problem_name,
                version=version,
                top_verilog_src=prepared_design["generated_src"],
                verilog_srcs=prepared_design.get("orfs_verilog_files", []),
                top_module_name=top_module_name,
                wrapper_template_dir=prepared_design["design_dir"],
            )
            if not pre_orfs_validation.get("success", False):
                run_ret = {
                    "returncode": -2,
                    "stdout": "",
                    "stderr": "Pre-ORFS validation failed.\n" + "\n".join(pre_orfs_validation.get("failure_messages", [])),
                    "cmd": None,
                    "cwd": str(self.orfs_flow_dir),
                    "tool_paths": pre_orfs_validation.get("tool_paths", {}),
                }
            else:
                generated_config = prepared_design["generated_config"]
                cmd = [*self.make_command, f"DESIGN_CONFIG={generated_config}"]
                run_ret = self._run_cmd(cmd, cwd=self.orfs_flow_dir)
        else:
            pre_orfs_validation = self.validate_design_setup(
                problem_name=problem_name,
                version=version,
                top_verilog_src=top_verilog_src,
                verilog_srcs=candidate_verilog_srcs,
                top_module_name=top_module_name,
                wrapper_template_dir=wrapper_template_dir,
            )

        metrics = self._parse_metrics(saved_run_dir)
        copied_artifacts = self._copy_metric_sources(saved_run_dir, copy_artifacts_dir)
        copied_snapshot_artifacts = self._snapshot_key_artifacts(saved_run_dir, prepared_design, copy_artifacts_dir)
        metric_files = self._locate_metric_files(saved_run_dir)
        stale_metrics = bool(run_orfs and run_ret["returncode"] not in (None, 0) and saved_run_existed_before)

        return {
            "problem_name": problem_name,
            "problem_key": self._normalize_problem_name(problem_name),
            "version": version,
            "run_orfs": run_orfs,
            "prepared_design": prepared_design,
            "saved_run_dir": str(saved_run_dir),
            "saved_run_existed_before": saved_run_existed_before,
            "saved_run_exists": saved_run_dir.exists(),
            "metrics_may_be_stale": stale_metrics,
            "stale_metrics_from_saved_run": stale_metrics,
            "pre_orfs_validation": pre_orfs_validation,
            "candidate_rtl_files": candidate_verilog_srcs,
            "support_rtl_files": support_verilog_srcs,
            "orfs_verilog_files": prepared_design.get("orfs_verilog_files", []),
            "primary_top_module": top_module_name,
            "orfs_returncode": run_ret["returncode"],
            "orfs_cmd": run_ret["cmd"],
            "orfs_cwd": run_ret["cwd"],
            "orfs_stdout_tail": str(run_ret["stdout"])[-4000:],
            "orfs_stderr_tail": str(run_ret["stderr"])[-4000:],
            "tool_paths": run_ret.get("tool_paths", {}),
            "metrics": metrics,
            "metric_source_files": {key: str(path) if path else None for key, path in metric_files.items()},
            "copied_metric_artifacts": copied_artifacts,
            "copied_snapshot_artifacts": copied_snapshot_artifacts,
        }
