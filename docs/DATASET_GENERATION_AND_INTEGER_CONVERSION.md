# Integer conversion and memory words

For each index i, take the flattened pixel and corresponding fc1 weight. Apply a common scale to both operands, then use Python int() to truncate each scaled value toward zero.

| Zero-based indices | Count | Multiplier applied to each operand |
|---|---:|---:|
| 0–249 | 250 | 50 |
| 250–499 | 250 | 5,000 |
| 500–783 | 284 | 100,000 |

The original code uses `"{:08X}".format(value & 0xFFFFFFFF)`. There is no clipping or saturation operation. For example, a hypothetical weight of −0.03 in the first region would truncate to −1 and encode as `FFFFFFFF`. The third line in the archived DNN weights is `FFFFFFFF`, paired with activation word `00000000`. That is an authentic memory example, independent of the hypothetical float.

The export is region-scaled integer stimulus. Its counters describe index regions. The RTL separately checks whether each signed operand fits INT8, INT16 or INT32. A 32-bit transport word can represent any of those modes. Region products use different scale squares, so there is no single fixed-point output scale. [Archived DNN memories](../datasets/DNN/)
