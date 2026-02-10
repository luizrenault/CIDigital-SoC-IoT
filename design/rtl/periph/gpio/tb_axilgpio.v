`timescale 1ns/1ps

module tb_axilgpio;

reg clk = 0;
always #5 clk = ~clk; // 100 MHz

reg rstn = 0;

// ---------------- AXI-Lite ----------------
reg  awvalid=0;
wire awready;
reg  [4:0] awaddr=0;
reg  [2:0] awprot=0;

reg  wvalid=0;
wire wready;
reg  [31:0] wdata=0;
reg  [3:0]  wstrb=4'hF;

wire bvalid;
reg  bready=0;

reg  arvalid=0;
wire arready;
reg  [4:0] araddr=0;
reg  [2:0] arprot=0;

wire rvalid;
reg  rready=0;
wire [31:0] rdata;

// --------------- GPIO ---------------------
wire [29:0] o_gpio;
reg  [4:0]  i_gpio = 0;
wire        o_int;


// ==========================================
// DUT
// ==========================================
axilgpio #(
    .NOUT(30),
    .NIN(5)
) dut (
    .S_AXI_ACLK(clk),
    .S_AXI_ARESETN(rstn),

    .S_AXI_AWVALID(awvalid),
    .S_AXI_AWREADY(awready),
    .S_AXI_AWADDR(awaddr),
    .S_AXI_AWPROT(awprot),

    .S_AXI_WVALID(wvalid),
    .S_AXI_WREADY(wready),
    .S_AXI_WDATA(wdata),
    .S_AXI_WSTRB(wstrb),

    .S_AXI_BVALID(bvalid),
    .S_AXI_BREADY(bready),
    .S_AXI_BRESP(),

    .S_AXI_ARVALID(arvalid),
    .S_AXI_ARREADY(arready),
    .S_AXI_ARADDR(araddr),
    .S_AXI_ARPROT(arprot),

    .S_AXI_RVALID(rvalid),
    .S_AXI_RREADY(rready),
    .S_AXI_RDATA(rdata),
    .S_AXI_RRESP(),

    .o_gpio(o_gpio),
    .i_gpio(i_gpio),
    .o_int(o_int)
);


// ==========================================
// AXI WRITE
// ==========================================
task axi_write;
input [4:0] addr;
input [31:0] data;
begin
    @(posedge clk);
    awaddr  <= addr;
    awvalid <= 1;
    wdata   <= data;
    wvalid  <= 1;
    bready  <= 1;

    wait(awready && wready);
    @(posedge clk);
    awvalid <= 0;
    wvalid  <= 0;

    wait(bvalid);
    @(posedge clk);
    bready <= 0;

    $display("WRITE addr=%h data=%h", addr, data);
end
endtask


// ==========================================
// AXI READ
// ==========================================
task axi_read;
input [4:0] addr;
begin
    @(posedge clk);
    araddr  <= addr;
    arvalid <= 1;
    rready  <= 1;

    wait(arready);
    @(posedge clk);
    arvalid <= 0;

    wait(rvalid);
    $display("READ addr=%h data=%h", addr, rdata);

    @(posedge clk);
    rready <= 0;
end
endtask


// ==========================================
// TEST
// ==========================================
initial begin
    $display("=== AXILGPIO TEST ===");

    repeat(5) @(posedge clk);
    rstn = 1;

    // ------------------------------
    // LOAD
    // ------------------------------
    axi_write(5'h00, 32'h0000000F);
    axi_read (5'h00);

    // ------------------------------
    // SET bits
    // ------------------------------
    axi_write(5'h04, 32'h00000030);
    axi_read (5'h00);

    // ------------------------------
    // CLEAR bits
    // ------------------------------
    axi_write(5'h08, 32'h00000003);
    axi_read (5'h00);

    // ------------------------------
    // TOGGLE bits
    // ------------------------------
    axi_write(5'h0C, 32'h0000000C);
    axi_read (5'h00);

    // ------------------------------
    // INPUT read
    // ------------------------------
    i_gpio = 5'b10101;
    repeat(3) @(posedge clk);
    axi_read(5'h10);

    // ------------------------------
    // Enable interrupt mask
    // ------------------------------
    axi_write(5'h18, 32'h0000001F);

    // toggle input to trigger interrupt
    i_gpio = 5'b00101;
    repeat(4) @(posedge clk);

    axi_read(5'h14); // changed
    axi_read(5'h1C); // interrupt source

    $display("o_int = %b", o_int);

    repeat(10) @(posedge clk);
    $finish;
end

endmodule
