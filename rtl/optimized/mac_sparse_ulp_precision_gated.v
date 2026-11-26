`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Candidate 3: Ultra-Low-Power Precision & Sparsity Gated MAC (Final Optimized)
// Target Device: xc7a200tfbg676-2 (AMD Artix-7)
// Microarchitectural Optimizations:
// 1. Parallel Zero-Detection: Primary A and B feed mode_controller and 
//    operand_formatter directly in parallel with sparsity detection, removing
//    the 32-bit comparator/mux cascade from the critical multiplier datapath.
// 2. Dual Precision & Sparsity PPG Gating: Combines dynamic mode-based PPG
//    shutdown (silencing groups 4..15 in INT8 and 8..15 in INT16) with instantaneous
//    sparsity zeroing (forcing all 16 PPGs to zero on skip cycles).
// 3. Accumulator Clock Enable: Disables accumulator register switching on skip cycles.
// 4. Native FPGA Carry Chains: Implements Wallace final summation and accumulation
//    using native fast-carry (CARRY4) primitives for minimal latency and routing delay.
//////////////////////////////////////////////////////////////////////////////////

module mac_sparse_ulp_precision_gated (
    input  wire               clk,
    input  wire               reset,
    input  wire signed [31:0] A,
    input  wire signed [31:0] B,
    output wire signed [63:0] product,
    output wire signed [64:0] accumulator_out,
    output wire               carry_out,
    output wire               skip_flag
);

    // Sparsity detection evaluated in parallel with formatting logic
    wire skip;
    assign skip = (A == 32'd0) || (B == 32'd0);
    assign skip_flag = skip;

    wire [1:0] mode;
    wire signed [31:0] A_eff, B_eff;
    wire [2:0] booth_group [15:0];
    wire [15:0] neg_raw, two_raw, zero_raw;
    wire [15:0] neg, two, zero;
    wire [1023:0] pp_flat;
    wire signed [63:0] wallace_sum, wallace_carry;

    // Mode Controller and Operand Formatter operate directly on A and B
    // avoiding upstream gating multiplexer delays on the timing path
    mode_controller mc (
        .A(A),
        .B(B),
        .mode(mode)
    );

    operand_formatter opf (
        .A(A),
        .B(B),
        .mode(mode),
        .A_eff(A_eff),
        .B_eff(B_eff)
    );

    // Booth Group Generation from B_eff
    assign booth_group[0]  = {B_eff[1],  B_eff[0],  1'b0};
    assign booth_group[1]  = {B_eff[3],  B_eff[2],  B_eff[1]};
    assign booth_group[2]  = {B_eff[5],  B_eff[4],  B_eff[3]};
    assign booth_group[3]  = {B_eff[7],  B_eff[6],  B_eff[5]};
    assign booth_group[4]  = {B_eff[9],  B_eff[8],  B_eff[7]};
    assign booth_group[5]  = {B_eff[11], B_eff[10], B_eff[9]};
    assign booth_group[6]  = {B_eff[13], B_eff[12], B_eff[11]};
    assign booth_group[7]  = {B_eff[15], B_eff[14], B_eff[13]};
    assign booth_group[8]  = {B_eff[17], B_eff[16], B_eff[15]};
    assign booth_group[9]  = {B_eff[19], B_eff[18], B_eff[17]};
    assign booth_group[10] = {B_eff[21], B_eff[20], B_eff[19]};
    assign booth_group[11] = {B_eff[23], B_eff[22], B_eff[21]};
    assign booth_group[12] = {B_eff[25], B_eff[24], B_eff[23]};
    assign booth_group[13] = {B_eff[27], B_eff[26], B_eff[25]};
    assign booth_group[14] = {B_eff[29], B_eff[28], B_eff[27]};
    assign booth_group[15] = {B_eff[31], B_eff[30], B_eff[29]};

    genvar i;
    generate
        for(i = 0; i < 16; i = i + 1) begin : BE
            booth_encoder_r4 be (
                .b_group(booth_group[i]),
                .neg(neg_raw[i]),
                .two(two_raw[i]),
                .zero(zero_raw[i])
            );

            // Precision-Aware and Sparsity-Aware Gating:
            // - For i < 4: active in all modes when not skipped
            // - For 4 <= i < 8: active in INT16 and INT32 when not skipped
            // - For 8 <= i < 16: active only in INT32 when not skipped
            wire precision_enable = (i < 4)  ? 1'b1 :
                                   (i < 8)  ? (mode != 2'b00) :
                                              (mode == 2'b10);

            wire be_enable = (!skip) && precision_enable;

            assign zero[i] = be_enable ? zero_raw[i] : 1'b1;
            assign neg[i]  = be_enable ? neg_raw[i]  : 1'b0;
            assign two[i]  = be_enable ? two_raw[i]  : 1'b0;

            wire signed [63:0] pp_i;
            partial_product_generator ppg (
                .A(A_eff),
                .neg(neg[i]),
                .two(two[i]),
                .zero(zero[i]),
                .group_id(i[3:0]),
                .partial_product(pp_i)
            );

            assign pp_flat[(i*64)+:64] = pp_i;
        end
    endgenerate

    // Wallace Tree Reduction
    wallace_tree_32 wt (
        .pp_flat(pp_flat),
        .mode(mode),
        .final_sum_out(wallace_sum),
        .final_carry_out(wallace_carry)
    );

    // Fast carry addition for product
    wire signed [63:0] product_internal;
    wire               prod_cout;
    assign {prod_cout, product_internal} = wallace_sum + wallace_carry;
    assign product = product_internal;

    // Fast carry accumulation into 65-bit signed accumulator with clock gating
    wire [64:0] acc_operand = {{1{product_internal[63]}}, product_internal};
    reg  [64:0] acc_reg;

    always @(posedge clk or posedge reset) begin
        if (reset)
            acc_reg <= 65'd0;
        else if (!skip)
            acc_reg <= acc_reg + acc_operand;
    end

    assign accumulator_out = acc_reg;
    assign carry_out       = acc_reg[64];

endmodule
