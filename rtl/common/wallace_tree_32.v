`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.05.2026 19:08:55
// Design Name: 
// Module Name: wallace_tree_32
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

module wallace_tree_32 (
    input [1023:0] pp_flat,
    input [1:0] mode,
    output [63:0] final_sum_out,
    output [63:0] final_carry_out
);

// ---------------------------------
// STEP 1: UNPACK pp_flat → pp[i]
// ---------------------------------
wire [63:0] pp [15:0];

genvar i;
generate
    for(i = 0; i < 16; i = i + 1) begin : UNPACK
        assign pp[i] = pp_flat[i*64 +: 64];
    end
endgenerate

// ---------------------------------
// STEP 2: Masking (dynamic precision)
// ---------------------------------
reg [63:0] pp_active [15:0];
integer j;

always @(*) begin
    for (j = 0; j < 16; j = j + 1) begin
        case(mode)
            2'b10: pp_active[j] = pp[j];
            2'b01: pp_active[j] = (j < 8) ? pp[j] : 64'd0;
            2'b00: pp_active[j] = (j < 4) ? pp[j] : 64'd0;
            default: pp_active[j] = 64'd0;
        endcase
    end
end

// ---------------------------------
// STAGE 1: 16 → 11
// ---------------------------------
wire [63:0] s0,c0,s1,c1,s2,c2,s3,c3,s4,c4,p15;

csa u0(pp_active[0],  pp_active[1],  pp_active[2],  s0, c0);
csa u1(pp_active[3],  pp_active[4],  pp_active[5],  s1, c1);
csa u2(pp_active[6],  pp_active[7],  pp_active[8],  s2, c2);
csa u3(pp_active[9],  pp_active[10], pp_active[11], s3, c3);
csa u4(pp_active[12], pp_active[13], pp_active[14], s4, c4);

assign p15 = pp_active[15];

// ---------------------------------
// SHIFT WIRES (IMPORTANT FIX)
// ---------------------------------
wire [63:0] c0s, c1s, c2s, c3s, c4s;
assign c0s = c0 << 1;
assign c1s = c1 << 1;
assign c2s = c2 << 1;
assign c3s = c3 << 1;
assign c4s = c4 << 1;

// ---------------------------------
// STAGE 2: 11 → 8
// ---------------------------------
wire [63:0] s5,c5,s6,c6,s7,c7,p16,p17;

csa u5(s0, c0s, s1, s5, c5);
csa u6(c1s, s2, c2s, s6, c6);
csa u7(s3, c3s, s4, s7, c7);

assign p16 = c4s;
assign p17 = p15;

// ---------------------------------
// STAGE 3: 8 → 6
// ---------------------------------
wire [63:0] c5s,c6s,c7s;
assign c5s = c5 << 1;
assign c6s = c6 << 1;
assign c7s = c7 << 1;

wire [63:0] s8,c8,s9,c9,p18,p19;

csa u8(s5, c5s, s6, s8, c8);
csa u9(c6s, s7, c7s, s9, c9);

assign p18 = p16;
assign p19 = p17;

// ---------------------------------
// STAGE 4: 6 → 4
// ---------------------------------
wire [63:0] c8s,c9s;
assign c8s = c8 << 1;
assign c9s = c9 << 1;

wire [63:0] s10,c10,s11,c11;

csa u10(s8, c8s, s9, s10, c10);
csa u11(c9s, p18, p19, s11, c11);

// ---------------------------------
// STAGE 5: 4 → 3
// ---------------------------------
wire [63:0] c10s,c11s;
assign c10s = c10 << 1;
assign c11s = c11 << 1;

wire [63:0] s12,c12,p20;

csa u12(s10, c10s, s11, s12, c12);

assign p20 = c11s;

// ---------------------------------
// FINAL STAGE: 3 → 2
// ---------------------------------
wire [63:0] c12s;
assign c12s = c12 << 1;

wire [63:0] final_sum, final_carry;

csa u13(s12, c12s, p20, final_sum, final_carry);

// ---------------------------------
// FINAL ADDITION
// ---------------------------------
assign final_sum_out = final_sum;
assign final_carry_out = (final_carry << 1);

endmodule
