from __future__ import annotations

import os
import re
import shutil
import subprocess
from pathlib import Path
from typing import Dict, Optional


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

    def _run_cmd(self, cmd: list[str], cwd: Path) -> Dict[str, object]:
        proc = subprocess.run(
            cmd,
            cwd=str(cwd),
            capture_output=True,
            text=True,
            check=False,
        )
        return {
            "returncode": proc.returncode,
            "stdout": proc.stdout,
            "stderr": proc.stderr,
            "cmd": cmd,
            "cwd": str(cwd),
        }

    def _write_generated_config(self, design_dir: Path, generated_src: Path) -> Path:
        config_path = design_dir / "config.mk"
        if not config_path.exists():
            raise FileNotFoundError(f"config.mk not found: {config_path}")

        wrapper_path = design_dir / "wrapper.sv"
        if not wrapper_path.exists():
            raise FileNotFoundError(f"wrapper.sv not found: {wrapper_path}")

        config_text = config_path.read_text()
        flow_wrapper = os.path.relpath(wrapper_path, self.orfs_flow_dir)
        flow_generated = os.path.relpath(generated_src, self.orfs_flow_dir)
        new_verilog_files = f"export VERILOG_FILES    = {flow_wrapper} {flow_generated}"

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
        top_verilog_src: str,
        wrapper_template_dir: Optional[str] = None,
    ) -> Dict[str, str]:
        design_dir = Path(wrapper_template_dir).expanduser().resolve() if wrapper_template_dir else self.get_design_dir(problem_name, version)
        if not design_dir.is_dir():
            raise FileNotFoundError(f"Design dir not found: {design_dir}")

        src_path = Path(top_verilog_src).expanduser().resolve()
        if not src_path.exists():
            raise FileNotFoundError(f"Generated verilog not found: {src_path}")

        generated_src = design_dir / "generated_candidate.sv"
        shutil.copyfile(src_path, generated_src)
        generated_config = self._write_generated_config(design_dir, generated_src)

        return {
            "design_dir": str(design_dir),
            "generated_src": str(generated_src),
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
        prepared_design: Dict[str, str],
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

        saved_run_dir = self.get_saved_run_dir(problem_name, version)
        run_ret: Dict[str, object] = {"returncode": None, "stdout": "", "stderr": "", "cmd": None, "cwd": None}
        prepared_design: Dict[str, str] = {}
        saved_run_existed_before = saved_run_dir.exists()

        if run_orfs:
            if top_verilog_src is None:
                raise ValueError("top_verilog_src is required when run_orfs=True")

            prepared_design = self.prepare_design_inputs(
                problem_name=problem_name,
                version=version,
                top_verilog_src=top_verilog_src,
                wrapper_template_dir=wrapper_template_dir,
            )
            generated_config = prepared_design["generated_config"]
            cmd = [*self.make_command, f"DESIGN_CONFIG={generated_config}"]
            run_ret = self._run_cmd(cmd, cwd=self.orfs_flow_dir)

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
            "orfs_returncode": run_ret["returncode"],
            "orfs_cmd": run_ret["cmd"],
            "orfs_cwd": run_ret["cwd"],
            "orfs_stdout_tail": str(run_ret["stdout"])[-4000:],
            "orfs_stderr_tail": str(run_ret["stderr"])[-4000:],
            "metrics": metrics,
            "metric_source_files": {key: str(path) if path else None for key, path in metric_files.items()},
            "copied_metric_artifacts": copied_artifacts,
            "copied_snapshot_artifacts": copied_snapshot_artifacts,
        }
