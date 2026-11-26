`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: conventional_mac_csla_top
// Description: Candidate 2 Conventional MAC Architecture Top-Level.
//              Integrates:
//                - Non-Booth 32x32 Baugh-Wooley Carry-Save Array ladder.
//                - Structural 64-bit Carry-Select Adder (CSLA) for product merge.
//                - Structural 65-bit Carry-Select Accumulator (acc_csla).
//              Provides identical top-level interface ports for seamless drop-in
//              verification and PPA characterization against adaptive baselines.
//////////////////////////////////////////////////////////////////////////////////

module conventional_mac_csla_top (
    input  wire        clk,
    input  wire        reset,
    input  wire signed [31:0] A,
    input  wire signed [31:0] B,

    output wire signed [63:0] product,
    output wire signed [64:0] accumulator_out,
    output wire signed [64:0] final_output,
    output wire               carry_out,
    output wire               final_carry_out
);

    wire [1:0] mode_out_unused;
    wire [63:0] final_output_64;
    wire [64:0] acc_internal;

    conv_mac_carry_select u_csla_mac (
        .clk(clk),
        .rst(reset),
        .enable(1'b1),
        .a(A),
        .b(B),
        .product(product),
        .accumulator(acc_internal),
        .mode_out(mode_out_unused),
        .final_output(final_output_64),
        .final_carry_out(carry_out)
    );

    assign accumulator_out = acc_internal;
    assign final_output    = acc_internal;
    assign final_carry_out = carry_out;

endmodule
