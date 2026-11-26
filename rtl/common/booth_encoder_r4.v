`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.05.2026 19:08:55
// Design Name: 
// Module Name: booth_encoder_r4
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


module booth_encoder_r4 (
    input  [2:0] b_group,    // {B[i+1], B[i], B[i-1]}
    output reg   neg,        // negate flag
    output reg   two,        // double (use 2A) flag
    output reg   zero        // zero (skip) flag
);

    always @(*) begin
        case (b_group)
            3'b000: begin neg = 0; two = 0; zero = 1; end  //  0
            3'b001: begin neg = 0; two = 0; zero = 0; end  // +A
            3'b010: begin neg = 0; two = 0; zero = 0; end  // +A
            3'b011: begin neg = 0; two = 1; zero = 0; end  // +2A
            3'b100: begin neg = 1; two = 1; zero = 0; end  // -2A
            3'b101: begin neg = 1; two = 0; zero = 0; end  // -A
            3'b110: begin neg = 1; two = 0; zero = 0; end  // -A
            3'b111: begin neg = 0; two = 0; zero = 1; end  //  0
            default: begin neg = 0; two = 0; zero = 1; end
        endcase
    end

endmodule
