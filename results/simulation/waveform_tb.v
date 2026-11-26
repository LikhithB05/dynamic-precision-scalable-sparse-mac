`timescale 1ns/1ps
// Supplementary stimulus for the repository waveform. Original RTL is instantiated unchanged.
module waveform_tb;
    reg clk = 0, reset = 1;
    reg signed [31:0] A = 0, B = 0;
    wire signed [63:0] product;
    wire signed [64:0] accumulator_out;
    wire skip_flag;
    mac_sparse_ulp_precision_gated dut(.clk(clk), .reset(reset), .A(A), .B(B),
        .product(product), .accumulator_out(accumulator_out), .skip_flag(skip_flag), .carry_out());
    wire [1:0] mode = dut.mode;

    always #5 clk = ~clk;

    initial begin
        $dumpfile("trace.vcd");
        $dumpvars(0, clk, reset, A, B, mode, skip_flag, product, accumulator_out);
        @(negedge clk); reset = 0; A = 3; B = -4;
        @(negedge clk); A = 0; B = 300;
        @(negedge clk); A = 256; B = 2;
        @(negedge clk); A = 70000; B = -1;
        @(negedge clk); A = 0; B = 0;
        @(posedge clk); #1;
        if (accumulator_out !== -65'sd69500) $fatal(1, "Wrong terminal sum");
        $display("Waveform terminal check passed");
        $finish;
    end
endmodule
