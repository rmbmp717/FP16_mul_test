module fp16_multiplier (
    input [15:0] a,  // 入力A (FP16)
    input [15:0] b,  // 入力B (FP16)
    output reg [15:0] result  // 出力結果 (FP16)
);
    // 内部信号
    reg sign_a, sign_b, sign_result;
    reg [4:0] exp_a, exp_b;
    reg [10:0] frac_a, frac_b;
    reg zero_a, zero_b;
    reg inf_a, inf_b, nan_a, nan_b;
    reg [7:0] exp_sum; // Changed to signed integer
    reg [21:0] frac_mult;
    reg [10:0] frac_adjusted;
    reg [7:0] exp_adjusted; // Changed to signed integer
    reg guard_bit, round_bit, sticky_bit;
    reg [11:0] frac_final_tmp;
    reg [11:0] frac_final = 0;
    integer shift_amount;

    always @(*) begin
        // 入力の分解
        sign_a = a[15];
        exp_a = a[14:10];
        frac_a = (exp_a == 0) ? {1'b0, a[9:0]} : {1'b1, a[9:0]};
        zero_a = (exp_a == 0) && (a[9:0] == 0);

        sign_b = b[15];
        exp_b = b[14:10];
        frac_b = (exp_b == 0) ? {1'b0, b[9:0]} : {1'b1, b[9:0]};
        zero_b = (exp_b == 0) && (b[9:0] == 0);

        // 符号計算
        sign_result = sign_a ^ sign_b;

        // 特殊ケースの処理
        inf_a = (exp_a == 5'h1F) && (a[9:0] == 0);
        inf_b = (exp_b == 5'h1F) && (b[9:0] == 0);
        nan_a = (exp_a == 5'h1F) && (a[9:0] != 0);
        nan_b = (exp_b == 5'h1F) && (b[9:0] != 0);

        if (nan_a || nan_b || (inf_a && zero_b) || (zero_a && inf_b)) begin
            // Quiet NaNを返す
            result = {1'b0, 5'h1F, 10'h200};
        end else if (inf_a || inf_b) begin
            // 無限大の処理
            result = {sign_result, 5'h1F, 10'h0};
        end else if (zero_a || zero_b) begin
            // ゼロの処理
            result = {sign_result, 15'b0};
        end else begin
            // 通常の計算
            // 指数の計算 (signed)
            exp_sum = exp_a + exp_b - 15;

            // 仮数の乗算
            frac_mult = frac_a * frac_b; // 11-bit x 11-bit = 22-bit

            // 正規化
            if (frac_mult[21] == 1) begin
                frac_adjusted = frac_mult[21:11];
                exp_adjusted = exp_sum + 1;
                guard_bit = frac_mult[10];
                round_bit = frac_mult[9];
                sticky_bit = |frac_mult[8:0];
            end else begin
                frac_adjusted = frac_mult[20:10];
                exp_adjusted = exp_sum;
                guard_bit = frac_mult[9];
                round_bit = frac_mult[8];
                sticky_bit = |frac_mult[7:0];
            end

            // 丸め処理 (round to nearest even)
            if ((guard_bit && (round_bit | sticky_bit)) || (guard_bit && ~round_bit && ~sticky_bit && frac_adjusted[0])) begin
                frac_final_tmp = frac_adjusted + 1;
                if (frac_final_tmp == 11'b10000000000) begin
                    frac_final = 11'b0000000000; // 仮数をリセット
                    exp_adjusted = exp_adjusted + 1;
                end else begin
                    frac_final = frac_final_tmp;
                    exp_adjusted = exp_adjusted + 1;
                end
            end else begin
                frac_final = frac_adjusted;
            end

            // オーバーフローとアンダーフローの処理
            if (exp_adjusted >= 31) begin
                // オーバーフロー: 無限大
                result = {sign_result, 5'h1F, 10'h0};
            end else if (exp_adjusted <= 0) begin
                // アンダーフロー: 非正規化数またはゼロ
                shift_amount = 1 - exp_adjusted;
                if (shift_amount < 11) begin
                    // 仮数を右シフト
                    frac_final = frac_final >> shift_amount;
                    result = {sign_result, 5'b00000, frac_final[9:0]};
                end else begin
                    // ゼロ
                    result = {sign_result, 15'b0};
                end
            end else begin
                // 正規化数
                result = {sign_result, exp_adjusted[4:0], frac_final[9:0]};
            end
        end
    end
endmodule
