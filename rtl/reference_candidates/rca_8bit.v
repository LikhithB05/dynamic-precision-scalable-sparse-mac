`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: rca_8bit
// Description: Structural 8-bit Ripple Carry Adder built with soft-logic
//              full adder equations (XOR, AND, OR) without CARRY4 inference.
//////////////////////////////////////////////////////////////////////////////////

module rca_8bit (
    input [7:0] A,
    input [7:0] B,
    input Cin,
    output [7:0] Sum,
    output Cout
);
    wire [7:0] c;

    // Bit 0 Full Adder
    assign Sum[0] = A[0] ^ B[0] ^ Cin;
    assign c[0]   = (A[0] & B[0]) | (Cin & (A[0] ^ B[0]));

    // Bits 1 to 7 Full Adders
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : gen_fa
            assign Sum[i] = A[i] ^ B[i] ^ c[i-1];
            assign c[i]   = (A[i] & B[i]) | (c[i-1] & (A[i] ^ B[i]));
        end
    endgenerate

    assign Cout = c[7];

endmodule
