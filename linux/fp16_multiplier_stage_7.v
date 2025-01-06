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
  wire p1_sign_a_comb;
  wire p1_sign_b_comb;
  wire [10:0] p1_concat_777_comb;
  wire [10:0] p1_concat_778_comb;
  wire [5:0] p1_add_783_comb;
  wire p1_eq_786_comb;
  wire p1_eq_787_comb;
  wire p1_eq_790_comb;
  wire p1_eq_791_comb;
  wire p1_sign_result_comb;
  assign p1_exp_a_comb = p0_a[14:10];
  assign p1_exp_b_comb = p0_b[14:10];
  assign p1_eq_771_comb = p1_exp_a_comb == 5'h00;
  assign p1_eq_772_comb = p1_exp_b_comb == 5'h00;
  assign p1_leading_a_comb = ~p1_eq_771_comb;
  assign p1_frac_a_raw_comb = p0_a[9:0];
  assign p1_leading_b_comb = ~p1_eq_772_comb;
  assign p1_frac_b_raw_comb = p0_b[9:0];
  assign p1_sign_a_comb = p0_a[15];
  assign p1_sign_b_comb = p0_b[15];
  assign p1_concat_777_comb = {p1_leading_a_comb, p1_frac_a_raw_comb};
  assign p1_concat_778_comb = {p1_leading_b_comb, p1_frac_b_raw_comb};
  assign p1_add_783_comb = {1'h0, p1_exp_a_comb} + {1'h0, p1_exp_b_comb};
  assign p1_eq_786_comb = p1_frac_a_raw_comb == 10'h000;
  assign p1_eq_787_comb = p1_frac_b_raw_comb == 10'h000;
  assign p1_eq_790_comb = p1_exp_a_comb == 5'h1f;
  assign p1_eq_791_comb = p1_exp_b_comb == 5'h1f;
  assign p1_sign_result_comb = p1_sign_a_comb ^ p1_sign_b_comb;

  // Registers for pipe stage 1:
  reg p1_eq_771;
  reg p1_eq_772;
  reg [10:0] p1_concat_777;
  reg [10:0] p1_concat_778;
  reg [5:0] p1_add_783;
  reg p1_eq_786;
  reg p1_eq_787;
  reg p1_eq_790;
  reg p1_eq_791;
  reg p1_sign_result;
  always @ (posedge clk) begin
    p1_eq_771 <= p1_eq_771_comb;
    p1_eq_772 <= p1_eq_772_comb;
    p1_concat_777 <= p1_concat_777_comb;
    p1_concat_778 <= p1_concat_778_comb;
    p1_add_783 <= p1_add_783_comb;
    p1_eq_786 <= p1_eq_786_comb;
    p1_eq_787 <= p1_eq_787_comb;
    p1_eq_790 <= p1_eq_790_comb;
    p1_eq_791 <= p1_eq_791_comb;
    p1_sign_result <= p1_sign_result_comb;
  end

  // ===== Pipe stage 2:
  wire [21:0] p2_frac_mult_comb;
  wire p2_leading_bit_comb;
  wire p2_is_zero_a_comb;
  wire p2_is_zero_b_comb;
  wire p2_is_inf_comb;
  wire p2_is_inf__1_comb;
  wire [10:0] p2_frac_adjusted_comb;
  wire p2_is_zero_result_comb;
  wire p2_is_nan_comb;
  wire p2_is_nan__1_comb;
  wire p2_eq_825_comb;
  wire p2_round_bit_comb;
  wire p2_sticky_bit_comb;
  wire p2_guard_bit_comb;
  wire p2_not_833_comb;
  wire p2_is_nan_result_comb;
  assign p2_frac_mult_comb = umul22b_11b_x_11b(p1_concat_777, p1_concat_778);
  assign p2_leading_bit_comb = p2_frac_mult_comb[21];
  assign p2_is_zero_a_comb = p1_eq_771 & p1_eq_786;
  assign p2_is_zero_b_comb = p1_eq_772 & p1_eq_787;
  assign p2_is_inf_comb = p1_eq_790 & p1_eq_786;
  assign p2_is_inf__1_comb = p1_eq_791 & p1_eq_787;
  assign p2_frac_adjusted_comb = p2_leading_bit_comb ? p2_frac_mult_comb[21:11] : p2_frac_mult_comb[20:10];
  assign p2_is_zero_result_comb = p2_is_zero_a_comb | p2_is_zero_b_comb;
  assign p2_is_nan_comb = ~(~p1_eq_790 | p1_eq_786);
  assign p2_is_nan__1_comb = ~(~p1_eq_791 | p1_eq_787);
  assign p2_eq_825_comb = p2_frac_adjusted_comb == 11'h7ff;
  assign p2_round_bit_comb = p2_leading_bit_comb ? p2_frac_mult_comb[9] : p2_frac_mult_comb[8];
  assign p2_sticky_bit_comb = p2_frac_mult_comb[7:0] != 8'h00;
  assign p2_guard_bit_comb = p2_leading_bit_comb ? p2_frac_mult_comb[10] : p2_frac_mult_comb[9];
  assign p2_not_833_comb = ~p2_is_zero_result_comb;
  assign p2_is_nan_result_comb = p2_is_nan_comb | p2_is_nan__1_comb | p2_is_inf_comb & p1_eq_772 & p1_eq_787 | p1_eq_771 & p1_eq_786 & p2_is_inf__1_comb;

  // Registers for pipe stage 2:
  reg p2_leading_bit;
  reg [10:0] p2_frac_adjusted;
  reg p2_eq_825;
  reg p2_round_bit;
  reg p2_sticky_bit;
  reg [5:0] p2_add_783;
  reg p2_guard_bit;
  reg p2_not_833;
  reg p2_is_inf;
  reg p2_is_inf__1;
  reg p2_sign_result;
  reg p2_is_nan_result;
  always @ (posedge clk) begin
    p2_leading_bit <= p2_leading_bit_comb;
    p2_frac_adjusted <= p2_frac_adjusted_comb;
    p2_eq_825 <= p2_eq_825_comb;
    p2_round_bit <= p2_round_bit_comb;
    p2_sticky_bit <= p2_sticky_bit_comb;
    p2_add_783 <= p1_add_783;
    p2_guard_bit <= p2_guard_bit_comb;
    p2_not_833 <= p2_not_833_comb;
    p2_is_inf <= p2_is_inf_comb;
    p2_is_inf__1 <= p2_is_inf__1_comb;
    p2_sign_result <= p1_sign_result;
    p2_is_nan_result <= p2_is_nan_result_comb;
  end

  // ===== Pipe stage 3:
  wire [6:0] p3_concat_879_comb;
  wire [1:0] p3_exp_final__5_squeezed_comb;
  wire [1:0] p3_exp_final__6_squeezed_comb;
  wire [1:0] p3_add_878_comb;
  wire [6:0] p3_add_888_comb;
  wire [5:0] p3_exp_final__3_squeezed_const_msb_bits_comb;
  wire [1:0] p3_exp_final__3_squeezed_comb;
  wire p3_round_condition_comb;
  wire [10:0] p3_add_892_comb;
  wire [7:0] p3_exp_final__2_comb;
  wire [7:0] p3_exp_final__3_comb;
  wire [6:0] p3_add_893_comb;
  wire [10:0] p3_frac_final_comb;
  wire [7:0] p3_exp_final__4_comb;
  assign p3_concat_879_comb = {1'h0, p2_add_783};
  assign p3_exp_final__5_squeezed_comb = 2'h1;
  assign p3_exp_final__6_squeezed_comb = 2'h2;
  assign p3_add_878_comb = {1'h0, p2_leading_bit} + {1'h0, p2_eq_825};
  assign p3_add_888_comb = p3_concat_879_comb + {6'h00, p2_leading_bit};
  assign p3_exp_final__3_squeezed_const_msb_bits_comb = 6'h3c;
  assign p3_exp_final__3_squeezed_comb = p2_eq_825 ? p3_exp_final__6_squeezed_comb : p3_exp_final__5_squeezed_comb;
  assign p3_round_condition_comb = p2_guard_bit & (p2_round_bit | p2_sticky_bit) | p2_guard_bit & ~p2_round_bit & ~p2_sticky_bit & p2_frac_adjusted[0];
  assign p3_add_892_comb = p2_frac_adjusted + 11'h001;
  assign p3_exp_final__2_comb = {1'h0, p3_add_888_comb};
  assign p3_exp_final__3_comb = {p3_exp_final__3_squeezed_const_msb_bits_comb, p3_exp_final__3_squeezed_comb};
  assign p3_add_893_comb = p3_concat_879_comb + {5'h00, p3_add_878_comb};
  assign p3_frac_final_comb = p3_round_condition_comb ? p3_add_892_comb : p2_frac_adjusted;
  assign p3_exp_final__4_comb = p3_exp_final__2_comb + p3_exp_final__3_comb;

  // Registers for pipe stage 3:
  reg [6:0] p3_add_893;
  reg [10:0] p3_frac_final;
  reg [7:0] p3_exp_final__4;
  reg p3_not_833;
  reg p3_is_inf;
  reg p3_is_inf__1;
  reg p3_sign_result;
  reg p3_is_nan_result;
  always @ (posedge clk) begin
    p3_add_893 <= p3_add_893_comb;
    p3_frac_final <= p3_frac_final_comb;
    p3_exp_final__4 <= p3_exp_final__4_comb;
    p3_not_833 <= p2_not_833;
    p3_is_inf <= p2_is_inf;
    p3_is_inf__1 <= p2_is_inf__1;
    p3_sign_result <= p2_sign_result;
    p3_is_nan_result <= p2_is_nan_result;
  end

  // ===== Pipe stage 4:
  wire [7:0] p4_sub_919_comb;
  wire [31:0] p4_shrl_921_comb;
  wire [9:0] p4_frac_subnormal_comb;
  wire p4_nor_928_comb;
  wire [14:0] p4_normalized_result_bits_0_width_15_comb;
  wire p4_is_inf_result_comb;
  assign p4_sub_919_comb = 8'h10 - {1'h0, p3_add_893};
  assign p4_shrl_921_comb = p4_sub_919_comb >= 8'h20 ? 32'h0000_0000 : {21'h00_0000, p3_frac_final} >> p4_sub_919_comb;
  assign p4_frac_subnormal_comb = p4_shrl_921_comb[9:0];
  assign p4_nor_928_comb = ~((|p3_exp_final__4[7:1]) | p3_exp_final__4[0]);
  assign p4_normalized_result_bits_0_width_15_comb = {p3_exp_final__4[4:0], p3_frac_final[9:0]};
  assign p4_is_inf_result_comb = p3_is_inf | p3_is_inf__1 | p3_exp_final__4 > 8'h1e;

  // Registers for pipe stage 4:
  reg [9:0] p4_frac_subnormal;
  reg p4_nor_928;
  reg [14:0] p4_normalized_result_bits_0_width_15;
  reg p4_not_833;
  reg p4_is_inf_result;
  reg p4_sign_result;
  reg p4_is_nan_result;
  always @ (posedge clk) begin
    p4_frac_subnormal <= p4_frac_subnormal_comb;
    p4_nor_928 <= p4_nor_928_comb;
    p4_normalized_result_bits_0_width_15 <= p4_normalized_result_bits_0_width_15_comb;
    p4_not_833 <= p3_not_833;
    p4_is_inf_result <= p4_is_inf_result_comb;
    p4_sign_result <= p3_sign_result;
    p4_is_nan_result <= p3_is_nan_result;
  end

  // ===== Pipe stage 5:
  wire [14:0] p5_sel_952_comb;
  assign p5_sel_952_comb = p4_is_inf_result ? 15'h7c00 : (p4_nor_928 ? {5'h00, p4_frac_subnormal} : p4_normalized_result_bits_0_width_15) & {15{p4_not_833}};

  // Registers for pipe stage 5:
  reg p5_sign_result;
  reg [14:0] p5_sel_952;
  reg p5_is_nan_result;
  always @ (posedge clk) begin
    p5_sign_result <= p4_sign_result;
    p5_sel_952 <= p5_sel_952_comb;
    p5_is_nan_result <= p4_is_nan_result;
  end

  // ===== Pipe stage 6:
  wire [15:0] p6_concat_959_comb;
  assign p6_concat_959_comb = {p5_sign_result, p5_sel_952};

  // Registers for pipe stage 6:
  reg p6_is_nan_result;
  reg [15:0] p6_concat_959;
  always @ (posedge clk) begin
    p6_is_nan_result <= p5_is_nan_result;
    p6_concat_959 <= p6_concat_959_comb;
  end

  // ===== Pipe stage 7:
  wire [15:0] p7_result_comb;
  assign p7_result_comb = p6_is_nan_result ? 16'h7e00 : p6_concat_959;

  // Registers for pipe stage 7:
  reg [15:0] p7_result;
  always @ (posedge clk) begin
    p7_result <= p7_result_comb;
  end
  assign out = p7_result;
endmodule
