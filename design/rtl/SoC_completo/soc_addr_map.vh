`ifndef SOC_ADDR_MAP_VH
`define SOC_ADDR_MAP_VH

// -----------------------------------------------------------------------------
// SoC Address Map (AXI-Lite)
// Decode rule: (addr & MASK) == BASE
// -----------------------------------------------------------------------------

// ---------------- Root regions (AXI 1x2) ----------------
// Região de PERIFÉRICOS: 64KB em 0x4000_0000
`define AXI_PERIPH_REGION_BASE  32'h4000_0000
`define AXI_PERIPH_REGION_MASK  32'hFFFF_0000   // 64 KiB

// Região de MEMÓRIA: 128KB em 0x0000_0000 (exemplo)
// Se você quiser maior, mude a máscara conforme a janela.
`define AXI_MEM_REGION_BASE     32'h0000_0000
`define AXI_MEM_REGION_MASK     32'hFFFE_0000   // 128 KiB

// ---------------- Sub-regions dentro de MEM ----------------
// RAM: 64KB em 0x0001_0000 (alinhado em 64KB)
`define AXI_RAM_BASE            32'h0000_0000 // 32'h0001_0000 estava assim
`define AXI_RAM_MASK            32'hFFFF_0000   // 64 KiB

// (Opcional) ROM: 64KB em 0x0000_0000
`define AXI_ROM_BASE            32'h0000_0000
`define AXI_ROM_MASK            32'hFFFF_0000   // 64 KiB

// ---------------- Peripheral windows (AXI 1x6) ----------------
// 4 KB por periférico
`define AXI_PERIPH_MASK_4KB     32'hFFFF_F000

`define AXI_GPIO_BASE           32'h4000_0000
`define AXI_TIMER_BASE          32'h4000_1000
`define AXI_UART_BASE           32'h4000_2000
`define AXI_SPI_BASE            32'h4000_3000
`define AXI_I2C_BASE            32'h4000_4000
`define AXI_INTR_BASE           32'h4000_5000

`define AXI_GPIO_MASK           `AXI_PERIPH_MASK_4KB
`define AXI_TIMER_MASK          `AXI_PERIPH_MASK_4KB
`define AXI_UART_MASK           `AXI_PERIPH_MASK_4KB
`define AXI_SPI_MASK            `AXI_PERIPH_MASK_4KB
`define AXI_I2C_MASK            `AXI_PERIPH_MASK_4KB
`define AXI_INTR_MASK           `AXI_PERIPH_MASK_4KB

`endif
