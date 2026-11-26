`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Comprehensive Standalone Verification Testbench for Candidate 3:
// Ultra-Low-Power Precision & Sparsity Gated MAC (mac_sparse_ulp_precision_gated)
//
// Verification Scope:
// 1. 38 Directed Corner Cases covering:
//    - Zero combinations (A=0, B!=0; A!=0, B=0; A=0, B=0; consecutive/isolated zeros)
//    - Maximum positive & negative operands across INT8, INT16, INT32
//    - Mixed-sign combinations (+*+, -*-, +*-, -*+)
//    - Asymmetric operands & dynamic mode transitions
//    - Alternating zero/non-zero patterns
// 2. Full 784-Sample MNIST Layer-1 Benchmark Stream
// 3. Bit-for-bit equivalence check against Software Golden Checkpoint: 3,995,709,172
//////////////////////////////////////////////////////////////////////////////////

module tb_mac_sparse_ulp_precision_gated;

    // Clock and Reset
    reg clk;
    reg reset;

    // Inputs
    reg signed [31:0] A;
    reg signed [31:0] B;

    // Outputs
    wire signed [63:0] product;
    wire signed [64:0] accumulator_out;
    wire               carry_out;
    wire               skip_flag;

    // Instantiate Candidate 3 DUT
    mac_sparse_ulp_precision_gated uut (
        .clk(clk),
        .reset(reset),
        .A(A),
        .B(B),
        .product(product),
        .accumulator_out(accumulator_out),
        .carry_out(carry_out),
        .skip_flag(skip_flag)
    );

    // Clock generator: 12.0 MHz (83.333 ns period)
    always #41.666 clk = ~clk;

    // Memories for MNIST dataset
    reg [31:0] activations_mem [0:783];
    reg [31:0] weights_mem     [0:783];

    integer error_count = 0;
    integer test_idx = 0;
    integer op_idx = 0;
    integer zero_op_count = 0;
    integer active_op_count = 0;

    // Task for checking directed test vectors
    task check_case(
        input signed [31:0] in_a,
        input signed [31:0] in_b,
        input signed [63:0] exp_prod,
        input [8*28:1] test_name
    );
        begin
            @(negedge clk);
            A = in_a;
            B = in_b;
            @(posedge clk);
            #1; // Sample output after edge
            test_idx = test_idx + 1;
            if (product !== exp_prod) begin
                $display("[FAIL] Test #%02d (%0s): A=%0d, B=%0d | Exp=0x%016h (%0d), Got=0x%016h (%0d)",
                         test_idx, test_name, in_a, in_b, exp_prod, exp_prod, product, product);
                error_count = error_count + 1;
            end else begin
                $display("[PASS] Test #%02d (%0s): A=%0d, B=%0d | Product=0x%016h (%0d)",
                         test_idx, test_name, in_a, in_b, product, product);
            end
        end
    endtask

    initial begin
        $display("=========================================================================");
        $display("   CANDIDATE 3 COMPREHENSIVE RE-VALIDATION & VERIFICATION TESTBENCH     ");
        $display("   Architecture: mac_sparse_ulp_precision_gated (AMD Artix-7 @ 12 MHz)  ");
        $display("=========================================================================");

        clk = 0;
        reset = 1;
        A = 32'd0;
        B = 32'd0;

        // Load MNIST dataset
        $readmemh("activations.mem", activations_mem);
        $readmemh("weights.mem", weights_mem);

        // Apply Power-On Reset
        #100;
        @(negedge clk);
        reset = 0;
        @(posedge clk);

        // -----------------------------------------------------------------
        // SECTION 1: 38 DIRECTED CORNER CASES
        // -----------------------------------------------------------------
        $display("\n--- EXECUTING 38 DIRECTED CORNER-CASE VECTORS ---");

        // Group 1: Zero Operands & Sparsity Skipping (7 vectors)
        check_case(32'd0, 32'd50, 64'd0, "Zero A (Skip)");
        check_case(32'd100, 32'd0, 64'd0, "Zero B (Skip)");
        check_case(32'd0, 32'd0, 64'd0, "Both Zero (Skip)");
        check_case(32'd0, -32'd100, 64'd0, "Zero A, Neg B (Skip)");
        check_case(-32'd250, 32'd0, 64'd0, "Neg A, Zero B (Skip)");
        check_case(32'd0, 32'd1, 64'd0, "Consecutive Zero 1");
        check_case(32'd0, 32'd2, 64'd0, "Consecutive Zero 2");

        // Group 2: INT8 Precision Operands (8 vectors)
        check_case(32'd1, 32'd1, 64'd1, "INT8 Unity");
        check_case(32'd10, 32'd20, 64'd200, "INT8 Pos * Pos");
        check_case(-32'd10, 32'd20, -64'd200, "INT8 Neg * Pos");
        check_case(32'd15, -32'd10, -64'd150, "INT8 Pos * Neg");
        check_case(-32'd15, -32'd10, 64'd150, "INT8 Neg * Neg");
        check_case(32'd127, 32'd127, 64'd16129, "INT8 Max Pos");
        check_case(-32'd128, 32'd127, -64'd16256, "INT8 Min Neg * Max Pos");
        check_case(-32'd128, -32'd128, 64'd16384, "INT8 Min Neg * Min Neg");

        // Group 3: INT16 Precision Operands (8 vectors)
        check_case(32'd1000, 32'd2000, 64'd2000000, "INT16 Pos * Pos");
        check_case(-32'd1000, 32'd3000, -64'd3000000, "INT16 Neg * Pos");
        check_case(32'd2500, -32'd400, -64'd1000000, "INT16 Pos * Neg");
        check_case(-32'd1500, -32'd2000, 64'd3000000, "INT16 Neg * Neg");
        check_case(32'd32767, 32'd32767, 64'd1073676289, "INT16 Max Pos");
        check_case(-32'd32768, 32'd32767, -64'd1073709056, "INT16 Min Neg * Max Pos");
        check_case(-32'd32768, -32'd32768, 64'd1073741824, "INT16 Min Neg * Min Neg");
        check_case(32'd256, 32'd256, 64'd65536, "INT16 Boundary Low");

        // Group 4: INT32 Precision Operands (7 vectors)
        check_case(32'd70000, 32'd80000, 64'd5600000000, "INT32 Pos * Pos");
        check_case(-32'd70000, 32'd80000, -64'd5600000000, "INT32 Neg * Pos");
        check_case(32'd90000, -32'd50000, -64'd4500000000, "INT32 Pos * Neg");
        check_case(-32'd60000, -32'd70000, 64'd4200000000, "INT32 Neg * Neg");
        check_case(32'd1000000, 32'd1000000, 64'd1000000000000, "INT32 1M * 1M");
        check_case(-32'd2000000, 32'd500000, -64'd1000000000000, "INT32 -2M * 500k");
        check_case(32'd2147483647, 32'd1, 64'd2147483647, "INT32 Max Pos * 1");

        // Group 5: Asymmetric Precision & Dynamic Transitions (4 vectors)
        check_case(32'd10, 32'd70000, 64'd700000, "Asymmetric INT8 x INT32");
        check_case(32'd50000, 32'd120, 64'd6000000, "Asymmetric INT32 x INT8");
        check_case(32'd2000, 32'd80000, 64'd160000000, "Asymmetric INT16 x INT32");
        check_case(32'd90000, 32'd1500, 64'd135000000, "Asymmetric INT32 x INT16");

        // Group 6: Alternating Zero/Non-Zero Streams (4 vectors)
        check_case(32'd0, 32'd45, 64'd0, "Alternating Zero 1");
        check_case(32'd45, 32'd2, 64'd90, "Alternating Active 1");
        check_case(32'd78, 32'd0, 64'd0, "Alternating Zero 2");
        check_case(-32'd30, 32'd3, -64'd90, "Alternating Active 2");

        $display(">>> Directed Corner Cases Completed. Total Tests: %0d, Failures: %0d <<<", test_idx, error_count);

        // -----------------------------------------------------------------
        // SECTION 2: 784-SAMPLE MNIST BENCHMARK WORKLOAD STREAM
        // -----------------------------------------------------------------
        $display("\n--- EXECUTING 784-SAMPLE MNIST BENCHMARK WORKLOAD STREAM ---");
        
        // Clean synchronous reset of accumulator before benchmark loop
        @(negedge clk);
        reset = 1;
        A = 32'd0;
        B = 32'd0;
        #100;
        @(negedge clk);
        reset = 0;
        @(posedge clk);
        #5;

        for (op_idx = 0; op_idx < 784; op_idx = op_idx + 1) begin
            @(negedge clk);
            A = activations_mem[op_idx];
            B = weights_mem[op_idx];

            if (A == 32'd0 || B == 32'd0)
                zero_op_count = zero_op_count + 1;
            else
                active_op_count = active_op_count + 1;

            @(posedge clk);
        end

        // Settle one final cycle
        @(negedge clk);
        A = 32'd0;
        B = 32'd0;
        @(posedge clk);
        #1;

        $display("\n=========================================================================");
        $display("   MNIST BENCHMARK RE-VALIDATION REPORT:                                 ");
        $display("   Total Workload Samples: %0d", op_idx);
        $display("   Active Multiplications: %0d (%0.2f%%)", active_op_count, (active_op_count*100.0)/784.0);
        $display("   Zero-Skipped Cycles:    %0d (%0.2f%% sparsity)", zero_op_count, (zero_op_count*100.0)/784.0);
        $display("   Candidate 3 Accumulator Out: %0d (Hex: 0x%017h)", accumulator_out, accumulator_out);
        $display("   Software Golden Reference:   3995709172 (Hex: 0x00000000ee2796f4)");

        if (accumulator_out === 65'd3995709172) begin
            $display("\n[SUCCESS] CANDIDATE 3 MATCHES SOFTWARE GOLDEN VALUE BIT-FOR-BIT!");
            $display("[SUCCESS] CHECKPOINT 3,995,709,172 CONFIRMED 100%% EQUIVALENT.");
        end else begin
            $display("\n[ERROR] MISMATCH! Candidate 3 got %0d, expected 3995709172", accumulator_out);
            error_count = error_count + 1;
        end

        $display("=========================================================================");
        if (error_count == 0)
            $display(">>> ALL VERIFICATION TESTS PASSED (0 ERRORS) <<<");
        else
            $display(">>> VERIFICATION FAILED WITH %0d ERRORS <<<", error_count);
        $display("=========================================================================");

        $finish;
    end

endmodule
