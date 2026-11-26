# Reproduction

Use Verilog-2001 RTL and a simulator supporting Verilog testbench task arguments. The supplementary per-cycle oracle uses SystemVerilog. The core has no vendor simulation primitive dependency. Vivado's FPGA mapper infers vendor carry resources from arithmetic expressions.

From the repository root:

```sh
python verification/check_datasets.py
python scripts/simulate.py candidate3
python scripts/simulate.py candidate1
python scripts/simulate.py candidate2
python scripts/simulate.py comparison
python scripts/simulate.py oracle
```

Use --bin to point to an installed Vivado bin directory, and --work to choose the parent of the new simulation scratch directory. The default is build/. The runner physically copies the chosen source files and both memory files, runs xvlog, xelab and xsim, and checks simulator termination and result markers. The five-design comparison expects two original adaptive bit-64 differences.

The Candidate 3 closure consists of mode_controller, operand_formatter, booth_encoder_r4, partial_product_generator, csa, wallace_tree_32 and mac_sparse_ulp_precision_gated. It does not use the four-port acc module. The original adaptive and Candidate 1 references use the same four-port acc with clk, reset, in and out. Candidate 2 uses acc_csla. Original sparse wraps adaptive_mac_top and sparsity_detector. Conventional shift-and-add is self-contained. The runner lists files separately for every test, including the selectable alternate Booth implementation in the Candidate 1 wrapper.

For a new **vectorless routed OOC** implementation, start Vivado batch mode in a fresh directory. The portable Tcl script loads the Candidate 3 closure and corrected interface constraints. Its results will depend on tool version and implementation settings.

```sh
vivado -mode batch -source /path/to/repository/scripts/implement.tcl
```

The historical input timing assumption is 0–5 ns relative to clk. Output delays are 0–2 ns. The flow targets xc7a200tfbg676-2, an 83.333 ns clock and zero DSPs. The portable script does not regenerate the historical SAIF run. Its outputs describe a new implementation.
