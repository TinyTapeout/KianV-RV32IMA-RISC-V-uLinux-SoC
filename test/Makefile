# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
#SIM_ARGS=-fst
#SIM ?= verilator
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src

ifneq ($(GATES),yes)

# RTL simulation:
SIM_BUILD				= sim_build/rtl
VERILOG_SOURCES += $(SRC_DIR)/tt_um_kianV_rv32ima_uLinux_SoC.v # $(SRC_DIR)/decoder.v
VERILOG_SOURCES += $(SRC_DIR)/tx_uart.v
VERILOG_SOURCES += $(SRC_DIR)/clint.v
VERILOG_SOURCES += $(SRC_DIR)/spi.v
VERILOG_SOURCES += $(SRC_DIR)/gpio.v
VERILOG_SOURCES += $(SRC_DIR)/rx_uart.v
VERILOG_SOURCES += $(SRC_DIR)/qqspi.v
VERILOG_SOURCES += $(SRC_DIR)/soc.v
VERILOG_SOURCES += $(SRC_DIR)/fifo.v
VERILOG_SOURCES += $(SRC_DIR)/riscv_defines.vh
VERILOG_SOURCES += $(SRC_DIR)/csr_decoder.v
VERILOG_SOURCES += $(SRC_DIR)/misa.vh
VERILOG_SOURCES += $(SRC_DIR)/alu_decoder.v
VERILOG_SOURCES += $(SRC_DIR)/register_file.v
VERILOG_SOURCES += $(SRC_DIR)/design_elements.v
VERILOG_SOURCES += $(SRC_DIR)/riscv_defines.vh
VERILOG_SOURCES += $(SRC_DIR)/main_fsm.v
VERILOG_SOURCES += $(SRC_DIR)/csr_exception_handler.v
VERILOG_SOURCES += $(SRC_DIR)/control_unit.v
VERILOG_SOURCES += $(SRC_DIR)/store_decoder.v
VERILOG_SOURCES += $(SRC_DIR)/datapath_unit.v
VERILOG_SOURCES += $(SRC_DIR)/csr_utilities.vh
VERILOG_SOURCES += $(SRC_DIR)/riscv_priv_csr_status.vh
VERILOG_SOURCES += $(SRC_DIR)/load_decoder.v
VERILOG_SOURCES += $(SRC_DIR)/extend.v
VERILOG_SOURCES += $(SRC_DIR)/rv32_amo_opcodes.vh
VERILOG_SOURCES += $(SRC_DIR)/load_alignment.v
VERILOG_SOURCES += $(SRC_DIR)/mcause.vh
VERILOG_SOURCES += $(SRC_DIR)/kianv_harris_mc_edition.v
VERILOG_SOURCES += $(SRC_DIR)/alu.v
VERILOG_SOURCES += $(SRC_DIR)/store_alignment.v
VERILOG_SOURCES += $(SRC_DIR)/defines_soc.vh

VERILOG_SOURCES += $(SRC_DIR)/divider.v
VERILOG_SOURCES += $(SRC_DIR)/divider_decoder.v
VERILOG_SOURCES += $(SRC_DIR)/multiplier.v
VERILOG_SOURCES += $(SRC_DIR)/multiplier_decoder.v
VERILOG_SOURCES += $(SRC_DIR)/multiplier_extension_decoder.v

else

# Gate level simulation:
SIM_BUILD				= sim_build/gl
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DSIM
VERILOG_SOURCES += $(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_io/verilog/sg13g2_io.v
VERILOG_SOURCES += $(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog/sg13g2_stdcell.v

# this gets copied in by the GDS action workflow
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

# Allow sharing configuration between design and testbench via `include`:
COMPILE_ARGS 		+= -I$(SRC_DIR)

# Include the testbench sources:
VERILOG_SOURCES += $(PWD)/tb.v
VERILOG_SOURCES += $(PWD)/spiflash.v
VERILOG_SOURCES += $(PWD)/psram.v
TOPLEVEL = tb

# MODULE is the basename of the Python test file
MODULE = test

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
