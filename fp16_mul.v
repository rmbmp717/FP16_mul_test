/*
NISHIHARU
*/
module fp16_multiplier (
    input [15:0] a,  // 入力A (FP16)
    input [15:0] b,  // 入力B (FP16)
    output [15:0] result  // 出力結果 (FP16)
);
    // 各フィールドの抽出
    wire sign_a = a[15];
    wire [4:0] exp_a = a[14:10];
    wire [10:0] mantissa_a = {1'b1, a[9:0]};  // 隠れビットを追加

    wire sign_b = b[15];
    wire [4:0] exp_b = b[14:10];
    wire [10:0] mantissa_b = {1'b1, b[9:0]};  // 隠れビットを追加

    // 符号ビットの計算
    wire result_sign = sign_a ^ sign_b;

    // 指数部の計算
    wire [6:0] exp_sum = exp_a + exp_b - 5'd15;  // バイアス調整 (15)

    // 仮数部の乗算
    wire [21:0] mantissa_product = mantissa_a * mantissa_b;

    // 正規化処理
    wire [10:0] normalized_mantissa = (mantissa_product[21]) ? mantissa_product[21:11] : mantissa_product[20:10];
    wire [6:0] normalized_exp = (mantissa_product[21]) ? exp_sum + 1'b1 : exp_sum;

    // オーバーフローとアンダーフローのチェック
    wire overflow = (normalized_exp > 5'd30); // FP16の指数部の最大値は30
    wire underflow = (normalized_exp < 5'd1); // 1未満でアンダーフロー

    // 結果の組み立て
    assign result = (underflow) ? 16'b0 :  // アンダーフロー時は0
                    (overflow) ? {result_sign, 5'b11111, 10'b0} :  // オーバーフロー時は±∞
                    {result_sign, normalized_exp[4:0], normalized_mantissa[9:0]};  // 正常時の結果

endmodule
