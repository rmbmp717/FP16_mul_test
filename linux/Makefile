# Variables
SIM = icarus
COCOTB_DIR = /home/haruhiko/Program/GoogleXLS_test-main/Crc32_Proc/cocotb

# Cocotb simulation
simulate: 
	iverilog -o sim.vvp -D COCOTB_SIM=1 -g2012 fp16_mul.v
	MODULE=fp16_mul_test TOPLEVEL=fp16_multiplier TOPLEVEL_LANG=verilog \
	SIM=$(SIM) vvp -M $(shell cocotb-config --lib-dir) \
		-m libcocotbvpi_icarus sim.vvp
