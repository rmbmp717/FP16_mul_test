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

    // ----------------------------
    // 4. 乗算結果の計算
    // ----------------------------
    let sign_result = sign_a ^ sign_b;  // 結果の符号
    let exp_sum = u5_to_u8(exp_a) + u5_to_u8(exp_b) - bits[8]:15;  // Exponent 計算
    let frac_mult = u11_to_u22(frac_a) * u11_to_u22(frac_b);  // Fraction 乗算

    // ----------------------------
    // 5. 正規化と丸め処理
    // ----------------------------
    let leading_bit: bits[1] = frac_mult[21:22];  // 最上位1ビットをスライス
    let frac_adjusted = sel(leading_bit == bits[1]:1, frac_mult[11:22], frac_mult[10:21]);
    let exp_adjusted = exp_sum + sel(leading_bit == bits[1]:1, bits[8]:1, bits[8]:0);

    let guard_bit = sel(leading_bit == bits[1]:1, frac_mult[10:11], frac_mult[9:10]);
    let round_bit = sel(leading_bit == bits[1]:1, frac_mult[9:10], frac_mult[8:9]);
    let sticky_bit = frac_mult[0:9] != bits[9]:0;

    // 丸め条件の判定
    let round_condition = (guard_bit & (round_bit | sticky_bit)) |
                          (guard_bit & !round_bit & !sticky_bit & frac_adjusted[0:1]);

    let frac_final = sel(round_condition, frac_adjusted + bits[11]:1, frac_adjusted);
    let exp_final = exp_adjusted + sel(frac_final == bits[11]:0x7FF, bits[8]:1, bits[8]:0);

    // ----------------------------
    // 6. 特殊値・範囲外チェック
    // ----------------------------
    let is_nan_result = is_nan_a | is_nan_b | (is_inf_a & is_zero_b) | (is_zero_a & is_inf_b);
    let is_inf_a = (exp_a == bits[5]:0x1F) & (frac_a_raw == bits[10]:0);
    let is_inf_b = (exp_b == bits[5]:0x1F) & (frac_b_raw == bits[10]:0);
    let is_inf_result = is_inf_a | is_inf_b | (exp_final >= bits[8]:31);
    let is_zero_result = is_zero_a | is_zero_b;

    let frac_subnormal: bits[10] = (u11_to_u32(frac_final) >> u8_to_u32(bits[8]:1 - exp_final))[0:10];

    // ----------------------------
    // 7. 最終結果の生成
    // ----------------------------
    let result = if is_nan_result {
        bits[16]:0x7E00  // NaN
    } else if is_inf_result {
        (sign_result ++ bits[5]:0x1F) ++ bits[10]:0  // Infinity
    } else if is_zero_result {
        (sign_result ++ bits[5]:0) ++ bits[10]:0  // Zero
    } else if exp_final <= bits[8]:0 {
        (sign_result ++ bits[5]:0) ++ frac_subnormal  // Subnormal
    } else {
        let normalized_result: bits[16] = (sign_result ++ exp_final[0:5]) ++ frac_final[0:10];
        normalized_result
    };

    result
}

// トップレベル関数
pub fn fp16_multiplier(a: bits[16], b: bits[16]) -> bits[16] {
    fp16_multiply(a, b)
}
