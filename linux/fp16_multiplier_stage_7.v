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
  wire [9:0] p1_frac_a_raw_comb;
  wire [9:0] p1_frac_b_raw_comb;
  wire p1_sign_a_comb;
  wire p1_sign_b_comb;
  wire p1_eq_817_comb;
  wire p1_eq_818_comb;
  wire [5:0] p1_add_825_comb;
  wire p1_eq_830_comb;
  wire p1_eq_831_comb;
  wire p1_eq_832_comb;
  wire p1_eq_833_comb;
  wire p1_sign_result_comb;
  assign p1_exp_a_comb = p0_a[14:10];
  assign p1_exp_b_comb = p0_b[14:10];
  assign p1_frac_a_raw_comb = p0_a[9:0];
  assign p1_frac_b_raw_comb = p0_b[9:0];
  assign p1_sign_a_comb = p0_a[15];
  assign p1_sign_b_comb = p0_b[15];
  assign p1_eq_817_comb = p1_exp_a_comb == 5'h00;
  assign p1_eq_818_comb = p1_exp_b_comb == 5'h00;
  assign p1_add_825_comb = {1'h0, p1_exp_a_comb} + {1'h0, p1_exp_b_comb};
  assign p1_eq_830_comb = p1_frac_a_raw_comb == 10'h000;
  assign p1_eq_831_comb = p1_frac_b_raw_comb == 10'h000;
  assign p1_eq_832_comb = p1_exp_a_comb == 5'h1f;
  assign p1_eq_833_comb = p1_exp_b_comb == 5'h1f;
  assign p1_sign_result_comb = p1_sign_a_comb ^ p1_sign_b_comb;

  // Registers for pipe stage 1:
  reg p1_eq_817;
  reg p1_eq_818;
  reg [9:0] p1_frac_a_raw;
  reg [9:0] p1_frac_b_raw;
  reg [5:0] p1_add_825;
  reg p1_eq_830;
  reg p1_eq_831;
  reg p1_eq_832;
  reg p1_eq_833;
  reg p1_sign_result;
  always @ (posedge clk) begin
    p1_eq_817 <= p1_eq_817_comb;
    p1_eq_818 <= p1_eq_818_comb;
    p1_frac_a_raw <= p1_frac_a_raw_comb;
    p1_frac_b_raw <= p1_frac_b_raw_comb;
    p1_add_825 <= p1_add_825_comb;
    p1_eq_830 <= p1_eq_830_comb;
    p1_eq_831 <= p1_eq_831_comb;
    p1_eq_832 <= p1_eq_832_comb;
    p1_eq_833 <= p1_eq_833_comb;
    p1_sign_result <= p1_sign_result_comb;
  end

  // ===== Pipe stage 2:
  wire p2_leading_a_comb;
  wire p2_leading_b_comb;
  wire p2_is_zero_a_comb;
  wire p2_is_zero_b_comb;
  wire p2_is_inf_a_chk_comb;
  wire p2_is_inf_b_chk_comb;
  wire p2_is_zero_result_comb;
  wire p2_is_nan_comb;
  wire p2_is_nan__1_comb;
  wire [21:0] p2_frac_mult_comb;
  wire p2_not_867_comb;
  wire p2_is_nan_result_comb;
  assign p2_leading_a_comb = ~p1_eq_817;
  assign p2_leading_b_comb = ~p1_eq_818;
  assign p2_is_zero_a_comb = p1_eq_817 & p1_eq_830;
  assign p2_is_zero_b_comb = p1_eq_818 & p1_eq_831;
  assign p2_is_inf_a_chk_comb = p1_eq_832 & p1_eq_830;
  assign p2_is_inf_b_chk_comb = p1_eq_833 & p1_eq_831;
  assign p2_is_zero_result_comb = p2_is_zero_a_comb | p2_is_zero_b_comb;
  assign p2_is_nan_comb = ~(~p1_eq_832 | p1_eq_830);
  assign p2_is_nan__1_comb = ~(~p1_eq_833 | p1_eq_831);
  assign p2_frac_mult_comb = umul22b_11b_x_11b({p2_leading_a_comb, p1_frac_a_raw}, {p2_leading_b_comb, p1_frac_b_raw});
  assign p2_not_867_comb = ~p2_is_zero_result_comb;
  assign p2_is_nan_result_comb = p2_is_nan_comb | p2_is_nan__1_comb | p2_is_inf_a_chk_comb & p1_eq_818 & p1_eq_831 | p1_eq_817 & p1_eq_830 & p2_is_inf_b_chk_comb;

  // Registers for pipe stage 2:
  reg [21:0] p2_frac_mult;
  reg [5:0] p2_add_825;
  reg p2_is_inf_a_chk;
  reg p2_is_inf_b_chk;
  reg p2_not_867;
  reg p2_sign_result;
  reg p2_is_nan_result;
  always @ (posedge clk) begin
    p2_frac_mult <= p2_frac_mult_comb;
    p2_add_825 <= p1_add_825;
    p2_is_inf_a_chk <= p2_is_inf_a_chk_comb;
    p2_is_inf_b_chk <= p2_is_inf_b_chk_comb;
    p2_not_867 <= p2_not_867_comb;
    p2_sign_result <= p1_sign_result;
    p2_is_nan_result <= p2_is_nan_result_comb;
  end

  // ===== Pipe stage 3:
  wire p3_leading_bit_comb;
  wire p3_round_bit_comb;
  wire p3_sticky_bit_comb;
  wire [10:0] p3_frac_adjusted_comb;
  wire p3_guard_bit_comb;
  wire p3_or_905_comb;
  wire p3_not_906_comb;
  wire p3_not_907_comb;
  wire p3_bit_slice_908_comb;
  wire [6:0] p3_add_909_comb;
  assign p3_leading_bit_comb = p2_frac_mult[21];
  assign p3_round_bit_comb = p3_leading_bit_comb ? p2_frac_mult[9] : p2_frac_mult[8];
  assign p3_sticky_bit_comb = p2_frac_mult[7:0] != 8'h00;
  assign p3_frac_adjusted_comb = p3_leading_bit_comb ? p2_frac_mult[21:11] : p2_frac_mult[20:10];
  assign p3_guard_bit_comb = p3_leading_bit_comb ? p2_frac_mult[10] : p2_frac_mult[9];
  assign p3_or_905_comb = p3_round_bit_comb | p3_sticky_bit_comb;
  assign p3_not_906_comb = ~p3_round_bit_comb;
  assign p3_not_907_comb = ~p3_sticky_bit_comb;
  assign p3_bit_slice_908_comb = p3_frac_adjusted_comb[0];
  assign p3_add_909_comb = {1'h0, p2_add_825} + {6'h00, p3_leading_bit_comb};

  // Registers for pipe stage 3:
  reg [10:0] p3_frac_adjusted;
  reg p3_guard_bit;
  reg p3_or_905;
  reg p3_not_906;
  reg p3_not_907;
  reg p3_bit_slice_908;
  reg [6:0] p3_add_909;
  reg p3_is_inf_a_chk;
  reg p3_is_inf_b_chk;
  reg p3_not_867;
  reg p3_sign_result;
  reg p3_is_nan_result;
  always @ (posedge clk) begin
    p3_frac_adjusted <= p3_frac_adjusted_comb;
    p3_guard_bit <= p3_guard_bit_comb;
    p3_or_905 <= p3_or_905_comb;
    p3_not_906 <= p3_not_906_comb;
    p3_not_907 <= p3_not_907_comb;
    p3_bit_slice_908 <= p3_bit_slice_908_comb;
    p3_add_909 <= p3_add_909_comb;
    p3_is_inf_a_chk <= p2_is_inf_a_chk;
    p3_is_inf_b_chk <= p2_is_inf_b_chk;
    p3_not_867 <= p2_not_867;
    p3_sign_result <= p2_sign_result;
    p3_is_nan_result <= p2_is_nan_result;
  end

  // ===== Pipe stage 4:
  wire [7:0] p4_concat_938_comb;
  wire p4_round_condition_comb;
  wire [10:0] p4_add_941_comb;
  wire [7:0] p4_add_943_comb;
  wire [10:0] p4_frac_final_pre_comb;
  wire [7:0] p4_sub_945_comb;
  assign p4_concat_938_comb = {1'h0, p3_add_909};
  assign p4_round_condition_comb = p3_guard_bit & p3_or_905 | p3_guard_bit & p3_not_906 & p3_not_907 & p3_bit_slice_908;
  assign p4_add_941_comb = p3_frac_adjusted + 11'h001;
  assign p4_add_943_comb = p4_concat_938_comb + 8'hf1;
  assign p4_frac_final_pre_comb = p4_round_condition_comb ? p4_add_941_comb : p3_frac_adjusted;
  assign p4_sub_945_comb = 8'h10 - p4_concat_938_comb;

  // Registers for pipe stage 4:
  reg [7:0] p4_add_943;
  reg [10:0] p4_frac_final_pre;
  reg [7:0] p4_sub_945;
  reg p4_is_inf_a_chk;
  reg p4_is_inf_b_chk;
  reg p4_not_867;
  reg p4_sign_result;
  reg p4_is_nan_result;
  always @ (posedge clk) begin
    p4_add_943 <= p4_add_943_comb;
    p4_frac_final_pre <= p4_frac_final_pre_comb;
    p4_sub_945 <= p4_sub_945_comb;
    p4_is_inf_a_chk <= p3_is_inf_a_chk;
    p4_is_inf_b_chk <= p3_is_inf_b_chk;
    p4_not_867 <= p3_not_867;
    p4_sign_result <= p3_sign_result;
    p4_is_nan_result <= p3_is_nan_result;
  end

  // ===== Pipe stage 5:
  wire [4:0] p5_exp_out_5_comb;
  wire [31:0] p5_frac_final_32_comb;
  wire [8:0] p5_shift_9_comb;
  wire [31:0] p5_frac_subnormal_32_comb;
  wire [9:0] p5_frac_out_10_comb;
  wire p5_sign_comb;
  wire p5_nor_974_comb;
  wire p5_nor_975_comb;
  wire [9:0] p5_frac_subnormal_comb;
  wire [14:0] p5_concat_978_comb;
  assign p5_exp_out_5_comb = p4_add_943[4:0];
  assign p5_frac_final_32_comb = {21'h00_0000, p4_frac_final_pre};
  assign p5_shift_9_comb = {{1{p4_sub_945[7]}}, p4_sub_945};
  assign p5_frac_subnormal_32_comb = p5_shift_9_comb >= 9'h020 ? 32'h0000_0000 : p5_frac_final_32_comb >> p5_shift_9_comb;
  assign p5_frac_out_10_comb = p4_frac_final_pre[9:0];
  assign p5_sign_comb = p4_add_943[7];
  assign p5_nor_974_comb = ~((|p4_add_943[7:5]) | (&p5_exp_out_5_comb));
  assign p5_nor_975_comb = ~((|p4_add_943[7:1]) | p4_add_943[0]);
  assign p5_frac_subnormal_comb = p5_frac_subnormal_32_comb[9:0];
  assign p5_concat_978_comb = {p5_exp_out_5_comb, p5_frac_out_10_comb};

  // Registers for pipe stage 5:
  reg p5_sign;
  reg p5_nor_974;
  reg p5_nor_975;
  reg [9:0] p5_frac_subnormal;
  reg p5_is_inf_a_chk;
  reg p5_is_inf_b_chk;
  reg [14:0] p5_concat_978;
  reg p5_not_867;
  reg p5_sign_result;
  reg p5_is_nan_result;
  always @ (posedge clk) begin
    p5_sign <= p5_sign_comb;
    p5_nor_974 <= p5_nor_974_comb;
    p5_nor_975 <= p5_nor_975_comb;
    p5_frac_subnormal <= p5_frac_subnormal_comb;
    p5_is_inf_a_chk <= p4_is_inf_a_chk;
    p5_is_inf_b_chk <= p4_is_inf_b_chk;
    p5_concat_978 <= p5_concat_978_comb;
    p5_not_867 <= p4_not_867;
    p5_sign_result <= p4_sign_result;
    p5_is_nan_result <= p4_is_nan_result;
  end

  // ===== Pipe stage 6:
  wire p6_is_subnormal_comb;
  wire p6_is_inf_result_comb;
  wire [14:0] p6_sel_1006_comb;
  wire [14:0] p6_sign_ext_1007_comb;
  assign p6_is_subnormal_comb = p5_sign | p5_nor_975;
  assign p6_is_inf_result_comb = p5_is_inf_a_chk | p5_is_inf_b_chk | ~(p5_sign | p5_nor_974);
  assign p6_sel_1006_comb = p6_is_inf_result_comb ? 15'h7c00 : (p6_is_subnormal_comb ? {5'h00, p5_frac_subnormal} : p5_concat_978);
  assign p6_sign_ext_1007_comb = {15{p5_not_867}};

  // Registers for pipe stage 6:
  reg [14:0] p6_sel_1006;
  reg [14:0] p6_sign_ext_1007;
  reg p6_sign_result;
  reg p6_is_nan_result;
  always @ (posedge clk) begin
    p6_sel_1006 <= p6_sel_1006_comb;
    p6_sign_ext_1007 <= p6_sign_ext_1007_comb;
    p6_sign_result <= p5_sign_result;
    p6_is_nan_result <= p5_is_nan_result;
  end

  // ===== Pipe stage 7:
  wire [15:0] p7_result_comb;
  assign p7_result_comb = p6_is_nan_result ? 16'h7e00 : {p6_sign_result, p6_sel_1006 & p6_sign_ext_1007};

  // Registers for pipe stage 7:
  reg [15:0] p7_result;
  always @ (posedge clk) begin
    p7_result <= p7_result_comb;
  end
  assign out = p7_result;
endmodule
