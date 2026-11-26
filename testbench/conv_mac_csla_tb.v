`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: conv_mac_csla_tb
// Description: Dedicated Self-Checking Verification Testbench for Candidate 2
//              (Non-Booth Carry-Select Array MAC).
//              Exercises:
//                1. Reset functionality and initial state verification.
//                2. Comprehensive directed edge cases (bounds, signs, zeros).
//                3. Randomized regression vectors with golden reference models.
//                4. Exact 784-vector DNN inference workload from weights.mem and
//                   activations.mem with golden mathematical check.
//              Provides strict cycle-accurate checks, unknown (X/Z) detection,
//              and explicit pass/fail tally.
//////////////////////////////////////////////////////////////////////////////////

module conv_mac_csla_tb;

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
    // DUT Instantiation: Candidate 2 Carry-Select Top Module
    // -------------------------------------------------------------------------
    conventional_mac_csla_top uut (
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
    // Main Verification Process
    // -------------------------------------------------------------------------
    integer i;
    reg signed [31:0] rand_a;
    reg signed [31:0] rand_b;

    initial begin
        $display("==================================================================");
        $display("   STARTING FUNCTIONAL VERIFICATION: CANDIDATE 2 CSLA MAC        ");
        $display("==================================================================");

        clk = 1'b0;
        reset = 1'b1;
        A = 32'd0;
        B = 32'd0;
        total_tests = 0;
        passed_tests = 0;
        failed_tests = 0;
        dnn_pair_count = 0;

        // Load memory files
        $readmemh("weights.mem", weights_mem);
        $readmemh("activations.mem", activations_mem);

        // Apply Reset
        do_reset();

        // ---------------------------------------------------------------------
        // PHASE 1: DIRECTED BOUNDARY / CORNER CASES
        // ---------------------------------------------------------------------
        $display("\n--- PHASE 1: DIRECTED BOUNDARY / CORNER CASES ---");
        check_mac_cycle(32'sd0, 32'sd0, "Corner: 0 x 0");
        check_mac_cycle(32'sd1, 32'sd1, "Corner: 1 x 1");
        check_mac_cycle(-32'sd1, 32'sd1, "Corner: -1 x 1");
        check_mac_cycle(-32'sd1, -32'sd1, "Corner: -1 x -1");
        check_mac_cycle(32'sd127, 32'sd127, "Corner: +127 x +127");
        check_mac_cycle(-32'sd128, 32'sd127, "Corner: -128 x +127");
        check_mac_cycle(32'sd32767, 32'sd32767, "Corner: +32767 x +32767");
        check_mac_cycle(-32'sd32768, 32'sd32767, "Corner: -32768 x +32767");
        check_mac_cycle(32'sh7FFFFFFF, 32'sd1, "Corner: MaxInt x 1");
        check_mac_cycle(32'sh80000000, 32'sd1, "Corner: MinInt x 1");

        // ---------------------------------------------------------------------
        // PHASE 2: PSEUDO-RANDOM SIGNED REGRESSION
        // ---------------------------------------------------------------------
        $display("\n--- PHASE 2: PSEUDO-RANDOM SIGNED REGRESSION (100 VECTORS) ---");
        for (i = 0; i < 100; i = i + 1) begin
            rand_a = $random;
            rand_b = $random;
            check_mac_cycle(rand_a, rand_b, "Random Signed Vector");
        end

        // ---------------------------------------------------------------------
        // PHASE 3: EXACT 784 DNN INFERENCE WORKLOAD
        // ---------------------------------------------------------------------
        $display("\n--- PHASE 3: EXACT 784-VECTOR DNN INFERENCE WORKLOAD ---");
        do_reset(); // Reset accumulator before running workload

        for (i = 0; i < 784; i = i + 1) begin
            check_mac_cycle($signed(weights_mem[i]), $signed(activations_mem[i]), "DNN Vector");
            dnn_pair_count = dnn_pair_count + 1;
        end

        // Mathematical check on golden accumulator after 784 DNN cycles
        $display("\n[INFO] DNN Workload Processing Completed: %0d operand pairs.", dnn_pair_count);
        $display("[INFO] Final Hardware Accumulator = %0d (Hex: 0x%017h)", accumulator_out, accumulator_out);
        $display("[INFO] Expected Golden Accumulator = %0d (Hex: 0x%017h)", expected_accumulator, expected_accumulator);

        if (accumulator_out === -65'sd26017714596 && accumulator_out === expected_accumulator) begin
            $display("[PASSED] Mathematical integrity verified! Matches exact golden sum (-26017714596).");
        end else begin
            $display("[FAILED] Final accumulator mismatch! Expected -26017714596, Got %0d", accumulator_out);
            failed_tests = failed_tests + 1;
        end
        total_tests = total_tests + 1;

        // ---------------------------------------------------------------------
        // FINAL VERIFICATION SUMMARY
        // ---------------------------------------------------------------------
        $display("\n==================================================================");
        $display("   CANDIDATE 2 CSLA MAC VERIFICATION SUMMARY");
        $display("==================================================================");
        $display("   Total Checks Executed : %0d", total_tests);
        $display("   Passed Assertions    : %0d", passed_tests);
        $display("   Failed Assertions    : %0d", failed_tests);
        $display("==================================================================");

        if (failed_tests == 0) begin
            $display(">>> ALL FUNCTIONAL TESTS PASSED SUCCESSFULLY (100%% INTEGRITY) <<<");
        end else begin
            $display(">>> VERIFICATION FAILED WITH %0d ERRORS <<<", failed_tests);
        end

        $finish;
    end

endmodule
