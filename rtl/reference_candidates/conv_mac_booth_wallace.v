`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: conv_mac_booth_wallace
// Description: Conventional Fixed-Precision 32-bit MAC using Radix-4 Booth 
//              Encoding, 16-to-2 Wallace Tree Reduction, Structural CLA, 
//              and 65-bit Accumulator.
//              Strictly NON-ADAPTIVE: no mode controller, no operand formatter,
//              no dynamic bitwidth truncation, no sparsity skipping.
//////////////////////////////////////////////////////////////////////////////////

module conv_mac_booth_wallace (
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

    // -------------------------------------------------------------------------
    // 1. Radix-4 Booth Group Formation (Fixed 32-bit, 16 groups)
    // -------------------------------------------------------------------------
    wire [2:0] booth_group [15:0];
    assign booth_group[0]  = {B[1],  B[0],  1'b0};
    assign booth_group[1]  = {B[3],  B[2],  B[1]};
    assign booth_group[2]  = {B[5],  B[4],  B[3]};
    assign booth_group[3]  = {B[7],  B[6],  B[5]};
    assign booth_group[4]  = {B[9],  B[8],  B[7]};
    assign booth_group[5]  = {B[11], B[10], B[9]};
    assign booth_group[6]  = {B[13], B[12], B[11]};
    assign booth_group[7]  = {B[15], B[14], B[13]};
    assign booth_group[8]  = {B[17], B[16], B[15]};
    assign booth_group[9]  = {B[19], B[18], B[17]};
    assign booth_group[10] = {B[21], B[20], B[19]};
    assign booth_group[11] = {B[23], B[22], B[21]};
    assign booth_group[12] = {B[25], B[24], B[23]};
    assign booth_group[13] = {B[27], B[26], B[25]};
    assign booth_group[14] = {B[29], B[28], B[27]};
    assign booth_group[15] = {B[31], B[30], B[29]};

    // -------------------------------------------------------------------------
    // 2. Radix-4 Booth Encoders & Partial Product Generation
    // -------------------------------------------------------------------------
    wire [15:0] neg;
    wire [15:0] two;
    wire [15:0] zero;
    wire [1023:0] pp_flat;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : GEN_BOOTH_PPG
            booth_encoder_r4 be (
                .b_group(booth_group[i]),
                .neg(neg[i]),
                .two(two[i]),
                .zero(zero[i])
            );

            wire signed [63:0] pp_i;
            partial_product_generator ppg (
                .A(A),
                .neg(neg[i]),
                .two(two[i]),
                .zero(zero[i]),
                .group_id(i[3:0]),
                .partial_product(pp_i)
            );

            assign pp_flat[(i*64) +: 64] = pp_i;
        end
    endgenerate

    // -------------------------------------------------------------------------
    // 3. Wallace Tree Compression (Fixed Mode 2'b10 = Full 32-bit Precision)
    // -------------------------------------------------------------------------
    wire signed [63:0] wallace_sum;
    wire signed [63:0] wallace_carry;

    wallace_tree_32 wt (
        .pp_flat(pp_flat),
        .mode(2'b10), // Fixed full 32-bit mode
        .final_sum_out(wallace_sum),
        .final_carry_out(wallace_carry)
    );

    // -------------------------------------------------------------------------
    // 4. Structural 64-bit Carry-Lookahead Adder (Vector Merge)
    // -------------------------------------------------------------------------
    wire signed [63:0] cla_sum;
    wire cla_cout;

    cla_64bit cla_merge (
        .A(wallace_sum),
        .B(wallace_carry),
        .Cin(1'b0),
        .Sum(cla_sum),
        .Cout(cla_cout)
    );

    assign product = cla_sum;

    // -------------------------------------------------------------------------
    // 5. 65-bit Structural Accumulator (Always Enabled, Sign-Extended)
    // -------------------------------------------------------------------------
    wire [64:0] acc_input;
    wire [64:0] acc_out;

    // Correct mathematical two's complement sign-extension: bit 63 replicated
    assign acc_input = {cla_sum[63], cla_sum};

    acc accumulator (
        .clk(clk),
        .reset(reset),
        .in(acc_input),
        .out(acc_out)
    );

    // -------------------------------------------------------------------------
    // Output Assignments
    // -------------------------------------------------------------------------
    assign accumulator_out = acc_out;
    assign final_output    = acc_out;
    assign carry_out       = acc_out[64];
    assign final_carry_out = acc_out[64];

endmodule
