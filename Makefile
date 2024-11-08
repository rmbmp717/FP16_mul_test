TOPLEVEL_LANG = verilog
VERILOG_SOURCES  = $(PWD)/fp16_mul.v 
VERILOG_SOURCES += $(PWD)/fp16_mul_test.v
COCOTB_TOPLEVEL  = tb_fp16_multiplier
COCOTB_TEST_MODULES = fp16_mul_test  # Pythonテストモジュール名
SIM=icarus

include $(shell cocotb-config --makefiles)/Makefile.sim

# 最初にmake cleanをする！
