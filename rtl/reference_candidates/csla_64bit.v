`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: csla_64bit
// Description: Structural 64-bit Carry-Select Adder composed of 8 cascaded
//              8-bit CSLA blocks.
//////////////////////////////////////////////////////////////////////////////////

module csla_64bit (
    input [63:0] A,
    input [63:0] B,
    input Cin,
    output [63:0] Sum,
    output Cout
);
    wire [7:0] block_carry;

    // Block 0 (Bits 7:0)
    csla_8bit blk0 (
        .A(A[7:0]),
        .B(B[7:0]),
        .Cin(Cin),
        .Sum(Sum[7:0]),
        .Cout(block_carry[0])
    );

    // Blocks 1 through 7 (Bits 15:8 through 63:56)
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : gen_csla_blocks
            csla_8bit blki (
                .A(A[8*i +: 8]),
                .B(B[8*i +: 8]),
                .Cin(block_carry[i-1]),
                .Sum(Sum[8*i +: 8]),
                .Cout(block_carry[i])
            );
        end
    endgenerate

    assign Cout = block_carry[7];

endmodule
