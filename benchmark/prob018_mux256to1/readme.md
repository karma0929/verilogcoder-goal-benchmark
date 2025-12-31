# prob018_mux256to1

## Functionality
All three implementations (**area / perf / power**) are functionally correct.
Simulation against the provided testbench shows **0 mismatches out of 2000 samples** for all variants.

## Implementations
- **area**: direct indexed selection using a continuous assignment (`assign`)
- **perf**: identical logic and structure to the area version
- **power**: indexed selection implemented using a combinational `always @(*)` block

All three versions implement the same functional behavior:
out = in[sel]

## Cell Count Comparison (Yosys ABC)

| Version | AND | MUX | NOT | OR | Total |
|--------|-----|-----|-----|----|-------|
| ref    | 216 | 107 | 7 | 228 | 558 |
| area   | 216 | 107 | 7 | 228 | 558 |
| perf   | 216 | 107 | 7 | 228 | 558 |
| power  | 220 | 106 | 7 | 227 | 560 |

## Analysis
- The **area** and **perf** implementations result in identical gate-level mappings,
  indicating that this design does not expose meaningful trade-offs between area and performance.
- The **power-oriented** version produces a slightly different gate distribution after synthesis,
  but does **not reduce overall cell count** under the given synthesis flow.
- This suggests that for a purely combinational indexed multiplexer,
  **the synthesis tool dominates optimization decisions**, and coding style alone
  does not significantly affect power or area metrics.

## Notes
- All `top_*.sv` files contain **only the `TopModule` definition**
- The testbench (`tb.sv`) and reference design (`ref_original.sv`) are unchanged and reused for all variants
