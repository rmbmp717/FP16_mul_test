// DSLX code for FP16 multiply
//
// 16-bit FP16 Format:
// [15]    Sign
// [14:10] Exponent (5 bits)
// [9:0]   Fraction (10 bits)
//
// 特殊値 (Inf, NaN, Zero, Subnormal) などの取り扱いも
// Verilog コードと同じロジックをできるだけ反映しています。

pub fn sel<N: u32>(cond: bits[1], a: bits[N], b: bits[N]) -> bits[N] {
    if cond == bits[1]:1 {
      a
    } else {
      b
    }
  }  

pub fn u5_to_u8(x: bits[5]) -> bits[8] {
    let zero3: bits[3] = bits[3]:0;
    let out_u8: bits[8] = zero3 ++ x;
    out_u8
}

pub fn u11_to_u22(x: bits[11]) -> bits[22] {
    // 上位 11 ビットを 0 とし、それと x (bits[11]) を連結
    let zero11: bits[11] = bits[11]:0;
    let out_u22: bits[22] = zero11 ++ x;  // "++" でビット列を連結 (合計 22 ビット)
    out_u22
}

pub fn u11_to_u32(x: bits[11]) -> bits[32] {
    let zero21: bits[21] = bits[21]:0;
    let out_u32: bits[32] = zero21 ++ x;  // 上位21ビットをゼロ埋めして32ビット化
    out_u32
}

pub fn u8_to_u32(x: bits[8]) -> bits[32] {
    let zero24: bits[24] = bits[24]:0;
    let out_u32: bits[32] = zero24 ++ x;
    out_u32
}

pub fn fp16_multiply(a: bits[16], b: bits[16]) -> bits[16] {
    // exp_a, exp_b はスライス結果そのまま
    let exp_a = (a >> 10)[0:5];  // bits[5]
    let exp_b = (b >> 10)[0:5];  // bits[5]

    // frac_a_raw, frac_b_raw は "一度スライスして → 型付け変数に代入"
    let frac_a_raw = a[0:10];
    let frac_b_raw = b[0:10];

    // sign ビットは 1ビット
    let sign_a: bits[1] = (a >> 15)[0:1];  // 上位1ビットをスライスして bits[1] にする
    let sign_b: bits[1] = (b >> 15)[0:1];

    // 0 の定義（ビット幅を明示）
    let zero_5: bits[5]   = bits[5]:0;
    let zero_10: bits[10] = bits[10]:0;

    // “exp=0 and frac=0” → Zero の判定
    let is_zero_a = (exp_a == zero_5) & (frac_a_raw == zero_10);
    let is_zero_b = (exp_b == zero_5) & (frac_b_raw == zero_10);

    // subnormal or normal
    let leading_a = sel(exp_a == bits[5]:0, bits[1]:0, bits[1]:1);  // exp=0 → 0, else 1
    let leading_b = sel(exp_b == bits[5]:0, bits[1]:0, bits[1]:1);  // exp=0 → 0, else 1

    // 1ビット追加して 11 ビット化
    // frac_a = {leading_a, frac_a_raw}
    let frac_a = leading_a ++ frac_a_raw;   // bits[11]
    let frac_b = leading_b ++ frac_b_raw;   // bits[11]

    // 無限と NaN のチェック
    let is_inf_a = (exp_a == bits[5]:0x1F) & (frac_a_raw == bits[10]:0);
    let is_inf_b = (exp_b == bits[5]:0x1F) & (frac_b_raw == bits[10]:0);
    let is_nan_a = (exp_a == bits[5]:0x1F) & (frac_a_raw != bits[10]:0);
    let is_nan_b = (exp_b == bits[5]:0x1F) & (frac_b_raw != bits[10]:0);

    // ----------------------------
    // 2) 特殊ケースの処理
    // ----------------------------
    // NaN, inf * zero, zero, inf, etc...
    let sign_result = sign_a ^ sign_b;  // bits[1]

    // Quiet NaN: 0xFE00 (sign=0, exp=0x1F, fract=0x200)
    let qnan = bits[16]:0b0111111000000000; // = 0x7E00

    // Infinity: {sign, 11111, 0}
    let inf_val = (sign_result ++ bits[5]:0x1F) ++ bits[10]:0;

    // Zero: {sign, 00000, 0000000000}
    let zero_val = sign_result ++ bits[5]:0 ++ bits[10]:0;  // bits[21]
    
    // is_nan / is_inf / zero + inf など Verilog の条件
    let is_nan_condition =
        is_nan_a | is_nan_b |               // どちらかが NaN
        (is_inf_a & is_zero_b) |            // inf * zero
        (is_zero_a & is_inf_b);             // zero * inf

    // ----------------------------
    // 3) 正常演算の準備
    // ----------------------------
    // exponent の合計 (符号拡張して計算したいため 8bit に拡張)
    // exp_sum = exp_a + exp_b - 15
    let exp_a_ext = u5_to_u8(exp_a);
    let exp_b_ext = u5_to_u8(exp_b);
    let exp_sum_i8 = exp_a_ext + exp_b_ext - bits[8]:15; // bits[8]

    // 乗算 frac_mult = frac_a * frac_b (11x11=22ビット)
    let frac_mult_22 = u11_to_u22(frac_a) *
                       u11_to_u22(frac_b);       // bits[22]

    // ----------------------------
    // 4) 正常計算（正規化の処理）
    // ----------------------------
    //
    //   - frac_mult_22[21] が立っているかどうかで正規化を判断
    //   - guard bit, round bit, sticky bit を計算し、丸め (Round to nearest even)
    //
    let leading_bit = frac_mult_22[20:21];       // bits[1]
    let frac_adj_11 = sel(leading_bit == bits[1]:1,
                          frac_mult_22[11:22], // 11 bits
                          frac_mult_22[10:21]  // 11 bits
                         );
    // exp 加算
    let exp_adj_8 = exp_sum_i8 +
                    sel(leading_bit == bits[1]:1,
                        bits[8]:1,
                        bits[8]:0);

    let guard_bit  = sel(leading_bit == bits[1]:1,
                         frac_mult_22[9:10],
                         frac_mult_22[8:9]);
    let round_bit  = sel(leading_bit == bits[1]:1,
                         frac_mult_22[8:9],
                         frac_mult_22[7:8]);
    let sticky_vec = sel(leading_bit == bits[1]:1,
                         frac_mult_22[0:8],
                         frac_mult_22[0:8]);
    let sticky_bit = sticky_vec != bits[8]:0;

    //
    // Rounding (round to nearest even)
    //
    //  frac_final = frac_adj_11 + 1 (if 条件成立)
    //
    let round_condition =
       (guard_bit & (round_bit | sticky_bit)) |
       (guard_bit & !round_bit & !sticky_bit & frac_adj_11[0:1]);

    let frac_final_11 = sel(round_condition,
                            frac_adj_11 + bits[11]:1,
                            frac_adj_11);

    //
    // キャリーが出て桁あふれした場合の処理
    // e.g. frac_adj_11 が 0x7FF → +1 → 0x800 (12ビット相当)
    // DSLX ではオーバーフローする場合は下位ビットが切り捨てられるので、
    // それを検知して exp を再度 +1 する必要がある。
    //
    let was_overflow = (frac_adj_11 == bits[11]:0x7FF) & round_condition;
    let frac_of      = bits[11]:0b10000000000; // 11 bits, MSB=1
    let frac_cand    = sel(was_overflow, bits[11]:0, frac_final_11);
    let exp_cand_8   = exp_adj_8 + sel(was_overflow, bits[8]:1, bits[8]:0);
    let frac_cand_11 = sel(was_overflow, frac_of, frac_final_11);


    // ----------------------------
    // 5) 正規化後の exponent 範囲チェック
    // ----------------------------
    // exp >= 31 → オーバーフロー: inf
    // exp <= 0  → アンダーフロー: subnormal or zero
    //
    let overflow = exp_cand_8 >= bits[8]:31;
    let underflow = exp_cand_8 <= bits[8]:0;

    // シフト量 = 1 - exp_cand_8
    // DSLX は signed が無いので zero_ext / sign_ext + ビット演算で対処
    let one_8      = bits[8]:1;
    let shift_amt_8 = one_8 - exp_cand_8;  // bits[8], ただし underflow 時のみ意味あり

    //
    // subnormal シフト
    //  frac_cand_11 >> shift_amt
    //
    // DSLX では可変シフトするには shift_right_logical() を使用
    //
    let frac_subnormal_11: bits[11] = (u11_to_u32(frac_cand_11) >> u8_to_u32(shift_amt_8))[0:11];

    // ----------------------------
    // 6) if-else で特殊ケースをまとめる
    // ----------------------------
    let result_val =
        if is_nan_condition {
            // NaN
            qnan
        } else if is_inf_a | is_inf_b {
            // Infinity
            inf_val
        } else if is_zero_a | is_zero_b {
            // Zero
            zero_val
        } else if overflow {
            // Overflow
            inf_val
        } else if underflow {
            // Underflow → subnormal or zero
            // shift_amt が 11 以上なら 0
            let shift_too_large = shift_amt_8 >= bits[8]:11;
            if shift_too_large {
                zero_val
            } else {
                sign_result ++ bits[5]:0 ++ frac_subnormal_11[0:10]
            }
        } else {
            let exp_norm_5 = exp_cand_8[0:5];
            let frac_norm_10 = frac_cand_11[0:10];
            sign_result ++ exp_norm_5 ++ frac_norm_10
        };

    result_val
}

// ------------------------------------------------------
// 実際には DSLX には「module」は無いため、下記のように
// トップレベルの関数やテストベンチ関数から呼ぶイメージになります。
// ------------------------------------------------------
pub fn fp16_multiplier(a: bits[16], b: bits[16]) -> bits[16] {
    // Verilog のモジュールの代わりに単に呼び出すだけ
    let result = fp16_multiply(a, b);
    result
}
