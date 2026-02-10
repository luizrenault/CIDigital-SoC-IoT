//-----------------------------------------------------------------
//                      SPI-Lite Testbench
//                          V1.0
//                     Simple Verification
//-----------------------------------------------------------------
//
// This testbench validates the SPI-Lite peripheral with the
// following test scenarios:
//   1. Reset verification
//   2. Register read/write
//   3. Basic SPI transfer (loopback mode)
//   4. FIFO operation
//   5. SPI modes (CPOL/CPHA)
//   6. Bit order (MSB/LSB first)
//   7. Chip select control
//   8. Interrupt generation
//-----------------------------------------------------------------

`include "../spi_lite_defs.v"

`timescale 1ns/1ps

module spi_lite_tb;

//-----------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------
parameter CLK_PERIOD = 10;  // 100MHz clock
parameter C_SCK_RATIO = 4;  // SPI clock divider (reduced for faster simulation)

//-----------------------------------------------------------------
// Signals
//-----------------------------------------------------------------
reg         clk_i;
reg         rst_i;

// AXI4-Lite Write Address Channel
reg         cfg_awvalid_i;
reg  [31:0] cfg_awaddr_i;
wire        cfg_awready_o;

// AXI4-Lite Write Data Channel
reg         cfg_wvalid_i;
reg  [31:0] cfg_wdata_i;
reg  [3:0]  cfg_wstrb_i;
wire        cfg_wready_o;

// AXI4-Lite Write Response Channel
wire        cfg_bvalid_o;
wire [1:0]  cfg_bresp_o;
reg         cfg_bready_i;

// AXI4-Lite Read Address Channel
reg         cfg_arvalid_i;
reg  [31:0] cfg_araddr_i;
wire        cfg_arready_o;

// AXI4-Lite Read Data Channel
wire        cfg_rvalid_o;
wire [31:0] cfg_rdata_o;
wire [1:0]  cfg_rresp_o;
reg         cfg_rready_i;

// SPI Interface
wire        spi_clk_o;
wire        spi_mosi_o;
reg         spi_miso_i;
wire [7:0]  spi_cs_o;
wire        intr_o;

// Test tracking
integer     test_num;
integer     pass_count;
integer     fail_count;
reg [31:0]  read_data;

//-----------------------------------------------------------------
// DUT Instantiation
//-----------------------------------------------------------------
spi_lite #(
    .C_SCK_RATIO(C_SCK_RATIO)
) u_dut (
    .clk_i          (clk_i),
    .rst_i          (rst_i),
    .cfg_awvalid_i  (cfg_awvalid_i),
    .cfg_awaddr_i   (cfg_awaddr_i),
    .cfg_awready_o  (cfg_awready_o),
    .cfg_wvalid_i   (cfg_wvalid_i),
    .cfg_wdata_i    (cfg_wdata_i),
    .cfg_wstrb_i    (cfg_wstrb_i),
    .cfg_wready_o   (cfg_wready_o),
    .cfg_bvalid_o   (cfg_bvalid_o),
    .cfg_bresp_o    (cfg_bresp_o),
    .cfg_bready_i   (cfg_bready_i),
    .cfg_arvalid_i  (cfg_arvalid_i),
    .cfg_araddr_i   (cfg_araddr_i),
    .cfg_arready_o  (cfg_arready_o),
    .cfg_rvalid_o   (cfg_rvalid_o),
    .cfg_rdata_o    (cfg_rdata_o),
    .cfg_rresp_o    (cfg_rresp_o),
    .cfg_rready_i   (cfg_rready_i),
    .spi_clk_o      (spi_clk_o),
    .spi_mosi_o     (spi_mosi_o),
    .spi_miso_i     (spi_miso_i),
    .spi_cs_o       (spi_cs_o),
    .intr_o         (intr_o)
);

//-----------------------------------------------------------------
// Clock Generation
//-----------------------------------------------------------------
initial begin
    clk_i = 0;
    forever #(CLK_PERIOD/2) clk_i = ~clk_i;
end

//-----------------------------------------------------------------
// Tasks
//-----------------------------------------------------------------

// Reset DUT
task reset_dut;
begin
    rst_i = 1;
    cfg_awvalid_i = 0;
    cfg_awaddr_i = 0;
    cfg_wvalid_i = 0;
    cfg_wdata_i = 0;
    cfg_wstrb_i = 0;
    cfg_bready_i = 1;
    cfg_arvalid_i = 0;
    cfg_araddr_i = 0;
    cfg_rready_i = 1;
    spi_miso_i = 0;
    
    repeat(5) @(posedge clk_i);
    rst_i = 0;
    repeat(5) @(posedge clk_i);
end
endtask

// AXI4-Lite Write Transaction
task axi_write;
input [31:0] addr;
input [31:0] data;
begin
    // Address phase
    @(posedge clk_i);
    cfg_awvalid_i = 1;
    cfg_awaddr_i = addr;
    cfg_wvalid_i = 1;
    cfg_wdata_i = data;
    cfg_wstrb_i = 4'hF;
    
    // Wait for ready
    while (!cfg_awready_o || !cfg_wready_o)
        @(posedge clk_i);
    
    @(posedge clk_i);
    cfg_awvalid_i = 0;
    cfg_wvalid_i = 0;
    
    // Wait for response
    while (!cfg_bvalid_o)
        @(posedge clk_i);
    
    @(posedge clk_i);
end
endtask

// AXI4-Lite Read Transaction
task axi_read;
input  [31:0] addr;
output [31:0] data;
begin
    // Wait for master to be ready to accept address
    while (!cfg_arready_o)
        @(posedge clk_i);
    
    @(posedge clk_i);
    cfg_arvalid_i = 1;
    cfg_araddr_i = addr;
    
    // Wait for slave to accept address
    while (!cfg_arready_o)
        @(posedge clk_i);
    
    @(posedge clk_i);
    cfg_arvalid_i = 0;
    
    // Wait for read data valid
    while (!cfg_rvalid_o)
        @(posedge clk_i);
    
    data = cfg_rdata_o;
    @(posedge clk_i);
end
endtask

// Write register
task write_reg;
input [7:0]  reg_addr;
input [31:0] data;
begin
    axi_write({24'h0, reg_addr}, data);
end
endtask

// Read register
task read_reg;
input  [7:0]  reg_addr;
output [31:0] data;
begin
    axi_read({24'h0, reg_addr}, data);
end
endtask

// Check result
task check_result;
input [31:0] expected;
input [31:0] actual;
input [255:0] msg;
begin
    if (expected === actual) begin
        $display("PASS: %s - Expected: 0x%08X, Got: 0x%08X", msg, expected, actual);
        pass_count = pass_count + 1;
    end else begin
        $display("FAIL: %s - Expected: 0x%08X, Got: 0x%08X", msg, expected, actual);
        fail_count = fail_count + 1;
    end
end
endtask

// Wait for SPI transfer complete (RX not empty)
task wait_for_rx_data;
begin
    read_data = 32'h1;  // RX_EMPTY bit
    while (read_data[0]) begin
        read_reg(`SPI_SR, read_data);
    end
end
endtask

// Wait for TX FIFO empty
task wait_for_tx_empty;
begin
    read_data = 32'h0;
    while (!read_data[2]) begin
        read_reg(`SPI_SR, read_data);
    end
end
endtask

//-----------------------------------------------------------------
// Test Scenarios
//-----------------------------------------------------------------

// Test 1: Reset Verification
task test_reset;
begin
    $display("\n=== Test 1: Reset Verification ===");
    test_num = 1;
    
    // Read status register - should show TX_EMPTY=1, RX_EMPTY=1
    read_reg(`SPI_SR, read_data);
    check_result(32'h5, read_data & 32'h5, "Reset: TX_EMPTY and RX_EMPTY set");
    
    // Read SSR - RTL default is 0x01 (CS0 active low, others high)
    read_reg(`SPI_SSR, read_data);
    check_result(32'h01, read_data & 32'hFF, "Reset: SSR default value");
    
    // Read CR - should be 0
    read_reg(`SPI_CR, read_data);
    check_result(32'h0, read_data, "Reset: CR default value");
    
    $display("Test 1 completed\n");
end
endtask

// Test 2: Register Write/Read
task test_register_access;
begin
    $display("\n=== Test 2: Register Write/Read ===");
    test_num = 2;
    
    // Write and read CR
    write_reg(`SPI_CR, 32'h00000006);  // SPE=1, MASTER=1, CPOL=0, CPHA=1
    read_reg(`SPI_CR, read_data);
    check_result(32'h00000006, read_data & 32'h3FF, "CR write/read");
    
    // Write and read SSR
    write_reg(`SPI_SSR, 32'h000000FE);  // CS0 low
    read_reg(`SPI_SSR, read_data);
    check_result(32'h000000FE, read_data & 32'hFF, "SSR write/read");
    
    // Write and read DGIER
    write_reg(`SPI_DGIER, 32'h80000000);  // Global interrupt enable
    read_reg(`SPI_DGIER, read_data);
    check_result(32'h80000000, read_data, "DGIER write/read");
    
    // Reset for next test
    write_reg(`SPI_CR, 32'h0);
    write_reg(`SPI_SSR, 32'hFF);
    write_reg(`SPI_DGIER, 32'h0);
    
    $display("Test 2 completed\n");
end
endtask

// Test 3: Basic SPI Transfer (Loopback Mode)
task test_basic_transfer;
integer i;
begin
    $display("\n=== Test 3: Basic SPI Transfer (Loopback) ===");
    test_num = 3;
    
    // Configure: Mode 0, Master, Enabled, Loopback
    write_reg(`SPI_CR, 32'h00000007);  // LOOP=1, SPE=1, MASTER=1, TRANS_INHIBIT=0
    
    // Add small delay after configuration
    repeat(5) @(posedge clk_i);
    
    // Write data to transmit
    write_reg(`SPI_DTR, 32'h000000A5);
    
    // Wait for transfer to complete (RX not empty)
    wait_for_rx_data;
    
    // Read received data
    read_reg(`SPI_DRR, read_data);
    check_result(32'h000000A5, read_data & 32'hFF, "Loopback transfer data");
    
    // Verify TX is empty
    read_reg(`SPI_SR, read_data);
    check_result(32'h4, read_data & 32'h4, "TX_EMPTY after transfer");
    
    // Disable SPI
    write_reg(`SPI_CR, 32'h0);
    
    $display("Test 3 completed\n");
end
endtask

// Test 4: FIFO Operation
task test_fifo_operation;
begin
    $display("\n=== Test 4: FIFO Operation ===");
    test_num = 4;
    
    // Configure: Mode 0, Master, Enabled, Loopback
    write_reg(`SPI_CR, 32'h00000007);
    
    // Write 4 bytes to fill FIFO
    write_reg(`SPI_DTR, 32'h00000011);
    write_reg(`SPI_DTR, 32'h00000022);
    write_reg(`SPI_DTR, 32'h00000033);
    write_reg(`SPI_DTR, 32'h00000044);
    
    // Check TX_FULL flag
    read_reg(`SPI_SR, read_data);
    check_result(32'h8, read_data & 32'h8, "TX_FULL after 4 writes");
    
    // Read each byte as it becomes available
    wait_for_rx_data;
    read_reg(`SPI_DRR, read_data);
    check_result(32'h00000011, read_data & 32'hFF, "FIFO read byte 0");
    
    wait_for_rx_data;
    read_reg(`SPI_DRR, read_data);
    check_result(32'h00000022, read_data & 32'hFF, "FIFO read byte 1");
    
    wait_for_rx_data;
    read_reg(`SPI_DRR, read_data);
    check_result(32'h00000033, read_data & 32'hFF, "FIFO read byte 2");
    
    wait_for_rx_data;
    read_reg(`SPI_DRR, read_data);
    check_result(32'h00000044, read_data & 32'hFF, "FIFO read byte 3");
    
    // Reset TX FIFO
    write_reg(`SPI_CR, 32'h00000027);  // Set TXFIFO_RST
    write_reg(`SPI_CR, 32'h00000007);  // Clear TXFIFO_RST
    
    // Verify TX_EMPTY
    read_reg(`SPI_SR, read_data);
    check_result(32'h5, read_data & 32'h5, "TX_EMPTY after FIFO reset");
    
    // Disable SPI
    write_reg(`SPI_CR, 32'h0);
    
    $display("Test 4 completed\n");
end
endtask

// Test 5: SPI Modes (CPOL/CPHA)
task test_spi_modes;
begin
    $display("\n=== Test 5: SPI Modes ===");
    test_num = 5;
    
    // Test Mode 0 (CPOL=0, CPHA=0)
    write_reg(`SPI_CR, 32'h00000007);  // LOOP=1, SPE=1, MASTER=1, CPOL=0, CPHA=0
    repeat(5) @(posedge clk_i);
    write_reg(`SPI_DTR, 32'h00000055);
    wait_for_rx_data;
    read_reg(`SPI_DRR, read_data);
    check_result(32'h00000055, read_data & 32'hFF, "Mode 0 transfer");
    write_reg(`SPI_CR, 32'h0);
    repeat(5) @(posedge clk_i);

    // Test Mode 1 (CPOL=0, CPHA=1)
    write_reg(`SPI_CR, 32'h00000017);  // LOOP=1, SPE=1, MASTER=1, CPOL=0, CPHA=1
    repeat(5) @(posedge clk_i);
    write_reg(`SPI_DTR, 32'h000000AA);
    wait_for_rx_data;
    read_reg(`SPI_DRR, read_data);
    check_result(32'h000000AA, read_data & 32'hFF, "Mode 1 transfer");
    write_reg(`SPI_CR, 32'h0);
    repeat(5) @(posedge clk_i);

    // Test Mode 2 (CPOL=1, CPHA=0)
    write_reg(`SPI_CR, 32'h0000000F);  // LOOP=1, SPE=1, MASTER=1, CPOL=1, CPHA=0
    repeat(5) @(posedge clk_i);
    write_reg(`SPI_DTR, 32'h00000033);
    wait_for_rx_data;
    read_reg(`SPI_DRR, read_data);
    check_result(32'h00000033, read_data & 32'hFF, "Mode 2 transfer");
    write_reg(`SPI_CR, 32'h0);
    repeat(5) @(posedge clk_i);

    // Test Mode 3 (CPOL=1, CPHA=1)
    write_reg(`SPI_CR, 32'h0000001F);  // LOOP=1, SPE=1, MASTER=1, CPOL=1, CPHA=1
    repeat(5) @(posedge clk_i);
    write_reg(`SPI_DTR, 32'h000000CC);
    wait_for_rx_data;
    read_reg(`SPI_DRR, read_data);
    check_result(32'h000000CC, read_data & 32'hFF, "Mode 3 transfer");
    write_reg(`SPI_CR, 32'h0);
    repeat(5) @(posedge clk_i);
    
    $display("Test 5 completed\n");
end
endtask

// Test 6: Bit Order (MSB/LSB First)
task test_bit_order;
begin
    $display("\n=== Test 6: Bit Order ===");
    test_num = 6;
    
    // Test MSB first (default)
    write_reg(`SPI_CR, 32'h00000007);  // LSB_FIRST=0
    write_reg(`SPI_DTR, 32'h00000081);  // 10000001 binary
    wait_for_rx_data;
    read_reg(`SPI_DRR, read_data);
    check_result(32'h00000081, read_data & 32'hFF, "MSB-first transfer");
    write_reg(`SPI_CR, 32'h0);
    
    // Test LSB first
    // In loopback mode with LSB_FIRST: TX reverses bits, RX reverses them back
    // So 0x0F (00001111) -> TX shifts out as 11110000 -> RX receives as 11110000 -> reversed back to 00001111 = 0x0F
    write_reg(`SPI_CR, 32'h00000207);  // LSB_FIRST=1
    repeat(5) @(posedge clk_i);
    write_reg(`SPI_DTR, 32'h0000000F);  // In loopback, should receive same value due to double reversal
    wait_for_rx_data;
    read_reg(`SPI_DRR, read_data);
    check_result(32'h0000000F, read_data & 32'hFF, "LSB-first transfer (loopback)");
    write_reg(`SPI_CR, 32'h0);
    repeat(5) @(posedge clk_i);
    
    $display("Test 6 completed\n");
end
endtask

// Test 7: Chip Select Control
task test_chip_select;
begin
    $display("\n=== Test 7: Chip Select Control ===");
    test_num = 7;
    
    // Enable manual SS mode
    write_reg(`SPI_CR, 32'h00000087);  // LOOP=1, SPE=1, MASTER=1, MANUAL_SS=1
    
    // Check that in manual SS mode, CS output follows SSR register
    // Default SSR is 0x01, so CS0 should be low (0), others high (1) -> output 0x01
    // Actually wait - SSR default is 0x01, which means bit0=1 (CS0 deasserted)
    // But the naming suggests active-low, so 0x01 should mean CS0=1 (deasserted)
    // So writing 0x01 outputs 0x01 (all deasserted)
    
    // Assert CS0 only (write 0xFE: bit0=0, others=1)
    write_reg(`SPI_SSR, 32'h000000FE);
    #10;
    if (spi_cs_o === 8'hFE)
        check_result(8'hFE, spi_cs_o, "CS0 asserted");
    else
        check_result(8'hFE, spi_cs_o, "CS0 assertion");
    
    // Deassert all (write 0xFF: all bits=1, all CS high)
    write_reg(`SPI_SSR, 32'h000000FF);
    #10;
    if (spi_cs_o === 8'hFF)
        check_result(8'hFF, spi_cs_o, "All CS deasserted");
    else
        check_result(8'hFF, spi_cs_o, "CS deassertion");
    
    // Assert CS1 only (write 0xFD: bit1=0, others=1)
    write_reg(`SPI_SSR, 32'h000000FD);
    #10;
    if (spi_cs_o === 8'hFD)
        check_result(8'hFD, spi_cs_o, "CS1 asserted");
    else
        check_result(8'hFD, spi_cs_o, "CS1 assertion");
    
    // Disable SPI
    write_reg(`SPI_CR, 32'h0);
    
    $display("Test 7 completed\n");
end
endtask

// Test 8: Interrupt Generation
task test_interrupts;
begin
    $display("\n=== Test 8: Interrupt Generation ===");
    test_num = 8;
    
    // Enable global interrupt and TX empty interrupt
    write_reg(`SPI_IPIER, 32'h00000004);  // TX_EMPTY interrupt enable
    write_reg(`SPI_DGIER, 32'h80000000);  // Global interrupt enable
    
    // Configure SPI
    write_reg(`SPI_CR, 32'h00000007);  // LOOP=1, SPE=1, MASTER=1
    
    // Verify interrupt is not active initially (TX FIFO has space)
    #100;
    check_result(1'b0, intr_o, "Interrupt inactive initially");
    
    // Write data and wait for transfer
    write_reg(`SPI_DTR, 32'h00000077);
    wait_for_tx_empty;
    
    // Wait for interrupt to propagate and check_tx_level_q to update
    repeat(10) @(posedge clk_i);
    
    // Check interrupt is asserted
    check_result(1'b1, intr_o, "TX_EMPTY interrupt asserted");
    
    // Clear interrupt by writing to IPISR
    write_reg(`SPI_IPISR, 32'h00000004);  // Clear TX_EMPTY interrupt
    
    // Wait for clear to take effect (need clock edge for synchronization)
    repeat(10) @(posedge clk_i);
    
    check_result(1'b0, intr_o, "Interrupt cleared");
    
    // Disable interrupts
    write_reg(`SPI_DGIER, 32'h0);
    write_reg(`SPI_IPIER, 32'h0);
    write_reg(`SPI_CR, 32'h0);
    
    $display("Test 8 completed\n");
end
endtask

// Test 9: Software Reset
task test_software_reset;
begin
    $display("\n=== Test 9: Software Reset ===");
    test_num = 9;
    
    // Configure SPI and write data to FIFO
    write_reg(`SPI_CR, 32'h00000007);
    write_reg(`SPI_DTR, 32'h000000AA);  // Put data in TX FIFO
    
    // Verify TX FIFO has data
    read_reg(`SPI_SR, read_data);
    check_result(32'h0, read_data & 32'h4, "SW Reset: TX FIFO not empty before reset");
    
    // Trigger software reset
    write_reg(`SPI_SRR, 32'h0000000A);
    
    // Wait for reset to complete
    repeat(20) @(posedge clk_i);
    
    // Verify FIFOs are reset (TX should be empty)
    read_reg(`SPI_SR, read_data);
    check_result(32'h4, read_data & 32'h4, "SW Reset: TX FIFO empty after reset");
    check_result(32'h1, read_data & 32'h1, "SW Reset: RX FIFO empty after reset");
    
    // Note: Software reset only clears FIFOs and internal state, not control registers
    // Verify control registers are NOT reset (still have our values)
    read_reg(`SPI_CR, read_data);
    check_result(32'h00000007, read_data & 32'hFF, "SW Reset: CR unchanged (expected)");
    
    // Clean up
    write_reg(`SPI_CR, 32'h0);
    
    $display("Test 9 completed\n");
end
endtask

//-----------------------------------------------------------------
// Main Test Sequence
//-----------------------------------------------------------------
initial begin
    $display("==============================================");
    $display("      SPI-Lite Peripheral Testbench");
    $display("==============================================");
    
    pass_count = 0;
    fail_count = 0;
    
    // Dump waves
    $dumpfile("spi_lite_tb.vcd");
    $dumpvars(0, spi_lite_tb);
    
    // Initialize
    reset_dut;
    
    // Run tests
    test_reset;
    test_register_access;
    test_basic_transfer;
    test_fifo_operation;
    test_spi_modes;
    test_bit_order;
    test_chip_select;
    test_interrupts;
    test_software_reset;
    
    // Summary
    $display("==============================================");
    $display("              Test Summary");
    $display("==============================================");
    $display("Passed: %0d", pass_count);
    $display("Failed: %0d", fail_count);
    
    if (fail_count == 0)
        $display("\n*** ALL TESTS PASSED ***");
    else
        $display("\n*** SOME TESTS FAILED ***");
    
    $display("==============================================");
    
    $finish;
end

//-----------------------------------------------------------------
// Timeout watchdog
//-----------------------------------------------------------------
initial begin
    #1000000;  // 1ms timeout
    $display("ERROR: Simulation timeout!");
    $finish;
end

endmodule
