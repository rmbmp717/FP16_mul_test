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
  wire p1_eq_771_comb;
  wire p1_eq_772_comb;
  wire [5:0] p1_add_779_comb;
  wire p1_eq_782_comb;
  wire p1_eq_783_comb;
  wire p1_eq_786_comb;
  wire p1_eq_787_comb;
  wire p1_sign_result_comb;
  assign p1_exp_a_comb = p0_a[14:10];
  assign p1_exp_b_comb = p0_b[14:10];
  assign p1_frac_a_raw_comb = p0_a[9:0];
  assign p1_frac_b_raw_comb = p0_b[9:0];
  assign p1_sign_a_comb = p0_a[15];
  assign p1_sign_b_comb = p0_b[15];
  assign p1_eq_771_comb = p1_exp_a_comb == 5'h00;
  assign p1_eq_772_comb = p1_exp_b_comb == 5'h00;
  assign p1_add_779_comb = {1'h0, p1_exp_a_comb} + {1'h0, p1_exp_b_comb};
  assign p1_eq_782_comb = p1_frac_a_raw_comb == 10'h000;
  assign p1_eq_783_comb = p1_frac_b_raw_comb == 10'h000;
  assign p1_eq_786_comb = p1_exp_a_comb == 5'h1f;
  assign p1_eq_787_comb = p1_exp_b_comb == 5'h1f;
  assign p1_sign_result_comb = p1_sign_a_comb ^ p1_sign_b_comb;

  // Registers for pipe stage 1:
  reg p1_eq_771;
  reg p1_eq_772;
  reg [9:0] p1_frac_a_raw;
  reg [9:0] p1_frac_b_raw;
  reg [5:0] p1_add_779;
  reg p1_eq_782;
  reg p1_eq_783;
  reg p1_eq_786;
  reg p1_eq_787;
  reg p1_sign_result;
  always @ (posedge clk) begin
    p1_eq_771 <= p1_eq_771_comb;
    p1_eq_772 <= p1_eq_772_comb;
    p1_frac_a_raw <= p1_frac_a_raw_comb;
    p1_frac_b_raw <= p1_frac_b_raw_comb;
    p1_add_779 <= p1_add_779_comb;
    p1_eq_782 <= p1_eq_782_comb;
    p1_eq_783 <= p1_eq_783_comb;
    p1_eq_786 <= p1_eq_786_comb;
    p1_eq_787 <= p1_eq_787_comb;
    p1_sign_result <= p1_sign_result_comb;
  end

  // ===== Pipe stage 2:
  wire p2_leading_a_comb;
  wire p2_leading_b_comb;
  wire p2_is_zero_a_comb;
  wire p2_is_zero_b_comb;
  wire p2_is_inf_comb;
  wire p2_is_inf__1_comb;
  wire p2_is_zero_result_comb;
  wire p2_is_nan_comb;
  wire p2_is_nan__1_comb;
  wire [21:0] p2_frac_mult_comb;
  wire p2_not_819_comb;
  wire p2_is_nan_result_comb;
  assign p2_leading_a_comb = ~p1_eq_771;
  assign p2_leading_b_comb = ~p1_eq_772;
  assign p2_is_zero_a_comb = p1_eq_771 & p1_eq_782;
  assign p2_is_zero_b_comb = p1_eq_772 & p1_eq_783;
  assign p2_is_inf_comb = p1_eq_786 & p1_eq_782;
  assign p2_is_inf__1_comb = p1_eq_787 & p1_eq_783;
  assign p2_is_zero_result_comb = p2_is_zero_a_comb | p2_is_zero_b_comb;
  assign p2_is_nan_comb = ~(~p1_eq_786 | p1_eq_782);
  assign p2_is_nan__1_comb = ~(~p1_eq_787 | p1_eq_783);
  assign p2_frac_mult_comb = umul22b_11b_x_11b({p2_leading_a_comb, p1_frac_a_raw}, {p2_leading_b_comb, p1_frac_b_raw});
  assign p2_not_819_comb = ~p2_is_zero_result_comb;
  assign p2_is_nan_result_comb = p2_is_nan_comb | p2_is_nan__1_comb | p2_is_inf_comb & p1_eq_772 & p1_eq_783 | p1_eq_771 & p1_eq_782 & p2_is_inf__1_comb;

  // Registers for pipe stage 2:
  reg [21:0] p2_frac_mult;
  reg [5:0] p2_add_779;
  reg p2_not_819;
  reg p2_is_inf;
  reg p2_is_inf__1;
  reg p2_sign_result;
  reg p2_is_nan_result;
  always @ (posedge clk) begin
    p2_frac_mult <= p2_frac_mult_comb;
    p2_add_779 <= p1_add_779;
    p2_not_819 <= p2_not_819_comb;
    p2_is_inf <= p2_is_inf_comb;
    p2_is_inf__1 <= p2_is_inf__1_comb;
    p2_sign_result <= p1_sign_result;
    p2_is_nan_result <= p2_is_nan_result_comb;
  end

  // ===== Pipe stage 3:
  wire p3_leading_bit_comb;
  wire [10:0] p3_frac_adjusted_comb;
  wire p3_round_bit_comb;
  wire p3_sticky_bit_comb;
  wire p3_guard_bit_comb;
  assign p3_leading_bit_comb = p2_frac_mult[21];
  assign p3_frac_adjusted_comb = p3_leading_bit_comb ? p2_frac_mult[21:11] : p2_frac_mult[20:10];
  assign p3_round_bit_comb = p3_leading_bit_comb ? p2_frac_mult[9] : p2_frac_mult[8];
  assign p3_sticky_bit_comb = p2_frac_mult[7:0] != 8'h00;
  assign p3_guard_bit_comb = p3_leading_bit_comb ? p2_frac_mult[10] : p2_frac_mult[9];

  // Registers for pipe stage 3:
  reg p3_leading_bit;
  reg [10:0] p3_frac_adjusted;
  reg p3_round_bit;
  reg p3_sticky_bit;
  reg [5:0] p3_add_779;
  reg p3_guard_bit;
  reg p3_not_819;
  reg p3_is_inf;
  reg p3_is_inf__1;
  reg p3_sign_result;
  reg p3_is_nan_result;
  always @ (posedge clk) begin
    p3_leading_bit <= p3_leading_bit_comb;
    p3_frac_adjusted <= p3_frac_adjusted_comb;
    p3_round_bit <= p3_round_bit_comb;
    p3_sticky_bit <= p3_sticky_bit_comb;
    p3_add_779 <= p2_add_779;
    p3_guard_bit <= p3_guard_bit_comb;
    p3_not_819 <= p2_not_819;
    p3_is_inf <= p2_is_inf;
    p3_is_inf__1 <= p2_is_inf__1;
    p3_sign_result <= p2_sign_result;
    p3_is_nan_result <= p2_is_nan_result;
  end

  // ===== Pipe stage 4:
  wire p4_eq_880_comb;
  wire [6:0] p4_concat_890_comb;
  wire [1:0] p4_add_889_comb;
  wire [6:0] p4_add_894_comb;
  wire p4_round_condition_comb;
  assign p4_eq_880_comb = p3_frac_adjusted == 11'h7ff;
  assign p4_concat_890_comb = {1'h0, p3_add_779};
  assign p4_add_889_comb = {1'h0, p3_leading_bit} + {1'h0, p4_eq_880_comb};
  assign p4_add_894_comb = p4_concat_890_comb + {6'h00, p3_leading_bit};
  assign p4_round_condition_comb = p3_guard_bit & (p3_round_bit | p3_sticky_bit) | p3_guard_bit & ~p3_round_bit & ~p3_sticky_bit & p3_frac_adjusted[0];

  // Registers for pipe stage 4:
  reg [10:0] p4_frac_adjusted;
  reg p4_eq_880;
  reg [1:0] p4_add_889;
  reg [6:0] p4_concat_890;
  reg [6:0] p4_add_894;
  reg p4_round_condition;
  reg p4_not_819;
  reg p4_is_inf;
  reg p4_is_inf__1;
  reg p4_sign_result;
  reg p4_is_nan_result;
  always @ (posedge clk) begin
    p4_frac_adjusted <= p3_frac_adjusted;
    p4_eq_880 <= p4_eq_880_comb;
    p4_add_889 <= p4_add_889_comb;
    p4_concat_890 <= p4_concat_890_comb;
    p4_add_894 <= p4_add_894_comb;
    p4_round_condition <= p4_round_condition_comb;
    p4_not_819 <= p3_not_819;
    p4_is_inf <= p3_is_inf;
    p4_is_inf__1 <= p3_is_inf__1;
    p4_sign_result <= p3_sign_result;
    p4_is_nan_result <= p3_is_nan_result;
  end

  // ===== Pipe stage 5:
  wire [1:0] p5_exp_final__5_squeezed_comb;
  wire [1:0] p5_exp_final__6_squeezed_comb;
  wire [5:0] p5_exp_final__3_squeezed_const_msb_bits_comb;
  wire [1:0] p5_exp_final__3_squeezed_comb;
  wire [10:0] p5_add_926_comb;
  wire [6:0] p5_add_928_comb;
  wire [7:0] p5_exp_final__2_comb;
  wire [7:0] p5_exp_final__3_comb;
  wire [10:0] p5_frac_final_comb;
  wire [7:0] p5_concat_932_comb;
  wire [7:0] p5_exp_final__4_comb;
  assign p5_exp_final__5_squeezed_comb = 2'h1;
  assign p5_exp_final__6_squeezed_comb = 2'h2;
  assign p5_exp_final__3_squeezed_const_msb_bits_comb = 6'h3c;
  assign p5_exp_final__3_squeezed_comb = p4_eq_880 ? p5_exp_final__6_squeezed_comb : p5_exp_final__5_squeezed_comb;
  assign p5_add_926_comb = p4_frac_adjusted + 11'h001;
  assign p5_add_928_comb = p4_concat_890 + {5'h00, p4_add_889};
  assign p5_exp_final__2_comb = {1'h0, p4_add_894};
  assign p5_exp_final__3_comb = {p5_exp_final__3_squeezed_const_msb_bits_comb, p5_exp_final__3_squeezed_comb};
  assign p5_frac_final_comb = p4_round_condition ? p5_add_926_comb : p4_frac_adjusted;
  assign p5_concat_932_comb = {1'h0, p5_add_928_comb};
  assign p5_exp_final__4_comb = p5_exp_final__2_comb + p5_exp_final__3_comb;

  // Registers for pipe stage 5:
  reg [10:0] p5_frac_final;
  reg [7:0] p5_concat_932;
  reg [7:0] p5_exp_final__4;
  reg p5_not_819;
  reg p5_is_inf;
  reg p5_is_inf__1;
  reg p5_sign_result;
  reg p5_is_nan_result;
  always @ (posedge clk) begin
    p5_frac_final <= p5_frac_final_comb;
    p5_concat_932 <= p5_concat_932_comb;
    p5_exp_final__4 <= p5_exp_final__4_comb;
    p5_not_819 <= p4_not_819;
    p5_is_inf <= p4_is_inf;
    p5_is_inf__1 <= p4_is_inf__1;
    p5_sign_result <= p4_sign_result;
    p5_is_nan_result <= p4_is_nan_result;
  end

  // ===== Pipe stage 6:
  wire [7:0] p6_sub_953_comb;
  wire [31:0] p6_shrl_955_comb;
  wire [9:0] p6_frac_subnormal_comb;
  wire p6_nor_962_comb;
  wire [14:0] p6_normalized_result_bits_0_width_15_comb;
  wire p6_is_inf_result_comb;
  assign p6_sub_953_comb = 8'h10 - p5_concat_932;
  assign p6_shrl_955_comb = p6_sub_953_comb >= 8'h20 ? 32'h0000_0000 : {21'h00_0000, p5_frac_final} >> p6_sub_953_comb;
  assign p6_frac_subnormal_comb = p6_shrl_955_comb[9:0];
  assign p6_nor_962_comb = ~((|p5_exp_final__4[7:1]) | p5_exp_final__4[0]);
  assign p6_normalized_result_bits_0_width_15_comb = {p5_exp_final__4[4:0], p5_frac_final[9:0]};
  assign p6_is_inf_result_comb = p5_is_inf | p5_is_inf__1 | p5_exp_final__4 > 8'h1e;

  // Registers for pipe stage 6:
  reg [9:0] p6_frac_subnormal;
  reg p6_nor_962;
  reg [14:0] p6_normalized_result_bits_0_width_15;
  reg p6_not_819;
  reg p6_is_inf_result;
  reg p6_sign_result;
  reg p6_is_nan_result;
  always @ (posedge clk) begin
    p6_frac_subnormal <= p6_frac_subnormal_comb;
    p6_nor_962 <= p6_nor_962_comb;
    p6_normalized_result_bits_0_width_15 <= p6_normalized_result_bits_0_width_15_comb;
    p6_not_819 <= p5_not_819;
    p6_is_inf_result <= p6_is_inf_result_comb;
    p6_sign_result <= p5_sign_result;
    p6_is_nan_result <= p5_is_nan_result;
  end

  // ===== Pipe stage 7:
  wire [14:0] p7_and_984_comb;
  assign p7_and_984_comb = (p6_nor_962 ? {5'h00, p6_frac_subnormal} : p6_normalized_result_bits_0_width_15) & {15{p6_not_819}};

  // Registers for pipe stage 7:
  reg p7_is_inf_result;
  reg [14:0] p7_and_984;
  reg p7_sign_result;
  reg p7_is_nan_result;
  always @ (posedge clk) begin
    p7_is_inf_result <= p6_is_inf_result;
    p7_and_984 <= p7_and_984_comb;
    p7_sign_result <= p6_sign_result;
    p7_is_nan_result <= p6_is_nan_result;
  end

  // ===== Pipe stage 8:
  wire [15:0] p8_concat_995_comb;
  assign p8_concat_995_comb = {p7_sign_result, p7_is_inf_result ? 15'h7c00 : p7_and_984};

  // Registers for pipe stage 8:
  reg p8_is_nan_result;
  reg [15:0] p8_concat_995;
  always @ (posedge clk) begin
    p8_is_nan_result <= p7_is_nan_result;
    p8_concat_995 <= p8_concat_995_comb;
  end

  // ===== Pipe stage 9:

  // Registers for pipe stage 9:
  reg p9_is_nan_result;
  reg [15:0] p9_concat_995;
  always @ (posedge clk) begin
    p9_is_nan_result <= p8_is_nan_result;
    p9_concat_995 <= p8_concat_995;
  end

  // ===== Pipe stage 10:
  wire [15:0] p10_result_comb;
  assign p10_result_comb = p9_is_nan_result ? 16'h7e00 : p9_concat_995;

  // Registers for pipe stage 10:
  reg [15:0] p10_result;
  always @ (posedge clk) begin
    p10_result <= p10_result_comb;
  end
  assign out = p10_result;
endmodule
