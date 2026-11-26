`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: conv_mac_baugh_wooley
// Description: Conventional Full-Width 32-bit Signed Array MAC based on the 
//              classical Baugh-Wooley 2's Complement Array Multiplier, a 
//              30-stage Carry-Save Adder (CSA) reduction ladder, a structural
//              64-bit CLA vector merge adder, and a 65-bit CLA accumulator.
//
// Features:
//   - Purely conventional, non-adaptive architecture
//   - Full-precision 32x32 signed multiplication without Booth group truncation
//   - No mode controller, no operand formatter, no dynamic bitwidth gating
//   - No sparsity detection or operand skipping (accumulates on every clock cycle)
//   - 1 cycle latency from inputs to registered accumulator output
//   - True 2's complement sign-extension into 65-bit accumulator
//////////////////////////////////////////////////////////////////////////////////

module conv_mac_baugh_wooley (
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
    // 1. Baugh-Wooley Partial Product Matrix Generation (32 rows x 32 bits)
    // -------------------------------------------------------------------------
    // For 2's complement multiplication:
    // Bits (i == 31, j != 31) and (j == 31, i != 31) are inverted (NAND).
    // All other bit pairs are standard AND products.
    // Fixed correction constant: 2^63 + 2^32.
    // -------------------------------------------------------------------------
    wire [63:0] pp_row [31:0];

    genvar j, i;
    generate
        for (j = 0; j < 32; j = j + 1) begin : GEN_PP_ROWS
            wire [31:0] row_bits;
            for (i = 0; i < 32; i = i + 1) begin : GEN_PP_COLS
                if ((i == 31 && j != 31) || (j == 31 && i != 31)) begin : GEN_INV_BIT
                    assign row_bits[i] = ~(A[i] & B[j]);
                end else begin : GEN_NORM_BIT
                    assign row_bits[i] = A[i] & B[j];
                end
            end
            // Left-shift row j by j bits into 64-bit vector
            assign pp_row[j] = {32'd0, row_bits} << j;
        end
    endgenerate

    // Baugh-Wooley constant: 2^63 + 2^32
    wire [63:0] bw_constant;
    assign bw_constant = 64'h8000_0001_0000_0000;

    // -------------------------------------------------------------------------
    // 2. 31-Stage Carry-Save Adder (CSA) Reduction Ladder (Stages 0 to 30)
    // -------------------------------------------------------------------------
    // Compresses the 32 partial product rows and constant into two 64-bit vectors
    // -------------------------------------------------------------------------
    wire [63:0] csa_sum   [30:0];
    wire [63:0] csa_carry [30:0];

    // Stage 0: Compress pp_row[0], pp_row[1], and bw_constant
    csa csa_inst_0 (
        .A(pp_row[0]),
        .B(pp_row[1]),
        .C(bw_constant),
        .SUM(csa_sum[0]),
        .CARRY(csa_carry[0])
    );

    // Stages 1 to 30: Incrementally accumulate pp_row[2] through pp_row[31]
    genvar k;
    generate
        for (k = 1; k <= 30; k = k + 1) begin : GEN_CSA_LADDER
            wire [63:0] prev_carry_shifted;
            assign prev_carry_shifted = {csa_carry[k-1][62:0], 1'b0};

            csa csa_inst_k (
                .A(csa_sum[k-1]),
                .B(prev_carry_shifted),
                .C(pp_row[k+1]),
                .SUM(csa_sum[k]),
                .CARRY(csa_carry[k])
            );
        end
    endgenerate

    wire [63:0] final_stage_carry_shifted;
    assign final_stage_carry_shifted = {csa_carry[30][62:0], 1'b0};

    // -------------------------------------------------------------------------
    // 3. Structural 64-bit CLA Vector Merge Adder
    // -------------------------------------------------------------------------
    wire signed [63:0] cla_sum;
    wire cla_cout;

    cla_64bit cla_merge (
        .A(csa_sum[30]),
        .B(final_stage_carry_shifted),
        .Cin(1'b0),
        .Sum(cla_sum),
        .Cout(cla_cout)
    );

    assign product = cla_sum;

    // -------------------------------------------------------------------------
    // 4. 65-bit Structural Accumulator (Always Enabled, Sign-Extended)
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
