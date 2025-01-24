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
  wire [21:0] p1_frac_mult_comb;
  wire p1_leading_bit_comb;
  wire [5:0] p1_add_838_comb;
  wire p1_round_bit_comb;
  wire p1_sticky_bit_comb;
  wire [10:0] p1_frac_adjusted_comb;
  wire p1_eq_863_comb;
  wire p1_eq_864_comb;
  wire p1_eq_865_comb;
  wire p1_eq_866_comb;
  wire p1_guard_bit_comb;
  wire p1_is_zero_a_comb;
  wire p1_is_zero_b_comb;
  wire p1_is_inf_a_chk_comb;
  wire p1_is_inf_b_chk_comb;
  wire [6:0] p1_add_852_comb;
  wire p1_is_zero_result_comb;
  wire p1_sign_a_comb;
  wire p1_sign_b_comb;
  wire p1_is_nan_comb;
  wire p1_is_nan__1_comb;
  wire [7:0] p1_concat_856_comb;
  wire p1_round_condition_comb;
  wire [10:0] p1_add_858_comb;
  wire p1_not_872_comb;
  wire p1_sign_result_comb;
  wire p1_is_nan_result_comb;
  assign p1_exp_a_comb = p0_a[14:10];
  assign p1_exp_b_comb = p0_b[14:10];
  assign p1_eq_817_comb = p1_exp_a_comb == 5'h00;
  assign p1_eq_818_comb = p1_exp_b_comb == 5'h00;
  assign p1_leading_a_comb = ~p1_eq_817_comb;
  assign p1_frac_a_raw_comb = p0_a[9:0];
  assign p1_leading_b_comb = ~p1_eq_818_comb;
  assign p1_frac_b_raw_comb = p0_b[9:0];
  assign p1_frac_mult_comb = umul22b_11b_x_11b({p1_leading_a_comb, p1_frac_a_raw_comb}, {p1_leading_b_comb, p1_frac_b_raw_comb});
  assign p1_leading_bit_comb = p1_frac_mult_comb[21];
  assign p1_add_838_comb = {1'h0, p1_exp_a_comb} + {1'h0, p1_exp_b_comb};
  assign p1_round_bit_comb = p1_leading_bit_comb ? p1_frac_mult_comb[9] : p1_frac_mult_comb[8];
  assign p1_sticky_bit_comb = p1_frac_mult_comb[7:0] != 8'h00;
  assign p1_frac_adjusted_comb = p1_leading_bit_comb ? p1_frac_mult_comb[21:11] : p1_frac_mult_comb[20:10];
  assign p1_eq_863_comb = p1_frac_a_raw_comb == 10'h000;
  assign p1_eq_864_comb = p1_frac_b_raw_comb == 10'h000;
  assign p1_eq_865_comb = p1_exp_a_comb == 5'h1f;
  assign p1_eq_866_comb = p1_exp_b_comb == 5'h1f;
  assign p1_guard_bit_comb = p1_leading_bit_comb ? p1_frac_mult_comb[10] : p1_frac_mult_comb[9];
  assign p1_is_zero_a_comb = p1_eq_817_comb & p1_eq_863_comb;
  assign p1_is_zero_b_comb = p1_eq_818_comb & p1_eq_864_comb;
  assign p1_is_inf_a_chk_comb = p1_eq_865_comb & p1_eq_863_comb;
  assign p1_is_inf_b_chk_comb = p1_eq_866_comb & p1_eq_864_comb;
  assign p1_add_852_comb = {1'h0, p1_add_838_comb} + {6'h00, p1_leading_bit_comb};
  assign p1_is_zero_result_comb = p1_is_zero_a_comb | p1_is_zero_b_comb;
  assign p1_sign_a_comb = p0_a[15];
  assign p1_sign_b_comb = p0_b[15];
  assign p1_is_nan_comb = ~(~p1_eq_865_comb | p1_eq_863_comb);
  assign p1_is_nan__1_comb = ~(~p1_eq_866_comb | p1_eq_864_comb);
  assign p1_concat_856_comb = {1'h0, p1_add_852_comb};
  assign p1_round_condition_comb = p1_guard_bit_comb & (p1_round_bit_comb | p1_sticky_bit_comb) | p1_guard_bit_comb & ~p1_round_bit_comb & ~p1_sticky_bit_comb & p1_frac_adjusted_comb[0];
  assign p1_add_858_comb = p1_frac_adjusted_comb + 11'h001;
  assign p1_not_872_comb = ~p1_is_zero_result_comb;
  assign p1_sign_result_comb = p1_sign_a_comb ^ p1_sign_b_comb;
  assign p1_is_nan_result_comb = p1_is_nan_comb | p1_is_nan__1_comb | p1_is_inf_a_chk_comb & p1_eq_818_comb & p1_eq_864_comb | p1_eq_817_comb & p1_eq_863_comb & p1_is_inf_b_chk_comb;

  // Registers for pipe stage 1:
  reg [10:0] p1_frac_adjusted;
  reg [7:0] p1_concat_856;
  reg p1_round_condition;
  reg [10:0] p1_add_858;
  reg p1_is_inf_a_chk;
  reg p1_is_inf_b_chk;
  reg p1_not_872;
  reg p1_sign_result;
  reg p1_is_nan_result;
  always @ (posedge clk) begin
    p1_frac_adjusted <= p1_frac_adjusted_comb;
    p1_concat_856 <= p1_concat_856_comb;
    p1_round_condition <= p1_round_condition_comb;
    p1_add_858 <= p1_add_858_comb;
    p1_is_inf_a_chk <= p1_is_inf_a_chk_comb;
    p1_is_inf_b_chk <= p1_is_inf_b_chk_comb;
    p1_not_872 <= p1_not_872_comb;
    p1_sign_result <= p1_sign_result_comb;
    p1_is_nan_result <= p1_is_nan_result_comb;
  end

  // ===== Pipe stage 2:
  wire [7:0] p2_add_903_comb;
  wire [10:0] p2_frac_final_pre_comb;
  wire [7:0] p2_sub_906_comb;
  wire [4:0] p2_exp_out_5_comb;
  wire [31:0] p2_frac_final_32_comb;
  wire [8:0] p2_shift_9_comb;
  wire [31:0] p2_frac_subnormal_32_comb;
  wire p2_sign_comb;
  wire [9:0] p2_frac_out_10_comb;
  wire [9:0] p2_frac_subnormal_comb;
  wire p2_is_subnormal_comb;
  wire p2_is_inf_result_comb;
  wire [15:0] p2_concat_933_comb;
  wire [15:0] p2_result_comb;
  assign p2_add_903_comb = p1_concat_856 + 8'hf1;
  assign p2_frac_final_pre_comb = p1_round_condition ? p1_add_858 : p1_frac_adjusted;
  assign p2_sub_906_comb = 8'h10 - p1_concat_856;
  assign p2_exp_out_5_comb = p2_add_903_comb[4:0];
  assign p2_frac_final_32_comb = {21'h00_0000, p2_frac_final_pre_comb};
  assign p2_shift_9_comb = {{1{p2_sub_906_comb[7]}}, p2_sub_906_comb};
  assign p2_frac_subnormal_32_comb = p2_shift_9_comb >= 9'h020 ? 32'h0000_0000 : p2_frac_final_32_comb >> p2_shift_9_comb;
  assign p2_sign_comb = p2_add_903_comb[7];
  assign p2_frac_out_10_comb = p2_frac_final_pre_comb[9:0];
  assign p2_frac_subnormal_comb = p2_frac_subnormal_32_comb[9:0];
  assign p2_is_subnormal_comb = p2_sign_comb | ~((|p2_add_903_comb[7:1]) | p2_add_903_comb[0]);
  assign p2_is_inf_result_comb = p1_is_inf_a_chk | p1_is_inf_b_chk | ~(p2_sign_comb | ~((|p2_add_903_comb[7:5]) | (&p2_exp_out_5_comb)));
  assign p2_concat_933_comb = {p1_sign_result, (p2_is_inf_result_comb ? 15'h7c00 : (p2_is_subnormal_comb ? {5'h00, p2_frac_subnormal_comb} : {p2_exp_out_5_comb, p2_frac_out_10_comb})) & {15{p1_not_872}}};
  assign p2_result_comb = p1_is_nan_result ? 16'h7e00 : p2_concat_933_comb;

  // Registers for pipe stage 2:
  reg [15:0] p2_result;
  always @ (posedge clk) begin
    p2_result <= p2_result_comb;
  end
  assign out = p2_result;
endmodule
