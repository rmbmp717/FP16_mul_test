/*
NISHIHARU
*/
// FP16乗算関数の定義
function [15:0] fp16_multiply;
    input [15:0] a; // FP16入力A
    input [15:0] b; // FP16入力B
    reg sign_a, sign_b, sign_result;
    reg [4:0] exp_a, exp_b;
    reg [10:0] frac_a, frac_b;
    reg zero_a, zero_b;
    reg inf_a, inf_b, nan_a, nan_b;
    integer exp_sum; // 符号付き整数に変更
    reg [21:0] frac_mult;
    reg [10:0] frac_adjusted;
    integer exp_adjusted; // 符号付き整数に変更
    reg guard_bit, round_bit, sticky_bit;
    reg [10:0] frac_final;
    integer shift_amount;
    integer i;

begin
    // 入力の分解
    sign_a = a[15];
    exp_a = a[14:10];
    frac_a = (exp_a == 0) ? {1'b0, a[9:0]} : {1'b1, a[9:0]};
    zero_a = (exp_a == 0) && (a[9:0] == 0);

    sign_b = b[15];
    exp_b = b[14:10];
    frac_b = (exp_b == 0) ? {1'b0, b[9:0]} : {1'b1, b[9:0]};
    zero_b = (exp_b == 0) && (b[9:0] == 0);

    // 符号の計算
    sign_result = sign_a ^ sign_b;

    // 特殊なケースの処理
    inf_a = (exp_a == 5'h1F) && (a[9:0] == 0);
    inf_b = (exp_b == 5'h1F) && (b[9:0] == 0);
    nan_a = (exp_a == 5'h1F) && (a[9:0] != 0);
    nan_b = (exp_b == 5'h1F) && (b[9:0] != 0);

    if (nan_a || nan_b || (inf_a && zero_b) || (zero_a && inf_b)) begin
        // Quiet NaNを返す
        fp16_multiply = {1'b0, 5'h1F, 10'h200};
    end else if (inf_a || inf_b) begin
        // 無限大の処理
        fp16_multiply = {sign_result, 5'h1F, 10'h0};
    end else if (zero_a || zero_b) begin
        // ゼロの処理
        fp16_multiply = {sign_result, 15'b0};
    end else begin
        // 通常の計算
        // 指数の計算（符号付き整数として計算）
        exp_sum = exp_a + exp_b - 15;

        // 仮数の乗算
        frac_mult = frac_a * frac_b; // 11ビット x 11ビット = 22ビット

        // 正規化
        if (frac_mult[21] == 1) begin
            // 最上位ビットが1の場合
            frac_adjusted = frac_mult[21:11];
            exp_adjusted = exp_sum + 1;
            guard_bit = frac_mult[10];
            round_bit = frac_mult[9];
            sticky_bit = |frac_mult[8:0];
        end else begin
            // 最上位ビットが0の場合
            frac_adjusted = frac_mult[20:10];
            exp_adjusted = exp_sum;
            guard_bit = frac_mult[9];
            round_bit = frac_mult[8];
            sticky_bit = |frac_mult[7:0];
        end

        // 丸め処理（最近接偶数への丸め）
        if ((guard_bit && (round_bit | sticky_bit)) || (guard_bit && ~round_bit && ~sticky_bit && frac_adjusted[0])) begin
            frac_final = frac_adjusted + 1;
            if (frac_final == 11'b10000000000) begin
                // 繰り上がりが発生した場合
                frac_final = frac_final >> 1;
                exp_adjusted = exp_adjusted + 1;
            end
        end else begin
            frac_final = frac_adjusted;
        end

        // オーバーフローとアンダーフローの処理
        if (exp_adjusted >= 31) begin
            // オーバーフロー：無限大
            fp16_multiply = {sign_result, 5'h1F, 10'h0};
        end else if (exp_adjusted <= 0) begin
            // アンダーフロー：サブノーマル数またはゼロ
            shift_amount = 1 - exp_adjusted;
            if (shift_amount < 11) begin
                // 仮数を右シフト
                frac_final = frac_final >> shift_amount;
                fp16_multiply = {sign_result, 5'b00000, frac_final[9:0]};
            end else begin
                // ゼロ
                fp16_multiply = {sign_result, 15'b0};
            end
        end else begin
            // 正規化された数
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