# Architecture and interfaces

| Ports | Width | Behavior |
|---|---:|---|
| clk, reset | 1 each | Rising-edge update, asynchronously asserted high reset |
| A, B | signed 32 each | Two's-complement operands |
| product | signed 64 | Combinational multiply result |
| accumulator_out | signed 65 | Registered running sum modulo 2⁶⁵ |
| carry_out | 1 | Copy of accumulator_out[64], the sign bit |
| skip_flag | 1 | High if either full-width operand is zero |

Eight declared ports carry 197 interface bits (66 input and 131 output). The routed OOC report shows zero bonded IOBs. No fractional binary-point position is imposed by the RTL.

## Precision and recoding

Mode 00 requires both operands in [−128, 127]. Mode 01 covers the remaining pairs that both fit [−32768, 32767]. Mode 10 covers every other signed 32-bit pair. Mode 11 is unreachable for defined inputs. No external precision command exists. The formatter replicates the selected sign bit through the upper bits.

For digit i, the recoder reads multiplier bits (2i+1, 2i, 2i−1), taking bit −1 as zero. Codes 000/111 select zero, 001/010 select +A, 011 selects +2A, 100 selects −2A and 101/110 select −A. The 64-bit signed multiple shifts left by 2i. The generated encoders themselves are combinational. Their control outputs into the partial-product generators are masked with !skip and the group eligibility bit. Consequently a masked group contributes zero. This architecture can reduce switching downstream while input decode logic can still toggle.

## Hierarchy and cycle behavior

```text
mac_sparse_ulp_precision_gated
├── mode_controller
├── operand_formatter
├── BE[0..15]
│   ├── booth_encoder_r4
│   └── partial_product_generator
├── wallace_tree_32
│   └── csa × 14   (16 → 11 → 8 → 6 → 4 → 3 → 2 rows)
├── inferred final carry-propagate addition
└── inferred 65-bit accumulator addition and register
```

A compressor outputs bitwise XOR and majority. Every carry vector shifts left by one before reuse, including the final vector. Truncation to 64 bits preserves the product modulo 2⁶⁴. The signed 32 × 32 product always fits. Replicating product bit 63 into bit 64 gives the accumulator operand.

Before an edge, both operands must be stable for the combinational path. At the edge, reset clears the register, otherwise skip holds it, otherwise the sum advances. Product and skip follow the currently driven inputs independently of reset. Output overflow wraps without saturation or an overflow flag. The RTL uses a register enable and ordinary additions. CARRY4 mapping is a routed Artix-7 result; the top does not instantiate a clock-gating cell.

## Two proposed designs and their reference designs

* Conventional shift-and-add uses operand magnitudes and restores the sign. Candidate 1 builds signed Baugh–Wooley rows and a carry-save ladder with a CLA merge. Its configurable wrapper also offers Booth–Wallace; the default Baugh–Wooley selection is the historical comparison.
* Candidate 2 uses Baugh–Wooley partial products with carry-select merge and accumulation. The alternative carry logic changes the mapping without adding precision control.
* Proposed Design I adds precision selection and a Wallace tree. The sparse wrapper preconditions both operands through a zero detector. Their original accumulator connection exhibits F-01.
* Proposed Design II evaluates zero detection alongside formatting, suppresses individual partial-product controls, and conditionally updates its own correctly sign-extended accumulator. The separate clean sparse reference appears in the performance comparison as a historical experiment.
