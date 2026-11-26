`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.10.2026 18:13:28
// Design Name: 
// Module Name: acc
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


module acc (
    input clk,
    input reset,
    input [64:0] in,
    output reg [64:0] out
);

wire [63:0] cla_sum;
wire cla_cout;
wire upper_sum;

// Lower 64-bit addition using the existing CLA
cla_64bit cla_acc (
    .A(out[63:0]),
    .B(in[63:0]),
    .Cin(1'b0),
    .Sum(cla_sum),
    .Cout(cla_cout)
);

// Calculate bit 64
assign upper_sum = out[64] ^ in[64] ^ cla_cout;

// Register the accumulated result
always @(posedge clk or posedge reset) begin
    if (reset)
        out <= 65'd0;
    else
        out <= {upper_sum, cla_sum};
end

endmodule
