module tb_fp16_multiplier;
    reg [15:0] a, b;
    wire [15:0] result;

    fp16_multiplier uut (
        .a(a),
        .b(b),
        .result(result)
    );

    initial begin
        // 波形ダンプ設定
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_fp16_multiplier);
    end

    
    initial begin
        #21
        $monitor("Time: %0t | A: 0x%h | B: 0x%h | exp_sum: 0x%h | frac_mult: 0x%h | guard_bit: 0x%h | round_bit: 0x%h | sticky_bit: 0x%h | frac_adjusted: 0x%h | frac_final_tmp: 0x%h | frac_final: 0x%h | exp_adjusted: 0x%h | Result: 0x%h",
                 $time, a, b, uut.exp_sum, uut.frac_mult, uut.guard_bit, uut.round_bit, uut.sticky_bit, uut.frac_adjusted, uut.frac_final_tmp, uut.frac_final, uut.exp_adjusted, result);
    end
    

endmodule

