`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.05.2026 19:08:55
// Design Name: 
// Module Name: partial_product_generator
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


module partial_product_generator (
    input  signed [31:0] A,
    input                neg,
    input                two,
    input                zero,
    input        [3:0]   group_id,   // supports up to many groups
    output reg signed [63:0] partial_product
);

    reg signed [63:0] temp;

    always @(*) begin
        
        // STEP 1: ZERO case
        if (zero) begin
            partial_product = 64'd0;
        end
        else begin
            // STEP 2: extend A to 64-bit
            temp = {{32{A[31]}}, A};

            // STEP 3: multiply by 2 if needed
            if (two)
                temp = temp << 1;

            // STEP 4: apply sign if needed
            if (neg)
                temp = -temp;

            // STEP 5: shift based on Booth group
            partial_product = temp << (2 * group_id);
        end

    end

endmodule
