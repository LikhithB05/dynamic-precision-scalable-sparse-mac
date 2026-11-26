# Precision selection and zero skipping

The 65-bit accumulator moves from 0 to −12, holds on the zero operand, reaches 500 after 256 × 2, and then reaches −69,500 after 70,000 × −1. The figure shows the interval from 5 ns to 56 ns. Values come directly from the original RTL. The stimuli and trace were generated during the supplementary audit using Icarus Verilog 13 and VVP. The 10 ns simulation clock is independent of implementation constraints.

From the repository root, on a working Icarus installation, compile the file list and run the image:

```sh
iverilog -g2012 -s waveform_tb -o waveform.vvp -f results/simulation/waveform_sources.f
vvp waveform.vvp
```

The bench writes trace.vcd in the current directory and checks the terminal accumulator value. waveform.csv contains the decoded changes, including the initial reset interval. Signed operand, product and accumulator buses use decimal values. Internal probes are diagnostic signals. Simulation time gives event ordering without post-route delays.
