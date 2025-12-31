# prob030_popcount255

## Functionality
All three implementations (area / perf / power) are functionally correct.
Simulation against the provided testbench shows **0 mismatches**.

## Implementations
- **area**: AI-generated code with area-aware prompt
- **perf**: AI-generated code with performance-aware prompt
- **power**: AI-generated code with power-aware prompt

All variants compute the population count of a 255-bit input.

## Cell Count Comparison (Yosys ABC)

| Version | AND | OR | NOT | XOR | XNOR | MUX | Total |
|------|------|------|------|------|------|------|------|
| area | 1005 | 911 | 808 | 643 | 712 | 26 | 4105 |
| perf | 1005 | 911 | 808 | 643 | 712 | 26 | 4105 |
| power| 1005 | 911 | 808 | 643 | 712 | 26 | 4105 |

## Observations
- All three variants map to identical primitive cell counts under the current Yosys + ABC synthesis flow
- `popcount255` is a structure-dominated combinational circuit, where logic minimization converges to the same implementation regardless of coding style
- This benchmark indicates that prompt-level optimization has limited impact on highly symmetric arithmetic circuits

## Notes
- `top_*_only.sv` files contain **only the TopModule**
- Area statistics obtained using **Yosys + ABC**