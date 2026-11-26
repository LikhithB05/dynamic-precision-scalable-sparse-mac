`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.05.2026 19:08:55
// Design Name: 
// Module Name: mode_controller
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


module mode_controller (
    input  signed [31:0] A,
    input  signed [31:0] B,
    output reg [1:0] mode
);

    wire A_8bit, B_8bit;
    wire A_16bit, B_16bit;

    assign A_8bit  = (A[31:8]  == {24{A[7]}});
    assign B_8bit  = (B[31:8]  == {24{B[7]}});

    assign A_16bit = (A[31:16] == {16{A[15]}});
    assign B_16bit = (B[31:16] == {16{B[15]}});

    always @(*) begin
        if (A_8bit && B_8bit)
            mode = 2'b00;
        else if (A_16bit && B_16bit)
            mode = 2'b01;
        else
            mode = 2'b10;
    end

endmodule
