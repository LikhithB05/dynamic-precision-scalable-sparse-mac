// Supplementary generic 784-pair replay for regenerated memory files.
`timescale 1ns/1ps
module workload_replay_tb;
    reg clk = 0, reset = 0;
    reg signed [31:0] a = 0, b = 0;
    reg signed [31:0] activations [0:783], weights [0:783];
    wire signed [63:0] product;
    wire signed [64:0] sum;
    wire skip;
    reg signed [63:0] expected_product;
    reg signed [64:0] expected_sum = 0;
    integer i, skips = 0;

    mac_sparse_ulp_precision_gated dut (
        .clk(clk), .reset(reset), .A(a), .B(b), .product(product),
        .accumulator_out(sum), .carry_out(), .skip_flag(skip)
    );

    initial begin
        $readmemh("activations.mem", activations);
        $readmemh("weights.mem", weights);
        #1; reset = 1;
        #1; reset = 0;
        for (i = 0; i < 784; i = i + 1) begin
            a = activations[i];
            b = weights[i];
            if ((^a === 1'bx) || (^b === 1'bx))
                $fatal(1, "Incomplete memory pair at index %0d", i);
            expected_product = $signed(a) * $signed(b);
            expected_sum = expected_sum + $signed(expected_product);
            #2;
            if (product !== expected_product || skip !== ((a == 0) || (b == 0)))
                $fatal(1, "Product or skip mismatch at index %0d", i);
            if (skip) skips = skips + 1;
            clk = 1;
            #1;
            if (sum !== expected_sum)
                $fatal(1, "Accumulator mismatch at index %0d", i);
            clk = 0;
            #1;
        end
        $display("PASS pairs=784 skips=%0d accumulator=%0d hex=%h", skips, sum, sum);
        $finish;
    end
endmodule
