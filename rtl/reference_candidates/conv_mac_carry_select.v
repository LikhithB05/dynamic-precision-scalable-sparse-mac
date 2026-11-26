`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: conv_mac_carry_select
// Candidate 2 Architecture: Conventional Carry-Select Array MAC
// Description:
//   - 32x32 signed two's complement Baugh-Wooley partial product generation.
//   - 31-stage linear Carry-Save Adder (CSA) ladder (Stages 0 to 30).
//   - Structural 64-bit Carry-Select Adder (csla_64bit) vector-merge adder.
//   - Structural 65-bit Carry-Select Accumulator (acc_csla).
//   - Eliminates fast CARRY4 shortcuts, expanding physical Slice LUTs and
//     increasing concurrent dynamic switching activity.
//////////////////////////////////////////////////////////////////////////////////

module conv_mac_carry_select (
    input clk,
    input rst,
    input enable,
    input [31:0] a,
    input [31:0] b,
    output [63:0] product,
    output [64:0] accumulator,
    output [1:0] mode_out,
    output [63:0] final_output,
    output final_carry_out
);

    // Baseline conventional mode status indicators
    assign mode_out = 2'b10; // Full 32-bit mode
    assign final_output = accumulator[63:0];
    assign final_carry_out = accumulator[64];

    // -------------------------------------------------------------------------
    // 1. Partial Product Generation (Baugh-Wooley Signed Formulation)
    // -------------------------------------------------------------------------
    wire [63:0] pp_row [31:0];

    genvar j, i;
    generate
        for (j = 0; j < 32; j = j + 1) begin : GEN_PP_ROWS
            wire [31:0] row_bits;
            for (i = 0; i < 32; i = i + 1) begin : GEN_PP_COLS
                if ((i == 31 && j != 31) || (j == 31 && i != 31)) begin : GEN_INV_BIT
                    assign row_bits[i] = ~(a[i] & b[j]);
                end else begin : GEN_NORM_BIT
                    assign row_bits[i] = a[i] & b[j];
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
    // 2. 31-Stage Linear Carry-Save Adder (CSA) Reduction Ladder (Stages 0 to 30)
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
    // 3. Vector-Merge Adder: Structural 64-bit Carry-Select Adder (CSLA)
    // -------------------------------------------------------------------------
    wire csla_merge_cout;

    csla_64bit u_merge_csla (
        .A(csa_sum[30]),
        .B(final_stage_carry_shifted),
        .Cin(1'b0),
        .Sum(product),
        .Cout(csla_merge_cout)
    );

    // -------------------------------------------------------------------------
    // 4. Accumulator: Structural 65-bit Carry-Select Accumulator
    // -------------------------------------------------------------------------
    wire [64:0] product_ext;
    assign product_ext = {product[63], product}; // True two's complement sign extension

    acc_csla u_acc (
        .clk(clk),
        .reset(rst),
        .in(product_ext),
        .out(accumulator)
    );

endmodule
