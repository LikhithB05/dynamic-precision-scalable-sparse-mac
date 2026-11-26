# From software operands to RTL

The original gated-MAC bench loads signed data words using these statements.

```verilog
$readmemh("activations.mem", activations_mem);
$readmemh("weights.mem", weights_mem);
```

At the same index, the bench drives the pixel and weight in matching order. Design I selects a signed width with sign-bit redundancy and makes the product visible through cla_sum_out. Design II retains the same selection, additionally masks the Booth controls and holds its running sum when either operand is zero. Binary zero in the image is unrelated to hidden-layer ReLU because the actual exported activation tensor is the input image.

The final report's adaptive and sparse-adaptive distributions are historical. The frozen DNN bench replay independently verifies the 3,995,709,172 terminal sum, and the supplemental cycle test checks product, skip, mode and running state per pair. The array project reuses the same frozen data to validate its own lane schedule and 80-bit accumulation. [Original testbench](../testbench/tb_mac_sparse_ulp_precision_gated.v) · [Golden reference](GOLDEN_REFERENCE_VERIFICATION.md)
