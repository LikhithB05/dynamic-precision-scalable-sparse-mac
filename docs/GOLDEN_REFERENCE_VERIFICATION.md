# Signed reference and accumulator interpretation

For each position, the reference computes ACC(i+1) = ACC(i) + W(i) × A(i), starting at zero. The original PyTorch script sums Python integers without width truncation and masks only the printed hexadecimal to 64 bits. The archive checker decodes bit 31 as the sign of each input word and independently evaluates the exact sum. Proposed Design II sign-extends each 64-bit product and wraps its 65-bit running state modulo 2⁶⁵.

| Preserved data | Exact Python sum | 65-bit representation | RTL evidence |
|---|---:|---|---|
| DNN | 3,995,709,172 | 0x000000000ee29aef4 | Gated MAC workload match |
| MEM_Files | −26,017,714,596 | 0x1fffffff9f1392e5c | Three conventional references match; earlier adaptive upper bit differs |

The DNN value exceeds the signed 32-bit positive range. Interpretation uses the accumulator width, which retains the positive result. The original report's Figures 4.9–4.10 show the matching sparse-adaptive displayed checkpoint in their own context. [Dataset checker](../verification/check_datasets.py) · [Hardware coverage](verification.md)
