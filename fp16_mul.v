/*
NISHIHARU
*/
// FP16乗算関数の定義
function [15:0] fp16_multiply;
    input [15:0] a; // FP16 input A
    input [15:0] b; // FP16 input B
    reg sign_a, sign_b, sign_result;
    reg [4:0] exp_a, exp_b;
    reg [10:0] frac_a, frac_b;
    reg zero_a, zero_b;
    reg inf_a, inf_b, nan_a, nan_b;
    integer exp_sum; // Changed to signed integer
    reg [21:0] frac_mult;
    reg [10:0] frac_adjusted;
    integer exp_adjusted; // Changed to signed integer
    reg guard_bit, round_bit, sticky_bit;
    reg [10:0] frac_final;
    integer shift_amount;
    integer i;

begin
    // Decomposition of inputs
    sign_a = a[15];
    exp_a = a[14:10];
    frac_a = (exp_a == 0) ? {1'b0, a[9:0]} : {1'b1, a[9:0]};
    zero_a = (exp_a == 0) && (a[9:0] == 0);

    sign_b = b[15];
    exp_b = b[14:10];
    frac_b = (exp_b == 0) ? {1'b0, b[9:0]} : {1'b1, b[9:0]};
    zero_b = (exp_b == 0) && (b[9:0] == 0);

    // Calculation of sign
    sign_result = sign_a ^ sign_b;

    // Handling special cases
    inf_a = (exp_a == 5'h1F) && (a[9:0] == 0);
    inf_b = (exp_b == 5'h1F) && (b[9:0] == 0);
    nan_a = (exp_a == 5'h1F) && (a[9:0] != 0);
    nan_b = (exp_b == 5'h1F) && (b[9:0] != 0);

    if (nan_a || nan_b || (inf_a && zero_b) || (zero_a && inf_b)) begin
        // Return Quiet NaN
        fp16_multiply = {1'b0, 5'h1F, 10'h200};
    end else if (inf_a || inf_b) begin
        // Handling infinity
        fp16_multiply = {sign_result, 5'h1F, 10'h0};
    end else if (zero_a || zero_b) begin
        // Handling zero
        fp16_multiply = {sign_result, 15'b0};
    end else begin
        // Normal calculation
        // Calculation of exponent (as signed integer)
        exp_sum = exp_a + exp_b - 15;

        // Multiplication of significands
        frac_mult = frac_a * frac_b; // 11-bit x 11-bit = 22-bit

        // Normalization
        if (frac_mult[21] == 1) begin
            // If the most significant bit is 1
            frac_adjusted = frac_mult[21:11];
            exp_adjusted = exp_sum + 1;
            guard_bit = frac_mult[10];
            round_bit = frac_mult[9];
            sticky_bit = |frac_mult[8:0];
        end else begin
            // If the most significant bit is 0
            frac_adjusted = frac_mult[20:10];
            exp_adjusted = exp_sum;
            guard_bit = frac_mult[9];
            round_bit = frac_mult[8];
            sticky_bit = |frac_mult[7:0];
        end

        // Rounding (round to nearest even)
        if ((guard_bit && (round_bit | sticky_bit)) || (guard_bit && ~round_bit && ~sticky_bit && frac_adjusted[0])) begin
            frac_final = frac_adjusted + 1;
            if (frac_final == 11'b10000000000) begin
                // Handle carry
                frac_final = frac_final >> 1;
                exp_adjusted = exp_adjusted + 1;
            end
        end else begin
            frac_final = frac_adjusted;
        end

        // Handling overflow and underflow
        if (exp_adjusted >= 31) begin
            // Overflow: infinity
            fp16_multiply = {sign_result, 5'h1F, 10'h0};
        end else if (exp_adjusted <= 0) begin
            // Underflow: subnormal or zero
            shift_amount = 1 - exp_adjusted;
            if (shift_amount < 11) begin
                // Right shift of significand
                frac_final = frac_final >> shift_amount;
                fp16_multiply = {sign_result, 5'b00000, frac_final[9:0]};
            end else begin
                // Zero
                fp16_multiply = {sign_result, 15'b0};
            end
        end else begin
            // Normalized number
            fp16_multiply = {sign_result, exp_adjusted[4:0], frac_final[9:0]};
        end
    end
end
endfunction

module fp16_multiplier (
    input [15:0] a,  // 入力A (FP16)
    input [15:0] b,  // 入力B (FP16)
    output [15:0] result  // 出力結果 (FP16)
);
    assign result = fp16_multiply(a,b);

endmodule
