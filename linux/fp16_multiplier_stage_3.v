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
  wire p1_eq_771_comb;
  wire p1_eq_772_comb;
  wire p1_leading_a_comb;
  wire [9:0] p1_frac_a_raw_comb;
  wire p1_leading_b_comb;
  wire [9:0] p1_frac_b_raw_comb;
  wire [21:0] p1_frac_mult_comb;
  wire p1_eq_801_comb;
  wire p1_eq_802_comb;
  wire p1_eq_808_comb;
  wire p1_eq_809_comb;
  wire p1_leading_bit_comb;
  wire p1_is_zero_a_comb;
  wire p1_is_zero_b_comb;
  wire p1_is_inf_comb;
  wire p1_is_inf__1_comb;
  wire [10:0] p1_frac_adjusted_comb;
  wire p1_is_zero_result_comb;
  wire p1_sign_a_comb;
  wire p1_sign_b_comb;
  wire p1_is_nan_comb;
  wire p1_is_nan__1_comb;
  wire p1_eq_791_comb;
  wire p1_round_bit_comb;
  wire p1_sticky_bit_comb;
  wire [5:0] p1_add_797_comb;
  wire p1_guard_bit_comb;
  wire p1_not_810_comb;
  wire p1_sign_result_comb;
  wire p1_is_nan_result_comb;
  assign p1_exp_a_comb = p0_a[14:10];
  assign p1_exp_b_comb = p0_b[14:10];
  assign p1_eq_771_comb = p1_exp_a_comb == 5'h00;
  assign p1_eq_772_comb = p1_exp_b_comb == 5'h00;
  assign p1_leading_a_comb = ~p1_eq_771_comb;
  assign p1_frac_a_raw_comb = p0_a[9:0];
  assign p1_leading_b_comb = ~p1_eq_772_comb;
  assign p1_frac_b_raw_comb = p0_b[9:0];
  assign p1_frac_mult_comb = umul22b_11b_x_11b({p1_leading_a_comb, p1_frac_a_raw_comb}, {p1_leading_b_comb, p1_frac_b_raw_comb});
  assign p1_eq_801_comb = p1_frac_a_raw_comb == 10'h000;
  assign p1_eq_802_comb = p1_frac_b_raw_comb == 10'h000;
  assign p1_eq_808_comb = p1_exp_a_comb == 5'h1f;
  assign p1_eq_809_comb = p1_exp_b_comb == 5'h1f;
  assign p1_leading_bit_comb = p1_frac_mult_comb[21];
  assign p1_is_zero_a_comb = p1_eq_771_comb & p1_eq_801_comb;
  assign p1_is_zero_b_comb = p1_eq_772_comb & p1_eq_802_comb;
  assign p1_is_inf_comb = p1_eq_808_comb & p1_eq_801_comb;
  assign p1_is_inf__1_comb = p1_eq_809_comb & p1_eq_802_comb;
  assign p1_frac_adjusted_comb = p1_leading_bit_comb ? p1_frac_mult_comb[21:11] : p1_frac_mult_comb[20:10];
  assign p1_is_zero_result_comb = p1_is_zero_a_comb | p1_is_zero_b_comb;
  assign p1_sign_a_comb = p0_a[15];
  assign p1_sign_b_comb = p0_b[15];
  assign p1_is_nan_comb = ~(~p1_eq_808_comb | p1_eq_801_comb);
  assign p1_is_nan__1_comb = ~(~p1_eq_809_comb | p1_eq_802_comb);
  assign p1_eq_791_comb = p1_frac_adjusted_comb == 11'h7ff;
  assign p1_round_bit_comb = p1_leading_bit_comb ? p1_frac_mult_comb[9] : p1_frac_mult_comb[8];
  assign p1_sticky_bit_comb = p1_frac_mult_comb[7:0] != 8'h00;
  assign p1_add_797_comb = {1'h0, p1_exp_a_comb} + {1'h0, p1_exp_b_comb};
  assign p1_guard_bit_comb = p1_leading_bit_comb ? p1_frac_mult_comb[10] : p1_frac_mult_comb[9];
  assign p1_not_810_comb = ~p1_is_zero_result_comb;
  assign p1_sign_result_comb = p1_sign_a_comb ^ p1_sign_b_comb;
  assign p1_is_nan_result_comb = p1_is_nan_comb | p1_is_nan__1_comb | p1_is_inf_comb & p1_eq_772_comb & p1_eq_802_comb | p1_eq_771_comb & p1_eq_801_comb & p1_is_inf__1_comb;

  // Registers for pipe stage 1:
  reg p1_leading_bit;
  reg [10:0] p1_frac_adjusted;
  reg p1_eq_791;
  reg p1_round_bit;
  reg p1_sticky_bit;
  reg [5:0] p1_add_797;
  reg p1_guard_bit;
  reg p1_not_810;
  reg p1_is_inf;
  reg p1_is_inf__1;
  reg p1_sign_result;
  reg p1_is_nan_result;
  always @ (posedge clk) begin
    p1_leading_bit <= p1_leading_bit_comb;
    p1_frac_adjusted <= p1_frac_adjusted_comb;
    p1_eq_791 <= p1_eq_791_comb;
    p1_round_bit <= p1_round_bit_comb;
    p1_sticky_bit <= p1_sticky_bit_comb;
    p1_add_797 <= p1_add_797_comb;
    p1_guard_bit <= p1_guard_bit_comb;
    p1_not_810 <= p1_not_810_comb;
    p1_is_inf <= p1_is_inf_comb;
    p1_is_inf__1 <= p1_is_inf__1_comb;
    p1_sign_result <= p1_sign_result_comb;
    p1_is_nan_result <= p1_is_nan_result_comb;
  end

  // ===== Pipe stage 2:
  wire [1:0] p2_add_858_comb;
  wire [6:0] p2_concat_859_comb;
  wire [1:0] p2_exp_final__5_squeezed_comb;
  wire [1:0] p2_exp_final__6_squeezed_comb;
  wire [6:0] p2_add_868_comb;
  wire [5:0] p2_exp_final__3_squeezed_const_msb_bits_comb;
  wire [1:0] p2_exp_final__3_squeezed_comb;
  wire p2_round_condition_comb;
  wire [10:0] p2_add_872_comb;
  wire [6:0] p2_add_874_comb;
  wire [7:0] p2_exp_final__2_comb;
  wire [7:0] p2_exp_final__3_comb;
  wire [10:0] p2_frac_final_comb;
  wire [7:0] p2_exp_final__4_comb;
  wire [7:0] p2_sub_883_comb;
  wire [31:0] p2_shrl_885_comb;
  wire [9:0] p2_frac_subnormal_comb;
  wire p2_nor_892_comb;
  wire [14:0] p2_normalized_result_bits_0_width_15_comb;
  wire p2_is_inf_result_comb;
  assign p2_add_858_comb = {1'h0, p1_leading_bit} + {1'h0, p1_eq_791};
  assign p2_concat_859_comb = {1'h0, p1_add_797};
  assign p2_exp_final__5_squeezed_comb = 2'h1;
  assign p2_exp_final__6_squeezed_comb = 2'h2;
  assign p2_add_868_comb = p2_concat_859_comb + {6'h00, p1_leading_bit};
  assign p2_exp_final__3_squeezed_const_msb_bits_comb = 6'h3c;
  assign p2_exp_final__3_squeezed_comb = p1_eq_791 ? p2_exp_final__6_squeezed_comb : p2_exp_final__5_squeezed_comb;
  assign p2_round_condition_comb = p1_guard_bit & (p1_round_bit | p1_sticky_bit) | p1_guard_bit & ~p1_round_bit & ~p1_sticky_bit & p1_frac_adjusted[0];
  assign p2_add_872_comb = p1_frac_adjusted + 11'h001;
  assign p2_add_874_comb = p2_concat_859_comb + {5'h00, p2_add_858_comb};
  assign p2_exp_final__2_comb = {1'h0, p2_add_868_comb};
  assign p2_exp_final__3_comb = {p2_exp_final__3_squeezed_const_msb_bits_comb, p2_exp_final__3_squeezed_comb};
  assign p2_frac_final_comb = p2_round_condition_comb ? p2_add_872_comb : p1_frac_adjusted;
  assign p2_exp_final__4_comb = p2_exp_final__2_comb + p2_exp_final__3_comb;
  assign p2_sub_883_comb = 8'h10 - {1'h0, p2_add_874_comb};
  assign p2_shrl_885_comb = p2_sub_883_comb >= 8'h20 ? 32'h0000_0000 : {21'h00_0000, p2_frac_final_comb} >> p2_sub_883_comb;
  assign p2_frac_subnormal_comb = p2_shrl_885_comb[9:0];
  assign p2_nor_892_comb = ~((|p2_exp_final__4_comb[7:1]) | p2_exp_final__4_comb[0]);
  assign p2_normalized_result_bits_0_width_15_comb = {p2_exp_final__4_comb[4:0], p2_frac_final_comb[9:0]};
  assign p2_is_inf_result_comb = p1_is_inf | p1_is_inf__1 | p2_exp_final__4_comb > 8'h1e;

  // Registers for pipe stage 2:
  reg [9:0] p2_frac_subnormal;
  reg p2_nor_892;
  reg [14:0] p2_normalized_result_bits_0_width_15;
  reg p2_not_810;
  reg p2_is_inf_result;
  reg p2_sign_result;
  reg p2_is_nan_result;
  always @ (posedge clk) begin
    p2_frac_subnormal <= p2_frac_subnormal_comb;
    p2_nor_892 <= p2_nor_892_comb;
    p2_normalized_result_bits_0_width_15 <= p2_normalized_result_bits_0_width_15_comb;
    p2_not_810 <= p1_not_810;
    p2_is_inf_result <= p2_is_inf_result_comb;
    p2_sign_result <= p1_sign_result;
    p2_is_nan_result <= p1_is_nan_result;
  end

  // ===== Pipe stage 3:
  wire [15:0] p3_concat_917_comb;
  wire [15:0] p3_result_comb;
  assign p3_concat_917_comb = {p2_sign_result, p2_is_inf_result ? 15'h7c00 : (p2_nor_892 ? {5'h00, p2_frac_subnormal} : p2_normalized_result_bits_0_width_15) & {15{p2_not_810}}};
  assign p3_result_comb = p2_is_nan_result ? 16'h7e00 : p3_concat_917_comb;

  // Registers for pipe stage 3:
  reg [15:0] p3_result;
  always @ (posedge clk) begin
    p3_result <= p3_result_comb;
  end
  assign out = p3_result;
endmodule
