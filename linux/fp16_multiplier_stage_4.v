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
  wire p1_eq_817_comb;
  wire p1_eq_818_comb;
  wire p1_eq_835_comb;
  wire p1_eq_836_comb;
  wire p1_eq_837_comb;
  wire p1_eq_838_comb;
  wire p1_leading_a_comb;
  wire p1_leading_b_comb;
  wire p1_is_zero_a_comb;
  wire p1_is_zero_b_comb;
  wire p1_is_inf_a_chk_comb;
  wire p1_is_inf_b_chk_comb;
  wire p1_is_zero_result_comb;
  wire p1_sign_a_comb;
  wire p1_sign_b_comb;
  wire p1_is_nan_comb;
  wire p1_is_nan__1_comb;
  wire [21:0] p1_frac_mult_comb;
  wire [5:0] p1_add_830_comb;
  wire p1_not_844_comb;
  wire p1_sign_result_comb;
  wire p1_is_nan_result_comb;
  assign p1_exp_a_comb = p0_a[14:10];
  assign p1_exp_b_comb = p0_b[14:10];
  assign p1_frac_a_raw_comb = p0_a[9:0];
  assign p1_frac_b_raw_comb = p0_b[9:0];
  assign p1_eq_817_comb = p1_exp_a_comb == 5'h00;
  assign p1_eq_818_comb = p1_exp_b_comb == 5'h00;
  assign p1_eq_835_comb = p1_frac_a_raw_comb == 10'h000;
  assign p1_eq_836_comb = p1_frac_b_raw_comb == 10'h000;
  assign p1_eq_837_comb = p1_exp_a_comb == 5'h1f;
  assign p1_eq_838_comb = p1_exp_b_comb == 5'h1f;
  assign p1_leading_a_comb = ~p1_eq_817_comb;
  assign p1_leading_b_comb = ~p1_eq_818_comb;
  assign p1_is_zero_a_comb = p1_eq_817_comb & p1_eq_835_comb;
  assign p1_is_zero_b_comb = p1_eq_818_comb & p1_eq_836_comb;
  assign p1_is_inf_a_chk_comb = p1_eq_837_comb & p1_eq_835_comb;
  assign p1_is_inf_b_chk_comb = p1_eq_838_comb & p1_eq_836_comb;
  assign p1_is_zero_result_comb = p1_is_zero_a_comb | p1_is_zero_b_comb;
  assign p1_sign_a_comb = p0_a[15];
  assign p1_sign_b_comb = p0_b[15];
  assign p1_is_nan_comb = ~(~p1_eq_837_comb | p1_eq_835_comb);
  assign p1_is_nan__1_comb = ~(~p1_eq_838_comb | p1_eq_836_comb);
  assign p1_frac_mult_comb = umul22b_11b_x_11b({p1_leading_a_comb, p1_frac_a_raw_comb}, {p1_leading_b_comb, p1_frac_b_raw_comb});
  assign p1_add_830_comb = {1'h0, p1_exp_a_comb} + {1'h0, p1_exp_b_comb};
  assign p1_not_844_comb = ~p1_is_zero_result_comb;
  assign p1_sign_result_comb = p1_sign_a_comb ^ p1_sign_b_comb;
  assign p1_is_nan_result_comb = p1_is_nan_comb | p1_is_nan__1_comb | p1_is_inf_a_chk_comb & p1_eq_818_comb & p1_eq_836_comb | p1_eq_817_comb & p1_eq_835_comb & p1_is_inf_b_chk_comb;

  // Registers for pipe stage 1:
  reg [21:0] p1_frac_mult;
  reg [5:0] p1_add_830;
  reg p1_is_inf_a_chk;
  reg p1_is_inf_b_chk;
  reg p1_not_844;
  reg p1_sign_result;
  reg p1_is_nan_result;
  always @ (posedge clk) begin
    p1_frac_mult <= p1_frac_mult_comb;
    p1_add_830 <= p1_add_830_comb;
    p1_is_inf_a_chk <= p1_is_inf_a_chk_comb;
    p1_is_inf_b_chk <= p1_is_inf_b_chk_comb;
    p1_not_844 <= p1_not_844_comb;
    p1_sign_result <= p1_sign_result_comb;
    p1_is_nan_result <= p1_is_nan_result_comb;
  end

  // ===== Pipe stage 2:
  wire p2_leading_bit_comb;
  wire p2_round_bit_comb;
  wire p2_sticky_bit_comb;
  wire [10:0] p2_frac_adjusted_comb;
  wire p2_guard_bit_comb;
  wire [6:0] p2_add_890_comb;
  wire [7:0] p2_concat_894_comb;
  wire p2_round_condition_comb;
  wire [10:0] p2_add_896_comb;
  assign p2_leading_bit_comb = p1_frac_mult[21];
  assign p2_round_bit_comb = p2_leading_bit_comb ? p1_frac_mult[9] : p1_frac_mult[8];
  assign p2_sticky_bit_comb = p1_frac_mult[7:0] != 8'h00;
  assign p2_frac_adjusted_comb = p2_leading_bit_comb ? p1_frac_mult[21:11] : p1_frac_mult[20:10];
  assign p2_guard_bit_comb = p2_leading_bit_comb ? p1_frac_mult[10] : p1_frac_mult[9];
  assign p2_add_890_comb = {1'h0, p1_add_830} + {6'h00, p2_leading_bit_comb};
  assign p2_concat_894_comb = {1'h0, p2_add_890_comb};
  assign p2_round_condition_comb = p2_guard_bit_comb & (p2_round_bit_comb | p2_sticky_bit_comb) | p2_guard_bit_comb & ~p2_round_bit_comb & ~p2_sticky_bit_comb & p2_frac_adjusted_comb[0];
  assign p2_add_896_comb = p2_frac_adjusted_comb + 11'h001;

  // Registers for pipe stage 2:
  reg [10:0] p2_frac_adjusted;
  reg [7:0] p2_concat_894;
  reg p2_round_condition;
  reg [10:0] p2_add_896;
  reg p2_is_inf_a_chk;
  reg p2_is_inf_b_chk;
  reg p2_not_844;
  reg p2_sign_result;
  reg p2_is_nan_result;
  always @ (posedge clk) begin
    p2_frac_adjusted <= p2_frac_adjusted_comb;
    p2_concat_894 <= p2_concat_894_comb;
    p2_round_condition <= p2_round_condition_comb;
    p2_add_896 <= p2_add_896_comb;
    p2_is_inf_a_chk <= p1_is_inf_a_chk;
    p2_is_inf_b_chk <= p1_is_inf_b_chk;
    p2_not_844 <= p1_not_844;
    p2_sign_result <= p1_sign_result;
    p2_is_nan_result <= p1_is_nan_result;
  end

  // ===== Pipe stage 3:
  wire [7:0] p3_add_917_comb;
  wire [10:0] p3_frac_final_pre_comb;
  wire [7:0] p3_sub_920_comb;
  wire [4:0] p3_exp_out_5_comb;
  wire [31:0] p3_frac_final_32_comb;
  wire [8:0] p3_shift_9_comb;
  wire [31:0] p3_frac_subnormal_32_comb;
  wire p3_sign_comb;
  wire [9:0] p3_frac_out_10_comb;
  wire [9:0] p3_frac_subnormal_comb;
  wire p3_nor_937_comb;
  wire p3_is_subnormal_comb;
  wire [14:0] p3_concat_939_comb;
  wire [14:0] p3_concat_940_comb;
  assign p3_add_917_comb = p2_concat_894 + 8'hf1;
  assign p3_frac_final_pre_comb = p2_round_condition ? p2_add_896 : p2_frac_adjusted;
  assign p3_sub_920_comb = 8'h10 - p2_concat_894;
  assign p3_exp_out_5_comb = p3_add_917_comb[4:0];
  assign p3_frac_final_32_comb = {21'h00_0000, p3_frac_final_pre_comb};
  assign p3_shift_9_comb = {{1{p3_sub_920_comb[7]}}, p3_sub_920_comb};
  assign p3_frac_subnormal_32_comb = p3_shift_9_comb >= 9'h020 ? 32'h0000_0000 : p3_frac_final_32_comb >> p3_shift_9_comb;
  assign p3_sign_comb = p3_add_917_comb[7];
  assign p3_frac_out_10_comb = p3_frac_final_pre_comb[9:0];
  assign p3_frac_subnormal_comb = p3_frac_subnormal_32_comb[9:0];
  assign p3_nor_937_comb = ~(p3_sign_comb | ~((|p3_add_917_comb[7:5]) | (&p3_exp_out_5_comb)));
  assign p3_is_subnormal_comb = p3_sign_comb | ~((|p3_add_917_comb[7:1]) | p3_add_917_comb[0]);
  assign p3_concat_939_comb = {p3_exp_out_5_comb, p3_frac_out_10_comb};
  assign p3_concat_940_comb = {5'h00, p3_frac_subnormal_comb};

  // Registers for pipe stage 3:
  reg p3_is_inf_a_chk;
  reg p3_is_inf_b_chk;
  reg p3_nor_937;
  reg p3_is_subnormal;
  reg [14:0] p3_concat_939;
  reg [14:0] p3_concat_940;
  reg p3_not_844;
  reg p3_sign_result;
  reg p3_is_nan_result;
  always @ (posedge clk) begin
    p3_is_inf_a_chk <= p2_is_inf_a_chk;
    p3_is_inf_b_chk <= p2_is_inf_b_chk;
    p3_nor_937 <= p3_nor_937_comb;
    p3_is_subnormal <= p3_is_subnormal_comb;
    p3_concat_939 <= p3_concat_939_comb;
    p3_concat_940 <= p3_concat_940_comb;
    p3_not_844 <= p2_not_844;
    p3_sign_result <= p2_sign_result;
    p3_is_nan_result <= p2_is_nan_result;
  end

  // ===== Pipe stage 4:
  wire p4_is_inf_result_comb;
  wire [15:0] p4_result_comb;
  assign p4_is_inf_result_comb = p3_is_inf_a_chk | p3_is_inf_b_chk | p3_nor_937;
  assign p4_result_comb = p3_is_nan_result ? 16'h7e00 : {p3_sign_result, (p4_is_inf_result_comb ? 15'h7c00 : (p3_is_subnormal ? p3_concat_940 : p3_concat_939)) & {15{p3_not_844}}};

  // Registers for pipe stage 4:
  reg [15:0] p4_result;
  always @ (posedge clk) begin
    p4_result <= p4_result_comb;
  end
  assign out = p4_result;
endmodule
