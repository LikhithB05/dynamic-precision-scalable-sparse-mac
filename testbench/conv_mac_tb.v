`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: conv_mac_tb
// Description: Dedicated Self-Checking Verification Testbench for Conventional MAC.
//              Exercises:
//                1. Reset functionality and initial state verification.
//                2. Comprehensive directed edge cases (bounds, signs, zeros).
//                3. Randomized regression vectors with golden reference models.
//                4. Exact 784-vector DNN inference workload from weights.mem and
//                   activations.mem with golden mathematical check.
//              Provides strict cycle-accurate checks, unknown (X/Z) detection,
//              and explicit pass/fail tally.
//////////////////////////////////////////////////////////////////////////////////

module conv_mac_tb;

    // -------------------------------------------------------------------------
    // Clock and Control Signals
    // -------------------------------------------------------------------------
    reg clk;
    reg reset;

    // -------------------------------------------------------------------------
    // DUT Inputs
    // -------------------------------------------------------------------------
    reg signed [31:0] A;
    reg signed [31:0] B;

    // -------------------------------------------------------------------------
    // DUT Outputs
    // -------------------------------------------------------------------------
    wire signed [63:0] product;
    wire signed [64:0] accumulator_out;
    wire signed [64:0] final_output;
    wire               carry_out;
    wire               final_carry_out;

    // -------------------------------------------------------------------------
    // Testbench Statistics and State
    // -------------------------------------------------------------------------
    integer total_tests;
    integer passed_tests;
    integer failed_tests;
    integer dnn_pair_count;

    // Golden Reference Model Registers
    reg signed [63:0] expected_product;
    reg signed [64:0] expected_accumulator;
    reg signed [65:0] acc_sum_temp;

    // Memory Arrays for DNN Workload
    reg [31:0] weights_mem     [0:783];
    reg [31:0] activations_mem [0:783];

    // -------------------------------------------------------------------------
    // DUT Instantiation (Configurable between architectures)
    // -------------------------------------------------------------------------
    // By default, instantiates conventional_mac_top_enhanced
    conventional_mac_top_enhanced uut (
        .clk(clk),
        .reset(reset),
        .A(A),
        .B(B),
        .product(product),
        .accumulator_out(accumulator_out),
        .final_output(final_output),
        .carry_out(carry_out),
        .final_carry_out(final_carry_out)
    );

    // -------------------------------------------------------------------------
    // 12 MHz Reference Clock Generation (Period = 83.333 ns, Half = 41.666 ns)
    // -------------------------------------------------------------------------
    always #41.666 clk = ~clk;

    // -------------------------------------------------------------------------
    // Helper Task: Apply Reset and Initialize Golden Model
    // -------------------------------------------------------------------------
    task do_reset;
        begin
            @(posedge clk);
            #1;
            reset = 1'b1;
            A = 32'd0;
            B = 32'd0;
            expected_product = 64'd0;
            expected_accumulator = 65'd0;

            @(posedge clk);
            @(posedge clk);
            #1;
            reset = 1'b0;
            @(posedge clk);
            #1;

            // Verify initial reset output state
            if (accumulator_out !== 65'd0 || carry_out !== 1'b0) begin
                $display("[ERROR] Reset state failure! accumulator_out=%0h, carry_out=%0b", accumulator_out, carry_out);
                failed_tests = failed_tests + 1;
            end else begin
                $display("[INFO] Reset applied successfully. Initial accumulator = 0.");
                passed_tests = passed_tests + 1;
            end
            total_tests = total_tests + 1;
        end
    endtask

    // -------------------------------------------------------------------------
    // Helper Task: Apply One Pair, Update Model, and Assert Correctness
    // -------------------------------------------------------------------------
    task check_mac_cycle;
        input signed [31:0] in_a;
        input signed [31:0] in_b;
        input [255:0] test_label;
        begin
            #1;
            A = in_a;
            B = in_b;
            expected_product = in_a * in_b;

            // Allow combinational product to propagate and verify
            #10;
            if (^product === 1'bx) begin
                $display("[FAIL] %s: Product has unknown (X/Z) bits! product=%0h", test_label, product);
                failed_tests = failed_tests + 1;
            end else if (product !== expected_product) begin
                $display("[FAIL] %s: Product mismatch! A=%0d, B=%0d | Expected=%0d (0x%016h), Got=%0d (0x%016h)",
                         test_label, in_a, in_b, expected_product, expected_product, product, product);
                failed_tests = failed_tests + 1;
            end else begin
                passed_tests = passed_tests + 1;
            end
            total_tests = total_tests + 1;

            acc_sum_temp = {expected_accumulator[64], expected_accumulator} + 
                           {{2{expected_product[63]}}, expected_product};
            expected_accumulator = acc_sum_temp[64:0];

            // Wait for exactly ONE clock edge where accumulator updates
            @(posedge clk);
            #2; // Sample after clock edge

            if ((^accumulator_out === 1'bx) || (^carry_out === 1'bx)) begin
                $display("[FAIL] %s: Accumulator has unknown (X/Z) bits! acc=%0h, carry=%0b", 
                         test_label, accumulator_out, carry_out);
                failed_tests = failed_tests + 1;
            end else if (accumulator_out !== expected_accumulator) begin
                $display("[FAIL] %s: Accumulator mismatch! Expected=0x%017h, Got=0x%017h",
                         test_label, expected_accumulator, accumulator_out);
                failed_tests = failed_tests + 1;
            end else if (final_output !== accumulator_out) begin
                $display("[FAIL] %s: final_output does not match accumulator_out!", test_label);
                failed_tests = failed_tests + 1;
            end else begin
                passed_tests = passed_tests + 1;
            end
            total_tests = total_tests + 1;
        end
    endtask

    // -------------------------------------------------------------------------
    // Main Stimulus Sequence
    // -------------------------------------------------------------------------
    integer k;
    reg signed [31:0] rand_a;
    reg signed [31:0] rand_b;

    initial begin
        $display("\n================================================================================");
        $display(" STARTING COMPREHENSIVE CONVENTIONAL MAC FUNCTIONAL VERIFICATION SUITE");
        $display(" Target: Artix-7 xc7a200tfbg676-2 | Clock: 12.0 MHz (83.333 ns)");
        $display("================================================================================\n");

        clk = 1'b0;
        reset = 1'b1;
        A = 32'd0;
        B = 32'd0;
        total_tests = 0;
        passed_tests = 0;
        failed_tests = 0;
        dnn_pair_count = 0;

        // Apply Reset
        do_reset;

        // ---------------------------------------------------------------------
        // TEST PHASE 1: DIRECTED PRECISION BOUNDARY CASES
        // ---------------------------------------------------------------------
        $display("--- PHASE 1: Directed Edge Cases & Precision Limits ---");
        check_mac_cycle(32'sd0, 32'sd0, "Zero x Zero");
        check_mac_cycle(32'sd1, 32'sd1, "Positive Unit 1 x 1");
        check_mac_cycle(-32'sd1, 32'sd1, "Negative Unit -1 x 1");
        check_mac_cycle(-32'sd1, -32'sd1, "Negative Unit -1 x -1");
        check_mac_cycle(32'sd0, 32'sd12345, "Zero A x Positive B");
        check_mac_cycle(32'sd54321, 32'sd0, "Positive A x Zero B");
        check_mac_cycle(32'sd0, -32'sd99999, "Zero A x Negative B");
        check_mac_cycle(-32'sd88888, 32'sd0, "Negative A x Zero B");

        // 8-bit Boundaries
        check_mac_cycle(32'sd127, 32'sd127, "Max 8-bit x Max 8-bit (127 x 127)");
        check_mac_cycle(-32'sd128, 32'sd127, "Min 8-bit x Max 8-bit (-128 x 127)");
        check_mac_cycle(-32'sd128, -32'sd128, "Min 8-bit x Min 8-bit (-128 x -128)");
        check_mac_cycle(32'sd128, 32'sd1, "Adjacent 8-bit (128 x 1)");
        check_mac_cycle(-32'sd129, 32'sd1, "Adjacent 8-bit (-129 x 1)");

        // 16-bit Boundaries
        check_mac_cycle(32'sd32767, 32'sd32767, "Max 16-bit x Max 16-bit (32767 x 32767)");
        check_mac_cycle(-32'sd32768, 32'sd32767, "Min 16-bit x Max 16-bit (-32768 x 32767)");
        check_mac_cycle(-32'sd32768, -32'sd32768, "Min 16-bit x Min 16-bit (-32768 x -32768)");
        check_mac_cycle(32'sd32768, 32'sd2, "Adjacent 16-bit (32768 x 2)");
        check_mac_cycle(-32'sd32769, 32'sd2, "Adjacent 16-bit (-32769 x 2)");

        // 32-bit Extreme Boundaries
        check_mac_cycle(32'sh7FFF_FFFF, 32'sd1, "Max 32-bit (+2147483647 x 1)");
        check_mac_cycle(-32'sh8000_0000, 32'sd1, "Min 32-bit (-2147483648 x 1)");
        check_mac_cycle(-32'sh8000_0000, -32'sd1, "Min 32-bit (-2147483648 x -1)");
        check_mac_cycle(32'sh7FFF_FFFF, 32'sh7FFF_FFFF, "Max 32-bit Squared");
        check_mac_cycle(-32'sh8000_0000, 32'sh7FFF_FFFF, "Min 32-bit x Max 32-bit");

        $display("[INFO] Phase 1 Completed: All directed edge cases processed.\n");

        // ---------------------------------------------------------------------
        // TEST PHASE 2: PSEUDO-RANDOM REGRESSION SUITE (100 VECTORS)
        // ---------------------------------------------------------------------
        $display("--- PHASE 2: Pseudo-Random Regression Suite (100 Vectors) ---");
        do_reset;

        for (k = 0; k < 100; k = k + 1) begin
            rand_a = $random;
            rand_b = $random;
            check_mac_cycle(rand_a, rand_b, "Random Regression Pair");
        end
        $display("[INFO] Phase 2 Completed: 100 random vectors verified against golden reference.\n");

        // ---------------------------------------------------------------------
        // TEST PHASE 3: REAL DNN WORKLOAD (784 VECTORS FROM MEM FILES)
        // ---------------------------------------------------------------------
        $display("--- PHASE 3: Real 784-Pair DNN Inference Workload Verification ---");
        $readmemh("weights.mem", weights_mem);
        $readmemh("activations.mem", activations_mem);

        do_reset;

        for (k = 0; k < 784; k = k + 1) begin
            check_mac_cycle($signed(activations_mem[k]), $signed(weights_mem[k]), "DNN Vector Pair");
            dnn_pair_count = dnn_pair_count + 1;
        end

        // Assert Final Accumulated Workload Value
        // Mathematical Golden Value: -26017714596 (64-bit: 0xFFFFFFF9F1392E5C, 65-bit signed: -26017714596)
        $display("\n================================================================================");
        $display(" FINAL WORKLOAD ACCUMULATOR VERIFICATION");
        $display("================================================================================");
        $display("  Processed DNN Pairs    = %0d / 784", dnn_pair_count);
        $display("  DUT Final Accumulator  = 0x%017h (%0d)", accumulator_out, accumulator_out);
        $display("  Golden Expected Value  = 0x1FFFFFFF9F1392E5C (-26017714596)");
        $display("  DUT Final Carry Out    = %0b", carry_out);

        total_tests = total_tests + 1;
        if (accumulator_out === 65'sh1_FFFF_FFF9_F139_2E5C) begin
            $display("[PASS] DNN Workload Accumulator MATCHES Golden Sum (-26,017,714,596) 100%% EXACTLY!");
            passed_tests = passed_tests + 1;
        end else begin
            $display("[FAIL] DNN Workload Accumulator MISMATCH! Got 0x%017h, Expected 0x1FFFFFFF9F1392E5C", accumulator_out);
            failed_tests = failed_tests + 1;
        end

        // ---------------------------------------------------------------------
        // SUMMARY REPORT
        // ---------------------------------------------------------------------
        $display("\n================================================================================");
        $display(" VERIFICATION SUMMARY");
        $display("================================================================================");
        $display(" Total Assertions Evaluated : %0d", total_tests);
        $display(" Passed Assertions          : %0d", passed_tests);
        $display(" Failed Assertions          : %0d", failed_tests);

        if (failed_tests == 0) begin
            $display("\n>>> VERIFICATION STATUS: 100%% PASSED (ALL CRITERIA SATISFIED) <<<\n");
        end else begin
            $display("\n>>> VERIFICATION STATUS: FAILED WITH %0d FAILURES <<<\n", failed_tests);
        end
        $display("================================================================================\n");

        $finish;
    end

endmodule
