# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
FST ?= -fst # Use more efficient FST format
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src
PROJECT_SOURCES = tt_um_kianV_rv32ima_uLinux_SoC.v 
PROJECT_SOURCES += tx_uart.v
PROJECT_SOURCES += clint.v
PROJECT_SOURCES += spi.v
PROJECT_SOURCES += gpio.v
PROJECT_SOURCES += rx_uart.v
PROJECT_SOURCES += qqspi.v
PROJECT_SOURCES += soc.v
PROJECT_SOURCES += fifo.v
PROJECT_SOURCES += riscv_defines.vh
PROJECT_SOURCES += csr_decoder.v
PROJECT_SOURCES += misa.vh
PROJECT_SOURCES += alu_decoder.v
PROJECT_SOURCES += register_file.v
PROJECT_SOURCES += design_elements.v
PROJECT_SOURCES += riscv_defines.vh
PROJECT_SOURCES += main_fsm.v
PROJECT_SOURCES += csr_exception_handler.v
PROJECT_SOURCES += control_unit.v
PROJECT_SOURCES += store_decoder.v
PROJECT_SOURCES += datapath_unit.v
PROJECT_SOURCES += csr_utilities.vh
PROJECT_SOURCES += riscv_priv_csr_status.vh
PROJECT_SOURCES += load_decoder.v
PROJECT_SOURCES += extend.v
PROJECT_SOURCES += rv32_amo_opcodes.vh
PROJECT_SOURCES += load_alignment.v
PROJECT_SOURCES += mcause.vh
PROJECT_SOURCES += kianv_harris_mc_edition.v
PROJECT_SOURCES += alu.v
PROJECT_SOURCES += store_alignment.v
PROJECT_SOURCES += defines_soc.vh
PROJECT_SOURCES += divider.v
PROJECT_SOURCES += divider_decoder.v
PROJECT_SOURCES += multiplier.v
PROJECT_SOURCES += multiplier_decoder.v
PROJECT_SOURCES += multiplier_extension_decoder.v


ifneq ($(GATES),yes)

# RTL simulation:
SIM_BUILD				= sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))

else

# Gate level simulation:
SIM_BUILD				= sim_build/gl
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DUSE_POWER_PINS
COMPILE_ARGS    += -DSIM
COMPILE_ARGS    += -DUNIT_DELAY=\#1
VERILOG_SOURCES += $(PDK_ROOT)/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/verilog/gf180mcu_fd_sc_mcu7t5v0.v

# this gets copied in by the GDS action workflow
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

endif

# Allow sharing configuration between design and testbench via `include`:
COMPILE_ARGS 		+= -I$(SRC_DIR)

# Include the testbench sources:
VERILOG_SOURCES += $(PWD)/spiflash.v
VERILOG_SOURCES += $(PWD)/psram.v
VERILOG_SOURCES += $(PWD)/tb.v
TOPLEVEL = tb

# List test modules to run, separated by commas and without the .py suffix:
COCOTB_TEST_MODULES = test

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
