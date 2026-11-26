`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.05.2026 19:08:55
// Design Name: 
// Module Name: cla_64bit
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


module cla_64bit(
    input [63:0] A,
    input [63:0] B,
    input Cin,
    output [63:0] Sum,
    output Cout
);

wire [14:0] carry;

cla_4bit u0(A[3:0],B[3:0],Cin,Sum[3:0],carry[0]);
cla_4bit u1(A[7:4],B[7:4],carry[0],Sum[7:4],carry[1]);
cla_4bit u2(A[11:8],B[11:8],carry[1],Sum[11:8],carry[2]);
cla_4bit u3(A[15:12],B[15:12],carry[2],Sum[15:12],carry[3]);
cla_4bit u4(A[19:16],B[19:16],carry[3],Sum[19:16],carry[4]);
cla_4bit u5(A[23:20],B[23:20],carry[4],Sum[23:20],carry[5]);
cla_4bit u6(A[27:24],B[27:24],carry[5],Sum[27:24],carry[6]);
cla_4bit u7(A[31:28],B[31:28],carry[6],Sum[31:28],carry[7]);
cla_4bit u8(A[35:32],B[35:32],carry[7],Sum[35:32],carry[8]);
cla_4bit u9(A[39:36],B[39:36],carry[8],Sum[39:36],carry[9]);
cla_4bit u10(A[43:40],B[43:40],carry[9],Sum[43:40],carry[10]);
cla_4bit u11(A[47:44],B[47:44],carry[10],Sum[47:44],carry[11]);
cla_4bit u12(A[51:48],B[51:48],carry[11],Sum[51:48],carry[12]);
cla_4bit u13(A[55:52],B[55:52],carry[12],Sum[55:52],carry[13]);
cla_4bit u14(A[59:56],B[59:56],carry[13],Sum[59:56],carry[14]);
cla_4bit u15(A[63:60],B[63:60],carry[14],Sum[63:60],Cout);

endmodule