module conventional_mac_top (
    input  wire        clk,
    input  wire        reset,
    input  wire signed [31:0] A,
    input  wire signed [31:0] B,

    output wire signed [63:0] product,

    // 65-bit accumulator
    output reg  signed [64:0] accumulator_out,

    // Carry beyond the 65-bit accumulator
    output reg                carry_out,

    // Final 65-bit accumulated output
    output wire signed [64:0] final_output
);

    // -------------------------------------------------------
    // Internal signals for shift-and-add multiplier
    // -------------------------------------------------------
    reg [31:0] mag_a;
    reg [31:0] mag_b;
    reg        sign_a;
    reg        sign_b;
    reg        result_sign;

    reg [63:0] unsigned_product;
    reg signed [63:0] signed_product;

    integer i;

    // -------------------------------------------------------
    // 66-bit accumulator addition
    // -------------------------------------------------------
    reg signed [65:0] accumulator_sum;

    // -------------------------------------------------------
    // Combinational shift-and-add multiplier
    // -------------------------------------------------------
    always @(*) begin

        // Determine signs
        sign_a = A[31];
        sign_b = B[31];

        result_sign = sign_a ^ sign_b;

        // Convert A to positive magnitude
        if (sign_a)
            mag_a = ~A[31:0] + 1'b1;
        else
            mag_a = A[31:0];

        // Convert B to positive magnitude
        if (sign_b)
            mag_b = ~B[31:0] + 1'b1;
        else
            mag_b = B[31:0];

        // ---------------------------------------------------
        // Unsigned shift-and-add multiplication
        // ---------------------------------------------------
        unsigned_product = 64'd0;

        for (i = 0; i < 32; i = i + 1) begin

            if (mag_b[i])
                unsigned_product =
                    unsigned_product + ({32'd0, mag_a} << i);

        end

        // ---------------------------------------------------
        // Apply result sign
        // ---------------------------------------------------
        if (result_sign)
            signed_product = ~unsigned_product + 64'd1;
        else
            signed_product = unsigned_product;

    end

    // -------------------------------------------------------
    // Product output
    // -------------------------------------------------------
    assign product = signed_product;

    // -------------------------------------------------------
    // 66-bit accumulator addition
    //
    // Product is sign-extended from 64 bits to 66 bits.
    // Accumulator is sign-extended from 65 bits to 66 bits.
    //
    // [64:0] -> new 65-bit accumulator
    // [65]   -> carry beyond the 65-bit accumulator
    // -------------------------------------------------------
    always @(*) begin

        accumulator_sum =
            {accumulator_out[64], accumulator_out}
            +
            {{2{signed_product[63]}}, signed_product};

    end

    // -------------------------------------------------------
    // 65-bit registered accumulator
    // -------------------------------------------------------
    always @(posedge clk) begin

        if (reset) begin
            accumulator_out <= 65'd0;
            carry_out       <= 1'b0;
        end
        else begin
            accumulator_out <= accumulator_sum[64:0];
            carry_out       <= accumulator_sum[65];
        end

    end

    // -------------------------------------------------------
    // Final output
    // -------------------------------------------------------
    assign final_output = accumulator_out;

endmodule