`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench: unified_5design_validation_tb
// Purpose: Apples-to-Apples Functional Validation of All Five MAC Architectures:
//          1. Original Conventional MAC (conventional_mac_top)
//          2. Candidate 1: Baugh-Wooley CSA + CLA (conv_mac_baugh_wooley)
//          3. Candidate 2: Carry-Select Array MAC (conventional_mac_csla_top)
//          4. Dynamic/Adaptive MAC (adaptive_mac_top)
//          5. Sparse Adaptive MAC (adaptive_sparse_mac_top)
//
// Features:
//   - Identical reference clock: 12.0 MHz (Period: 83.333 ns).
//   - Identical 784-vector DNN inference workload from weights.mem and activations.mem.
//   - Identical cycle-accurate stimuli and synchronous reset.
//   - Independent 66-bit golden mathematical reference model.
//////////////////////////////////////////////////////////////////////////////////

module unified_5design_validation_tb;

    // -------------------------------------------------------------------------
    // 12.0 MHz Clock and Control Signals (Period = 83.333 ns, Half = 41.666 ns)
    // -------------------------------------------------------------------------
    reg clk;
    reg reset;

    // -------------------------------------------------------------------------
    // Workload Inputs
    // -------------------------------------------------------------------------
    reg signed [31:0] A;
    reg signed [31:0] B;

    // -------------------------------------------------------------------------
    // Design 1: Original Conventional MAC Outputs
    // -------------------------------------------------------------------------
    wire signed [63:0] p_orig;
    wire signed [64:0] acc_orig;
    wire signed [64:0] fo_orig;
    wire               co_orig;

    // -------------------------------------------------------------------------
    // Design 2: Candidate 1 (Baugh-Wooley CSA + CLA) Outputs
    // -------------------------------------------------------------------------
    wire signed [63:0] p_c1;
    wire signed [64:0] acc_c1;
    wire signed [64:0] fo_c1;
    wire               co_c1;
    wire               fco_c1;

    // -------------------------------------------------------------------------
    // Design 3: Candidate 2 (Carry-Select Array MAC) Outputs
    // -------------------------------------------------------------------------
    wire signed [63:0] p_c2;
    wire signed [64:0] acc_c2;
    wire signed [64:0] fo_c2;
    wire               co_c2;
    wire               fco_c2;

    // -------------------------------------------------------------------------
    // Design 4: Dynamic/Adaptive MAC Outputs
    // -------------------------------------------------------------------------
    wire [1:0]         mode_adp;
    wire signed [31:0] a_eff_adp, b_eff_adp;
    wire [47:0]        bg_adp;
    wire [15:0]        neg_adp, two_adp, zero_adp;
    wire [1023:0]      pp_adp;
    wire signed [63:0] w_sum_adp, w_carry_adp;
    wire signed [63:0] cla_sum_adp;
    wire signed [63:0] acc_adp_64;
    wire signed [63:0] fo_adp_64;
    wire               fco_adp;

    // -------------------------------------------------------------------------
    // Design 5: Sparse Adaptive MAC Outputs
    // -------------------------------------------------------------------------
    wire               skip_sparse;
    wire [1:0]         mode_sparse;
    wire signed [31:0] a_eff_sparse, b_eff_sparse;
    wire [47:0]        bg_sparse;
    wire [15:0]        neg_sparse, two_sparse, zero_sparse;
    wire [1023:0]      pp_sparse;
    wire signed [63:0] w_sum_sparse, w_carry_sparse;
    wire signed [63:0] cla_sum_sparse;
    wire signed [63:0] acc_sparse_64;
    wire signed [63:0] fo_sparse_64;
    wire               fco_sparse;

    // -------------------------------------------------------------------------
    // Golden Model and Workload Memories
    // -------------------------------------------------------------------------
    reg [31:0] weights_mem     [0:783];
    reg [31:0] activations_mem [0:783];

    reg signed [63:0] expected_product;
    reg signed [64:0] expected_accumulator;
    reg signed [65:0] acc_sum_temp;

    integer i;
    integer mode8_cnt, mode16_cnt, mode32_cnt, skip_cnt;

    // -------------------------------------------------------------------------
    // DUT Instantiations
    // -------------------------------------------------------------------------

    // 1. Original Conventional MAC
    conventional_mac_top u_orig_conv (
        .clk(clk),
        .reset(reset),
        .A(A),
        .B(B),
        .product(p_orig),
        .accumulator_out(acc_orig),
        .carry_out(co_orig),
        .final_output(fo_orig)
    );

    // 2. Candidate 1: Baugh-Wooley CSA + CLA
    conv_mac_baugh_wooley u_cand1 (
        .clk(clk),
        .reset(reset),
        .A(A),
        .B(B),
        .product(p_c1),
        .accumulator_out(acc_c1),
        .final_output(fo_c1),
        .carry_out(co_c1),
        .final_carry_out(fco_c1)
    );

    // 3. Candidate 2: Carry-Select Array MAC
    conventional_mac_csla_top u_cand2 (
        .clk(clk),
        .reset(reset),
        .A(A),
        .B(B),
        .product(p_c2),
        .accumulator_out(acc_c2),
        .final_output(fo_c2),
        .carry_out(co_c2),
        .final_carry_out(fco_c2)
    );

    // 4. Dynamic/Adaptive MAC
    adaptive_mac_top u_adp (
        .clk(clk),
        .reset(reset),
        .A(A),
        .B(B),
        .mode_out(mode_adp),
        .A_eff_out(a_eff_adp),
        .B_eff_out(b_eff_adp),
        .booth_groups_out(bg_adp),
        .neg_out(neg_adp),
        .two_out(two_adp),
        .zero_out(zero_adp),
        .partial_products_out(pp_adp),
        .wallace_sum_out(w_sum_adp),
        .wallace_carry_out(w_carry_adp),
        .cla_sum_out(cla_sum_adp),
        .accumulator_out(acc_adp_64),
        .final_output(fo_adp_64),
        .final_carry_out(fco_adp)
    );

    // 5. Sparse Adaptive MAC
    adaptive_sparse_mac_top u_sparse (
        .clk(clk),
        .reset(reset),
        .A(A),
        .B(B),
        .skip(skip_sparse),
        .mode_out(mode_sparse),
        .A_eff_out(a_eff_sparse),
        .B_eff_out(b_eff_sparse),
        .booth_groups_out(bg_sparse),
        .neg_out(neg_sparse),
        .two_out(two_sparse),
        .zero_out(zero_sparse),
        .partial_products_out(pp_sparse),
        .wallace_sum_out(w_sum_sparse),
        .wallace_carry_out(w_carry_sparse),
        .cla_sum_out(cla_sum_sparse),
        .accumulator_out(acc_sparse_64),
        .final_output(fo_sparse_64),
        .final_carry_out(fco_sparse)
    );

    // -------------------------------------------------------------------------
    // Clock Generation: 12.0 MHz (83.333 ns period)
    // -------------------------------------------------------------------------
    always #41.666 clk = ~clk;

    // -------------------------------------------------------------------------
    // Main Verification Process
    // -------------------------------------------------------------------------
    initial begin
        $display("================================================================================");
        $display("   UNIFIED 5-DESIGN APPLES-TO-APPLES FUNCTIONAL VALIDATION ON 784 DNN VECTORS   ");
        $display("================================================================================");

        clk = 1'b0;
        reset = 1'b1;
        A = 32'd0;
        B = 32'd0;
        expected_product = 64'd0;
        expected_accumulator = 65'd0;
        mode8_cnt = 0;
        mode16_cnt = 0;
        mode32_cnt = 0;
        skip_cnt = 0;

        $readmemh("weights.mem", weights_mem);
        $readmemh("activations.mem", activations_mem);

        // Apply Synchronous Reset
        @(posedge clk);
        #1;
        reset = 1'b1;
        @(posedge clk);
        @(posedge clk);
        #1;
        reset = 1'b0;
        @(posedge clk);
        #1;

        $display("[INFO] Initial Reset Applied. Starting 784 DNN inference vector stream...");

        for (i = 0; i < 784; i = i + 1) begin
            #1;
            A = $signed(activations_mem[i]);
            B = $signed(weights_mem[i]);

            expected_product = A * B;
            acc_sum_temp = {expected_accumulator[64], expected_accumulator} + 
                           {{2{expected_product[63]}}, expected_product};
            expected_accumulator = acc_sum_temp[64:0];

            @(posedge clk);
            #2; // Sample after registered clock edge

            // Track adaptive statistics
            if (skip_sparse) skip_cnt = skip_cnt + 1;
            if (mode_adp == 2'b00) mode8_cnt = mode8_cnt + 1;
            else if (mode_adp == 2'b01) mode16_cnt = mode16_cnt + 1;
            else mode32_cnt = mode32_cnt + 1;
        end

        #50;

        $display("\n================================================================================");
        $display("   FINAL WORKLOAD ACCUMULATOR COMPARISON ACROSS ALL FIVE DESIGNS                 ");
        $display("================================================================================");
        $display("   Total Operand Pairs Processed      : %0d", 784);
        $display("   Golden Mathematical Sum            : %0d (0x%017h)", expected_accumulator, expected_accumulator);
        $display("--------------------------------------------------------------------------------");
        $display("   1. Original Conventional MAC       : %0d (0x%017h) | Match: %s", 
                 acc_orig, acc_orig, (acc_orig === expected_accumulator) ? "YES (100%)" : "NO");
        $display("   2. Candidate 1 (Baugh-Wooley CSA)  : %0d (0x%017h) | Match: %s", 
                 acc_c1, acc_c1, (acc_c1 === expected_accumulator) ? "YES (100%)" : "NO");
        $display("   3. Candidate 2 (Carry-Select MAC)  : %0d (0x%017h) | Match: %s", 
                 acc_c2, acc_c2, (acc_c2 === expected_accumulator) ? "YES (100%)" : "NO");
        $display("   4. Dynamic/Adaptive MAC (65-bit)   : %0d (0x%017h) | [63:0]: 0x%016h | Match: %s", 
                 $signed({fco_adp, acc_adp_64}), {fco_adp, acc_adp_64}, acc_adp_64,
                 ($signed({fco_adp, acc_adp_64}) === expected_accumulator) ? "YES (100%)" : "DIFFERENT");
        $display("   5. Sparse Adaptive MAC (65-bit)    : %0d (0x%017h) | [63:0]: 0x%016h | Match: %s", 
                 $signed({fco_sparse, acc_sparse_64}), {fco_sparse, acc_sparse_64}, acc_sparse_64,
                 ($signed({fco_sparse, acc_sparse_64}) === expected_accumulator) ? "YES (100%)" : "DIFFERENT");
        $display("--------------------------------------------------------------------------------");
        $display("   Workload Precision Breakdown (Adaptive):");
        $display("     - 8-bit  Precision Mode Cycles   : %0d (%.2f%%)", mode8_cnt, (mode8_cnt*100.0)/784.0);
        $display("     - 16-bit Precision Mode Cycles   : %0d (%.2f%%)", mode16_cnt, (mode16_cnt*100.0)/784.0);
        $display("     - 32-bit Precision Mode Cycles   : %0d (%.2f%%)", mode32_cnt, (mode32_cnt*100.0)/784.0);
        $display("     - Zero-Skipped Cycles (Sparsity) : %0d (%.2f%%)", skip_cnt, (skip_cnt*100.0)/784.0);
        $display("================================================================================\n");

        $finish;
    end

endmodule
