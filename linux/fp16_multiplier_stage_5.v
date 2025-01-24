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
  wire p1_eq_817_comb;
  wire p1_eq_818_comb;
  wire p1_leading_a_comb;
  wire [9:0] p1_frac_a_raw_comb;
  wire p1_leading_b_comb;
  wire [9:0] p1_frac_b_raw_comb;
  wire p1_sign_a_comb;
  wire p1_sign_b_comb;
  wire [10:0] p1_concat_823_comb;
  wire [10:0] p1_concat_824_comb;
  wire [5:0] p1_add_829_comb;
  wire p1_eq_834_comb;
  wire p1_eq_835_comb;
  wire p1_eq_836_comb;
  wire p1_eq_837_comb;
  wire p1_sign_result_comb;
  assign p1_exp_a_comb = p0_a[14:10];
  assign p1_exp_b_comb = p0_b[14:10];
  assign p1_eq_817_comb = p1_exp_a_comb == 5'h00;
  assign p1_eq_818_comb = p1_exp_b_comb == 5'h00;
  assign p1_leading_a_comb = ~p1_eq_817_comb;
  assign p1_frac_a_raw_comb = p0_a[9:0];
  assign p1_leading_b_comb = ~p1_eq_818_comb;
  assign p1_frac_b_raw_comb = p0_b[9:0];
  assign p1_sign_a_comb = p0_a[15];
  assign p1_sign_b_comb = p0_b[15];
  assign p1_concat_823_comb = {p1_leading_a_comb, p1_frac_a_raw_comb};
  assign p1_concat_824_comb = {p1_leading_b_comb, p1_frac_b_raw_comb};
  assign p1_add_829_comb = {1'h0, p1_exp_a_comb} + {1'h0, p1_exp_b_comb};
  assign p1_eq_834_comb = p1_frac_a_raw_comb == 10'h000;
  assign p1_eq_835_comb = p1_frac_b_raw_comb == 10'h000;
  assign p1_eq_836_comb = p1_exp_a_comb == 5'h1f;
  assign p1_eq_837_comb = p1_exp_b_comb == 5'h1f;
  assign p1_sign_result_comb = p1_sign_a_comb ^ p1_sign_b_comb;

  // Registers for pipe stage 1:
  reg p1_eq_817;
  reg p1_eq_818;
  reg [10:0] p1_concat_823;
  reg [10:0] p1_concat_824;
  reg [5:0] p1_add_829;
  reg p1_eq_834;
  reg p1_eq_835;
  reg p1_eq_836;
  reg p1_eq_837;
  reg p1_sign_result;
  always @ (posedge clk) begin
    p1_eq_817 <= p1_eq_817_comb;
    p1_eq_818 <= p1_eq_818_comb;
    p1_concat_823 <= p1_concat_823_comb;
    p1_concat_824 <= p1_concat_824_comb;
    p1_add_829 <= p1_add_829_comb;
    p1_eq_834 <= p1_eq_834_comb;
    p1_eq_835 <= p1_eq_835_comb;
    p1_eq_836 <= p1_eq_836_comb;
    p1_eq_837 <= p1_eq_837_comb;
    p1_sign_result <= p1_sign_result_comb;
  end

  // ===== Pipe stage 2:
  wire [21:0] p2_frac_mult_comb;
  wire p2_leading_bit_comb;
  wire p2_is_zero_a_comb;
  wire p2_is_zero_b_comb;
  wire p2_is_inf_a_chk_comb;
  wire p2_is_inf_b_chk_comb;
  wire p2_round_bit_comb;
  wire p2_sticky_bit_comb;
  wire [10:0] p2_frac_adjusted_comb;
  wire p2_is_zero_result_comb;
  wire p2_is_nan_comb;
  wire p2_is_nan__1_comb;
  wire p2_guard_bit_comb;
  wire p2_or_878_comb;
  wire p2_not_879_comb;
  wire p2_not_880_comb;
  wire p2_bit_slice_881_comb;
  wire [6:0] p2_add_882_comb;
  wire p2_not_888_comb;
  wire p2_is_nan_result_comb;
  assign p2_frac_mult_comb = umul22b_11b_x_11b(p1_concat_823, p1_concat_824);
  assign p2_leading_bit_comb = p2_frac_mult_comb[21];
  assign p2_is_zero_a_comb = p1_eq_817 & p1_eq_834;
  assign p2_is_zero_b_comb = p1_eq_818 & p1_eq_835;
  assign p2_is_inf_a_chk_comb = p1_eq_836 & p1_eq_834;
  assign p2_is_inf_b_chk_comb = p1_eq_837 & p1_eq_835;
  assign p2_round_bit_comb = p2_leading_bit_comb ? p2_frac_mult_comb[9] : p2_frac_mult_comb[8];
  assign p2_sticky_bit_comb = p2_frac_mult_comb[7:0] != 8'h00;
  assign p2_frac_adjusted_comb = p2_leading_bit_comb ? p2_frac_mult_comb[21:11] : p2_frac_mult_comb[20:10];
  assign p2_is_zero_result_comb = p2_is_zero_a_comb | p2_is_zero_b_comb;
  assign p2_is_nan_comb = ~(~p1_eq_836 | p1_eq_834);
  assign p2_is_nan__1_comb = ~(~p1_eq_837 | p1_eq_835);
  assign p2_guard_bit_comb = p2_leading_bit_comb ? p2_frac_mult_comb[10] : p2_frac_mult_comb[9];
  assign p2_or_878_comb = p2_round_bit_comb | p2_sticky_bit_comb;
  assign p2_not_879_comb = ~p2_round_bit_comb;
  assign p2_not_880_comb = ~p2_sticky_bit_comb;
  assign p2_bit_slice_881_comb = p2_frac_adjusted_comb[0];
  assign p2_add_882_comb = {1'h0, p1_add_829} + {6'h00, p2_leading_bit_comb};
  assign p2_not_888_comb = ~p2_is_zero_result_comb;
  assign p2_is_nan_result_comb = p2_is_nan_comb | p2_is_nan__1_comb | p2_is_inf_a_chk_comb & p1_eq_818 & p1_eq_835 | p1_eq_817 & p1_eq_834 & p2_is_inf_b_chk_comb;

  // Registers for pipe stage 2:
  reg [10:0] p2_frac_adjusted;
  reg p2_guard_bit;
  reg p2_or_878;
  reg p2_not_879;
  reg p2_not_880;
  reg p2_bit_slice_881;
  reg [6:0] p2_add_882;
  reg p2_is_inf_a_chk;
  reg p2_is_inf_b_chk;
  reg p2_not_888;
  reg p2_sign_result;
  reg p2_is_nan_result;
  always @ (posedge clk) begin
    p2_frac_adjusted <= p2_frac_adjusted_comb;
    p2_guard_bit <= p2_guard_bit_comb;
    p2_or_878 <= p2_or_878_comb;
    p2_not_879 <= p2_not_879_comb;
    p2_not_880 <= p2_not_880_comb;
    p2_bit_slice_881 <= p2_bit_slice_881_comb;
    p2_add_882 <= p2_add_882_comb;
    p2_is_inf_a_chk <= p2_is_inf_a_chk_comb;
    p2_is_inf_b_chk <= p2_is_inf_b_chk_comb;
    p2_not_888 <= p2_not_888_comb;
    p2_sign_result <= p1_sign_result;
    p2_is_nan_result <= p2_is_nan_result_comb;
  end

  // ===== Pipe stage 3:
  wire [7:0] p3_concat_924_comb;
  wire p3_round_condition_comb;
  wire [10:0] p3_add_927_comb;
  wire [7:0] p3_add_929_comb;
  wire [10:0] p3_frac_final_pre_comb;
  wire [7:0] p3_sub_932_comb;
  wire [4:0] p3_exp_out_5_comb;
  wire [31:0] p3_frac_final_32_comb;
  wire [8:0] p3_shift_9_comb;
  wire p3_or_reduce_938_comb;
  wire p3_or_reduce_939_comb;
  wire p3_bit_slice_940_comb;
  wire p3_sign_comb;
  wire [9:0] p3_frac_out_10_comb;
  assign p3_concat_924_comb = {1'h0, p2_add_882};
  assign p3_round_condition_comb = p2_guard_bit & p2_or_878 | p2_guard_bit & p2_not_879 & p2_not_880 & p2_bit_slice_881;
  assign p3_add_927_comb = p2_frac_adjusted + 11'h001;
  assign p3_add_929_comb = p3_concat_924_comb + 8'hf1;
  assign p3_frac_final_pre_comb = p3_round_condition_comb ? p3_add_927_comb : p2_frac_adjusted;
  assign p3_sub_932_comb = 8'h10 - p3_concat_924_comb;
  assign p3_exp_out_5_comb = p3_add_929_comb[4:0];
  assign p3_frac_final_32_comb = {21'h00_0000, p3_frac_final_pre_comb};
  assign p3_shift_9_comb = {{1{p3_sub_932_comb[7]}}, p3_sub_932_comb};
  assign p3_or_reduce_938_comb = |p3_add_929_comb[7:5];
  assign p3_or_reduce_939_comb = |p3_add_929_comb[7:1];
  assign p3_bit_slice_940_comb = p3_add_929_comb[0];
  assign p3_sign_comb = p3_add_929_comb[7];
  assign p3_frac_out_10_comb = p3_frac_final_pre_comb[9:0];

  // Registers for pipe stage 3:
  reg [4:0] p3_exp_out_5;
  reg [31:0] p3_frac_final_32;
  reg [8:0] p3_shift_9;
  reg p3_or_reduce_938;
  reg p3_or_reduce_939;
  reg p3_bit_slice_940;
  reg p3_sign;
  reg [9:0] p3_frac_out_10;
  reg p3_is_inf_a_chk;
  reg p3_is_inf_b_chk;
  reg p3_not_888;
  reg p3_sign_result;
  reg p3_is_nan_result;
  always @ (posedge clk) begin
    p3_exp_out_5 <= p3_exp_out_5_comb;
    p3_frac_final_32 <= p3_frac_final_32_comb;
    p3_shift_9 <= p3_shift_9_comb;
    p3_or_reduce_938 <= p3_or_reduce_938_comb;
    p3_or_reduce_939 <= p3_or_reduce_939_comb;
    p3_bit_slice_940 <= p3_bit_slice_940_comb;
    p3_sign <= p3_sign_comb;
    p3_frac_out_10 <= p3_frac_out_10_comb;
    p3_is_inf_a_chk <= p2_is_inf_a_chk;
    p3_is_inf_b_chk <= p2_is_inf_b_chk;
    p3_not_888 <= p2_not_888;
    p3_sign_result <= p2_sign_result;
    p3_is_nan_result <= p2_is_nan_result;
  end

  // ===== Pipe stage 4:
  wire [31:0] p4_frac_subnormal_32_comb;
  wire [9:0] p4_frac_subnormal_comb;
  wire p4_is_subnormal_comb;
  wire p4_is_inf_result_comb;
  wire [14:0] p4_sel_980_comb;
  assign p4_frac_subnormal_32_comb = p3_shift_9 >= 9'h020 ? 32'h0000_0000 : p3_frac_final_32 >> p3_shift_9;
  assign p4_frac_subnormal_comb = p4_frac_subnormal_32_comb[9:0];
  assign p4_is_subnormal_comb = p3_sign | ~(p3_or_reduce_939 | p3_bit_slice_940);
  assign p4_is_inf_result_comb = p3_is_inf_a_chk | p3_is_inf_b_chk | ~(p3_sign | ~(p3_or_reduce_938 | (&p3_exp_out_5)));
  assign p4_sel_980_comb = p4_is_subnormal_comb ? {5'h00, p4_frac_subnormal_comb} : {p3_exp_out_5, p3_frac_out_10};

  // Registers for pipe stage 4:
  reg p4_is_inf_result;
  reg [14:0] p4_sel_980;
  reg p4_not_888;
  reg p4_sign_result;
  reg p4_is_nan_result;
  always @ (posedge clk) begin
    p4_is_inf_result <= p4_is_inf_result_comb;
    p4_sel_980 <= p4_sel_980_comb;
    p4_not_888 <= p3_not_888;
    p4_sign_result <= p3_sign_result;
    p4_is_nan_result <= p3_is_nan_result;
  end

  // ===== Pipe stage 5:
  wire [15:0] p5_result_comb;
  assign p5_result_comb = p4_is_nan_result ? 16'h7e00 : {p4_sign_result, (p4_is_inf_result ? 15'h7c00 : p4_sel_980) & {15{p4_not_888}}};

  // Registers for pipe stage 5:
  reg [15:0] p5_result;
  always @ (posedge clk) begin
    p5_result <= p5_result_comb;
  end
  assign out = p5_result;
endmodule
