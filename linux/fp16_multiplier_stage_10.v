module fp16_multiplier(
  input wire clk,
  input wire [15:0] a,
  input wire [15:0] b,
  output wire [15:0] out
);
  // lint_off MULTIPLY
  function automatic [21:0] umul22b_11b_x_11b (input reg [10:0] lhs, input reg [10:0] rhs);
    begin
      umul22b_11b_x_11b = lhs * rhs;
    end
  endfunction
  // lint_on MULTIPLY

  // ===== Pipe stage 0:

  // Registers for pipe stage 0:
  reg [15:0] p0_a;
  reg [15:0] p0_b;
  always @ (posedge clk) begin
    p0_a <= a;
    p0_b <= b;
  end

  // ===== Pipe stage 1:
  wire [4:0] p1_exp_a_comb;
  wire [4:0] p1_exp_b_comb;
  wire p1_sign_a_comb;
  wire p1_sign_b_comb;
  wire p1_eq_817_comb;
  wire p1_eq_818_comb;
  wire [9:0] p1_frac_a_raw_comb;
  wire [9:0] p1_frac_b_raw_comb;
  wire p1_sign_result_comb;
  assign p1_exp_a_comb = p0_a[14:10];
  assign p1_exp_b_comb = p0_b[14:10];
  assign p1_sign_a_comb = p0_a[15];
  assign p1_sign_b_comb = p0_b[15];
  assign p1_eq_817_comb = p1_exp_a_comb == 5'h00;
  assign p1_eq_818_comb = p1_exp_b_comb == 5'h00;
  assign p1_frac_a_raw_comb = p0_a[9:0];
  assign p1_frac_b_raw_comb = p0_b[9:0];
  assign p1_sign_result_comb = p1_sign_a_comb ^ p1_sign_b_comb;

  // Registers for pipe stage 1:
  reg [4:0] p1_exp_a;
  reg [4:0] p1_exp_b;
  reg p1_eq_817;
  reg p1_eq_818;
  reg [9:0] p1_frac_a_raw;
  reg [9:0] p1_frac_b_raw;
  reg p1_sign_result;
  always @ (posedge clk) begin
    p1_exp_a <= p1_exp_a_comb;
    p1_exp_b <= p1_exp_b_comb;
    p1_eq_817 <= p1_eq_817_comb;
    p1_eq_818 <= p1_eq_818_comb;
    p1_frac_a_raw <= p1_frac_a_raw_comb;
    p1_frac_b_raw <= p1_frac_b_raw_comb;
    p1_sign_result <= p1_sign_result_comb;
  end

  // ===== Pipe stage 2:
  wire p2_leading_a_comb;
  wire p2_leading_b_comb;
  wire p2_eq_853_comb;
  wire p2_eq_851_comb;
  wire p2_eq_854_comb;
  wire p2_eq_852_comb;
  wire [10:0] p2_concat_840_comb;
  wire [10:0] p2_concat_841_comb;
  wire [5:0] p2_add_846_comb;
  wire p2_is_inf_a_chk_comb;
  wire p2_is_inf_b_chk_comb;
  wire p2_not_857_comb;
  wire p2_not_858_comb;
  assign p2_leading_a_comb = ~p1_eq_817;
  assign p2_leading_b_comb = ~p1_eq_818;
  assign p2_eq_853_comb = p1_exp_a == 5'h1f;
  assign p2_eq_851_comb = p1_frac_a_raw == 10'h000;
  assign p2_eq_854_comb = p1_exp_b == 5'h1f;
  assign p2_eq_852_comb = p1_frac_b_raw == 10'h000;
  assign p2_concat_840_comb = {p2_leading_a_comb, p1_frac_a_raw};
  assign p2_concat_841_comb = {p2_leading_b_comb, p1_frac_b_raw};
  assign p2_add_846_comb = {1'h0, p1_exp_a} + {1'h0, p1_exp_b};
  assign p2_is_inf_a_chk_comb = p2_eq_853_comb & p2_eq_851_comb;
  assign p2_is_inf_b_chk_comb = p2_eq_854_comb & p2_eq_852_comb;
  assign p2_not_857_comb = ~p2_eq_853_comb;
  assign p2_not_858_comb = ~p2_eq_854_comb;

  // Registers for pipe stage 2:
  reg p2_eq_817;
  reg p2_eq_818;
  reg [10:0] p2_concat_840;
  reg [10:0] p2_concat_841;
  reg [5:0] p2_add_846;
  reg p2_eq_851;
  reg p2_eq_852;
  reg p2_is_inf_a_chk;
  reg p2_is_inf_b_chk;
  reg p2_not_857;
  reg p2_not_858;
  reg p2_sign_result;
  always @ (posedge clk) begin
    p2_eq_817 <= p1_eq_817;
    p2_eq_818 <= p1_eq_818;
    p2_concat_840 <= p2_concat_840_comb;
    p2_concat_841 <= p2_concat_841_comb;
    p2_add_846 <= p2_add_846_comb;
    p2_eq_851 <= p2_eq_851_comb;
    p2_eq_852 <= p2_eq_852_comb;
    p2_is_inf_a_chk <= p2_is_inf_a_chk_comb;
    p2_is_inf_b_chk <= p2_is_inf_b_chk_comb;
    p2_not_857 <= p2_not_857_comb;
    p2_not_858 <= p2_not_858_comb;
    p2_sign_result <= p1_sign_result;
  end

  // ===== Pipe stage 3:
  wire [21:0] p3_frac_mult_comb;
  wire p3_is_zero_a_comb;
  wire p3_is_zero_b_comb;
  wire p3_is_nan_comb;
  wire p3_is_nan__1_comb;
  wire p3_leading_bit_comb;
  wire p3_bit_slice_885_comb;
  wire p3_bit_slice_886_comb;
  wire [7:0] p3_bit_slice_887_comb;
  wire [10:0] p3_bit_slice_888_comb;
  wire [10:0] p3_bit_slice_889_comb;
  wire p3_bit_slice_890_comb;
  wire p3_is_zero_result_comb;
  wire p3_is_nan_result_comb;
  assign p3_frac_mult_comb = umul22b_11b_x_11b(p2_concat_840, p2_concat_841);
  assign p3_is_zero_a_comb = p2_eq_817 & p2_eq_851;
  assign p3_is_zero_b_comb = p2_eq_818 & p2_eq_852;
  assign p3_is_nan_comb = ~(p2_not_857 | p2_eq_851);
  assign p3_is_nan__1_comb = ~(p2_not_858 | p2_eq_852);
  assign p3_leading_bit_comb = p3_frac_mult_comb[21];
  assign p3_bit_slice_885_comb = p3_frac_mult_comb[8];
  assign p3_bit_slice_886_comb = p3_frac_mult_comb[9];
  assign p3_bit_slice_887_comb = p3_frac_mult_comb[7:0];
  assign p3_bit_slice_888_comb = p3_frac_mult_comb[20:10];
  assign p3_bit_slice_889_comb = p3_frac_mult_comb[21:11];
  assign p3_bit_slice_890_comb = p3_frac_mult_comb[10];
  assign p3_is_zero_result_comb = p3_is_zero_a_comb | p3_is_zero_b_comb;
  assign p3_is_nan_result_comb = p3_is_nan_comb | p3_is_nan__1_comb | p2_is_inf_a_chk & p2_eq_818 & p2_eq_852 | p2_eq_817 & p2_eq_851 & p2_is_inf_b_chk;

  // Registers for pipe stage 3:
  reg p3_leading_bit;
  reg p3_bit_slice_885;
  reg p3_bit_slice_886;
  reg [7:0] p3_bit_slice_887;
  reg [10:0] p3_bit_slice_888;
  reg [10:0] p3_bit_slice_889;
  reg [5:0] p3_add_846;
  reg p3_bit_slice_890;
  reg p3_is_inf_a_chk;
  reg p3_is_inf_b_chk;
  reg p3_is_zero_result;
  reg p3_sign_result;
  reg p3_is_nan_result;
  always @ (posedge clk) begin
    p3_leading_bit <= p3_leading_bit_comb;
    p3_bit_slice_885 <= p3_bit_slice_885_comb;
    p3_bit_slice_886 <= p3_bit_slice_886_comb;
    p3_bit_slice_887 <= p3_bit_slice_887_comb;
    p3_bit_slice_888 <= p3_bit_slice_888_comb;
    p3_bit_slice_889 <= p3_bit_slice_889_comb;
    p3_add_846 <= p2_add_846;
    p3_bit_slice_890 <= p3_bit_slice_890_comb;
    p3_is_inf_a_chk <= p2_is_inf_a_chk;
    p3_is_inf_b_chk <= p2_is_inf_b_chk;
    p3_is_zero_result <= p3_is_zero_result_comb;
    p3_sign_result <= p2_sign_result;
    p3_is_nan_result <= p3_is_nan_result_comb;
  end

  // ===== Pipe stage 4:
  wire p4_round_bit_comb;
  wire p4_sticky_bit_comb;
  wire [10:0] p4_frac_adjusted_comb;
  wire p4_guard_bit_comb;
  wire p4_or_934_comb;
  wire p4_not_935_comb;
  wire p4_not_936_comb;
  wire p4_bit_slice_937_comb;
  wire [6:0] p4_add_938_comb;
  wire p4_not_939_comb;
  assign p4_round_bit_comb = p3_leading_bit ? p3_bit_slice_886 : p3_bit_slice_885;
  assign p4_sticky_bit_comb = p3_bit_slice_887 != 8'h00;
  assign p4_frac_adjusted_comb = p3_leading_bit ? p3_bit_slice_889 : p3_bit_slice_888;
  assign p4_guard_bit_comb = p3_leading_bit ? p3_bit_slice_890 : p3_bit_slice_886;
  assign p4_or_934_comb = p4_round_bit_comb | p4_sticky_bit_comb;
  assign p4_not_935_comb = ~p4_round_bit_comb;
  assign p4_not_936_comb = ~p4_sticky_bit_comb;
  assign p4_bit_slice_937_comb = p4_frac_adjusted_comb[0];
  assign p4_add_938_comb = {1'h0, p3_add_846} + {6'h00, p3_leading_bit};
  assign p4_not_939_comb = ~p3_is_zero_result;

  // Registers for pipe stage 4:
  reg [10:0] p4_frac_adjusted;
  reg p4_guard_bit;
  reg p4_or_934;
  reg p4_not_935;
  reg p4_not_936;
  reg p4_bit_slice_937;
  reg [6:0] p4_add_938;
  reg p4_is_inf_a_chk;
  reg p4_is_inf_b_chk;
  reg p4_not_939;
  reg p4_sign_result;
  reg p4_is_nan_result;
  always @ (posedge clk) begin
    p4_frac_adjusted <= p4_frac_adjusted_comb;
    p4_guard_bit <= p4_guard_bit_comb;
    p4_or_934 <= p4_or_934_comb;
    p4_not_935 <= p4_not_935_comb;
    p4_not_936 <= p4_not_936_comb;
    p4_bit_slice_937 <= p4_bit_slice_937_comb;
    p4_add_938 <= p4_add_938_comb;
    p4_is_inf_a_chk <= p3_is_inf_a_chk;
    p4_is_inf_b_chk <= p3_is_inf_b_chk;
    p4_not_939 <= p4_not_939_comb;
    p4_sign_result <= p3_sign_result;
    p4_is_nan_result <= p3_is_nan_result;
  end

  // ===== Pipe stage 5:
  wire [7:0] p5_concat_968_comb;
  wire p5_round_condition_comb;
  wire [10:0] p5_add_971_comb;
  wire [7:0] p5_add_973_comb;
  wire [7:0] p5_sub_974_comb;
  assign p5_concat_968_comb = {1'h0, p4_add_938};
  assign p5_round_condition_comb = p4_guard_bit & p4_or_934 | p4_guard_bit & p4_not_935 & p4_not_936 & p4_bit_slice_937;
  assign p5_add_971_comb = p4_frac_adjusted + 11'h001;
  assign p5_add_973_comb = p5_concat_968_comb + 8'hf1;
  assign p5_sub_974_comb = 8'h10 - p5_concat_968_comb;

  // Registers for pipe stage 5:
  reg [10:0] p5_frac_adjusted;
  reg p5_round_condition;
  reg [10:0] p5_add_971;
  reg [7:0] p5_add_973;
  reg [7:0] p5_sub_974;
  reg p5_is_inf_a_chk;
  reg p5_is_inf_b_chk;
  reg p5_not_939;
  reg p5_sign_result;
  reg p5_is_nan_result;
  always @ (posedge clk) begin
    p5_frac_adjusted <= p4_frac_adjusted;
    p5_round_condition <= p5_round_condition_comb;
    p5_add_971 <= p5_add_971_comb;
    p5_add_973 <= p5_add_973_comb;
    p5_sub_974 <= p5_sub_974_comb;
    p5_is_inf_a_chk <= p4_is_inf_a_chk;
    p5_is_inf_b_chk <= p4_is_inf_b_chk;
    p5_not_939 <= p4_not_939;
    p5_sign_result <= p4_sign_result;
    p5_is_nan_result <= p4_is_nan_result;
  end

  // ===== Pipe stage 6:
  wire [10:0] p6_frac_final_pre_comb;
  wire [4:0] p6_exp_out_5_comb;
  wire [31:0] p6_frac_final_32_comb;
  wire [8:0] p6_shift_9_comb;
  wire p6_or_reduce_1002_comb;
  wire p6_and_reduce_1003_comb;
  wire p6_or_reduce_1004_comb;
  wire p6_bit_slice_1005_comb;
  wire p6_sign_comb;
  wire [9:0] p6_frac_out_10_comb;
  assign p6_frac_final_pre_comb = p5_round_condition ? p5_add_971 : p5_frac_adjusted;
  assign p6_exp_out_5_comb = p5_add_973[4:0];
  assign p6_frac_final_32_comb = {21'h00_0000, p6_frac_final_pre_comb};
  assign p6_shift_9_comb = {{1{p5_sub_974[7]}}, p5_sub_974};
  assign p6_or_reduce_1002_comb = |p5_add_973[7:5];
  assign p6_and_reduce_1003_comb = &p6_exp_out_5_comb;
  assign p6_or_reduce_1004_comb = |p5_add_973[7:1];
  assign p6_bit_slice_1005_comb = p5_add_973[0];
  assign p6_sign_comb = p5_add_973[7];
  assign p6_frac_out_10_comb = p6_frac_final_pre_comb[9:0];

  // Registers for pipe stage 6:
  reg [4:0] p6_exp_out_5;
  reg [31:0] p6_frac_final_32;
  reg [8:0] p6_shift_9;
  reg p6_or_reduce_1002;
  reg p6_and_reduce_1003;
  reg p6_or_reduce_1004;
  reg p6_bit_slice_1005;
  reg p6_sign;
  reg [9:0] p6_frac_out_10;
  reg p6_is_inf_a_chk;
  reg p6_is_inf_b_chk;
  reg p6_not_939;
  reg p6_sign_result;
  reg p6_is_nan_result;
  always @ (posedge clk) begin
    p6_exp_out_5 <= p6_exp_out_5_comb;
    p6_frac_final_32 <= p6_frac_final_32_comb;
    p6_shift_9 <= p6_shift_9_comb;
    p6_or_reduce_1002 <= p6_or_reduce_1002_comb;
    p6_and_reduce_1003 <= p6_and_reduce_1003_comb;
    p6_or_reduce_1004 <= p6_or_reduce_1004_comb;
    p6_bit_slice_1005 <= p6_bit_slice_1005_comb;
    p6_sign <= p6_sign_comb;
    p6_frac_out_10 <= p6_frac_out_10_comb;
    p6_is_inf_a_chk <= p5_is_inf_a_chk;
    p6_is_inf_b_chk <= p5_is_inf_b_chk;
    p6_not_939 <= p5_not_939;
    p6_sign_result <= p5_sign_result;
    p6_is_nan_result <= p5_is_nan_result;
  end

  // ===== Pipe stage 7:
  wire [31:0] p7_frac_subnormal_32_comb;
  wire [9:0] p7_frac_subnormal_comb;
  wire p7_nor_1040_comb;
  wire p7_is_subnormal_comb;
  wire [14:0] p7_concat_1042_comb;
  assign p7_frac_subnormal_32_comb = p6_shift_9 >= 9'h020 ? 32'h0000_0000 : p6_frac_final_32 >> p6_shift_9;
  assign p7_frac_subnormal_comb = p7_frac_subnormal_32_comb[9:0];
  assign p7_nor_1040_comb = ~(p6_sign | ~(p6_or_reduce_1002 | p6_and_reduce_1003));
  assign p7_is_subnormal_comb = p6_sign | ~(p6_or_reduce_1004 | p6_bit_slice_1005);
  assign p7_concat_1042_comb = {p6_exp_out_5, p6_frac_out_10};

  // Registers for pipe stage 7:
  reg [9:0] p7_frac_subnormal;
  reg p7_is_inf_a_chk;
  reg p7_is_inf_b_chk;
  reg p7_nor_1040;
  reg p7_is_subnormal;
  reg [14:0] p7_concat_1042;
  reg p7_not_939;
  reg p7_sign_result;
  reg p7_is_nan_result;
  always @ (posedge clk) begin
    p7_frac_subnormal <= p7_frac_subnormal_comb;
    p7_is_inf_a_chk <= p6_is_inf_a_chk;
    p7_is_inf_b_chk <= p6_is_inf_b_chk;
    p7_nor_1040 <= p7_nor_1040_comb;
    p7_is_subnormal <= p7_is_subnormal_comb;
    p7_concat_1042 <= p7_concat_1042_comb;
    p7_not_939 <= p6_not_939;
    p7_sign_result <= p6_sign_result;
    p7_is_nan_result <= p6_is_nan_result;
  end

  // ===== Pipe stage 8:
  wire p8_is_inf_result_comb;
  wire [14:0] p8_sel_1064_comb;
  assign p8_is_inf_result_comb = p7_is_inf_a_chk | p7_is_inf_b_chk | p7_nor_1040;
  assign p8_sel_1064_comb = p7_is_subnormal ? {5'h00, p7_frac_subnormal} : p7_concat_1042;

  // Registers for pipe stage 8:
  reg p8_is_inf_result;
  reg [14:0] p8_sel_1064;
  reg p8_not_939;
  reg p8_sign_result;
  reg p8_is_nan_result;
  always @ (posedge clk) begin
    p8_is_inf_result <= p8_is_inf_result_comb;
    p8_sel_1064 <= p8_sel_1064_comb;
    p8_not_939 <= p7_not_939;
    p8_sign_result <= p7_sign_result;
    p8_is_nan_result <= p7_is_nan_result;
  end

  // ===== Pipe stage 9:
  wire [14:0] p9_and_1078_comb;
  assign p9_and_1078_comb = (p8_is_inf_result ? 15'h7c00 : p8_sel_1064) & {15{p8_not_939}};

  // Registers for pipe stage 9:
  reg p9_sign_result;
  reg [14:0] p9_and_1078;
  reg p9_is_nan_result;
  always @ (posedge clk) begin
    p9_sign_result <= p8_sign_result;
    p9_and_1078 <= p9_and_1078_comb;
    p9_is_nan_result <= p8_is_nan_result;
  end

  // ===== Pipe stage 10:
  wire [15:0] p10_result_comb;
  assign p10_result_comb = p9_is_nan_result ? 16'h7e00 : {p9_sign_result, p9_and_1078};

  // Registers for pipe stage 10:
  reg [15:0] p10_result;
  always @ (posedge clk) begin
    p10_result <= p10_result_comb;
  end
  assign out = p10_result;
endmodule
