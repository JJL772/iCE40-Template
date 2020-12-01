# Generic makefile for a iCE40 project, based on the Open Source toolchain
PROJECT=template # TO be overwritten by script
YOSYS?=yosys
NEXTPNR?=nextpnr-ice40 
ICEPROG?=iceprog
ICEPACK?=icepack

# Libdirs, feel free to add more to this
LIBDIRS+=$(shell find rtl -type d) $(shell find sim -type d) 
# Output file/build dir
OUTFILE=$(PROJECT)
BUILD=build

# Device you're targeting
DEVICE=ICE40LP384 

# Device to program
PROG_DEVICE=

# TOP file to be programmed to the board
TOPFILE=src/rtl/top.v 
TOPMOD=top

# TOP file for the simulation
TOPSIM=src/sim/sim.v 

# Constraints file
CONSTRAINTS=constraints.pcf 

# Sources
SRCS_RTL+=$(wildcard rtl/*.v)

#
# Avoid editing below here
#
LIBDIRS_YOSYS:=$(addprefix -I,$(LIBDIRS))
YOSYS_SRCS_RTL:=$(addsuffix ;,$(SRCS_RTL))
YOSYS_SRCS_RTL:=$(addprefix read_verilog $(LIBDIRS_YOSYS) ,$(YOSYS_SRCS_RTL))
PNR_ARGS=
OUTFILE:=$(strip $(OUTFILE))

ifeq ($(DEVICE),ICE40LP384)
	PNR_ARGS=--lp384 
else ifeq ($(DEVICE),ICE40LP1K)
	PNR_ARGS=--lp1k 
else ifeq ($(DEVICE),ICE40LP4K)
	PNR_ARGS=--lp4k 
else ifeq ($(DEVICE),ICE40LP8K)
	PNR_ARGS=--lp8k 
else ifeq ($(DEVICE),ICE40HX1K)
	PNR_ARGS=--hx1k 
else ifeq ($(DEVICE),ICE40HX4K)
	PNR_ARGS=--hx4k 
else ifeq ($(DEVICE),ICE40HX8K)
	PNR_ARGS=--hx8k 
else ifeq ($(DEVICE),ICE40UP3K)
	PNR_ARGS=--up3k 
else ifeq ($(DEVICE),ICE40UP5K)
	PNR_ARGS=--up5k 
else ifeq ($(DEVICE),ICE5LP1K)
	PNR_ARGS=--u1k 
else ifeq ($(DEVICE),ICE5LP2K)
	PNR_ARGS=--u2k
else ifeq ($(DEVICE),ICE5LP4K)
	PNR_ARGS=--u4k
endif 

#
# Rules 
#
all: bitstream

clean:
	rm -rf build 

build_dir:
	mkdir -p build 

.PHONY: clean build_dir all 

# Synthesis step using yosys 
$(BUILD)/$(OUTFILE).json: 
	echo -e "==== Synthesis With yosys ===="
	$(YOSYS) -p '$(YOSYS_SRCS_RTL) synth_ice40 -top $(TOPMOD) -json $(BUILD)/$(OUTFILE).json'  

# Place and route 
$(BUILD)/$(OUTFILE).asc: $(BUILD)/$(OUTFILE).json 
	echo -e "==== Place & Route With nextpnr-ice40 ===="
	$(NEXTPNR) $(PNR_ARGS) --json $(BUILD)/$(OUTFILE).json --pcf $(CONSTRAINTS) \
		--asc $(BUILD)/$(OUTFILE).asc --top $(TOPMOD)

# Pack into bitstream
$(BUILD)/$(OUTFILE).bin: $(BUILD)/$(OUTFILE).asc 
	echo -e "==== Bitstream Generation with icepack ===="
	$(ICEPACK) $(BUILD)/$(OUTFILE).asc $(BUILD)/$(OUTFILE).bin

# The bitstream itself 
bitstream: build_dir $(BUILD)/$(OUTFILE).bin 

# Program
program: $(BUILD)/$(OUTFILE).bin 
	$(ICEPROG) $(BUILD)/$(OUTFILE).bin -d$(PROG_DEVICE)

