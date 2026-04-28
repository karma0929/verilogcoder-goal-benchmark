from __future__ import annotations

import argparse
from pathlib import Path
import sys

SCRIPT_PATH = Path(__file__).resolve()
UPSTREAM_ROOT = SCRIPT_PATH.parents[3]
if str(UPSTREAM_ROOT) not in sys.path:
    sys.path.insert(0, str(UPSTREAM_ROOT))

from hardware_agent.examples.VerilogCoder.openroad_eval import OpenROADEvaluator


def discover_workspace_root(start: Path) -> Path:
    start_dir = start if start.is_dir() else start.parent
    for candidate in [start_dir, *start_dir.parents]:
        if (candidate / "benchmark").is_dir() and (candidate / "orfs_workspace").is_dir():
            return candidate
    raise FileNotFoundError("Could not discover workspace root containing benchmark/ and orfs_workspace/")


def fmt_pass(value: bool) -> str:
    return "PASS" if value else "FAIL"


def main() -> None:
    workspace_root = discover_workspace_root(SCRIPT_PATH)

    parser = argparse.ArgumentParser(
        description="Run lightweight ORFS preflight validation for prob200-style design directories.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--problem", default="prob200_pipe5cpu")
    parser.add_argument("--orfs-flow-dir", default=str(workspace_root / "orfs_workspace" / "OpenROAD-flow-scripts" / "flow"))
    parser.add_argument("--versions", nargs="*", default=["ref", "area", "perf", "power"])
    args = parser.parse_args()

    evaluator = OpenROADEvaluator(orfs_flow_dir=args.orfs_flow_dir)
    tool_paths = evaluator.discover_tool_paths()

    print("Tool Discovery")
    for env_name in ("YOSYS_EXE", "OPENROAD_EXE", "OPENSTA_EXE", "KLAYOUT_CMD", "DOCKER_EXE"):
        value = tool_paths.get(env_name)
        print(f"  {fmt_pass(bool(value))} {env_name}: {value or 'not found'}")

    print("\nExport Commands")
    for env_name in ("YOSYS_EXE", "OPENROAD_EXE", "OPENSTA_EXE", "KLAYOUT_CMD"):
        value = tool_paths.get(env_name)
        if value:
            print(f"export {env_name}='{value}'")

    overall_success = True
    for version in args.versions:
        result = evaluator.validate_design_setup(problem_name=args.problem, version=version)
        checks = result["checks"]
        success = result["success"]
        overall_success = overall_success and success

        print(f"\n[{args.problem} / {version}]")
        print(f"  {fmt_pass(checks['wrapper_module_matches_design_name'])} wrapper top naming")
        print(f"  {fmt_pass(checks['rtl_file_discovered'] and checks['rtl_defines_topmodule'])} RTL file discovery")
        print(f"  {fmt_pass(checks['wrapper_instantiates_topmodule'])} TopModule instantiation")
        print(
            f"  {fmt_pass(checks['sdc_current_design_matches_design_name'] and checks['sdc_has_create_clock'] and checks['sdc_clk_port_is_clk'])} "
            "constraint.sdc consistency"
        )
        print(f"  {fmt_pass(checks['yosys_available'] and checks['yosys_synth_sanity'])} yosys synth sanity")
        print(
            f"  {fmt_pass(checks['yosys_available'] and checks['openroad_available'] and checks['opensta_available'] and checks['klayout_available'])} "
            "tool path discovery"
        )
        print(f"  {fmt_pass(success)} overall")

        failure_messages = result.get("failure_messages", [])
        if failure_messages:
            print("  Failure details:")
            for message in failure_messages:
                print(f"    - {message}")

    if overall_success:
        print("\nOverall: PASS")
    else:
        print("\nOverall: FAIL")


if __name__ == "__main__":
    main()
