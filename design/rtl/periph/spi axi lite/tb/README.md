# SPI-Lite Testbench

## Overview

This directory contains the testbench for the SPI-Lite peripheral validation.

## Files

- `spi_lite_tb.v` - Main testbench file with comprehensive test scenarios

## Test Scenarios

The testbench includes the following test cases:

1. **Reset Verification** - Validates hardware reset values
2. **Register Access** - Tests read/write operations on all registers
3. **Basic SPI Transfer** - Loopback mode single byte transfer
4. **FIFO Operation** - Tests 4-entry TX/RX FIFOs
5. **SPI Modes** - All 4 CPOL/CPHA combinations
6. **Bit Order** - MSB-first and LSB-first transmission
7. **Chip Select** - Manual chip select control
8. **Interrupts** - TX empty interrupt generation and clearing
9. **Software Reset** - Software reset functionality

## Running the Testbench

### With Icarus Verilog (free)

```bash
cd design/rtl/periph/spi\ axi\ lite/tb
iverilog -I.. -s spi_lite_tb -o spi_lite_tb.vvp ../spi_lite_defs.v ../spi_lite.v spi_lite_tb.v
vvp -N spi_lite_tb.vvp
```

### With Verilator (free, for linting)

```bash
cd design/rtl/periph/spi\ axi\ lite/tb
verilator --lint-only -Wall ../spi_lite.v
```

### With Commercial Simulators

**VCS:**
```bash
cd design/rtl/periph/spi\ axi\ lite/tb
vcs -full64 -sverilog -debug_access+all spi_lite_tb.v ../spi_lite.v ../spi_lite_defs.v
./simv
```

**Questa/ModelSim:**
```bash
cd design/rtl/periph/spi\ axi\ lite/tb
vlib work
vlog -sv ../spi_lite_defs.v ../spi_lite.v spi_lite_tb.v
vsim -c spi_lite_tb -do "run -all"
```

**Xcelium:**
```bash
cd design/rtl/periph/spi\ axi\ lite/tb
xrun -sv -access +rwc spi_lite_tb.v ../spi_lite.v ../spi_lite_defs.v
```

## Waveform Viewing

After simulation, open the VCD file with GTKWave:

```bash
gtkwave spi_lite_tb.vcd
```

## Key Signals to Monitor

- `spi_clk_o` - SPI clock output
- `spi_mosi_o` - Master Out Slave In
- `spi_cs_o` - Chip select outputs
- `intr_o` - Interrupt output
- `cfg_*` - AXI4-Lite interface signals

## Expected Results

All 30 tests should pass:

```
==============================================
      SPI-Lite Peripheral Testbench
==============================================

=== Test 1: Reset Verification ===
PASS: Reset: TX_EMPTY and RX_EMPTY set ...
...

==============================================
              Test Summary
==============================================
Passed: 30
Failed: 0

*** ALL TESTS PASSED ***
==============================================
```

## Notes

- Default clock period: 10ns (100MHz)
- Default SPI clock ratio: 32 (16 clocks per bit, 128 clocks per byte)
- Simulation timeout: 1ms
