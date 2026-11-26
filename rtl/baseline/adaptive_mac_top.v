`timescale 1ns / 1ps

module adaptive_mac_top(
    input clk,
    input reset,
    input signed [31:0] A,
    input signed [31:0] B,

    output [1:0] mode_out,
    output signed [31:0] A_eff_out,
    output signed [31:0] B_eff_out,

    output [47:0] booth_groups_out,

    output [15:0] neg_out,
    output [15:0] two_out,
    output [15:0] zero_out,

    output [1023:0] partial_products_out,

    output signed [63:0] wallace_sum_out,
    output signed [63:0] wallace_carry_out,

    output signed [63:0] cla_sum_out,

    output signed [63:0] accumulator_out,

    output signed [63:0] final_output,
    output final_carry_out
);

//////////////////////////////////////////////////////
// MODE CONTROLLER
//////////////////////////////////////////////////////

wire [1:0] mode;

mode_controller mc(
    .A(A),
    .B(B),
    .mode(mode)
);

assign mode_out = mode;

//////////////////////////////////////////////////////
// OPERAND FORMATTER
//////////////////////////////////////////////////////

wire signed [31:0] A_eff;
wire signed [31:0] B_eff;

operand_formatter opf(
    .A(A),
    .B(B),
    .mode(mode),
    .A_eff(A_eff),
    .B_eff(B_eff)
);

assign A_eff_out = A_eff;
assign B_eff_out = B_eff;

//////////////////////////////////////////////////////
// BOOTH GROUP FORMATION
//////////////////////////////////////////////////////

wire [2:0] booth_group [15:0];

assign booth_group[0]  = {B_eff[1],B_eff[0],1'b0};
assign booth_group[1]  = {B_eff[3],B_eff[2],B_eff[1]};
assign booth_group[2]  = {B_eff[5],B_eff[4],B_eff[3]};
assign booth_group[3]  = {B_eff[7],B_eff[6],B_eff[5]};
assign booth_group[4]  = {B_eff[9],B_eff[8],B_eff[7]};
assign booth_group[5]  = {B_eff[11],B_eff[10],B_eff[9]};
assign booth_group[6]  = {B_eff[13],B_eff[12],B_eff[11]};
assign booth_group[7]  = {B_eff[15],B_eff[14],B_eff[13]};
assign booth_group[8]  = {B_eff[17],B_eff[16],B_eff[15]};
assign booth_group[9]  = {B_eff[19],B_eff[18],B_eff[17]};
assign booth_group[10] = {B_eff[21],B_eff[20],B_eff[19]};
assign booth_group[11] = {B_eff[23],B_eff[22],B_eff[21]};
assign booth_group[12] = {B_eff[25],B_eff[24],B_eff[23]};
assign booth_group[13] = {B_eff[27],B_eff[26],B_eff[25]};
assign booth_group[14] = {B_eff[29],B_eff[28],B_eff[27]};
assign booth_group[15] = {B_eff[31],B_eff[30],B_eff[29]};

assign booth_groups_out = {
booth_group[15],booth_group[14],booth_group[13],booth_group[12],
booth_group[11],booth_group[10],booth_group[9],booth_group[8],
booth_group[7],booth_group[6],booth_group[5],booth_group[4],
booth_group[3],booth_group[2],booth_group[1],booth_group[0]
};
//////////////////////////////////////////////////////
// BOOTH ENCODERS
//////////////////////////////////////////////////////

wire neg [15:0];
wire two [15:0];
wire zero [15:0];

genvar i;

generate
for(i=0;i<16;i=i+1)
begin : BOOTH_ENCODERS

booth_encoder_r4 be(
    .b_group(booth_group[i]),   // FIXED
    .neg(neg[i]),
    .two(two[i]),
    .zero(zero[i])
);

end
endgenerate


generate
for(i=0;i<16;i=i+1)
begin
    assign neg_out[i] = neg[i];
    assign two_out[i] = two[i];
    assign zero_out[i] = zero[i];
end
endgenerate


//////////////////////////////////////////////////////
// PARTIAL PRODUCT GENERATOR
//////////////////////////////////////////////////////

wire signed [63:0] partial_product [15:0];

generate
for(i=0;i<16;i=i+1)
begin : PPG_BLOCK

partial_product_generator ppg(
    .A(A_eff),
    .neg(neg[i]),
    .two(two[i]),
    .zero(zero[i]),

    .group_id(i[3:0]),          // FIXED

    .partial_product(partial_product[i])
);

end
endgenerate
//////////////////////////////////////////////////////
// FLATTEN PP
//////////////////////////////////////////////////////

wire [1023:0] pp_flat;

generate
for(i=0;i<16;i=i+1)
begin
    assign pp_flat[(i*64)+:64] = partial_product[i];
end
endgenerate

assign partial_products_out = pp_flat;

//////////////////////////////////////////////////////
// WALLACE TREE
//////////////////////////////////////////////////////

wire signed [63:0] wallace_sum;
wire signed [63:0] wallace_carry;

wallace_tree_32 wt(
    .pp_flat(pp_flat),
    .mode(mode),
    .final_sum_out(wallace_sum),
    .final_carry_out(wallace_carry)
);

assign wallace_sum_out = wallace_sum;
assign wallace_carry_out = wallace_carry;

//////////////////////////////////////////////////////
// CLA
//////////////////////////////////////////////////////

wire signed [63:0] cla_sum;
wire cla_cout;

cla_64bit cla(
    .A(wallace_sum),
    .B(wallace_carry),
    .Cin(1'b0),
    .Sum(cla_sum),
    .Cout(cla_cout)
);

assign cla_sum_out = cla_sum;

//////////////////////////////////////////////////////
// ACCUMULATOR (65-bit for overflow visibility)
//////////////////////////////////////////////////////
wire [64:0] acc_input;
wire [64:0] acc_out;

assign acc_input = {cla_cout, cla_sum};

acc accumulator(
    .clk(clk),
    .reset(reset),
    .in(acc_input),
    .out(acc_out)
);

assign accumulator_out = acc_out[63:0];

//////////////////////////////////////////////////////
// FINAL OUTPUT + FINAL CARRY
//////////////////////////////////////////////////////

assign final_output     = acc_out[63:0];
assign final_carry_out = acc_out[64];

endmodule