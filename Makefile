# Generic makefile for a iCE40 project, based on the Open Source toolchain
PROJECT=template # TO be overwritten by script
YOSYS?=yosys
NEXTPNR?=nextpnr-ice40 
ICEPROG?=iceprog
ICEPACK?=icepack
IVERILOG?=iverilog
VVP?=vvp

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
SIM_MODULES=sim

# Constraints file
CONSTRAINTS=scripts/constraints/constraints.pcf 

# Sources
SRCS_RTL+=$(wildcard rtl/*.v)
SRCS_SIM+=$(wildcard sim/*.v)

#
# Avoid editing below here
#
LIBDIRS_YOSYS:=$(addprefix -I,$(LIBDIRS))
YOSYS_SRCS_RTL:=$(addsuffix ;,$(SRCS_RTL))
YOSYS_SRCS_RTL:=$(addprefix read_verilog $(LIBDIRS_YOSYS) ,$(YOSYS_SRCS_RTL))
PNR_ARGS=
OUTFILE:=$(strip $(OUTFILE))
RAWSIM_MODULES:=$(SIM_MODULES)
OUTSIM_MODULES:=$(addsuffix .out,$(SIM_MODULES))
OUTSIM_MODULES:=$(addprefix $(BUILD)/,$(OUTSIM_MODULES))
SIM_MODULES:=$(addsuffix .v,$(SIM_MODULES))
SIM_MODULES:=$(addprefix sim/,$(SIM_MODULES))
VCD_FILES:=$(addprefix $(BUILD)/,$(addsuffix .vcd,$(RAWSIM_MODULES)))

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

show_settings:
	@echo "==== General Settings ===="
	@echo PROJECT=$(PROJECT)
	@echo BUILD=$(BUILD)
	@echo OUTFILE=$(OUTFILE)
	@echo DEVICE=$(DEVICE)
	@echo SRCS_RTL=$(SRCS_RTL)
	@echo TOPMOD=$(TOPMOD)
	@echo TOPFILE=$(TOPFILE)
	@echo SIM_MODULES=$(SIM_MODULES)
	@echo PROG_DEVICE=$(PROG_DEVICE)
	@echo "==== Programs ===="
	@echo YOSYS=$(YOSYS)
	@echo NEXTPNR=$(NEXTPNR)
	@echo ICEPACK=$(ICEPACK)
	@echo ICETIME=$(ICETIME)
	@echo IVERILOG=$(IVERILOG)
	@echo VVP=$(VVP)

.PHONY: clean build_dir all show_settings 

# Synthesis step using yosys 
$(BUILD)/$(OUTFILE).json: 
	@echo -e "==== Synthesis With yosys ===="
	@mkdir -p $(BUILD)
	$(YOSYS) -p '$(YOSYS_SRCS_RTL) synth_ice40 -top $(TOPMOD) -json $(BUILD)/$(OUTFILE).json'  

$(BUILD)/modules/%.json: $(SRCS_RTL)
	@mkdir -p $(BUILD)/modules
	$(YOSYS) -p 'read -sv $< ; prep -top $(notdir $(subst .v,,$<)) -flatten ; write_json $@'

$(BUILD)/modules/%.svg: $(BUILD)/modules/%.json
	@mkdir -p $(BUILD)/modules
	netlistsvg $< -o $@

# Generates a schematic for each module in RTL/
schematic: $(addprefix $(BUILD)/modules/,$(notdir $(SRCS_RTL:.v=.svg)))

synthesis: $(BUILD)/$(OUTFILE).json

# Place and route 
$(BUILD)/$(OUTFILE).asc: $(BUILD)/$(OUTFILE).json 
	@echo -e "==== Place & Route With nextpnr-ice40 ===="
	@mkdir -p $(BUILD) 
	$(NEXTPNR) $(PNR_ARGS) --json $(BUILD)/$(OUTFILE).json --pcf $(CONSTRAINTS) \
		--asc $(BUILD)/$(OUTFILE).asc --top $(TOPMOD)

pnr: build_dir $(BUILD)/$(OUTFILE).asc

# Pack into bitstream
$(BUILD)/$(OUTFILE).bin: $(BUILD)/$(OUTFILE).asc 
	@echo -e "==== Bitstream Generation with icepack ===="
	@mkdir -p $(BUILD) 
	$(ICEPACK) $(BUILD)/$(OUTFILE).asc $(BUILD)/$(OUTFILE).bin

# The bitstream itself 
bitstream: build_dir $(BUILD)/$(OUTFILE).bin 

# Program
program: $(BUILD)/$(OUTFILE).bin 
	@mkdir -p $(BUILD) 
	$(ICEPROG) $(BUILD)/$(OUTFILE).bin -d$(PROG_DEVICE)

$(BUILD)/%.out: sim/%.v
	@mkdir -p $(BUILD)
	$(IVERILOG) $(LIBDIRS_YOSYS) -o $@ $< 

$(BUILD)/%.vcd: $(BUILD)/%.out
	@mkdir -p $(BUILD)
	cd $(BUILD) && $(VVP) $(subst $(BUILD)/,,$<)

sim: $(OUTSIM_MODULES) $(VCD_FILES)

# Rule to archive the simulation files 
archive-sim: sim
	@echo -e "==== Archiving simulation files ===="
	tar -cf "$(BUILD)/Simulation-$(shell date +%b-%d-%Y-%I-%m%p).tgz" $(wildcard build/*.vcd)

archive: sim schematic
	@echo -e "==== Archiving files ===="
	tar -cf "$(BUILD)/Simulation-$(shell date +%b-%d-%Y-%I-%m%p).tgz" $(wildcard build/*.vcd) $(wildcard build/modules/*.svg)
