module tb_fp16_multiplier;
    reg [15:0] a, b;
    wire [15:0] result;

    fp16_multiplier uut (
        .a(a),
        .b(b),
        .result(result)
    );

endmodule
