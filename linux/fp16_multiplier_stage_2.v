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
  wire p1_leading_bit_comb;
  wire [10:0] p1_frac_adjusted_comb;
  wire p1_round_bit_comb;
  wire p1_sticky_bit_comb;
  wire [5:0] p1_add_802_comb;
  wire p1_eq_793_comb;
  wire p1_guard_bit_comb;
  wire [6:0] p1_concat_811_comb;
  wire [1:0] p1_exp_final__5_squeezed_comb;
  wire [1:0] p1_exp_final__6_squeezed_comb;
  wire p1_eq_831_comb;
  wire p1_eq_832_comb;
  wire p1_eq_838_comb;
  wire p1_eq_839_comb;
  wire [6:0] p1_add_820_comb;
  wire [5:0] p1_exp_final__3_squeezed_const_msb_bits_comb;
  wire [1:0] p1_exp_final__3_squeezed_comb;
  wire p1_is_zero_a_comb;
  wire p1_is_zero_b_comb;
  wire p1_is_inf_comb;
  wire p1_is_inf__1_comb;
  wire [1:0] p1_add_810_comb;
  wire p1_round_condition_comb;
  wire [10:0] p1_add_824_comb;
  wire [7:0] p1_exp_final__2_comb;
  wire [7:0] p1_exp_final__3_comb;
  wire p1_is_zero_result_comb;
  wire p1_sign_a_comb;
  wire p1_sign_b_comb;
  wire p1_is_nan_comb;
  wire p1_is_nan__1_comb;
  wire [6:0] p1_concat_818_comb;
  wire [10:0] p1_frac_final_comb;
  wire [7:0] p1_exp_final__4_comb;
  wire p1_not_840_comb;
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
  assign p1_leading_bit_comb = p1_frac_mult_comb[21];
  assign p1_frac_adjusted_comb = p1_leading_bit_comb ? p1_frac_mult_comb[21:11] : p1_frac_mult_comb[20:10];
  assign p1_round_bit_comb = p1_leading_bit_comb ? p1_frac_mult_comb[9] : p1_frac_mult_comb[8];
  assign p1_sticky_bit_comb = p1_frac_mult_comb[7:0] != 8'h00;
  assign p1_add_802_comb = {1'h0, p1_exp_a_comb} + {1'h0, p1_exp_b_comb};
  assign p1_eq_793_comb = p1_frac_adjusted_comb == 11'h7ff;
  assign p1_guard_bit_comb = p1_leading_bit_comb ? p1_frac_mult_comb[10] : p1_frac_mult_comb[9];
  assign p1_concat_811_comb = {1'h0, p1_add_802_comb};
  assign p1_exp_final__5_squeezed_comb = 2'h1;
  assign p1_exp_final__6_squeezed_comb = 2'h2;
  assign p1_eq_831_comb = p1_frac_a_raw_comb == 10'h000;
  assign p1_eq_832_comb = p1_frac_b_raw_comb == 10'h000;
  assign p1_eq_838_comb = p1_exp_a_comb == 5'h1f;
  assign p1_eq_839_comb = p1_exp_b_comb == 5'h1f;
  assign p1_add_820_comb = p1_concat_811_comb + {6'h00, p1_leading_bit_comb};
  assign p1_exp_final__3_squeezed_const_msb_bits_comb = 6'h3c;
  assign p1_exp_final__3_squeezed_comb = p1_eq_793_comb ? p1_exp_final__6_squeezed_comb : p1_exp_final__5_squeezed_comb;
  assign p1_is_zero_a_comb = p1_eq_771_comb & p1_eq_831_comb;
  assign p1_is_zero_b_comb = p1_eq_772_comb & p1_eq_832_comb;
  assign p1_is_inf_comb = p1_eq_838_comb & p1_eq_831_comb;
  assign p1_is_inf__1_comb = p1_eq_839_comb & p1_eq_832_comb;
  assign p1_add_810_comb = {1'h0, p1_leading_bit_comb} + {1'h0, p1_eq_793_comb};
  assign p1_round_condition_comb = p1_guard_bit_comb & (p1_round_bit_comb | p1_sticky_bit_comb) | p1_guard_bit_comb & ~p1_round_bit_comb & ~p1_sticky_bit_comb & p1_frac_adjusted_comb[0];
  assign p1_add_824_comb = p1_frac_adjusted_comb + 11'h001;
  assign p1_exp_final__2_comb = {1'h0, p1_add_820_comb};
  assign p1_exp_final__3_comb = {p1_exp_final__3_squeezed_const_msb_bits_comb, p1_exp_final__3_squeezed_comb};
  assign p1_is_zero_result_comb = p1_is_zero_a_comb | p1_is_zero_b_comb;
  assign p1_sign_a_comb = p0_a[15];
  assign p1_sign_b_comb = p0_b[15];
  assign p1_is_nan_comb = ~(~p1_eq_838_comb | p1_eq_831_comb);
  assign p1_is_nan__1_comb = ~(~p1_eq_839_comb | p1_eq_832_comb);
  assign p1_concat_818_comb = {5'h00, p1_add_810_comb};
  assign p1_frac_final_comb = p1_round_condition_comb ? p1_add_824_comb : p1_frac_adjusted_comb;
  assign p1_exp_final__4_comb = p1_exp_final__2_comb + p1_exp_final__3_comb;
  assign p1_not_840_comb = ~p1_is_zero_result_comb;
  assign p1_sign_result_comb = p1_sign_a_comb ^ p1_sign_b_comb;
  assign p1_is_nan_result_comb = p1_is_nan_comb | p1_is_nan__1_comb | p1_is_inf_comb & p1_eq_772_comb & p1_eq_832_comb | p1_eq_771_comb & p1_eq_831_comb & p1_is_inf__1_comb;

  // Registers for pipe stage 1:
  reg [6:0] p1_concat_811;
  reg [6:0] p1_concat_818;
  reg [10:0] p1_frac_final;
  reg [7:0] p1_exp_final__4;
  reg p1_not_840;
  reg p1_is_inf;
  reg p1_is_inf__1;
  reg p1_sign_result;
  reg p1_is_nan_result;
  always @ (posedge clk) begin
    p1_concat_811 <= p1_concat_811_comb;
    p1_concat_818 <= p1_concat_818_comb;
    p1_frac_final <= p1_frac_final_comb;
    p1_exp_final__4 <= p1_exp_final__4_comb;
    p1_not_840 <= p1_not_840_comb;
    p1_is_inf <= p1_is_inf_comb;
    p1_is_inf__1 <= p1_is_inf__1_comb;
    p1_sign_result <= p1_sign_result_comb;
    p1_is_nan_result <= p1_is_nan_result_comb;
  end

  // ===== Pipe stage 2:
  wire [6:0] p2_add_872_comb;
  wire [7:0] p2_sub_877_comb;
  wire [31:0] p2_shrl_879_comb;
  wire [9:0] p2_frac_subnormal_comb;
  wire [14:0] p2_normalized_result_bits_0_width_15_comb;
  wire p2_is_inf_result_comb;
  wire [14:0] p2_sel_896_comb;
  wire [15:0] p2_result_comb;
  assign p2_add_872_comb = p1_concat_811 + p1_concat_818;
  assign p2_sub_877_comb = 8'h10 - {1'h0, p2_add_872_comb};
  assign p2_shrl_879_comb = p2_sub_877_comb >= 8'h20 ? 32'h0000_0000 : {21'h00_0000, p1_frac_final} >> p2_sub_877_comb;
  assign p2_frac_subnormal_comb = p2_shrl_879_comb[9:0];
  assign p2_normalized_result_bits_0_width_15_comb = {p1_exp_final__4[4:0], p1_frac_final[9:0]};
  assign p2_is_inf_result_comb = p1_is_inf | p1_is_inf__1 | p1_exp_final__4 > 8'h1e;
  assign p2_sel_896_comb = p2_is_inf_result_comb ? 15'h7c00 : (~((|p1_exp_final__4[7:1]) | p1_exp_final__4[0]) ? {5'h00, p2_frac_subnormal_comb} : p2_normalized_result_bits_0_width_15_comb) & {15{p1_not_840}};
  assign p2_result_comb = p1_is_nan_result ? 16'h7e00 : {p1_sign_result, p2_sel_896_comb};

  // Registers for pipe stage 2:
  reg [15:0] p2_result;
  always @ (posedge clk) begin
    p2_result <= p2_result_comb;
  end
  assign out = p2_result;
endmodule
