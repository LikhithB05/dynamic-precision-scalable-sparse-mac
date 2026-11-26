`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module: acc_csla
// Description: Structural 65-bit Carry-Select Accumulator register.
//              Uses structural csla_64bit for lower 64 bits and an explicit
//              full adder equation for bit 64 with sign propagation.
//////////////////////////////////////////////////////////////////////////////////

module acc_csla (
    input clk,
    input reset,
    input [64:0] in,
    output reg [64:0] out
);
    wire [63:0] csla_sum;
    wire csla_cout;
    wire upper_sum;

    // Lower 64-bit addition using structural CSLA
    csla_64bit u_csla_acc (
        .A(out[63:0]),
        .B(in[63:0]),
        .Cin(1'b0),
        .Sum(csla_sum),
        .Cout(csla_cout)
    );

    // Calculate bit 64
    assign upper_sum = out[64] ^ in[64] ^ csla_cout;

    // Register the accumulated result
    always @(posedge clk or posedge reset) begin
        if (reset)
            out <= 65'd0;
        else
            out <= {upper_sum, csla_sum};
    end

endmodule
