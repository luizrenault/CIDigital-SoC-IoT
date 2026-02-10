# Makefile for Timer Peripheral Testbench
# Based on SPI testbench Makefile structure

# Compiler settings
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave
VERILATOR = verilator

# Source files
SRC_DIR = ..
SOURCES = $(SRC_DIR)/timer_defs.v $(SRC_DIR)/timer.v timer_tb.v

# Output files
VVP_FILE = timer_tb.vvp
VCD_FILE = timer_tb.vcd

# Default target
.PHONY: all compile run sim view clean lint help

all: sim

# Compile testbench
compile:
	@echo "Compiling timer testbench..."
	$(IVERILOG) -I$(SRC_DIR) -s timer_tb -o $(VVP_FILE) $(SOURCES)
	@echo "Compilation complete."

# Run simulation
run: compile
	@echo "Running simulation..."
	$(VVP) $(VVP_FILE)
	@echo "Simulation complete."

# Compile and run
sim: run

# View waveforms
view:
	@echo "Opening GTKWave..."
	$(GTKWAVE) $(VCD_FILE) &

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -f $(VVP_FILE) $(VCD_FILE)
	@echo "Clean complete."

# Run linter
lint:
	@echo "Running Verilator lint..."
	$(VERILATOR) --lint-only -Wall $(SRC_DIR)/timer.v
	@echo "Lint complete."

# Help
help:
	@echo "Timer Peripheral Testbench Makefile"
	@echo "===================================="
	@echo ""
	@echo "Targets:"
	@echo "  all      - Compile and run simulation (default)"
	@echo "  compile  - Compile testbench only"
	@echo "  run      - Run simulation (compiles if needed)"
	@echo "  sim      - Compile and run simulation"
	@echo "  view     - Open waveforms in GTKWave"
	@echo "  clean    - Remove build artifacts"
	@echo "  lint     - Run Verilator lint"
	@echo "  help     - Show this help message"
	@echo ""
	@echo "Files:"
	@echo "  Source:   $(SOURCES)"
	@echo "  Output:   $(VVP_FILE), $(VCD_FILE)"
