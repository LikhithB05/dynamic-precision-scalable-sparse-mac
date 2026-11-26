// Supplementary Phase 2 check. The DUT is the original Candidate 3 RTL.
`timescale 1ns/1ps
module candidate3_oracle_tb;
    reg clk = 0, reset = 0;
    reg signed [31:0] a = 0, b = 0;
    wire signed [63:0] product;
    wire signed [64:0] acc;
    wire carry_out, skip_flag;
    reg signed [64:0] expected_acc = 0;
    reg [31:0] state = 32'h13c0ffee;
    reg signed [31:0] x, y;
    integer i, checked = 0, wraps = 0, skips = 0;
    integer modes [0:2];

    mac_sparse_ulp_precision_gated dut (
        .clk(clk), .reset(reset), .A(a), .B(b), .product(product),
        .accumulator_out(acc), .carry_out(carry_out), .skip_flag(skip_flag)
    );
    function automatic [31:0] advance(input [31:0] value);
        reg [31:0] v;
        begin
            v = value ^ (value << 13);
            v = v ^ (v >> 17);
            advance = v ^ (v << 5);
        end
    endfunction

    task automatic check_pair(input integer left, input integer right);
        reg signed [63:0] expected_product;
        reg signed [65:0] wide_sum;
        integer expected_mode;
        begin
            a = left; b = right;
            #2;
            expected_product = $signed(left) * $signed(right);
            expected_mode = 2;
            if (left >= -32768 && left <= 32767 && right >= -32768 && right <= 32767)
                expected_mode = 1;
            if (left >= -128 && left <= 127 && right >= -128 && right <= 127)
                expected_mode = 0;
            if (dut.mode !== expected_mode[1:0] || product !== expected_product ||
                skip_flag !== ((left == 0) || (right == 0)))
                $fatal(1, "Combinational mismatch at pair %0d: %0d x %0d", checked, left, right);
            wide_sum = $signed(expected_acc) + $signed(expected_product);
            if (wide_sum[65] != wide_sum[64]) wraps = wraps + 1;
            expected_acc = wide_sum[64:0];
            clk = 1;
            #1;
            if (acc !== expected_acc || carry_out !== expected_acc[64])
                $fatal(1, "State mismatch at pair %0d: %h vs %h", checked, acc, expected_acc);
            clk = 0;
            #1;
            modes[expected_mode] = modes[expected_mode] + 1;
            if (skip_flag) skips = skips + 1;
            checked = checked + 1;
        end
    endtask

    initial begin
        modes[0] = 0; modes[1] = 0; modes[2] = 0;
        #1; reset = 1;
        #1; reset = 0;
        for (i=0; i<9; i=i+1) check_pair(32'sh80000000, 32'sh80000000);
        check_pair(-128,127); check_pair(-129,128);
        check_pair(-32768,32767); check_pair(-32769,32768);
        for (i=0; i<3000; i=i+1) begin
            state=advance(state); x=state;
            state=advance(state); y=state;
            case (i%3)
                0: check_pair($signed(x[7:0]),$signed(y[7:0]));
                1: check_pair($signed(x[15:0]),$signed(y[15:0]));
                2: check_pair(x,y);
            endcase
            if (i%100==0) check_pair(0,y);
        end
        reset=1;
        #1;
        if (acc !== 0 || carry_out !== 0) $fatal(1,"Asynchronous reset failed");
        if (!wraps || !skips) $fatal(1,"Coverage incomplete");
        $display("PASS pairs=%0d INT8=%0d INT16=%0d INT32=%0d skips=%0d signed_wraps=%0d",
            checked,modes[0],modes[1],modes[2],skips,wraps);
        $finish;
    end
endmodule
