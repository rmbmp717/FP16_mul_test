'''
NISHIHARU
'''
import cocotb
import struct
import random
from cocotb.triggers import Timer, RisingEdge

async def generate_clock(dut, period=10):
    """Generate a clock on dut.clk with the given period in ns."""
    while True:
        dut.clk.value = 0
        await Timer(period // 2, units="ns")
        dut.clk.value = 1
        await Timer(period // 2, units="ns")

@cocotb.test()
async def FP16_mul_test(dut):
    """Test FP16 multiplier with memory dump at the end."""
    print("==========================================================================")    

    # Start clock generation
    #cocotb.start_soon(generate_clock(dut))
    
    # Initialize input values
    dut.a.value = 0
    dut.b.value = 0
    
    # fp16_libのテスト
    # n回繰り返してテストを実行
    print("fp16_lib test.")
    for _ in range(100000):
        x = random.uniform(-255, 255)
        fp16_x = float_to_fp16(x)
        float_x = fp16_to_float(fp16_x)
        if abs(x-float_x)/x > 0.001 and x > 0.0001 :
            print(f"Err. x = {x:.04f}")
            
    print("==========================================================================")    
    # Wait for some time to simulate initial conditions
    await Timer(10, units="ns")
    # n回繰り返してテストを実行
    print("fp16_mul.v test.")
    
    for _ in range(300000):
        if _ % 10000 == 0:
            print("times=", _)
        #await Timer(10, units="ns")
        await fp16_test(dut, random.uniform(-0.255, 0.255), random.uniform(-0.255, 0.255))
        await fp16_test(dut, random.uniform(-255, 255), random.uniform(-255, 255))
    
    #await fp16_test(dut, 0.1, 0.1)
    await fp16_test(dut, 0.172854, 0.180827)
    
    print("==========================================================================")   
    await Timer(100, units="ns") 

    # Further tests can be added here with different input values and checks
    
async def fp16_test(dut, real_a, real_b):

    # Test with a
    value_a = real_a
    fp16_result_a = float_to_fp16(value_a)
    #print(f"{real_a} in FP16: {fp16_result_a:016b}")
    
    # Convert back to float
    real_value = fp16_to_float(fp16_result_a)
    #print(f"Converted back to float: {real_value}")
    
    # Test with b
    value_b = real_b
    fp16_result_b = float_to_fp16(value_b)
    #print(f"{real_b} in FP16: {fp16_result_b:016b}")
    
    # Convert back to float
    real_value = fp16_to_float(fp16_result_b)
    #print(f"Converted back to float: {real_value}")

    # RTL Sim Start
    # Perform test cases
    fp16_verilog_result = await fp16_mul(dut, fp16_result_a, fp16_result_b)
    
    # Convert back to float
    real_value = fp16_to_float(fp16_verilog_result)
    #print(f"RTL: Converted back to float: {real_value}")
    
    # Check Value
    value_c = value_a * value_b
    #await Timer(1, units="ns")
    fp16_value_c = float_to_fp16(value_c)
    #print(f"value_c: {value_c}")
    
    #print(f"A:{value_a:.5f}, \tB:{value_b:.5f}, \tRTL value: {real_value:.8f}, \t\tValue_c: {value_c:.8f}")
    #print(f"A:0x{fp16_result_a:04X}, \tB:0x{fp16_result_b:04X}, \tRTL value: 0x{fp16_verilog_result:04X}, \tValue_c: 0x{fp16_value_c:04X}")
    if abs(real_value - value_c) > 0.01 * abs(real_value) and abs(real_value)>0.000001 :
        print(f"A:{value_a:.6f}, \tB:{value_b:.6f}, \tRTL value: {real_value:.8f}, \tValue_c: {value_c:.8f}")
        print(f"A:0x{fp16_result_a:04X}, \tB:0x{fp16_result_b:04X}, \tRTL value: 0x{fp16_verilog_result:04X}, \tValue_c: 0x{fp16_value_c:04X}")
        print(f"Err rate : {value_c/real_value:.3f}")
        print(f"float->fp16->float: {fp16_to_float(fp16_result_a)}")
        print(f"float->fp16->float: {fp16_to_float(fp16_result_b)}")
        print("Warning: Difference between RTL value and calculated value exceeds 1.0 %")
    
async def fp16_mul(dut, fp_a, fp_b):
    dut.a.value = fp_a
    dut.b.value = fp_b
    await Timer(100, units="ns")
    # Read and print the result
    bin_str = dut.out.value.binstr  # 'binstr' は '0', '1', 'x', 'z' が含まれる
    bin_str_sanitized = bin_str.replace('x', '0').replace('z', '0')
    result = int(bin_str_sanitized, 2)  # 修正点
    #print(f"RTL: mul result = {result}")
    return result

import struct

def float_to_fp16(value):
    # Convert Python float to 32-bit float bits
    packed = struct.pack('>f', value)  
    int_rep = struct.unpack('>I', packed)[0]

    # Extract sign, exponent, mantissa (from 32-bit float)
    sign = (int_rep >> 31) & 0x1
    exp  = (int_rep >> 23) & 0xFF  # 0..255
    mantissa = int_rep & 0x7FFFFF  # 23 bits

    # Target: 16-bit (sign, 5-bit exp, 10-bit frac)
    if exp == 0:  # 32-bit float: 0 or subnormal
        # → FP16側でも ゼロ として処理 (細かい subnormal処理は省略)
        exp_fp16 = 0
        mantissa_fp16 = 0
    elif exp == 0xFF:  # 32-bit float: Inf or NaN
        exp_fp16 = 0x1F
        # NaN → mantissa != 0 なら FP16の 仮数先頭ビット=1 (例:0x200)
        # Inf → mantissa=0 の場合
        mantissa_fp16 = 0x200 if (mantissa != 0) else 0
    else:
        # 通常の正規化領域
        # FP16の指数 = (exp - 127) + 15
        e = exp - 127 + 15
        if e >= 0x1F:
            # 32bit exponentが大きすぎ → FP16だと Inf に飽和
            exp_fp16 = 0x1F
            mantissa_fp16 = 0  # Infinity
        elif e <= 0:
            # eが0以下 → サブノーマル/ゼロに… ここでは簡単に 0
            exp_fp16 = 0
            mantissa_fp16 = 0
        else:
            # 0 < e < 31 → 正規化
            exp_fp16 = e
            mantissa_fp16 = mantissa >> 13  # 上位10ビット

    # 組み立て
    fp16 = (sign << 15) | (exp_fp16 << 10) | (mantissa_fp16 & 0x3FF)
    return fp16

def fp16_to_float(fp16):
    """
    IEEE 754 half-float (16bit) を Python の float (32/64bit) に復元する。

    引数:
      fp16 (int): 16bit の半精度浮動小数点表現 (0x0000 ~ 0xFFFF)

    戻り値:
      float: Python 標準の倍精度 float (IEEE 754 64bit) に変換した値
    """
    import math

    # 1. 16bit から sign(1bit), exponent(5bit), fraction(10bit) を抽出
    sign = (fp16 >> 15) & 0x1
    exp = (fp16 >> 10) & 0x1F
    mantissa = fp16 & 0x3FF

    # 2. 符号を決定
    sign_factor = -1.0 if sign else 1.0

    # 3. 特殊ケース
    if exp == 0:
        # ゼロ or サブノーマル
        if mantissa == 0:
            # +0.0 or -0.0
            return sign_factor * 0.0
        else:
            # サブノーマル: 指数部は 2^(-14) (隠しビット=0 で mantissa/2^10)
            #   参考: exponent=0 の half-float は実指数=-14, 正規仮数= 0.(mantissa)
            return sign_factor * (mantissa / 2**10) * (2**-14)

    elif exp == 0x1F:
        # Infinity or NaN
        if mantissa == 0:
            # Inf
            return math.inf if sign == 0 else -math.inf
        else:
            # NaN
            return math.nan
    else:
        # 通常(正規化数)
        #   実指数 = exp - バイアス(15)
        #   仮数 = 1.(mantissa/2^10)
        real_exp = exp - 15
        real_frac = 1.0 + (mantissa / 2**10)
        return sign_factor * real_frac * (2**real_exp)
