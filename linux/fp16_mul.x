// DSLX code for FP16 multiply
// [15] Sign, [14:10] Exponent (5 bits, bias=15), [9:0] Fraction (10 bits)

pub fn sel<N: u32>(cond: bits[1], a: bits[N], b: bits[N]) -> bits[N] {
    if cond == bits[1]:1 {
        a
    } else {
        b
    }
}

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

// Special-value check
fn check_special_values(exp: bits[5], frac: bits[10]) -> (bits[1], bits[1]) {
    let is_inf = (exp == bits[5]:0x1F) & (frac == bits[10]:0);
    let is_nan = (exp == bits[5]:0x1F) & (frac != bits[10]:0);
    (is_inf, is_nan)
}

// 5bit exponent => 9bit (上位4ビット0拡張)
fn exp5_to_u9(e: bits[5]) -> bits[9] {
    bits[4]:0 ++ e
}

const BIAS_9 = bits[9]:15;  // バイアス15を9ビットに

pub fn fp16_multiply(a: bits[16], b: bits[16]) -> bits[16] {
    // 1. 分解
    let exp_a = a[10:15];
    let exp_b = b[10:15];
    let frac_a_raw = a[0:10];
    let frac_b_raw = b[0:10];
    let sign_a = a[15:16];
    let sign_b = b[15:16];

    trace!(a);
    trace!(b);
    trace!(exp_a);
    trace!(exp_b);
    trace!(frac_a_raw);
    trace!(frac_b_raw);
    trace!(sign_a);
    trace!(sign_b);

    // 2. 特殊値判定
    let (is_inf_a, is_nan_a) = check_special_values(exp_a, frac_a_raw);
    let (is_inf_b, is_nan_b) = check_special_values(exp_b, frac_b_raw);
    let is_zero_a = (exp_a == bits[5]:0) & (frac_a_raw == bits[10]:0);
    let is_zero_b = (exp_b == bits[5]:0) & (frac_b_raw == bits[10]:0);

    // 3. hidden bit
    let leading_a = sel(exp_a == bits[5]:0, bits[1]:0, bits[1]:1);
    let leading_b = sel(exp_b == bits[5]:0, bits[1]:0, bits[1]:1);
    let frac_a = leading_a ++ frac_a_raw;  // bits[11]
    let frac_b = leading_b ++ frac_b_raw;  // bits[11]

    trace!(frac_a);
    trace!(frac_b);

    // 4. 乗算
    let sign_result = sign_a ^ sign_b;

    let exp_a_9 = exp5_to_u9(exp_a); // bits[9]
    let exp_b_9 = exp5_to_u9(exp_b); // bits[9]
    let exp_sum_9 = (exp_a_9 + exp_b_9) - BIAS_9; // bits[9] 2の補数的に

    // (下の exp_sum は trace 用: bits[8])
    let exp_sum = (u5_to_u8(exp_a) + u5_to_u8(exp_b)) - bits[8]:15;
    trace!(exp_sum);

    let frac_mult = u11_to_u22(frac_a) * u11_to_u22(frac_b);
    trace!(frac_mult);

    // 5. 正規化
    let leading_bit = frac_mult[21:22];
    let frac_adjusted = sel(leading_bit == bits[1]:1,
                            frac_mult[11:22],
                            frac_mult[10:21]);

    let exp_adjusted_9 = exp_sum_9 + sel(leading_bit == bits[1]:1,
                                         bits[9]:1,
                                         bits[9]:0);

    let guard_bit = sel(leading_bit == bits[1]:1,
                        frac_mult[10:11],
                        frac_mult[9:10]);
    let round_bit = sel(leading_bit == bits[1]:1,
                        frac_mult[9:10],
                        frac_mult[8:9]);
    let sticky_bit = frac_mult[0:8] != bits[8]:0;

    trace!(leading_bit);
    trace!(frac_adjusted);
    trace!(round_bit);
    trace!(sticky_bit);

    let round_condition = (guard_bit & (round_bit | sticky_bit)) |
                          (guard_bit & !round_bit & !sticky_bit & frac_adjusted[0:1]);

    let frac_final_pre = sel(round_condition,
                             frac_adjusted + bits[11]:1,
                             frac_adjusted);

    // frac_final_pre => bits[12] に拡張して ">= 0x800"
    let frac_final_pre_12 = bits[1]:0 ++ frac_final_pre; // bits[12]
    let cond_of = frac_final_pre_12 >= bits[12]:0x800;
    let overflow_bit = sel(cond_of, bits[1]:1, bits[1]:0);

    let exp_final_9 = exp_adjusted_9 + (bits[8]:0 ++ overflow_bit); // bits[9]
    let frac_final_shifted = sel(overflow_bit == bits[1]:1,
                                 frac_final_pre >> bits[11]:1,
                                 frac_final_pre);

    trace!(frac_adjusted);
    trace!(round_condition);
    trace!(frac_final_shifted);

    // trace 用に exp_final( bits[8] ) を計算しておく
    let exp_final = exp_sum
                    + sel(leading_bit == bits[1]:1, bits[8]:1, bits[8]:0)
                    + sel(frac_adjusted == bits[11]:0x7FF, bits[8]:1, bits[8]:0);
    trace!(exp_final);

    // 6. 特殊ケース判定
    let is_nan_result = is_nan_a | is_nan_b | (is_inf_a & is_zero_b) | (is_zero_a & is_inf_b);
    let is_inf_a_chk = (exp_a == bits[5]:0x1F) & (frac_a_raw == bits[10]:0);
    let is_inf_b_chk = (exp_b == bits[5]:0x1F) & (frac_b_raw == bits[10]:0);

    // ここで bits[9] の exp_final_9 を使ってオーバーフロー判定！
    let is_inf_result = is_inf_a_chk
                        | is_inf_b_chk
                        | (exp_final_9 >= bits[9]:31);

    let is_zero_result = is_zero_a | is_zero_b;

    // サブノーマル: exp_final_9 < 1
    let is_subnormal = exp_final_9 < bits[9]:1;

    // サブノーマル用に仮数を右シフト
    let shift_9 = bits[9]:1 - exp_final_9; // bits[9]
    let shift_32 = bits[23]:0 ++ shift_9;  // bits[32]
    let frac_final_32 = bits[21]:0 ++ frac_final_shifted; // bits[32]
    let frac_subnormal_32 = frac_final_32 >> shift_32;
    let frac_subnormal = frac_subnormal_32[0:10];

    trace!(is_inf_result);
    trace!(is_zero_result);
    trace!(frac_subnormal);

    // 7. 出力生成
    let result = if is_nan_result {
        trace!(is_nan_result);
        bits[16]:0x7E00
    } else if is_zero_result {
        trace!(is_zero_result);
        (sign_result ++ bits[5]:0) ++ bits[10]:0
    } else if is_inf_result {
        trace!(is_inf_result);
        (sign_result ++ bits[5]:0x1F) ++ bits[10]:0
    } else if is_subnormal {
        // exponent < 1 => subnormal
        trace!(exp_final_9);
        (sign_result ++ bits[5]:0) ++ frac_subnormal
    } else {
        // normal
        trace!(sign_result);
        let exp_out_5 = exp_final_9[0:5];
        let frac_out_10 = frac_final_shifted[0:10];
        trace!(exp_out_5);
        trace!(frac_out_10);

        (sign_result ++ exp_out_5) ++ frac_out_10
    };

    result
}

pub fn fp16_multiplier(a: bits[16], b: bits[16]) -> bits[16] {
    fp16_multiply(a, b)
}

// TEST function
#[test]
fn fp16_multiply_test_zero() {
    // 0 * 17.0 = 0
    let input_a: bits[16] = bits[16]:0x0000;   // 0.0
    let input_b: bits[16] = bits[16]:0x4C40;   // 17.0 (exponent=10011=19, fraction=0100000000=0x40)
    let expected_output: bits[16] = bits[16]:0x0000; // 0.0
    let output = fp16_multiply(input_a, input_b);
    assert_eq(output, expected_output);
}

#[test]
fn fp16_multiply_test_zero_cases() {
    // ゼロ同士の乗算
    let input_a = bits[16]:0x0000; // 0.0
    let input_b = bits[16]:0x0000; // 0.0
    assert_eq(fp16_multiply(input_a, input_b), bits[16]:0x0000);

    // ゼロと非ゼロ（2.0）の乗算
    let input_c = bits[16]:0x4000; // 2.0
    assert_eq(fp16_multiply(input_a, input_c), bits[16]:0x0000);
}

#[test]
fn fp16_multiply_test_nan_cases() {
    // NaNが絡む乗算
    let nan = bits[16]:0x7E00;  // NaN (exponent=11111, fraction=1000000000)
    let num = bits[16]:0x4400;  // 4.0 (exponent=10001=17, fraction=0000000000)

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
    let inf = bits[16]:0x7C00;   // +∞ (exponent=11111, fraction=0)
    let zero = bits[16]:0x0000;  // 0.0
    let num = bits[16]:0x5000;   // 32.0 (exponent=10100=20, fraction=0)

    // Inf × 数値 = Inf
    assert_eq(fp16_multiply(inf, num), inf);

    // Inf × Inf = Inf
    assert_eq(fp16_multiply(inf, inf), inf);

    // Inf × 0 = NaN (IEEE754ルール: ∞×0 → NaN)
    assert_eq(fp16_multiply(inf, zero), bits[16]:0x7E00);
}

#[test]
fn fp16_multiply_test_sign_handling() {
    // 符号処理のテスト
    let pos = bits[16]:0x4800; // +8.0  (exponent=10010=18, fraction=0)
    let neg = bits[16]:0xC800; // -8.0

    // 正×正=正 (8.0 * 8.0 = 64.0)
    assert_eq(fp16_multiply(pos, pos), bits[16]:0x5400); // 64.0 (exponent=10101=21, fraction=0)

    // 正×負=負 (8.0 * -8.0 = -64.0)
    assert_eq(fp16_multiply(pos, neg), bits[16]:0xD400); // -64.0

    // 負×負=正 (-8.0 * -8.0 = 64.0)
    assert_eq(fp16_multiply(neg, neg), bits[16]:0x5400);
}

#[test]
fn fp16_multiply_test_normal_numbers() {
    // 1.5 × 2.0 = 3.0
    let a = bits[16]:0x3E00; // 1.5 (exponent=01111=15, fraction=1000000000=0.5)
    let b = bits[16]:0x4000; // 2.0 (exponent=10000=16, fraction=0)
    assert_eq(fp16_multiply(a, b), bits[16]:0x4200); // 3.0 (exponent=10000=16, fraction=1000000000=0.5)

    // 最大値近傍のテスト (65504.0)
    let max_normal = bits[16]:0x7BFF; // exponent=11110=30, fraction=1111111111
    assert_eq(fp16_multiply(max_normal, max_normal), bits[16]:0x7C00); // Inf
}

#[test]
fn fp16_multiply_test_subnormal() {
    // 非正規化数のテスト: 最小サブノーマル × 最小サブノーマル
    let min_subnormal = bits[16]:0x0001; // 最小サブノーマル = 2^-24
    let result = fp16_multiply(min_subnormal, min_subnormal);
    // 非常に小さいのでアンダーフロー→0
    assert_eq(result, bits[16]:0x0000);
}

#[test]
fn fp16_multiply_test_rounding() {
    // 丸め処理のテスト
    // 1.0009765625 × 1.0009765625 = 1.001953125
    // 1.0009765625 = exponent=01111(15), fraction=0000000001(1/1024)
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
