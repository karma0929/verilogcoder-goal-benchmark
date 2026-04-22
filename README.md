# OpenROAD + VerilogCoder Goal Benchmark

## 中文简介
这是一个面向 RTL 自动优化的工程化仓库。  
目标是让 VerilogCoder 在同一 benchmark 上自动完成 area / perf / power 三方向候选生成、功能验证、OpenROAD 评估与指标对比落盘。

## English Overview
This repository is an engineering workspace for RTL auto-optimization.  
The goal is to let VerilogCoder run closed-loop optimization across area/perf/power: candidate generation, functional verification, OpenROAD evaluation, and result summarization.

## 核心能力 | Core Capabilities
- 复用原 VerilogCoder 流程（生成、语法检查、仿真、debug）  
  Reuses the original VerilogCoder flow (generation, syntax check, simulation, debug).
- 支持优化循环（迭代、停止条件、结果比较）  
  Supports iterative optimization with stop rules and metric-based comparison.
- 支持多文件 benchmark 编译（candidate + support RTL）  
  Supports multi-file benchmark compilation (candidate + support RTL).
- 支持 ORFS 预检（wrapper/config/sdc/tool paths/yosys sanity）  
  Supports ORFS preflight checks (wrapper/config/sdc/tool paths/yosys sanity).

## 目录结构 | Repository Layout
```text
.
├── benchmark/                                 # benchmark 数据与每个 problem 的运行结果
│   ├── prob105_rotate100/
│   ├── prob130_circuit5/
│   ├── prob155_lemmings4/
│   ├── prob210_multifile_smoke/               # 最小多文件 smoke case
│   ├── prob220_pipe2engine/                   # 较复杂多文件 case
│   └── prob230_multifile_easy/                # 简化多文件 case（推荐先跑）
├── orfs_workspace/OpenROAD-flow-scripts/flow/ # ORFS flow 目录
└── verilogcoder-goal-benchmark/verilogcoder_upstream/
    └── hardware_agent/examples/VerilogCoder/  # 主代码与 CLI 入口
```

## 关键入口 | Key Entry Points
- 优化循环 | Optimization loop  
  `verilogcoder-goal-benchmark/verilogcoder_upstream/hardware_agent/examples/VerilogCoder/run_optimization_loop.py`
- ORFS 预检 | ORFS preflight  
  `verilogcoder-goal-benchmark/verilogcoder_upstream/hardware_agent/examples/VerilogCoder/run_openroad_preflight.py`

## 快速开始 | Quick Start

### 1) 进入代码目录 | Enter Code Directory
```bash
cd <repo_root>/verilogcoder-goal-benchmark/verilogcoder_upstream
```

### 2) 配置模型 | Configure LLM
编辑 `OAI_CONFIG_LIST`，填入可用模型与 API key。  
Edit `OAI_CONFIG_LIST` with your model and API key.

### 3) 功能闸门（不跑 ORFS）| Functional Gate (No ORFS)
```bash
python hardware_agent/examples/VerilogCoder/run_optimization_loop.py \
  --problem prob230_multifile_easy \
  --benchmark-root <repo_root>/benchmark \
  --orfs-flow-dir <repo_root>/orfs_workspace/OpenROAD-flow-scripts/flow \
  --oai-config-list <repo_root>/verilogcoder-goal-benchmark/verilogcoder_upstream/OAI_CONFIG_LIST \
  --parse-saved-runs-only \
  --max-iterations 1 \
  --no-improvement-limit 1 \
  --functional-failure-limit 1
```

### 4) 全流程（含 ORFS）| Full Flow (With ORFS)
```bash
python hardware_agent/examples/VerilogCoder/run_optimization_loop.py \
  --problem prob230_multifile_easy \
  --benchmark-root <repo_root>/benchmark \
  --orfs-flow-dir <repo_root>/orfs_workspace/OpenROAD-flow-scripts/flow \
  --oai-config-list <repo_root>/verilogcoder-goal-benchmark/verilogcoder_upstream/OAI_CONFIG_LIST \
  --max-iterations 3 \
  --no-improvement-limit 1 \
  --functional-failure-limit 2
```

## 输出文件 | Output Artifacts
重点查看：  
Check these first:
- `benchmark/<problem>/optimization_runs/summary.json`
- `benchmark/<problem>/optimization_runs/summary.csv`
- `benchmark/<problem>/optimization_runs/best.json`
- `benchmark/<problem>/optimization_runs/<target>/iter_<n>/verify.json`
- `benchmark/<problem>/optimization_runs/<target>/iter_<n>/openroad_eval.json`
- `benchmark/<problem>/optimization_runs/<target>/iter_<n>/metrics.json`
- `benchmark/<problem>/optimization_runs/<target>/iter_<n>/prompt.txt`
- `benchmark/<problem>/optimization_runs/<target>/iter_<n>/rtl.sv`

## 多文件支持 | Multi-File Support
- 多文件 support/reference（稳定）  
  Stable support/reference multi-file flow via:
  - `src/verify_support_files.txt`
  - `src/openroad_support_files.txt`
- 多文件 candidate 输出（按 contract 启用）  
  Multi-file candidate output is enabled by benchmark contract:
  - `candidate_contract.json` with `mode: multi`
  - output parsed by `FILE: <filename>` blocks into `iter_n/generated/`
- 若 `mode: single`，候选输出为 `iter_n/rtl.sv`  
  If `mode: single`, candidate output remains `iter_n/rtl.sv`.

## ORFS 预检 | ORFS Preflight
```bash
python hardware_agent/examples/VerilogCoder/run_openroad_preflight.py \
  --problem prob230 \
  --orfs-flow-dir <repo_root>/orfs_workspace/OpenROAD-flow-scripts/flow \
  --versions ref area perf power
```

常见缺失工具 | Common missing tools:
- `OPENROAD_EXE`
- `OPENSTA_EXE`
- `KLAYOUT_CMD`

## 已知限制 | Known Limitations
- 功能验证失败时，当前迭代会跳过 ORFS（`skipped_functional_failure`）。  
  If functional verification fails, ORFS is skipped for that iteration.
- 未安装 OpenROAD/OpenSTA/KLayout 时，无法得到完整物理指标。  
  Without OpenROAD/OpenSTA/KLayout, full physical QoR metrics cannot be produced.

## 致谢 | Acknowledgements
- VerilogCoder paper: [https://arxiv.org/abs/2408.08927v1](https://arxiv.org/abs/2408.08927v1)
- OpenROAD-flow-scripts: [https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts](https://github.com/The-OpenROAD-Project/OpenROAD-flow-scripts)
