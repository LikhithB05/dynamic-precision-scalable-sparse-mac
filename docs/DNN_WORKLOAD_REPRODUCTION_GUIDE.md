# Reproduce the workload

## Verify the frozen inputs

From the repository root run `python verification/check_datasets.py`. This path uses Python’s standard library. Then run `python scripts/simulate.py candidate3` with Vivado XSim available. The runner stages the DNN weights and activations in a fresh simulation build directory. The expected checkpoint is 3,995,709,172. Use `comparison` for the alternate MEM_Files inputs.

## Regenerate with PyTorch

Start in a new scratch directory. Use a Python environment with mutually compatible PyTorch and torchvision installations. The archived environment used Python 3.14.7, torch 2.13.0 and torchvision 0.28.0. The original source runs on CPU and downloads MNIST into `./data` if the local dataset is absent. The complete MNIST dataset stays outside this repository.

```sh
python /path/to/repository/software/pytorch/mnist_dnn_mem_generator.py
```

The unchanged generator trains two epochs and writes its own `weights.mem`, `activations.mem` and `run_report.txt` to the current directory. Preserve the repository snapshots by keeping this scratch directory distinct. The script has no RNG seed and saves no checkpoint. A new run validates the generation method and produces a new expected sum. Its weights need not match either archived pair. Use that run’s own signed Python sum as its test oracle. The supplied original RTL bench contains the frozen historical checkpoint. [Model and dependency detail](PYTORCH_MODEL_ARCHITECTURE.md)

## Check a regenerated pair in RTL

From the repository root, compile the supplemental bench with Icarus. Supply the absolute path of the scratch directory containing the freshly generated memory files.

```sh
iverilog -g2012 -s workload_replay_tb -o /path/to/scratch/replay.vvp rtl/optimized/mac_sparse_ulp_precision_gated.v rtl/common/mode_controller.v rtl/common/operand_formatter.v rtl/common/booth_encoder_r4.v rtl/common/partial_product_generator.v rtl/common/csa.v rtl/common/wallace_tree_32.v verification/workload_replay_tb.sv
cd /path/to/scratch
vvp replay.vvp
```

The bench checks each input pair and prints the final signed state. Compare it with the exact integer result printed by that same training run. The independent regeneration completed two epochs and matched 220,166,315 on its new data, with 633 zero pairs. This result belongs to that run.
