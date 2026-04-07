import json
from hardware_agent.examples.VerilogCoder.openroad_eval import OpenROADEvaluator

evaluator = OpenROADEvaluator(
    orfs_flow_dir="/Users/huang/Desktop/verilogcoder-goal-benchmark/orfs_workspace/OpenROAD-flow-scripts/flow"
)

result = evaluator.evaluate(
    problem_name="prob105",
    version="power",
    run_orfs=False
)

print(json.dumps(result, indent=2))