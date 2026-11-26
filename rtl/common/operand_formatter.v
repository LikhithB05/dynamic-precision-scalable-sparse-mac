`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.05.2026 19:08:55
// Design Name: 
// Module Name: operand_formatter
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


module operand_formatter (
    input  signed [31:0] A,
    input  signed [31:0] B,
    input  [1:0] mode,
    output reg signed [31:0] A_eff,
    output reg signed [31:0] B_eff
);

    always @(*) begin
        case(mode)

            2'b00: begin // 8-bit
                A_eff = {{24{A[7]}}, A[7:0]};
                B_eff = {{24{B[7]}}, B[7:0]};
            end

            2'b01: begin // 16-bit
                A_eff = {{16{A[15]}}, A[15:0]};
                B_eff = {{16{B[15]}}, B[15:0]};
            end

            2'b10: begin // 32-bit
                A_eff = A;
                B_eff = B;
            end

            default: begin
                A_eff = A;
                B_eff = B;
            end

        endcase
    end

endmodule

