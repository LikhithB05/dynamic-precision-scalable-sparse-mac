# Supplementary FPGA runs and path analysis

The README reproduces the original academic five-design comparison. The rows below document separate report scopes and additional runs.

Archived Vivado 2026.1 reports classify the design state as **Routed**. The filename 01_Synthesis_Utilization.rpt also refers to this routed state. The architecture targeted xc7a200tfbg676-2, with an 83.333 ns clock, OOC synthesis and -max_dsp 0. These are historical implementation results. The independent replay covered functional simulation. Timing is static, post-route and model-based. Power is an estimate, reported to the nearest milliwatt.

| Original comparison subject | Scope | LUTs | FFs | Dynamic (mW) | Static (mW) | Total (mW) |
|---|---|---:|---:|---:|---:|---:|
| Conventional shift-and-add | Top-level with I/O | 1,518 | 66 | 69 | 131 | 200 |
| Conventional shift-and-add | OOC | 1,521 | 66 | 3 | 122 | 125 |
| Baugh–Wooley MAC (Candidate 1) | OOC | 2,025 | 65 | 10 | 122 | 132 |
| Carry-Select Array MAC (Candidate 2) | OOC | 2,282 | 65 | 12 | 122 | 133 |
| Proposed Design I · dynamic precision-scalable MAC | OOC | 2,409 | 65 | 9 | 122 | 131 |
| Original sparse adaptive MAC | OOC | 2,341 | 65 | 9 | 122 | 131 |
| Clean sparse reference | OOC | 2,351 | 65 | 10 | 122 | 131 |
| Proposed Design II · gated sparsity-aware MAC | OOC | 2,568 | 65 | 7 | 122 | 129 |

Rows are run-specific values transcribed from the archived reports and results register. Independent milliwatt rounding can prevent displayed components from summing to the displayed total. The conventional top-level run includes 261 bonded IOBs and 63 mW attributed to I/O, leaving about 6 mW of displayed dynamic component power. Removing rounded I/O power from a top-level result does not recreate its separately placed OOC implementation. The poster endpoints differ by 62 mW or 89.86% numerically. Their packaging scopes differ.

## Setup and hold

| Input-to-register data path | Delay (ns) | Endpoint |
|---|---:|---|
| Adaptive | 33.255 | B[20] → accumulator/out_reg[63]/D |
| Clean sparse | 35.448 | A[11] → u_adp/accumulator/out_reg[60]/D |
| Proposed Design II | 24.111 | A[12] → acc_reg_reg[64]/D |

The respective routed **input-to-register delay reductions** are (33.255 − 24.111) / 33.255 = 27.50% and (35.448 − 24.111) / 35.448 = 31.98%. These comparisons use the same path category and different physical endpoints. Original adaptive exposes many debug outputs and has F-01. Historical activity, interface and run differences limit architecture-only attribution.

Proposed Design II's worst setup slack is +52.684 ns on A[12] → product[61], a 23.613 ns input-to-output path. The 24.111 ns input-to-register path has +54.993 ns slack. Output delay assumptions make a shorter path tighter against its requirement. WHS is +0.238 ns. Report Table 4.17 uses 23.613 ns versus 33.255 ns for a historical 28.99% difference across path classes. The slides' 27.50% uses the two input-to-register delays. The 12 MHz target and inverse propagation delays do not establish maximum operating frequency.

## Activity and resource interpretation

Design II vectorless and SAIF-assisted analyses both display 7 mW dynamic. Only **1 of 3,946** design nets matched in the SAIF run (displayed as 0%). The clean sparse run likewise reports 1/3,870 matches. These files establish rounded estimator results with limited internal activity annotation. They cannot quantify energy per active multiply or validate a workload power saving. Comparing displayed values gives 22.22% below adaptive and 30.00% below clean sparse, while conventional OOC estimates 4 mW less than Proposed Design II. The final implementation uses 183 CARRY4 resources; the 152 count belongs to the adaptive reference.

The academic work also used Cadence Genus on earlier architectures. Those standard-cell runs use different constraints and technology models. The FPGA table applies only to Artix-7. [Traceable values](../results/fpga-evidence.csv)
