`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: conventional_mac_top_enhanced
// Description: Deliverable A - Primary Top-Level Conventional MAC Architecture.
//
// Architectural Characteristics:
//   - Strictly non-adaptive, full-width 32-bit signed multiply-accumulate engine.
//   - No dynamic mode controller, no operand formatter, no dynamic bitwidth gating.
//   - No sparsity detection and no operand skipping.
//   - Full 32x32 signed 2's complement multiplier core (default: Baugh-Wooley
//     carry-save array multiplier ladder).
//   - Structural 64-bit carry-lookahead vector merge adder.
//   - Structural 65-bit signed accumulator register with correct two's complement
//     sign-extension (bit 63 replication).
//   - Latency: 1 cycle from inputs to updated accumulator register.
//   - Initiation Interval: 1 cycle (processes a new operand pair every cycle).
//   - Supports fair PPA comparison against Dynamic/Adaptive and Sparse MAC.
//////////////////////////////////////////////////////////////////////////////////

module conventional_mac_top_enhanced #(
    parameter ARCH_SELECT = "BAUGH_WOOLEY" // "BAUGH_WOOLEY" or "BOOTH_WALLACE"
) (
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

    generate
        if (ARCH_SELECT == "BOOTH_WALLACE") begin : GEN_BOOTH_WALLACE
            conv_mac_booth_wallace u_bw_mac (
                .clk(clk),
                .reset(reset),
                .A(A),
                .B(B),
                .product(product),
                .accumulator_out(accumulator_out),
                .final_output(final_output),
                .carry_out(carry_out),
                .final_carry_out(final_carry_out)
            );
        end else begin : GEN_BAUGH_WOOLEY
            conv_mac_baugh_wooley u_bw_array_mac (
                .clk(clk),
                .reset(reset),
                .A(A),
                .B(B),
                .product(product),
                .accumulator_out(accumulator_out),
                .final_output(final_output),
                .carry_out(carry_out),
                .final_carry_out(final_carry_out)
            );
        end
    endgenerate

endmodule
