# SPI-Lite Testbench Makefile

# Compiler settings
IVERILOG = iverilog
VVP = vvp
GTKWAVE = gtkwave
VERILATOR = verilator

# Source files
SRC_DIR = ..
SOURCES = $(SRC_DIR)/spi_lite_defs.v $(SRC_DIR)/spi_lite.v spi_lite_tb.v

# Output files
VVP_FILE = spi_lite_tb.vvp
VCD_FILE = spi_lite_tb.vcd

.PHONY: all compile run sim view clean lint

# Default target
all: compile run

# Compile testbench
compile:
	$(IVERILOG) -I$(SRC_DIR) -s spi_lite_tb -o $(VVP_FILE) $(SOURCES)

# Run simulation
run: compile
	$(VVP) -N $(VVP_FILE)

# Compile and run (shortcut)
sim: compile run

# View waveforms
view: $(VCD_FILE)
	$(GTKWAVE) $(VCD_FILE)

# Lint with Verilator
lint:
	$(VERILATOR) --lint-only -Wall $(SRC_DIR)/spi_lite.v

# Clean build artifacts
clean:
	rm -f $(VVP_FILE) $(VCD_FILE)
	rm -rf obj_dir

# Help
help:
	@echo "SPI-Lite Testbench Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all      - Compile and run simulation (default)"
	@echo "  compile  - Compile the testbench"
	@echo "  run      - Run the simulation"
	@echo "  sim      - Compile and run simulation"
	@echo "  view     - Open waveforms in GTKWave"
	@echo "  lint     - Run Verilator lint checks"
	@echo "  clean    - Remove generated files"
	@echo "  help     - Show this help message"
