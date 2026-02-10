# Timer Peripheral Testbench

Comprehensive testbench for the Timer peripheral with prescaler and postscaler support.

## Overview

This testbench follows the same structure and style as the SPI peripheral testbench, providing:
- AXI4-Lite interface testing
- Register read/write verification
- Timer functionality validation
- Interrupt generation testing
- Status flag verification

## Test Scenarios

1. **Reset Verification**: Verifies all registers reset to correct default values
2. **Register Access**: Tests read/write access to all timer registers
3. **Basic Timer Operation**: One-shot mode, counts to match and stops
4. **Auto-Reload Mode**: Periodic timer operation with automatic counter reset
5. **Prescaler Functionality**: Clock division before counter increment
6. **Postscaler Functionality**: IRQ generation rate division
7. **Interrupt Generation**: Tests interrupt enable/disable and clearing
8. **Status Register W1C**: Write-1-to-clear behavior for status flags
9. **Combined Scaling**: Prescaler and postscaler working together
10. **Manual Counter Load**: Loading arbitrary values into counter while running

## Build and Run

### Compile and Simulate
```bash
make sim
```

### View Waveforms
```bash
make view
```

### Run Linter
```bash
make lint
```

### Clean Build Files
```bash
make clean
```

## Testbench Architecture

### Helper Tasks

- `reset_dut`: Initialize and reset the DUT
- `axi_write`: Perform AXI4-Lite write transaction
- `axi_read`: Perform AXI4-Lite read transaction
- `write_reg`: Register-level write helper
- `read_reg`: Register-level read helper
- `check_result`: Assertion with pass/fail tracking
- `wait_for_interrupt`: Wait for interrupt with timeout
- `wait_for_match_pending`: Poll status for match flag
- `clear_status`: Clear status flags (W1C)

### Pass/Fail Tracking

The testbench tracks:
- `pass_count`: Number of successful assertions
- `fail_count`: Number of failed assertions
- `test_num`: Current test number

Final summary displays total passed/failed counts.

## Timer Registers

| Register | Address | Description |
|----------|---------|-------------|
| TIMER_CTRL0 | 0x08 | Control: IRQ_EN, ENABLE, AUTORELOAD |
| TIMER_CMP0 | 0x0C | Compare value |
| TIMER_VAL0 | 0x10 | Current counter value |
| TIMER_PRESCALE0 | 0x20 | Prescaler divider (N) |
| TIMER_POSTSCALE0 | 0x24 | Postscaler divider (M) |
| TIMER_STATUS0 | 0x28 | Status: MATCH_PEND, IRQ_PEND (W1C) |

## Notes

- Prescaler value of 0 is treated as 1 (no division)
- Postscaler value of 0 is treated as 1 (no division)
- Status flags are sticky and require writing 1 to clear
- Counter can be loaded with arbitrary values while timer is running
