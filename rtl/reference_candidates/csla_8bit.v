`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: csla_8bit
// Description: Structural 8-bit Carry-Select Adder block.
//              Evaluates dual speculative ripple carry paths (Cin=0 and Cin=1)
//              concurrently and selects the output using 2:1 multiplexers.
//////////////////////////////////////////////////////////////////////////////////

module csla_8bit (
    input [7:0] A,
    input [7:0] B,
    input Cin,
    output [7:0] Sum,
    output Cout
);
    wire [7:0] sum0, sum1;
    wire cout0, cout1;

    // Speculative evaluation branch for Cin = 0
    rca_8bit rca_branch0 (
        .A(A),
        .B(B),
        .Cin(1'b0),
        .Sum(sum0),
        .Cout(cout0)
    );

    // Speculative evaluation branch for Cin = 1
    rca_8bit rca_branch1 (
        .A(A),
        .B(B),
        .Cin(1'b1),
        .Sum(sum1),
        .Cout(cout1)
    );

    // Multiplexers selected by actual incoming carry-in
    assign Sum  = Cin ? sum1  : sum0;
    assign Cout = Cin ? cout1 : cout0;

endmodule
