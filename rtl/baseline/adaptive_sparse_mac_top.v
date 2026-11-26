`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.06.2026 15:52:54
// Design Name: 
// Module Name: adaptive_sparse_mac_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module adaptive_sparse_mac_top(

    input clk,
    input reset,

    input signed [31:0] A,
    input signed [31:0] B,

    output skip,

    output [1:0] mode_out,

    output signed [31:0] A_eff_out,
    output signed [31:0] B_eff_out,

    output [47:0] booth_groups_out,

    output [15:0] neg_out,
    output [15:0] two_out,
    output [15:0] zero_out,

    output [1023:0] partial_products_out,

    output signed [63:0] wallace_sum_out,
    output signed [63:0] wallace_carry_out,

    output signed [63:0] cla_sum_out,

    output signed [63:0] accumulator_out,

    output signed [63:0] final_output,

    output final_carry_out

);

wire signed [31:0] A_sparse;
wire signed [31:0] B_sparse;

sparsity_detector SD(

    .A(A),
    .B(B),

    .A_out(A_sparse),
    .B_out(B_sparse),

    .skip(skip)

);

adaptive_mac_top MAC(

    .clk(clk),
    .reset(reset),

    .A(A_sparse),
    .B(B_sparse),

    .mode_out(mode_out),

    .A_eff_out(A_eff_out),
    .B_eff_out(B_eff_out),

    .booth_groups_out(booth_groups_out),

    .neg_out(neg_out),
    .two_out(two_out),
    .zero_out(zero_out),

    .partial_products_out(partial_products_out),

    .wallace_sum_out(wallace_sum_out),
    .wallace_carry_out(wallace_carry_out),

    .cla_sum_out(cla_sum_out),

    .accumulator_out(accumulator_out),

    .final_output(final_output),

    .final_carry_out(final_carry_out)

);

endmodule