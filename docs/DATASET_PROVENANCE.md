# Operand corpora and historical traces

| Evidence | All INT8/16/32 | Active INT8/16/32 | Skip/total | Signed sum |
|---|---|---|---|---:|
| Final report Tables 4.4–4.6, adaptive and sparse-adaptive traces | 307 / 430 / 47 | 31 / 64 / 47 | 642 / 784 | See original figures 4.9–4.10 |
| Archived DNN pair | 316 / 421 / 47 | 46 / 62 / 47 | 629 / 784 | 3,995,709,172 |
| Archived MEM_Files pair | 298 / 439 / 47 | 44 / 64 / 47 | 629 / 784 | −26,017,714,596 |

The report names the instrumented sparse-adaptive bench for its waveform. Matching the published skip and precision counts to a surviving exact pair has not been established. The report's sparse waveform displays the same positive checkpoint that the frozen DNN pair independently reproduces. A matching terminal sum cannot reconcile different skip counts.

The two frozen pairs use identical activation bytes and different weight bytes. DNN has 619 zero activations and 71 zero weights with 61 pairs where both are zero. MEM_Files has 619, 61 and 51 respectively. The counts follow the actual signed integer representation. Training is unseeded and no corresponding saved checkpoint was located, so the exact run history of each weight file remains unestablished.

[Precision and sparsity data](PRECISION_AND_SPARSITY_ANALYSIS.csv) · [Verification](SOFTWARE_HARDWARE_VERIFICATION.md)
