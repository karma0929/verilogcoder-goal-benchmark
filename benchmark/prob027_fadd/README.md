# prob027_fadd

## Description
Prob027_fadd: 1-bit full adder benchmark.

## Variants
- **ref**   : reference implementation
- **area**  : AI-generated code with area-aware prompt
- **perf**  : AI-generated code with performance-aware prompt
- **power** : AI-generated code with power-aware prompt

## Functional Verification
All variants pass the same testbench (`tb.sv`) with **0 mismatches out of all samples**.

## Area Proxy (Yosys ABC)

Primitive cell count extracted from Yosys `stat` (ABC mapping):

| Variant | AND | OR | XOR | NOT | Total |
|-------|-----|----|-----|-----|-------|
| area  | 2   | 0  | 3   | 0   | 5 |
| perf  | 2   | 1  | 2   | 0   | 5 |
| power | 2   | 1  | 2   | 0   | 5 |

## Discussion
- All implementations map to **5 primitive cells**, confirming functional and area equivalence.
- The **area** variant avoids an explicit OR gate by leveraging XOR-based carry logic.
- The **perf** and **power** variants introduce an OR gate, reflecting alternative logic decompositions.
- This demonstrates that prompt style influences synthesized structure even when overall area is unchanged.

## Notes
- All `top_*.sv` files contain **only the TopModule definition**
- Testbench and reference design are unchanged