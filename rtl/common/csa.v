`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.05.2026 19:08:55
// Design Name: 
// Module Name: csa
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

module csa(
    input  [63:0] A, B, C,
    output [63:0] SUM,
    output [63:0] CARRY
);

assign SUM   = A ^ B ^ C;
assign CARRY = (A & B) | (B & C) | (A & C);

endmodule
