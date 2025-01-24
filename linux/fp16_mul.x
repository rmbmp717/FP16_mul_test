// DSLX code for FP16 multiply
//
// 16-bit FP16 Format:
// [15]    Sign
// [14:10] Exponent (5 bits)
// [9:0]   Fraction (10 bits)
//
// 特殊値 (Inf, NaN, Zero, Subnormal) の取り扱いも Verilog コードに準拠。

// 条件に基づいて a または b を選択する汎用関数
pub fn sel<N: u32>(cond: bits[1], a: bits[N], b: bits[N]) -> bits[N] {
    if cond == bits[1]:1 {
        a
    } else {
        b
    }
}

// ビット幅変換用のユーティリティ関数
pub fn u5_to_u8(x: bits[5]) -> bits[8] {
    bits[3]:0 ++ x
}

pub fn u11_to_u22(x: bits[11]) -> bits[22] {
    bits[11]:0 ++ x
}

pub fn u11_to_u32(x: bits[11]) -> bits[32] {
    bits[21]:0 ++ x
}

pub fn u8_to_u32(x: bits[8]) -> bits[32] {
    bits[24]:0 ++ x
}

// FP16 の特殊値チェック (Inf, NaN)
fn check_special_values(exp: bits[5], frac: bits[10]) -> (bits[1], bits[1]) {
    let is_inf = (exp == bits[5]:0x1F) & (frac == bits[10]:0);
    let is_nan = (exp == bits[5]:0x1F) & (frac != bits[10]:0);
    (is_inf, is_nan)
}

// FP16 乗算関数
pub fn fp16_multiply(a: bits[16], b: bits[16]) -> bits[16] {
    // ----------------------------
    // 1. ビットフィールドの分解
    // ----------------------------
    let exp_a = a[10:15];  // Exponent (bits[5])
    let exp_b = b[10:15];  // Exponent (bits[5])
    let frac_a_raw: bits[10] = a[0:10];  // 下位 10 ビットをスライス
    let frac_b_raw: bits[10] = b[0:10];  // 下位 10 ビットをスライス
    let sign_a: bits[1] = a[15:16];  // 上位1ビットをスライス
    let sign_b: bits[1] = b[15:16];  // 上位1ビットをスライス

    trace!(a);
    trace!(b);
    trace!(exp_a);
    trace!(exp_b);
    trace!(frac_a_raw);
    trace!(frac_b_raw);
    trace!(sign_a);
    trace!(sign_b);

    // ----------------------------
    // 2. 特殊値の判定
    // ----------------------------
    let (is_inf_a, is_nan_a) = check_special_values(exp_a, frac_a_raw);
    let (is_inf_b, is_nan_b) = check_special_values(exp_b, frac_b_raw);
    let is_zero_a = (exp_a == bits[5]:0) & (frac_a_raw == bits[10]:0);
    let is_zero_b = (exp_b == bits[5]:0) & (frac_b_raw == bits[10]:0);
    
    // ----------------------------
    // 3. 正常値の準備
    // ----------------------------
    let leading_a = sel(exp_a == bits[5]:0, bits[1]:0, bits[1]:1);
    let leading_b = sel(exp_b == bits[5]:0, bits[1]:0, bits[1]:1);
    let frac_a = leading_a ++ frac_a_raw;  // bits[11]
    let frac_b = leading_b ++ frac_b_raw;  // bits[11]

    trace!(frac_a);
    trace!(frac_b);

    // ----------------------------
    // 4. 乗算結果の計算
    // ----------------------------
    let sign_result = sign_a ^ sign_b;  // 結果の符号
    let exp_sum = u5_to_u8(exp_a) + u5_to_u8(exp_b) - bits[8]:15;  // Exponent 計算
    let frac_mult = u11_to_u22(frac_a) * u11_to_u22(frac_b);  // Fraction 乗算

    trace!(frac_mult);

    // ----------------------------
    // 5. 正規化と丸め処理
    // ----------------------------
    let leading_bit = frac_mult[21:22];  // 最上位1ビットをスライス
    let frac_adjusted = sel(leading_bit == bits[1]:1, frac_mult[11:22], frac_mult[10:21]);
    let exp_adjusted = exp_sum + sel(leading_bit == bits[1]:1, bits[8]:1, bits[8]:0);

    let guard_bit = sel(leading_bit == bits[1]:1, frac_mult[10:11], frac_mult[9:10]);
    let round_bit = sel(leading_bit == bits[1]:1, frac_mult[9:10], frac_mult[8:9]);
    let sticky_bit = frac_mult[0:8] != bits[8]:0;

    trace!(leading_bit);
    trace!(frac_adjusted);

    trace!(round_bit);
    trace!(sticky_bit);

    // 丸め条件の判定
    let round_condition = (guard_bit & (round_bit | sticky_bit)) |
                          (guard_bit & !round_bit & !sticky_bit & frac_adjusted[0:1]);

    let frac_final = sel(round_condition, frac_adjusted + bits[11]:1, frac_adjusted);
    let exp_final = exp_adjusted + sel(frac_adjusted == bits[11]:0x7FF, bits[8]:1, bits[8]:0);

    trace!(frac_adjusted);
    trace!(round_condition);
    trace!(frac_final);
    trace!(exp_final);
    
    // ----------------------------
    // 6. 特殊値・範囲外チェック
    // ----------------------------
    let is_nan_result = is_nan_a | is_nan_b | (is_inf_a & is_zero_b) | (is_zero_a & is_inf_b);
    let is_inf_a = (exp_a == bits[5]:0x1F) & (frac_a_raw == bits[10]:0);
    let is_inf_b = (exp_b == bits[5]:0x1F) & (frac_b_raw == bits[10]:0);
    let is_inf_result = is_inf_a | is_inf_b | (exp_final >= bits[8]:31);
    let is_zero_result = is_zero_a | is_zero_b;

    let frac_subnormal: bits[10] = (u11_to_u32(frac_final) >> u8_to_u32(bits[8]:1 - exp_final))[0:10];

    trace!(is_inf_result);
    trace!(is_zero_result);
    trace!(frac_subnormal);

    //trace!("=================================");

    // ----------------------------
    // 7. 最終結果の生成
    // ----------------------------
    let result = if is_nan_result {
        trace!(is_nan_result);
        bits[16]:0x7E00  // NaN
    } else if is_inf_result {
        trace!(is_inf_result);
        (sign_result ++ bits[5]:0x1F) ++ bits[10]:0  // Infinity
    } else if is_zero_result {
        trace!(is_zero_result);
        (sign_result ++ bits[5]:0) ++ bits[10]:0  // Zero
    } else if exp_final <= bits[8]:0 {
        trace!(exp_final);
        (sign_result ++ bits[5]:0) ++ frac_subnormal  // Subnormal
    } else {
        trace!(sign_result);
        trace!(exp_final[0:5]);
        trace!(frac_final[0:10]);
        let normalized_result: bits[16] = (sign_result ++ exp_final[0:5]) ++ frac_final[0:10];
        normalized_result
    };

    result
}

// トップレベル関数
pub fn fp16_multiplier(a: bits[16], b: bits[16]) -> bits[16] {
    fp16_multiply(a, b)
}

#[test]
fn fp16_multiply_test_zero() {
    // 0 * 任意の値 = 0
    let input_a: bits[16] = bits[16]:0b0000000000000000;  // 0.0
    let input_b: bits[16] = bits[16]:0b0100010001000000;  // 17.0
    let expected_output: bits[16] = bits[16]:0b0000000000000000;  // 0.0
    let output = fp16_multiply(input_a, input_b);
    assert_eq(output, expected_output);
}

#[test]
fn fp16_multiply_test_zero_cases() {
    // ゼロ同士の乗算
    let input_a = bits[16]:0x0000; // 0.0
    let input_b = bits[16]:0x0000; // 0.0
    assert_eq(fp16_multiply(input_a, input_b), bits[16]:0x0000);

    // ゼロと非ゼロの乗算
    let input_c = bits[16]:0x4000; // 2.0
    assert_eq(fp16_multiply(input_a, input_c), bits[16]:0x0000);
}

#[test]
fn fp16_multiply_test_nan_cases() {
    // NaNが絡む乗算
    let nan = bits[16]:0x7E00; // NaN
    let num = bits[16]:0x4400; // 4.0
    
    // NaN × 数値 = NaN
    assert_eq(fp16_multiply(nan, num), nan);
    
    // 数値 × NaN = NaN
    assert_eq(fp16_multiply(num, nan), nan);
    
    // NaN × NaN = NaN
    assert_eq(fp16_multiply(nan, nan), nan);
}

#[test]
fn fp16_multiply_test_infinity_cases() {
    // 無限大のテスト
    let inf = bits[16]:0x7C00; // +Inf
    let zero = bits[16]:0x0000; // 0.0
    let num = bits[16]:0x5000; // 32.0

    // Inf × 数値 = Inf
    assert_eq(fp16_multiply(inf, num), inf);
    
    // Inf × Inf = Inf
    assert_eq(fp16_multiply(inf, inf), inf);
    
    // Inf × 0 = NaN
    assert_eq(fp16_multiply(inf, zero), bits[16]:0x7E00);
}

#[test]
fn fp16_multiply_test_sign_handling() {
    // 符号処理のテスト
    let pos = bits[16]:0x4800; // +8.0
    let neg = bits[16]:0xC800; // -8.0
    
    // 正×正=正 (8.0 * 8.0 = 64.0)
    assert_eq(fp16_multiply(pos, pos), bits[16]:0x5400); // 正しい64.0の表現
    
    // 正×負=負 (8.0 * -8.0 = -64.0)
    assert_eq(fp16_multiply(pos, neg), bits[16]:0xD400); // 正しい-64.0の表現
    
    // 負×負=正 (-8.0 * -8.0 = 64.0)
    assert_eq(fp16_multiply(neg, neg), bits[16]:0x5400); // 正しい64.0の表現
}

#[test]
fn fp16_multiply_test_normal_numbers() {
    // 通常数値の乗算
    // 1.5 × 2.0 = 3.0
    let a = bits[16]:0x3E00; // 1.5 (0_01111_1000000000)
    let b = bits[16]:0x4000; // 2.0 (0_00001_0000000000)
    assert_eq(fp16_multiply(a, b), bits[16]:0x0C00); // 3.0 (0_00001_1000000000)

    // 最大値近傍のテスト
    let max_normal = bits[16]:0x7BFF; // 65504.0
    assert_eq(fp16_multiply(max_normal, max_normal), bits[16]:0x7C00); // Inf
}

#[test]
fn fp16_multiply_test_subnormal() {
    // 非正規化数のテスト
    let min_subnormal = bits[16]:0x0001; // 最小の非正規化数
    let result = fp16_multiply(min_subnormal, min_subnormal);
    assert_eq(result, bits[16]:0x0000); // アンダーフローで0
}

#[test]
fn fp16_multiply_test_rounding() {
    // 丸め処理のテスト
    // 1.0009765625 × 1.0009765625 = 1.001953125
    let a = bits[16]:0x3C01; // 1.0009765625
    let expected = bits[16]:0x3C02; // 1.001953125
    assert_eq(fp16_multiply(a, a), expected);
}

#[test]
fn fp16_multiply_test_overflow() {
    // オーバーフローテスト
    let huge = bits[16]:0x7BFF; // 最大正規化数 65504.0
    assert_eq(fp16_multiply(huge, huge), bits[16]:0x7C00); // Infinity
}
