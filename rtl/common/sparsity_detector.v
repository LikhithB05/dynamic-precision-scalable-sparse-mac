`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.10.2026 16:14:12
// Design Name: 
// Module Name: sparsity_detector
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
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.06.2026 15:52:54
// Design Name: 
// Module Name: sparsity_detector
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


module sparsity_detector(

    input signed [31:0] A,
    input signed [31:0] B,

    output signed [31:0] A_out,
    output signed [31:0] B_out,

    output skip

);

//////////////////////////////////////////////////////
// SPARSITY DETECTION
//////////////////////////////////////////////////////

assign skip = (A == 0 || B == 0);

//////////////////////////////////////////////////////
// INPUT GATING
//////////////////////////////////////////////////////

assign A_out = (skip) ? 32'd0 : A;
assign B_out = (skip) ? 32'd0 : B;

endmodule
