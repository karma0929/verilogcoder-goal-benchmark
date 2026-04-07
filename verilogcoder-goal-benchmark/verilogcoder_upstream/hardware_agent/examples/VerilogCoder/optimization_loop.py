from __future__ import annotations

import csv
import json
import os
import shutil
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Dict, Iterable, Optional

from hardware_agent.examples.VerilogCoder.openroad_eval import OpenROADEvaluator
from hardware_agent.examples.VerilogCoder.verilogcoder import VerilogCoder


TARGETS = ("area", "perf", "power")

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
    no_improvement_limit: int = 1
    functional_failure_limit: int = 2
    min_area_improvement_um2: float = 1.0
    min_slack_improvement_ns: float = 0.01
    min_power_proxy_improvement_um2: float = 0.5
    run_openroad: bool = True


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


def _timing_clean(metrics: Optional[Dict[str, Optional[float]]]) -> bool:
    if not metrics:
        return False
    worst_slack = metrics.get("worst_slack_ns")
    tns = metrics.get("tns_ns")
    return worst_slack is not None and worst_slack >= 0 and tns is not None and abs(tns) < 1e-9


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
    if mode == "area":
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
    if current_metrics is None or reference_metrics is None:
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
) -> str:
    guidance = ""
    if verification.get("functional_success"):
        if target == "area":
            previous_place = previous_metrics.get("place_area_um2") if previous_metrics else None
            ref_place = reference_metrics.get("place_area_um2") if reference_metrics else None
            guidance = (
                f"Previous candidate passed functionality but placement area is {_format_metric_value(previous_place, 'um^2')} "
                f"and reference placement area is {_format_metric_value(ref_place, 'um^2')}. "
                "Generate a functionally equivalent TopModule with less logic duplication, simpler control logic, and lower implementation area."
            )
        elif target == "perf":
            previous_slack = previous_metrics.get("worst_slack_ns") if previous_metrics else None
            ref_slack = reference_metrics.get("worst_slack_ns") if reference_metrics else None
            guidance = (
                f"Previous candidate passed functionality but worst slack is {_format_metric_value(previous_slack, 'ns')} "
                f"and reference worst slack is {_format_metric_value(ref_slack, 'ns')}. "
                "Generate a functionally equivalent TopModule with shallower critical combinational paths and reduced logic depth."
            )
        else:
            previous_synth = previous_metrics.get("synth_area_um2") if previous_metrics else None
            ref_synth = reference_metrics.get("synth_area_um2") if reference_metrics else None
            guidance = (
                f"Previous candidate passed functionality but synth area is {_format_metric_value(previous_synth, 'um^2')} "
                f"and reference synth area is {_format_metric_value(ref_synth, 'um^2')}. "
                "Generate a functionally equivalent TopModule with lower logic complexity, lower area proxy for power, and fewer unnecessary switching opportunities."
            )
    else:
        report_tail = verification.get("raw_report", "")[-1500:]
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
        "reference_metrics": _summarize_metrics(reference_metrics),
        "previous_functional_success": verification.get("functional_success", False),
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

    def validate_loaded_sources(self) -> None:
        testbench_path = self.get_testbench_path()
        testbench_text = _read_text(testbench_path)
        if not testbench_text.strip():
            raise RuntimeError(f"Loaded benchmark testbench is empty: {testbench_path}")
        if "module tb" not in testbench_text:
            raise RuntimeError(f"Loaded benchmark testbench does not contain 'module tb': {testbench_path}")

        reference_path = self.get_reference_module_path(require_refmodule="RefModule" in testbench_text)
        if reference_path is None:
            raise RuntimeError(
                f"Could not find reference RTL for {self.problem_name}. "
                f"Searched dataset/benchmark reference files under {self.benchmark_dir} and {self.dataset_dir}."
            )
        reference_text = _read_text(reference_path)
        if not reference_text.strip():
            raise RuntimeError(f"Loaded reference RTL is empty: {reference_path}")

    def get_testbench(self) -> str:
        testbench = _read_text(self.get_testbench_path())
        if "module RefModule" in testbench:
            return testbench

        ref_module = self.get_reference_module(require_refmodule="RefModule" in testbench)
        if ref_module:
            return testbench.rstrip() + "\n\n" + ref_module.rstrip() + "\n"
        return testbench

    def get_prompt(self, target: str) -> str:
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
                return _read_text(candidate)

        for candidate in (
            self.benchmark_dir / "prompt.txt",
            self.benchmark_dir / "prompts" / "prompt.txt",
            self.benchmark_dir / "prompts" / "original.txt",
            self.benchmark_dir / "prompt" / "prompt_original.txt",
            self._dataset_file("prompt.txt"),
        ):
            if candidate.exists():
                base_prompt = _read_text(candidate).rstrip()
                return f"{base_prompt}\n\n[Optimization Goal]\n{TARGET_INSTRUCTION_SUFFIX[target]}\n"

        raise FileNotFoundError(f"Could not find prompt for {self.problem_name} target {target}")


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
        _write_json(target_dir / "best.json", best_result)

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
            },
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

        reference_eval = self.evaluator.evaluate(problem_name=problem_name, version="ref", run_orfs=False)
        _write_json(optimization_root / "ref_metrics.json", reference_eval)

        summary: Dict[str, Any] = {
            "problem_name": problem_name,
            "benchmark_dir": str(benchmark_dir),
            "optimization_root": str(optimization_root),
            "reference": reference_eval,
            "targets": {},
            "final_candidates": {},
            "config": asdict(self.config),
        }
        csv_rows: list[Dict[str, Any]] = []
        overall_iteration_history: Dict[str, Any] = {"problem_name": problem_name, "targets": {}}
        best_by_target: Dict[str, Any] = {"problem_name": problem_name, "targets": {}}
        testbench = problem.get_testbench()

        for target in targets:
            target_dir = optimization_root / target
            target_dir.mkdir(parents=True, exist_ok=True)

            best_result: Optional[Dict[str, Any]] = None
            best_metrics: Optional[Dict[str, Optional[float]]] = None
            previous_best_metrics: Optional[Dict[str, Optional[float]]] = None
            history: list[Dict[str, Any]] = []
            no_improvement_count = 0
            functional_failures = 0

            for iteration in range(self.config.max_iterations):
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
                    )

                _write_text(iter_dir / "prompt.txt", prompt_text)

                task_id = f"{problem_name}_{target}_iter{iteration}"
                self.coder.verilog_tools.reset()
                success = self.coder.write_Verilog_module(
                    cur_task_id=task_id,
                    spec=prompt_text,
                    golden_test_bench=testbench,
                    plan_filename="",
                    have_plans=False,
                )

                completed_verilog = (self.coder.verilog_tools.completed_verilog or "").strip()
                _write_text(iter_dir / "rtl.sv", (completed_verilog + "\n") if completed_verilog else "")

                verify_result: Dict[str, Any]
                verification_exception: Optional[Exception] = None
                if completed_verilog:
                    try:
                        self.coder.verilog_tools.load_test_bench(task_id=task_id, spec=prompt_text, test_bench=testbench, write_file=False)
                        verify_report = self.coder.verilog_tools.verilog_simulation_tool(completed_verilog=completed_verilog)
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
                else:
                    verify_result = {
                        "compiled_success": False,
                        "functional_success": False,
                        "generation_success": success,
                        "module_available": False,
                        "raw_report": "No completed RTL was available after the VerilogCoder run.",
                    }
                _write_json(iter_dir / "verify.json", verify_result)

                iteration_result: Dict[str, Any] = {
                    "iteration": iteration,
                    "iter_dir": str(iter_dir),
                    "verification": verify_result,
                    "metrics": None,
                    "openroad_eval": None,
                    "stop_reason": None,
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
                    }
                    iteration_result["openroad_eval"] = skipped_openroad_eval
                    iteration_result["metrics"] = {}
                    _write_json(iter_dir / "openroad_eval.json", skipped_openroad_eval)
                    _write_json(iter_dir / "metrics.json", {})
                    functional_failures += 1
                    if functional_failures >= self.config.functional_failure_limit:
                        iteration_result["stop_reason"] = "functional_failure_limit"
                    else:
                        iteration_result["stop_reason"] = "functional_retry"
                    history.append(iteration_result)
                    csv_rows.append(self._build_iteration_row(problem_name, target, iteration_result, False))
                    if iteration_result["stop_reason"] == "functional_failure_limit":
                        break
                    continue

                openroad_eval = self.evaluator.evaluate(
                    problem_name=problem_name,
                    version=target,
                    top_verilog_src=str(iter_dir / "rtl.sv"),
                    run_orfs=self.config.run_openroad,
                    copy_artifacts_dir=str(iter_dir / "openroad_artifacts"),
                )
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
                elif reference_beaten(target, metrics, reference_eval.get("metrics")):
                    iteration_result["stop_reason"] = "reference_beaten"
                elif no_improvement_count >= self.config.no_improvement_limit:
                    iteration_result["stop_reason"] = "no_improvement"
                elif iteration == self.config.max_iterations - 1:
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
                "locally_optimal": bool(best_result and best_result.get("stop_reason") in {"reference_beaten", "no_improvement", "max_iterations"}),
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
