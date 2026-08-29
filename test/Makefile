# Makefile
# See https://cocotb.org for more info

# defaults
SIM ?= icarus
FST ?= -fst # Use more efficient FST format
FST ?= -fst
TOPLEVEL_LANG ?= verilog
SRC_DIR = $(PWD)/../src
PROJECT_SOURCES = project.v

ifneq ($(GATES),yes)

# RTL simulation:
SIM_BUILD				= sim_build/rtl
# RTL simulation target path
SIM_BUILD = sim_build/rtl
VERILOG_SOURCES += $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES))

else

# Gate level simulation:
SIM_BUILD				= sim_build/gl
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DSIM
COMPILE_ARGS    += -s tb
COMPILE_ARGS    += -gno-specify

# AUTOMATED AUTOMATION FIX:
# Copy the IHP library file locally and use sed to strip the unsupported "ifnone" timing lines
# before iverilog parses it. This completely bypasses the simulator bugs.
IHP_CELL_SRC = $(PDK_ROOT)/ihp-sg13g2/libs.ref/sg13g2_stdcell/verilog/sg13g2_stdcell.v
LOCAL_CELL_SRC = $(PWD)/sg13g2_stdcell_patched.v

# Insert pre-compilation rule to patch the IHP cells file
_patch_ihp_lib:
	@cp $(IHP_CELL_SRC) $(LOCAL_CELL_SRC)
	@sed -i '/ifnone.*edge-sensitive/d' $(LOCAL_CELL_SRC)
	@sed -i '/ifnone.*=>/d' $(LOCAL_CELL_SRC)

VERILOG_SOURCES += $(LOCAL_CELL_SRC)
VERILOG_SOURCES += $(PWD)/gate_level_netlist.v

# Hook the patch step into the simulation compilation dependency tree
sim_build/gl/sim.vvp: _patch_ihp_lib

endif

# Allow sharing configuration between design and testbench via `include`:
COMPILE_ARGS 		+= -I$(SRC_DIR)

# Include the testbench sources:
COMPILE_ARGS += -I$(SRC_DIR)
VERILOG_SOURCES += $(PWD)/tb.v
TOPLEVEL = tb

# List test modules to run, separated by commas and without the .py suffix:
COCOTB_TEST_MODULES = test

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim

# Ensure patched files are removed during make clean execution blocks
clean::
	rm -f $(PWD)/sg13g2_stdcell_patched.v
