'''
NISHIHARU
'''
import cocotb
import struct
import random
from cocotb.triggers import Timer

@cocotb.test()
async def FP16_mul_test(dut):
    """Test FP16 multiplier with memory dump at the end."""
    print("==========================================================================")    
    
    # Initialize input values
    dut.a.value = 0
    dut.b.value = 0

    # Wait for some time to simulate initial conditions
    await Timer(100, units="ns")
    # 10回繰り返してテストを実行
    for _ in range(300):
        await fp16_test(dut, random.uniform(-255, 255), random.uniform(-255, 255))

    print("==========================================================================")    

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
    #print(f"value_c: {value_c}")
    
    print(f"A:{value_a:.3f}, \tB:{value_b:.3f}, \tRTL value: {real_value:.3f}, \tValue_c: {value_c:.3f}")
    if abs(real_value - value_c) > 0.005 * abs(real_value):
        print("Warning: Difference between RTL value and calculated value exceeds 0.5 %")
    
    print(f"A:{value_a:.3f}, \tB:{value_b:.3f}, \tRTL value: {real_value:.3f}, \tValue_c: {value_c:.3f}")

async def fp16_mul(dut, fp_a, fp_b):
    dut.a.value = fp_a
    dut.b.value = fp_b
    await Timer(100, units="ns")
    # Read and print the result
    result = dut.result.value.to_unsigned()
    #print(f"RTL: mul result = {result}")
    return result

def float_to_fp16(value):
    # Convert to 32-bit float representation
    packed = struct.pack('>f', value)
    int_rep = struct.unpack('>I', packed)[0]

    # Extract sign, exponent, and mantissa
    sign = (int_rep >> 31) & 0x1
    exp = (int_rep >> 23) & 0xFF
    mantissa = int_rep & 0x7FFFFF

    # Convert to 16-bit floating point
    if exp == 0:  # Zero or subnormal
        exp_fp16 = 0
        mantissa_fp16 = 0
    elif exp == 0xFF:  # Inf or NaN
        exp_fp16 = 0x1F
        mantissa_fp16 = (mantissa != 0) * 0x200  # NaN has a non-zero mantissa
    else:
        exp_fp16 = max(0, min(0x1F, exp - 127 + 15))
        mantissa_fp16 = mantissa >> 13

    # Assemble 16-bit result
    fp16 = (sign << 15) | (exp_fp16 << 10) | mantissa_fp16
    return fp16

def fp16_to_float(fp16):
    # Extract sign, exponent, and mantissa from 16-bit representation
    sign = (fp16 >> 15) & 0x1
    exp = (fp16 >> 10) & 0x1F
    mantissa = fp16 & 0x3FF

    if exp == 0:  # Zero or subnormal
        if mantissa == 0:
            return (-1)**sign * 0.0
        else:
            return (-1)**sign * (mantissa / 2**10) * 2**(-14)
    elif exp == 0x1F:  # Inf or NaN
        if mantissa == 0:
            return float('inf') if sign == 0 else float('-inf')
        else:
            return float('nan')
    else:
        return (-1)**sign * (1 + mantissa / 2**10) * 2**(exp - 15)