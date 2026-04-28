from __future__ import annotations

import argparse
from pathlib import Path
import sys

SCRIPT_PATH = Path(__file__).resolve()
UPSTREAM_ROOT = SCRIPT_PATH.parents[3]
if str(UPSTREAM_ROOT) not in sys.path:
    sys.path.insert(0, str(UPSTREAM_ROOT))

from autogen import config_list_from_json

from hardware_agent.examples.VerilogCoder.openroad_eval import OpenROADEvaluator
from hardware_agent.examples.VerilogCoder.optimization_loop import (
    OptimizationLoopConfig,
    OptimizationLoopController,
    SUPPORTED_TARGETS,
)
from hardware_agent.examples.VerilogCoder.verilogcoder import VerilogCoder


def discover_workspace_root(start: Path) -> Path:
    start_dir = start if start.is_dir() else start.parent
    for candidate in [start_dir, *start_dir.parents]:
        if (candidate / "benchmark").is_dir() and (candidate / "orfs_workspace").is_dir():
            return candidate
    raise FileNotFoundError("Could not discover workspace root containing benchmark/ and orfs_workspace/")


def build_verilog_coder(problem_dir: Path, oai_config_list: str) -> VerilogCoder:
    llm_config_list = config_list_from_json(env_or_file=oai_config_list)
    llm_configs = {
        "task_planner_llm": llm_config_list,
        "kg_llm": llm_config_list,
        "graph_retrieval_llm": llm_config_list,
        "verilog_writing_llm": llm_config_list,
        "verilog_debug_llm": llm_config_list,
    }
    llm_types = {
        name: ("llama3" if "llama3" in llm_configs[name][0]["model"] else "gpt")
        for name in llm_configs
    }

    internal_root = problem_dir / "optimization_runs" / "_internal"
    return VerilogCoder(
        task_planner_llm_config=llm_configs["task_planner_llm"],
        kg_llm_config=llm_configs["kg_llm"],
        graph_retrieval_llm_config=llm_configs["graph_retrieval_llm"],
        verilog_writing_llm_config=llm_configs["verilog_writing_llm"],
        debug_llm_config=llm_configs["verilog_debug_llm"],
        llm_types=llm_types,
        generate_plan_dir=str(internal_root / "plans"),
        generate_verilog_dir=str(internal_root / "generated"),
        verilog_tmp_dir=str(internal_root / "tmp"),
    )


def main() -> None:
    script_path = SCRIPT_PATH
    workspace_root = discover_workspace_root(script_path)
    upstream_root = UPSTREAM_ROOT
    default_dataset_root = upstream_root / "hardware_agent" / "examples" / "VerilogCoder" / "verilog-eval-v2" / "dataset_dumpall"

    parser = argparse.ArgumentParser(
        description="Run VerilogCoder with a physical-feedback optimization loop.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--problem", required=True, help="Benchmark problem directory name, for example prob105_rotate100")
    parser.add_argument("--benchmark-root", default=str(workspace_root / "benchmark"))
    parser.add_argument("--dataset-root", default=str(default_dataset_root))
    parser.add_argument("--orfs-flow-dir", default=str(workspace_root / "orfs_workspace" / "OpenROAD-flow-scripts" / "flow"))
    parser.add_argument("--oai-config-list", default=str(upstream_root / "OAI_CONFIG_LIST"))
    parser.add_argument("--max-iterations", type=int, default=3)
    parser.add_argument(
        "--baseline-max-iterations",
        type=int,
        default=3,
        help=(
            "Maximum baseline iterations. "
            "Use >1 to allow baseline functional self-repair instead of a single-shot attempt."
        ),
    )
    parser.add_argument(
        "--targets",
        default="area,perf,power",
        help=(
            "Comma-separated optimization targets. "
            f"Supported: {', '.join(SUPPORTED_TARGETS)}"
        ),
    )
    parser.add_argument("--no-improvement-limit", type=int, default=1)
    parser.add_argument("--functional-failure-limit", type=int, default=2)
    parser.add_argument(
        "--disable-reference-baseline",
        action="store_true",
        help=(
            "Disable reference-based baseline comparison/evaluation. "
            "Optimization decisions are made only from iteration-to-iteration candidate metrics."
        ),
    )
    parser.add_argument(
        "--parse-saved-runs-only",
        action="store_true",
        help="Do not launch ORFS. Parse existing saved_runs only.",
    )
    args = parser.parse_args()
    requested_targets = [target.strip().lower() for target in args.targets.split(",") if target.strip()]
    if not requested_targets:
        raise ValueError("No valid --targets provided.")
    invalid_targets = [target for target in requested_targets if target not in SUPPORTED_TARGETS]
    if invalid_targets:
        raise ValueError(
            f"Unsupported targets in --targets: {invalid_targets}. "
            f"Supported: {SUPPORTED_TARGETS}"
        )

    benchmark_root = Path(args.benchmark_root).expanduser().resolve()
    problem_dir = benchmark_root / args.problem
    if not problem_dir.is_dir():
        raise FileNotFoundError(f"Problem dir not found: {problem_dir}")

    coder = build_verilog_coder(problem_dir=problem_dir, oai_config_list=args.oai_config_list)
    evaluator = OpenROADEvaluator(orfs_flow_dir=args.orfs_flow_dir)
    loop_config = OptimizationLoopConfig(
        max_iterations=args.max_iterations,
        baseline_max_iterations=args.baseline_max_iterations,
        no_improvement_limit=args.no_improvement_limit,
        functional_failure_limit=args.functional_failure_limit,
        run_openroad=not args.parse_saved_runs_only,
        use_reference_baseline=not args.disable_reference_baseline,
    )
    controller = OptimizationLoopController(
        coder=coder,
        evaluator=evaluator,
        benchmark_root=str(benchmark_root),
        dataset_root=args.dataset_root,
        config=loop_config,
    )
    summary = controller.run_problem(problem_name=args.problem, targets=requested_targets)
    print(f"Wrote optimization summary to {problem_dir / 'optimization_runs' / 'summary.json'}")
    print(f"Wrote benchmark-level summary copy to {problem_dir / 'summary.json'}")
    print(f"Targets completed: {', '.join(summary['targets'].keys())}")


if __name__ == "__main__":
    main()
