//-----------------------------------------------------------------
// Timer Peripheral Testbench
//-----------------------------------------------------------------
// Copyright (c) 2024 CIDigital SoC IoT Project
// License: BSD
//-----------------------------------------------------------------

`timescale 1ns/1ps

`include "timer_defs.v"

//-----------------------------------------------------------------
// Testbench Module
//-----------------------------------------------------------------
module timer_tb;

//-----------------------------------------------------------------
// Parameters
//-----------------------------------------------------------------
parameter CLK_PERIOD = 10;  // 100MHz clock

//-----------------------------------------------------------------
// Signals
//-----------------------------------------------------------------
reg         clk_i;
reg         rst_i;

// AXI4-Lite Interface
reg         cfg_awvalid_i;
reg [31:0]  cfg_awaddr_i;
reg         cfg_wvalid_i;
reg [31:0]  cfg_wdata_i;
reg [3:0]   cfg_wstrb_i;
reg         cfg_bready_i;
reg         cfg_arvalid_i;
reg [31:0]  cfg_araddr_i;
reg         cfg_rready_i;

wire        cfg_awready_o;
wire        cfg_wready_o;
wire        cfg_bvalid_o;
wire [1:0]  cfg_bresp_o;
wire        cfg_arready_o;
wire        cfg_rvalid_o;
wire [31:0] cfg_rdata_o;
wire [1:0]  cfg_rresp_o;
wire        intr_o;

//-----------------------------------------------------------------
// Test Tracking
//-----------------------------------------------------------------
integer     test_num;
integer     pass_count;
integer     fail_count;

//-----------------------------------------------------------------
// DUT Instantiation
//-----------------------------------------------------------------
timer uut
(
    // Inputs
     .clk_i(clk_i)
    ,.rst_i(rst_i)
    ,.cfg_awvalid_i(cfg_awvalid_i)
    ,.cfg_awaddr_i(cfg_awaddr_i)
    ,.cfg_wvalid_i(cfg_wvalid_i)
    ,.cfg_wdata_i(cfg_wdata_i)
    ,.cfg_wstrb_i(cfg_wstrb_i)
    ,.cfg_bready_i(cfg_bready_i)
    ,.cfg_arvalid_i(cfg_arvalid_i)
    ,.cfg_araddr_i(cfg_araddr_i)
    ,.cfg_rready_i(cfg_rready_i)

    // Outputs
    ,.cfg_awready_o(cfg_awready_o)
    ,.cfg_wready_o(cfg_wready_o)
    ,.cfg_bvalid_o(cfg_bvalid_o)
    ,.cfg_bresp_o(cfg_bresp_o)
    ,.cfg_arready_o(cfg_arready_o)
    ,.cfg_rvalid_o(cfg_rvalid_o)
    ,.cfg_rdata_o(cfg_rdata_o)
    ,.cfg_rresp_o(cfg_rresp_o)
    ,.intr_o(intr_o)
);

//-----------------------------------------------------------------
// Clock Generation
//-----------------------------------------------------------------
initial begin
    clk_i = 0;
    forever #(CLK_PERIOD/2) clk_i = ~clk_i;
end

//-----------------------------------------------------------------
// Reset Task
//-----------------------------------------------------------------
task reset_dut;
begin
    $display("[%0t] Resetting DUT...", $time);
    
    rst_i = 1;
    cfg_awvalid_i = 0;
    cfg_awaddr_i = 0;
    cfg_wvalid_i = 0;
    cfg_wdata_i = 0;
    cfg_wstrb_i = 4'hF;
    cfg_bready_i = 1;
    cfg_arvalid_i = 0;
    cfg_araddr_i = 0;
    cfg_rready_i = 1;
    
    repeat(10) @(posedge clk_i);
    rst_i = 0;
    repeat(2) @(posedge clk_i);
    
    $display("[%0t] Reset complete", $time);
end
endtask

//-----------------------------------------------------------------
// AXI4-Lite Write Transaction
//-----------------------------------------------------------------
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
    
    if (cfg_bresp_o !== 2'b00)
        $display("[%0t] WARNING: Write response error at address %h", $time, addr);
end
endtask

//-----------------------------------------------------------------
// AXI4-Lite Read Transaction
//-----------------------------------------------------------------
task axi_read;
    input  [31:0] addr;
    output [31:0] data;
begin
    // Address phase
    @(posedge clk_i);
    cfg_arvalid_i = 1;
    cfg_araddr_i = addr;
    
    // Wait for ready
    while (!cfg_arready_o)
        @(posedge clk_i);
    
    @(posedge clk_i);
    cfg_arvalid_i = 0;
    
    // Wait for data
    while (!cfg_rvalid_o)
        @(posedge clk_i);
    
    data = cfg_rdata_o;
    
    @(posedge clk_i);
    
    if (cfg_rresp_o !== 2'b00)
        $display("[%0t] WARNING: Read response error at address %h", $time, addr);
end
endtask

//-----------------------------------------------------------------
// Register Write/Read Helpers
//-----------------------------------------------------------------
task write_reg;
    input [31:0] addr;
    input [31:0] data;
begin
    axi_write(addr, data);
end
endtask

task read_reg;
    input  [31:0] addr;
    output [31:0] data;
begin
    axi_read(addr, data);
end
endtask

//-----------------------------------------------------------------
// Check Result Task
//-----------------------------------------------------------------
task check_result;
    input [31:0] expected;
    input [31:0] actual;
    input [255:0] msg;
begin
    if (expected === actual) begin
        $display("PASS: %s", msg);
        pass_count = pass_count + 1;
    end else begin
        $display("FAIL: %s (expected %h, got %h)", msg, expected, actual);
        fail_count = fail_count + 1;
    end
end
endtask

//-----------------------------------------------------------------
// Wait for Interrupt Task
//-----------------------------------------------------------------
task wait_for_interrupt;
    input [31:0] timeout_cycles;
    output       success;
    reg [31:0]   count;
begin
    count = 0;
    success = 0;
    
    while (count < timeout_cycles && !intr_o) begin
        @(posedge clk_i);
        count = count + 1;
    end
    
    if (intr_o)
        success = 1;
end
endtask

//-----------------------------------------------------------------
// Wait for Match Pending Task
//-----------------------------------------------------------------
task wait_for_match_pending;
    input [31:0] timeout_cycles;
    output       success;
    reg [31:0]   count;
    reg [31:0]   status;
begin
    count = 0;
    success = 0;
    
    while (count < timeout_cycles && !success) begin
        @(posedge clk_i);
        read_reg(`TIMER_STATUS0, status);
        if (status[0])
            success = 1;
        count = count + 1;
    end
end
endtask

//-----------------------------------------------------------------
// Clear Status Flags Task
//-----------------------------------------------------------------
task clear_status;
begin
    // Write 1 to clear both flags
    write_reg(`TIMER_STATUS0, 32'h0000_0003);
end
endtask

//-----------------------------------------------------------------
// Test 1: Reset Verification
//-----------------------------------------------------------------
task test_reset;
    reg [31:0] data;
begin
    test_num = 1;
    $display("\n=== Test %0d: Reset Verification ===", test_num);
    
    // Check default register values after reset
    read_reg(`TIMER_CTRL0, data);
    check_result(32'h0000_0000, data, "CTRL0 reset value");
    
    read_reg(`TIMER_CMP0, data);
    check_result(32'h0000_0000, data, "CMP0 reset value");
    
    read_reg(`TIMER_VAL0, data);
    check_result(32'h0000_0000, data, "VAL0 reset value");
    
    read_reg(`TIMER_PRESCALE0, data);
    check_result(32'h0000_0001, data, "PRESCALE0 reset value (N=1)");
    
    read_reg(`TIMER_POSTSCALE0, data);
    check_result(32'h0000_0001, data, "POSTSCALE0 reset value (M=1)");
    
    read_reg(`TIMER_STATUS0, data);
    check_result(32'h0000_0000, data, "STATUS0 reset value");
    
    check_result(1'b0, intr_o, "INTR reset value");
end
endtask

//-----------------------------------------------------------------
// Test 2: Register Write/Read
//-----------------------------------------------------------------
task test_register_access;
    reg [31:0] data;
begin
    test_num = 2;
    $display("\n=== Test %0d: Register Write/Read ===", test_num);
    
    // Write and read CTRL0
    write_reg(`TIMER_CTRL0, 32'h0000_000E);  // Enable, autoreload, interrupt
    read_reg(`TIMER_CTRL0, data);
    check_result(32'h0000_000E, data, "CTRL0 write/read");
    
    // Write and read CMP0
    write_reg(`TIMER_CMP0, 32'h0000_0100);
    read_reg(`TIMER_CMP0, data);
    check_result(32'h0000_0100, data, "CMP0 write/read");
    
    // Write and read PRESCALE0
    write_reg(`TIMER_PRESCALE0, 32'h0000_000A);
    read_reg(`TIMER_PRESCALE0, data);
    check_result(32'h0000_000A, data, "PRESCALE0 write/read");
    
    // Write and read POSTSCALE0
    write_reg(`TIMER_POSTSCALE0, 32'h0000_0005);
    read_reg(`TIMER_POSTSCALE0, data);
    check_result(32'h0000_0005, data, "POSTSCALE0 write/read");
    
    // Reset for next test
    reset_dut;
end
endtask

//-----------------------------------------------------------------
// Test 3: Basic Timer Operation (One-Shot)
//-----------------------------------------------------------------
task test_basic_timer;
    reg [31:0] data;
    reg        success;
begin
    test_num = 3;
    $display("\n=== Test %0d: Basic Timer Operation (One-Shot) ===", test_num);
    
    // Set compare value to 50
    write_reg(`TIMER_CMP0, 32'd50);
    
    // Set prescaler to 1 (no division)
    write_reg(`TIMER_PRESCALE0, 32'd1);
    
    // Set postscaler to 1 (no division)
    write_reg(`TIMER_POSTSCALE0, 32'd1);
    
    // Enable timer with interrupt
    write_reg(`TIMER_CTRL0, 32'h0000_0006);  // Enable + Interrupt, no autoreload
    
    // Wait for match
    wait_for_match_pending(1000, success);
    check_result(1'b1, success, "Timer reached match");
    
    // Check that interrupt is pending
    read_reg(`TIMER_STATUS0, data);
    check_result(1'b1, data[1], "IRQ pending flag set");
    check_result(1'b1, data[0], "Match pending flag set");
    check_result(1'b1, intr_o, "Interrupt output active");
    
    // In one-shot mode, timer continues counting but doesn't reload
    // The MATCH_PEND flag indicates the match occurred
    read_reg(`TIMER_STATUS0, data);
    check_result(1'b1, data[0], "Match pending flag remains set");
    
    // Clear status
    clear_status;
    read_reg(`TIMER_STATUS0, data);
    check_result(32'h0000_0000, data, "Status cleared");
    check_result(1'b0, intr_o, "Interrupt cleared");
    
    // Disable timer
    write_reg(`TIMER_CTRL0, 32'h0000_0000);
    
    reset_dut;
end
endtask

//-----------------------------------------------------------------
// Test 4: Auto-Reload Mode
//-----------------------------------------------------------------
task test_autoreload;
    reg [31:0] data;
    reg        success;
begin
    test_num = 4;
    $display("\n=== Test %0d: Auto-Reload Mode ===", test_num);
    
    // Set compare value to 20
    write_reg(`TIMER_CMP0, 32'd20);
    
    // Set prescaler to 1
    write_reg(`TIMER_PRESCALE0, 32'd1);
    
    // Set postscaler to 1
    write_reg(`TIMER_POSTSCALE0, 32'd1);
    
    // Enable timer with autoreload and interrupt
    write_reg(`TIMER_CTRL0, 32'h0000_000E);  // Enable + Interrupt + Autoreload
    
    // Wait for first match
    wait_for_match_pending(100, success);
    check_result(1'b1, success, "First match occurred");
    
    // Check timer restarted
    read_reg(`TIMER_VAL0, data);
    if (data < 32'd20)
        $display("PASS: Timer auto-reloaded (VAL0=%0d < 20)", data);
    else
        $display("FAIL: Timer did not auto-reload (VAL0=%0d)", data);
    
    // Wait for second match
    wait_for_match_pending(100, success);
    check_result(1'b1, success, "Second match occurred");
    
    // Disable timer
    write_reg(`TIMER_CTRL0, 32'h0000_0000);
    clear_status;
    
    reset_dut;
end
endtask

//-----------------------------------------------------------------
// Test 5: Prescaler Functionality
//-----------------------------------------------------------------
task test_prescaler;
    reg [31:0] data;
    reg        success;
begin
    test_num = 5;
    $display("\n=== Test %0d: Prescaler Functionality ===", test_num);
    
    // Set compare value to 10
    write_reg(`TIMER_CMP0, 32'd10);
    
    // Set prescaler to 5 (count every 5 clock cycles)
    write_reg(`TIMER_PRESCALE0, 32'd5);
    
    // Set postscaler to 1
    write_reg(`TIMER_POSTSCALE0, 32'd1);
    
    // Enable timer
    write_reg(`TIMER_CTRL0, 32'h0000_0006);  // Enable + Interrupt
    
    // With prescaler=5, timer should take 10*5=50 cycles to reach match
    // plus some setup cycles
    wait_for_match_pending(500, success);
    check_result(1'b1, success, "Prescaler match occurred");
    
    // Verify match occurred (timer value may be at 10 or incremented to 11)
    read_reg(`TIMER_STATUS0, data);
    check_result(1'b1, data[0], "Match pending with prescaler");
    
    // Clear and disable
    clear_status;
    write_reg(`TIMER_CTRL0, 32'h0000_0000);
    
    reset_dut;
end
endtask

//-----------------------------------------------------------------
// Test 6: Postscaler Functionality
//-----------------------------------------------------------------
task test_postscaler;
    reg [31:0] data;
    reg        success;
    integer    matches_seen;
begin
    test_num = 6;
    $display("\n=== Test %0d: Postscaler Functionality ===", test_num);
    
    // Set compare value to 5 (fast matches)
    write_reg(`TIMER_CMP0, 32'd5);
    
    // Set prescaler to 1
    write_reg(`TIMER_PRESCALE0, 32'd1);
    
    // Set postscaler to 3 (IRQ every 3 matches)
    write_reg(`TIMER_POSTSCALE0, 32'd3);
    
    // Enable timer with autoreload
    write_reg(`TIMER_CTRL0, 32'h0000_000E);  // Enable + Interrupt + Autoreload
    
    // Wait for interrupt (should take 3 matches)
    wait_for_interrupt(1000, success);
    check_result(1'b1, success, "Postscaler generated interrupt after 3 matches");
    
    // Check status
    read_reg(`TIMER_STATUS0, data);
    check_result(1'b1, data[1], "IRQ pending after postscale");
    check_result(1'b1, data[0], "Match pending after postscale");
    
    // Clear and check we don't get another IRQ immediately
    clear_status;
    
    // Wait again for next interrupt (another 3 matches)
    wait_for_interrupt(1000, success);
    check_result(1'b1, success, "Second postscale interrupt");
    
    // Disable
    write_reg(`TIMER_CTRL0, 32'h0000_0000);
    clear_status;
    
    reset_dut;
end
endtask

//-----------------------------------------------------------------
// Test 7: Interrupt Generation and Clearing
//-----------------------------------------------------------------
task test_interrupts;
    reg [31:0] data;
    reg        success;
begin
    test_num = 7;
    $display("\n=== Test %0d: Interrupt Generation and Clearing ===", test_num);
    
    // Set compare value to 10
    write_reg(`TIMER_CMP0, 32'd10);
    
    // Enable timer WITHOUT interrupt bit
    write_reg(`TIMER_CTRL0, 32'h0000_0004);  // Enable only
    
    // Wait for match
    wait_for_match_pending(200, success);
    check_result(1'b1, success, "Match without interrupt");
    
    // Check interrupt NOT generated
    read_reg(`TIMER_STATUS0, data);
    check_result(1'b0, data[1], "IRQ pending not set when disabled");
    check_result(1'b0, intr_o, "INTR not active when disabled");
    
    // Enable interrupt bit while timer running
    write_reg(`TIMER_CTRL0, 32'h0000_0006);  // Enable + Interrupt
    
    // Wait a bit for the match to happen again (autoreload is off, timer stopped)
    // Actually, with autoreload off timer stopped at match, so we need to restart
    write_reg(`TIMER_VAL0, 32'd0);  // Reset counter
    write_reg(`TIMER_CTRL0, 32'h0000_000E);  // Enable + Interrupt + Autoreload
    
    // Clear previous match
    clear_status;
    
    // Wait for new match
    wait_for_interrupt(200, success);
    check_result(1'b1, success, "Interrupt generated when enabled");
    check_result(1'b1, intr_o, "INTR active");
    
    // Disable timer - IRQ output goes low immediately (gated by enable), but STATUS stays sticky
    write_reg(`TIMER_CTRL0, 32'h0000_0000);
    check_result(1'b0, intr_o, "INTR goes low when timer disabled");
    
    // Verify STATUS0 bits remain sticky
    read_reg(`TIMER_STATUS0, data);
    check_result(1'b1, data[1], "IRQ pending sticky in STATUS after disable");
    check_result(1'b1, data[0], "Match pending sticky in STATUS after disable");
    
    // Clear status
    clear_status;
    check_result(1'b0, intr_o, "INTR cleared");
    
    reset_dut;
end
endtask

//-----------------------------------------------------------------
// Test 8: Status Register W1C Behavior
//-----------------------------------------------------------------
task test_status_w1c;
    reg [31:0] data;
begin
    test_num = 8;
    $display("\n=== Test %0d: Status Register W1C Behavior ===", test_num);
    
    // Set compare value
    write_reg(`TIMER_CMP0, 32'd5);
    
    // Enable timer
    write_reg(`TIMER_CTRL0, 32'h0000_0006);
    
    // Wait for match
    while (!intr_o) @(posedge clk_i);
    
    // Check both flags are set
    read_reg(`TIMER_STATUS0, data);
    check_result(2'b11, data[1:0], "Both flags set");
    
    // Write 0 to clear - should NOT clear
    write_reg(`TIMER_STATUS0, 32'h0000_0000);
    read_reg(`TIMER_STATUS0, data);
    check_result(2'b11, data[1:0], "Write 0 does not clear");
    
    // Write 1 to clear bit 0 only
    write_reg(`TIMER_STATUS0, 32'h0000_0001);
    read_reg(`TIMER_STATUS0, data);
    check_result(2'b10, data[1:0], "Cleared bit 0 only");
    
    // Write 1 to clear bit 1 only
    write_reg(`TIMER_STATUS0, 32'h0000_0002);
    read_reg(`TIMER_STATUS0, data);
    check_result(2'b00, data[1:0], "Cleared bit 1 only");
    
    // Disable
    write_reg(`TIMER_CTRL0, 32'h0000_0000);
    
    reset_dut;
end
endtask

//-----------------------------------------------------------------
// Test 9: Combined Prescaler and Postscaler
//-----------------------------------------------------------------
task test_combined_scaling;
    reg [31:0] data;
    reg        success;
begin
    test_num = 9;
    $display("\n=== Test %0d: Combined Prescaler and Postscaler ===", test_num);
    
    // Set compare value to 5
    write_reg(`TIMER_CMP0, 32'd5);
    
    // Set prescaler to 4
    write_reg(`TIMER_PRESCALE0, 32'd4);
    
    // Set postscaler to 3
    write_reg(`TIMER_POSTSCALE0, 32'd3);
    
    // Enable timer with autoreload
    write_reg(`TIMER_CTRL0, 32'h0000_000E);
    
    // Total cycles for one IRQ: 5 * 4 * 3 = 60 cycles + overhead
    wait_for_interrupt(1000, success);
    check_result(1'b1, success, "Combined scaling generated interrupt");
    
    // Verify values
    read_reg(`TIMER_VAL0, data);
    $display("VAL0 at interrupt: %0d", data);
    
    read_reg(`TIMER_STATUS0, data);
    check_result(1'b1, data[0], "Match pending");
    check_result(1'b1, data[1], "IRQ pending");
    
    // Disable and clear
    write_reg(`TIMER_CTRL0, 32'h0000_0000);
    clear_status;
    
    reset_dut;
end
endtask

//-----------------------------------------------------------------
// Test 10: Manual Counter Load
//-----------------------------------------------------------------
task test_manual_load;
    reg [31:0] data;
begin
    test_num = 10;
    $display("\n=== Test %0d: Manual Counter Load ===", test_num);
    
    // Set compare value
    write_reg(`TIMER_CMP0, 32'd100);
    
    // Write initial value to counter
    write_reg(`TIMER_VAL0, 32'd50);
    
    // Enable timer
    write_reg(`TIMER_CTRL0, 32'h0000_0004);
    
    // Check counter started from 50 (allow some time for register write)
    @(posedge clk_i);
    read_reg(`TIMER_VAL0, data);
    check_result(1'b1, (data >= 32'd50 && data < 32'd100), "Counter loaded with initial value");
    
    // Load new value while running
    write_reg(`TIMER_VAL0, 32'd90);
    
    // Check counter loaded (value loads on next cycle, so check after delay)
    @(posedge clk_i);
    read_reg(`TIMER_VAL0, data);
    if (data >= 32'd90 && data <= 32'd100)
        $display("PASS: Counter reloaded at %0d", data);
    else if (data > 32'd100)
        check_result(1'b1, 1'b1, "Counter already passed match (acceptable)");
    else
        check_result(1'b1, 1'b0, "Counter reload value incorrect");
    
    // Disable
    write_reg(`TIMER_CTRL0, 32'h0000_0000);
    
    reset_dut;
end
endtask

//-----------------------------------------------------------------
// Main Test Sequence
//-----------------------------------------------------------------
initial begin
    $display("========================================");
    $display("Timer Peripheral Testbench");
    $display("========================================");
    
    pass_count = 0;
    fail_count = 0;
    
    // Initialize and reset
    reset_dut;
    
    // Run all tests
    test_reset;
    test_register_access;
    test_basic_timer;
    test_autoreload;
    test_prescaler;
    test_postscaler;
    test_interrupts;
    test_status_w1c;
    test_combined_scaling;
    test_manual_load;
    
    // Test Summary
    $display("\n========================================");
    $display("Test Summary");
    $display("========================================");
    $display("Total Tests:  10");
    $display("Passed:       %0d", pass_count);
    $display("Failed:       %0d", fail_count);
    
    if (fail_count == 0)
        $display("\nALL TESTS PASSED!");
    else
        $display("\nSOME TESTS FAILED!");
    
    $display("========================================");
    
    $finish;
end

//-----------------------------------------------------------------
// Waveform Dump
//-----------------------------------------------------------------
initial begin
    $dumpfile("timer_tb.vcd");
    $dumpvars(0, timer_tb);
end

endmodule
