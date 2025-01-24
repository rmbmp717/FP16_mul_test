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
  wire p1_sign_a_comb;
  wire p1_sign_b_comb;
  wire p1_leading_a_comb;
  wire [9:0] p1_frac_a_raw_comb;
  wire p1_leading_b_comb;
  wire [9:0] p1_frac_b_raw_comb;
  wire [5:0] p1_add_827_comb;
  wire p1_eq_830_comb;
  wire p1_eq_831_comb;
  wire p1_sign_result_comb;
  assign p1_exp_a_comb = p0_a[14:10];
  assign p1_exp_b_comb = p0_b[14:10];
  assign p1_eq_817_comb = p1_exp_a_comb == 5'h00;
  assign p1_eq_818_comb = p1_exp_b_comb == 5'h00;
  assign p1_sign_a_comb = p0_a[15];
  assign p1_sign_b_comb = p0_b[15];
  assign p1_leading_a_comb = ~p1_eq_817_comb;
  assign p1_frac_a_raw_comb = p0_a[9:0];
  assign p1_leading_b_comb = ~p1_eq_818_comb;
  assign p1_frac_b_raw_comb = p0_b[9:0];
  assign p1_add_827_comb = {1'h0, p1_exp_a_comb} + {1'h0, p1_exp_b_comb};
  assign p1_eq_830_comb = p1_exp_a_comb == 5'h1f;
  assign p1_eq_831_comb = p1_exp_b_comb == 5'h1f;
  assign p1_sign_result_comb = p1_sign_a_comb ^ p1_sign_b_comb;

  // Registers for pipe stage 1:
  reg p1_eq_817;
  reg p1_eq_818;
  reg p1_leading_a;
  reg [9:0] p1_frac_a_raw;
  reg p1_leading_b;
  reg [9:0] p1_frac_b_raw;
  reg [5:0] p1_add_827;
  reg p1_eq_830;
  reg p1_eq_831;
  reg p1_sign_result;
  always @ (posedge clk) begin
    p1_eq_817 <= p1_eq_817_comb;
    p1_eq_818 <= p1_eq_818_comb;
    p1_leading_a <= p1_leading_a_comb;
    p1_frac_a_raw <= p1_frac_a_raw_comb;
    p1_leading_b <= p1_leading_b_comb;
    p1_frac_b_raw <= p1_frac_b_raw_comb;
    p1_add_827 <= p1_add_827_comb;
    p1_eq_830 <= p1_eq_830_comb;
    p1_eq_831 <= p1_eq_831_comb;
    p1_sign_result <= p1_sign_result_comb;
  end

  // ===== Pipe stage 2:
  wire p2_eq_872_comb;
  wire p2_eq_873_comb;
  wire [21:0] p2_frac_mult_comb;
  wire p2_is_zero_a_comb;
  wire p2_is_zero_b_comb;
  wire p2_is_inf_a_chk_comb;
  wire p2_is_inf_b_chk_comb;
  wire p2_leading_bit_comb;
  wire p2_is_zero_result_comb;
  wire p2_is_nan_comb;
  wire p2_is_nan__1_comb;
  wire p2_round_bit_comb;
  wire p2_sticky_bit_comb;
  wire [10:0] p2_frac_adjusted_comb;
  wire p2_guard_bit_comb;
  wire p2_not_879_comb;
  wire p2_is_nan_result_comb;
  assign p2_eq_872_comb = p1_frac_a_raw == 10'h000;
  assign p2_eq_873_comb = p1_frac_b_raw == 10'h000;
  assign p2_frac_mult_comb = umul22b_11b_x_11b({p1_leading_a, p1_frac_a_raw}, {p1_leading_b, p1_frac_b_raw});
  assign p2_is_zero_a_comb = p1_eq_817 & p2_eq_872_comb;
  assign p2_is_zero_b_comb = p1_eq_818 & p2_eq_873_comb;
  assign p2_is_inf_a_chk_comb = p1_eq_830 & p2_eq_872_comb;
  assign p2_is_inf_b_chk_comb = p1_eq_831 & p2_eq_873_comb;
  assign p2_leading_bit_comb = p2_frac_mult_comb[21];
  assign p2_is_zero_result_comb = p2_is_zero_a_comb | p2_is_zero_b_comb;
  assign p2_is_nan_comb = ~(~p1_eq_830 | p2_eq_872_comb);
  assign p2_is_nan__1_comb = ~(~p1_eq_831 | p2_eq_873_comb);
  assign p2_round_bit_comb = p2_leading_bit_comb ? p2_frac_mult_comb[9] : p2_frac_mult_comb[8];
  assign p2_sticky_bit_comb = p2_frac_mult_comb[7:0] != 8'h00;
  assign p2_frac_adjusted_comb = p2_leading_bit_comb ? p2_frac_mult_comb[21:11] : p2_frac_mult_comb[20:10];
  assign p2_guard_bit_comb = p2_leading_bit_comb ? p2_frac_mult_comb[10] : p2_frac_mult_comb[9];
  assign p2_not_879_comb = ~p2_is_zero_result_comb;
  assign p2_is_nan_result_comb = p2_is_nan_comb | p2_is_nan__1_comb | p2_is_inf_a_chk_comb & p1_eq_818 & p2_eq_873_comb | p1_eq_817 & p2_eq_872_comb & p2_is_inf_b_chk_comb;

  // Registers for pipe stage 2:
  reg p2_leading_bit;
  reg [5:0] p2_add_827;
  reg p2_round_bit;
  reg p2_sticky_bit;
  reg [10:0] p2_frac_adjusted;
  reg p2_guard_bit;
  reg p2_is_inf_a_chk;
  reg p2_is_inf_b_chk;
  reg p2_not_879;
  reg p2_sign_result;
  reg p2_is_nan_result;
  always @ (posedge clk) begin
    p2_leading_bit <= p2_leading_bit_comb;
    p2_add_827 <= p1_add_827;
    p2_round_bit <= p2_round_bit_comb;
    p2_sticky_bit <= p2_sticky_bit_comb;
    p2_frac_adjusted <= p2_frac_adjusted_comb;
    p2_guard_bit <= p2_guard_bit_comb;
    p2_is_inf_a_chk <= p2_is_inf_a_chk_comb;
    p2_is_inf_b_chk <= p2_is_inf_b_chk_comb;
    p2_not_879 <= p2_not_879_comb;
    p2_sign_result <= p1_sign_result;
    p2_is_nan_result <= p2_is_nan_result_comb;
  end

  // ===== Pipe stage 3:
  wire [6:0] p3_add_918_comb;
  wire p3_round_condition_comb;
  wire [10:0] p3_add_924_comb;
  wire [7:0] p3_concat_922_comb;
  wire [10:0] p3_frac_final_pre_comb;
  assign p3_add_918_comb = {1'h0, p2_add_827} + {6'h00, p2_leading_bit};
  assign p3_round_condition_comb = p2_guard_bit & (p2_round_bit | p2_sticky_bit) | p2_guard_bit & ~p2_round_bit & ~p2_sticky_bit & p2_frac_adjusted[0];
  assign p3_add_924_comb = p2_frac_adjusted + 11'h001;
  assign p3_concat_922_comb = {1'h0, p3_add_918_comb};
  assign p3_frac_final_pre_comb = p3_round_condition_comb ? p3_add_924_comb : p2_frac_adjusted;

  // Registers for pipe stage 3:
  reg [7:0] p3_concat_922;
  reg [10:0] p3_frac_final_pre;
  reg p3_is_inf_a_chk;
  reg p3_is_inf_b_chk;
  reg p3_not_879;
  reg p3_sign_result;
  reg p3_is_nan_result;
  always @ (posedge clk) begin
    p3_concat_922 <= p3_concat_922_comb;
    p3_frac_final_pre <= p3_frac_final_pre_comb;
    p3_is_inf_a_chk <= p2_is_inf_a_chk;
    p3_is_inf_b_chk <= p2_is_inf_b_chk;
    p3_not_879 <= p2_not_879;
    p3_sign_result <= p2_sign_result;
    p3_is_nan_result <= p2_is_nan_result;
  end

  // ===== Pipe stage 4:
  wire [7:0] p4_add_942_comb;
  wire [7:0] p4_sub_944_comb;
  wire [4:0] p4_exp_out_5_comb;
  wire [31:0] p4_frac_final_32_comb;
  wire [8:0] p4_shift_9_comb;
  wire [31:0] p4_frac_subnormal_32_comb;
  wire [9:0] p4_frac_out_10_comb;
  wire p4_sign_comb;
  wire p4_nor_956_comb;
  wire p4_nor_957_comb;
  wire [9:0] p4_frac_subnormal_comb;
  wire [14:0] p4_concat_960_comb;
  assign p4_add_942_comb = p3_concat_922 + 8'hf1;
  assign p4_sub_944_comb = 8'h10 - p3_concat_922;
  assign p4_exp_out_5_comb = p4_add_942_comb[4:0];
  assign p4_frac_final_32_comb = {21'h00_0000, p3_frac_final_pre};
  assign p4_shift_9_comb = {{1{p4_sub_944_comb[7]}}, p4_sub_944_comb};
  assign p4_frac_subnormal_32_comb = p4_shift_9_comb >= 9'h020 ? 32'h0000_0000 : p4_frac_final_32_comb >> p4_shift_9_comb;
  assign p4_frac_out_10_comb = p3_frac_final_pre[9:0];
  assign p4_sign_comb = p4_add_942_comb[7];
  assign p4_nor_956_comb = ~((|p4_add_942_comb[7:5]) | (&p4_exp_out_5_comb));
  assign p4_nor_957_comb = ~((|p4_add_942_comb[7:1]) | p4_add_942_comb[0]);
  assign p4_frac_subnormal_comb = p4_frac_subnormal_32_comb[9:0];
  assign p4_concat_960_comb = {p4_exp_out_5_comb, p4_frac_out_10_comb};

  // Registers for pipe stage 4:
  reg p4_sign;
  reg p4_nor_956;
  reg p4_nor_957;
  reg [9:0] p4_frac_subnormal;
  reg p4_is_inf_a_chk;
  reg p4_is_inf_b_chk;
  reg [14:0] p4_concat_960;
  reg p4_not_879;
  reg p4_sign_result;
  reg p4_is_nan_result;
  always @ (posedge clk) begin
    p4_sign <= p4_sign_comb;
    p4_nor_956 <= p4_nor_956_comb;
    p4_nor_957 <= p4_nor_957_comb;
    p4_frac_subnormal <= p4_frac_subnormal_comb;
    p4_is_inf_a_chk <= p3_is_inf_a_chk;
    p4_is_inf_b_chk <= p3_is_inf_b_chk;
    p4_concat_960 <= p4_concat_960_comb;
    p4_not_879 <= p3_not_879;
    p4_sign_result <= p3_sign_result;
    p4_is_nan_result <= p3_is_nan_result;
  end

  // ===== Pipe stage 5:
  wire p5_is_subnormal_comb;
  wire p5_is_inf_result_comb;
  wire [14:0] p5_and_990_comb;
  assign p5_is_subnormal_comb = p4_sign | p4_nor_957;
  assign p5_is_inf_result_comb = p4_is_inf_a_chk | p4_is_inf_b_chk | ~(p4_sign | p4_nor_956);
  assign p5_and_990_comb = (p5_is_inf_result_comb ? 15'h7c00 : (p5_is_subnormal_comb ? {5'h00, p4_frac_subnormal} : p4_concat_960)) & {15{p4_not_879}};

  // Registers for pipe stage 5:
  reg p5_sign_result;
  reg [14:0] p5_and_990;
  reg p5_is_nan_result;
  always @ (posedge clk) begin
    p5_sign_result <= p4_sign_result;
    p5_and_990 <= p5_and_990_comb;
    p5_is_nan_result <= p4_is_nan_result;
  end

  // ===== Pipe stage 6:
  wire [15:0] p6_result_comb;
  assign p6_result_comb = p5_is_nan_result ? 16'h7e00 : {p5_sign_result, p5_and_990};

  // Registers for pipe stage 6:
  reg [15:0] p6_result;
  always @ (posedge clk) begin
    p6_result <= p6_result_comb;
  end
  assign out = p6_result;
endmodule
