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
  wire p1_eq_771_comb;
  wire p1_eq_772_comb;
  wire p1_eq_787_comb;
  wire p1_eq_788_comb;
  wire p1_eq_794_comb;
  wire p1_eq_795_comb;
  wire p1_leading_a_comb;
  wire p1_leading_b_comb;
  wire p1_is_zero_a_comb;
  wire p1_is_zero_b_comb;
  wire p1_is_inf_comb;
  wire p1_is_inf__1_comb;
  wire p1_is_zero_result_comb;
  wire p1_sign_a_comb;
  wire p1_sign_b_comb;
  wire p1_is_nan_comb;
  wire p1_is_nan__1_comb;
  wire [21:0] p1_frac_mult_comb;
  wire [5:0] p1_add_784_comb;
  wire p1_not_796_comb;
  wire p1_sign_result_comb;
  wire p1_is_nan_result_comb;
  assign p1_exp_a_comb = p0_a[14:10];
  assign p1_exp_b_comb = p0_b[14:10];
  assign p1_frac_a_raw_comb = p0_a[9:0];
  assign p1_frac_b_raw_comb = p0_b[9:0];
  assign p1_eq_771_comb = p1_exp_a_comb == 5'h00;
  assign p1_eq_772_comb = p1_exp_b_comb == 5'h00;
  assign p1_eq_787_comb = p1_frac_a_raw_comb == 10'h000;
  assign p1_eq_788_comb = p1_frac_b_raw_comb == 10'h000;
  assign p1_eq_794_comb = p1_exp_a_comb == 5'h1f;
  assign p1_eq_795_comb = p1_exp_b_comb == 5'h1f;
  assign p1_leading_a_comb = ~p1_eq_771_comb;
  assign p1_leading_b_comb = ~p1_eq_772_comb;
  assign p1_is_zero_a_comb = p1_eq_771_comb & p1_eq_787_comb;
  assign p1_is_zero_b_comb = p1_eq_772_comb & p1_eq_788_comb;
  assign p1_is_inf_comb = p1_eq_794_comb & p1_eq_787_comb;
  assign p1_is_inf__1_comb = p1_eq_795_comb & p1_eq_788_comb;
  assign p1_is_zero_result_comb = p1_is_zero_a_comb | p1_is_zero_b_comb;
  assign p1_sign_a_comb = p0_a[15];
  assign p1_sign_b_comb = p0_b[15];
  assign p1_is_nan_comb = ~(~p1_eq_794_comb | p1_eq_787_comb);
  assign p1_is_nan__1_comb = ~(~p1_eq_795_comb | p1_eq_788_comb);
  assign p1_frac_mult_comb = umul22b_11b_x_11b({p1_leading_a_comb, p1_frac_a_raw_comb}, {p1_leading_b_comb, p1_frac_b_raw_comb});
  assign p1_add_784_comb = {1'h0, p1_exp_a_comb} + {1'h0, p1_exp_b_comb};
  assign p1_not_796_comb = ~p1_is_zero_result_comb;
  assign p1_sign_result_comb = p1_sign_a_comb ^ p1_sign_b_comb;
  assign p1_is_nan_result_comb = p1_is_nan_comb | p1_is_nan__1_comb | p1_is_inf_comb & p1_eq_772_comb & p1_eq_788_comb | p1_eq_771_comb & p1_eq_787_comb & p1_is_inf__1_comb;

  // Registers for pipe stage 1:
  reg [21:0] p1_frac_mult;
  reg [5:0] p1_add_784;
  reg p1_not_796;
  reg p1_is_inf;
  reg p1_is_inf__1;
  reg p1_sign_result;
  reg p1_is_nan_result;
  always @ (posedge clk) begin
    p1_frac_mult <= p1_frac_mult_comb;
    p1_add_784 <= p1_add_784_comb;
    p1_not_796 <= p1_not_796_comb;
    p1_is_inf <= p1_is_inf_comb;
    p1_is_inf__1 <= p1_is_inf__1_comb;
    p1_sign_result <= p1_sign_result_comb;
    p1_is_nan_result <= p1_is_nan_result_comb;
  end

  // ===== Pipe stage 2:
  wire p2_leading_bit_comb;
  wire p2_round_bit_comb;
  wire p2_sticky_bit_comb;
  wire [10:0] p2_frac_adjusted_comb;
  wire p2_guard_bit_comb;
  wire p2_eq_834_comb;
  wire p2_round_condition_comb;
  wire [10:0] p2_add_850_comb;
  wire [1:0] p2_add_845_comb;
  wire [10:0] p2_frac_final_comb;
  assign p2_leading_bit_comb = p1_frac_mult[21];
  assign p2_round_bit_comb = p2_leading_bit_comb ? p1_frac_mult[9] : p1_frac_mult[8];
  assign p2_sticky_bit_comb = p1_frac_mult[7:0] != 8'h00;
  assign p2_frac_adjusted_comb = p2_leading_bit_comb ? p1_frac_mult[21:11] : p1_frac_mult[20:10];
  assign p2_guard_bit_comb = p2_leading_bit_comb ? p1_frac_mult[10] : p1_frac_mult[9];
  assign p2_eq_834_comb = p2_frac_adjusted_comb == 11'h7ff;
  assign p2_round_condition_comb = p2_guard_bit_comb & (p2_round_bit_comb | p2_sticky_bit_comb) | p2_guard_bit_comb & ~p2_round_bit_comb & ~p2_sticky_bit_comb & p2_frac_adjusted_comb[0];
  assign p2_add_850_comb = p2_frac_adjusted_comb + 11'h001;
  assign p2_add_845_comb = {1'h0, p2_leading_bit_comb} + {1'h0, p2_eq_834_comb};
  assign p2_frac_final_comb = p2_round_condition_comb ? p2_add_850_comb : p2_frac_adjusted_comb;

  // Registers for pipe stage 2:
  reg p2_leading_bit;
  reg p2_eq_834;
  reg [5:0] p2_add_784;
  reg [1:0] p2_add_845;
  reg [10:0] p2_frac_final;
  reg p2_not_796;
  reg p2_is_inf;
  reg p2_is_inf__1;
  reg p2_sign_result;
  reg p2_is_nan_result;
  always @ (posedge clk) begin
    p2_leading_bit <= p2_leading_bit_comb;
    p2_eq_834 <= p2_eq_834_comb;
    p2_add_784 <= p1_add_784;
    p2_add_845 <= p2_add_845_comb;
    p2_frac_final <= p2_frac_final_comb;
    p2_not_796 <= p1_not_796;
    p2_is_inf <= p1_is_inf;
    p2_is_inf__1 <= p1_is_inf__1;
    p2_sign_result <= p1_sign_result;
    p2_is_nan_result <= p1_is_nan_result;
  end

  // ===== Pipe stage 3:
  wire [6:0] p3_concat_875_comb;
  wire [1:0] p3_exp_final__5_squeezed_comb;
  wire [1:0] p3_exp_final__6_squeezed_comb;
  wire [6:0] p3_add_881_comb;
  wire [5:0] p3_exp_final__3_squeezed_const_msb_bits_comb;
  wire [1:0] p3_exp_final__3_squeezed_comb;
  wire [6:0] p3_add_885_comb;
  wire [7:0] p3_exp_final__2_comb;
  wire [7:0] p3_exp_final__3_comb;
  wire [7:0] p3_exp_final__4_comb;
  wire [7:0] p3_sub_893_comb;
  wire [31:0] p3_shrl_895_comb;
  wire p3_or_reduce_896_comb;
  wire p3_bit_slice_897_comb;
  wire [9:0] p3_frac_subnormal_comb;
  wire [14:0] p3_normalized_result_bits_0_width_15_comb;
  wire p3_is_inf_result_comb;
  assign p3_concat_875_comb = {1'h0, p2_add_784};
  assign p3_exp_final__5_squeezed_comb = 2'h1;
  assign p3_exp_final__6_squeezed_comb = 2'h2;
  assign p3_add_881_comb = p3_concat_875_comb + {6'h00, p2_leading_bit};
  assign p3_exp_final__3_squeezed_const_msb_bits_comb = 6'h3c;
  assign p3_exp_final__3_squeezed_comb = p2_eq_834 ? p3_exp_final__6_squeezed_comb : p3_exp_final__5_squeezed_comb;
  assign p3_add_885_comb = p3_concat_875_comb + {5'h00, p2_add_845};
  assign p3_exp_final__2_comb = {1'h0, p3_add_881_comb};
  assign p3_exp_final__3_comb = {p3_exp_final__3_squeezed_const_msb_bits_comb, p3_exp_final__3_squeezed_comb};
  assign p3_exp_final__4_comb = p3_exp_final__2_comb + p3_exp_final__3_comb;
  assign p3_sub_893_comb = 8'h10 - {1'h0, p3_add_885_comb};
  assign p3_shrl_895_comb = p3_sub_893_comb >= 8'h20 ? 32'h0000_0000 : {21'h00_0000, p2_frac_final} >> p3_sub_893_comb;
  assign p3_or_reduce_896_comb = |p3_exp_final__4_comb[7:1];
  assign p3_bit_slice_897_comb = p3_exp_final__4_comb[0];
  assign p3_frac_subnormal_comb = p3_shrl_895_comb[9:0];
  assign p3_normalized_result_bits_0_width_15_comb = {p3_exp_final__4_comb[4:0], p2_frac_final[9:0]};
  assign p3_is_inf_result_comb = p2_is_inf | p2_is_inf__1 | p3_exp_final__4_comb > 8'h1e;

  // Registers for pipe stage 3:
  reg p3_or_reduce_896;
  reg p3_bit_slice_897;
  reg [9:0] p3_frac_subnormal;
  reg [14:0] p3_normalized_result_bits_0_width_15;
  reg p3_not_796;
  reg p3_is_inf_result;
  reg p3_sign_result;
  reg p3_is_nan_result;
  always @ (posedge clk) begin
    p3_or_reduce_896 <= p3_or_reduce_896_comb;
    p3_bit_slice_897 <= p3_bit_slice_897_comb;
    p3_frac_subnormal <= p3_frac_subnormal_comb;
    p3_normalized_result_bits_0_width_15 <= p3_normalized_result_bits_0_width_15_comb;
    p3_not_796 <= p2_not_796;
    p3_is_inf_result <= p3_is_inf_result_comb;
    p3_sign_result <= p2_sign_result;
    p3_is_nan_result <= p2_is_nan_result;
  end

  // ===== Pipe stage 4:
  wire [15:0] p4_concat_929_comb;
  wire [15:0] p4_result_comb;
  assign p4_concat_929_comb = {p3_sign_result, p3_is_inf_result ? 15'h7c00 : (~(p3_or_reduce_896 | p3_bit_slice_897) ? {5'h00, p3_frac_subnormal} : p3_normalized_result_bits_0_width_15) & {15{p3_not_796}}};
  assign p4_result_comb = p3_is_nan_result ? 16'h7e00 : p4_concat_929_comb;

  // Registers for pipe stage 4:
  reg [15:0] p4_result;
  always @ (posedge clk) begin
    p4_result <= p4_result_comb;
  end
  assign out = p4_result;
endmodule
