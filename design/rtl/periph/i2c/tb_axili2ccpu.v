`timescale 1ns/1ps

module tb_axili2ccpu;

// =====================================
// CLOCK / RESET
// =====================================
reg clk;
reg resetn;

initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100 MHz
end

initial begin
    resetn = 0;
    #100;
    resetn = 1;
end

// =====================================
// AXI-Lite SLAVE SIGNALS
// =====================================
reg         S_AXI_AWVALID;
wire        S_AXI_AWREADY;
reg  [3:0]  S_AXI_AWADDR;
reg  [2:0]  S_AXI_AWPROT;

reg         S_AXI_WVALID;
wire        S_AXI_WREADY;
reg  [31:0] S_AXI_WDATA;
reg  [3:0]  S_AXI_WSTRB;

wire        S_AXI_BVALID;
reg         S_AXI_BREADY;
wire [1:0]  S_AXI_BRESP;

reg         S_AXI_ARVALID;
wire        S_AXI_ARREADY;
reg  [3:0]  S_AXI_ARADDR;
reg  [2:0]  S_AXI_ARPROT;

wire        S_AXI_RVALID;
reg         S_AXI_RREADY;
wire [31:0] S_AXI_RDATA;
wire [1:0]  S_AXI_RRESP;

// =====================================
// AXI MASTER (dummy responses)
// =====================================
wire M_INSN_ARVALID;
reg  M_INSN_ARREADY = 1;

wire [31:0] M_INSN_ARADDR;
wire [2:0]  M_INSN_ARPROT;

reg  M_INSN_RVALID = 0;
wire M_INSN_RREADY;
reg  [31:0] M_INSN_RDATA = 0;
reg  [1:0]  M_INSN_RRESP = 0;

// =====================================
// AXI STREAM (dummy)
// =====================================
wire M_AXIS_TVALID;
reg  M_AXIS_TREADY = 1;
wire [7:0] M_AXIS_TDATA;
wire M_AXIS_TLAST;
wire M_AXIS_TID;

// =====================================
// I2C LINES (open drain simulation)
// =====================================
tri1 sda;
tri1 scl;

pullup(sda);
pullup(scl);

// =====================================
// OUTROS
// =====================================
reg i_sync_signal = 0;
wire [31:0] o_debug;

// =====================================
// DUT
// =====================================
axili2ccpu dut (
    .S_AXI_ACLK(clk),
    .S_AXI_ARESETN(resetn),

    .S_AXI_AWVALID(S_AXI_AWVALID),
    .S_AXI_AWREADY(S_AXI_AWREADY),
    .S_AXI_AWADDR(S_AXI_AWADDR),
    .S_AXI_AWPROT(S_AXI_AWPROT),

    .S_AXI_WVALID(S_AXI_WVALID),
    .S_AXI_WREADY(S_AXI_WREADY),
    .S_AXI_WDATA(S_AXI_WDATA),
    .S_AXI_WSTRB(S_AXI_WSTRB),

    .S_AXI_BVALID(S_AXI_BVALID),
    .S_AXI_BREADY(S_AXI_BREADY),
    .S_AXI_BRESP(S_AXI_BRESP),

    .S_AXI_ARVALID(S_AXI_ARVALID),
    .S_AXI_ARREADY(S_AXI_ARREADY),
    .S_AXI_ARADDR(S_AXI_ARADDR),
    .S_AXI_ARPROT(S_AXI_ARPROT),

    .S_AXI_RVALID(S_AXI_RVALID),
    .S_AXI_RREADY(S_AXI_RREADY),
    .S_AXI_RDATA(S_AXI_RDATA),
    .S_AXI_RRESP(S_AXI_RRESP),

    // AXI master dummy
    .M_INSN_ARVALID(M_INSN_ARVALID),
    .M_INSN_ARREADY(M_INSN_ARREADY),
    .M_INSN_ARADDR(M_INSN_ARADDR),
    .M_INSN_ARPROT(M_INSN_ARPROT),

    .M_INSN_RVALID(M_INSN_RVALID),
    .M_INSN_RREADY(M_INSN_RREADY),
    .M_INSN_RDATA(M_INSN_RDATA),
    .M_INSN_RRESP(M_INSN_RRESP),

    // I2C
    .i_i2c_sda(sda),
    .i_i2c_scl(scl),
    .o_i2c_sda(sda),
    .o_i2c_scl(scl),

    // AXIS
    .M_AXIS_TVALID(M_AXIS_TVALID),
    .M_AXIS_TREADY(M_AXIS_TREADY),
    .M_AXIS_TDATA(M_AXIS_TDATA),
    .M_AXIS_TLAST(M_AXIS_TLAST),
    .M_AXIS_TID(M_AXIS_TID),

    .i_sync_signal(i_sync_signal),
    .o_debug(o_debug)
);

// =====================================
// AXI INIT
// =====================================
initial begin
    S_AXI_AWVALID = 0;
    S_AXI_WVALID  = 0;
    S_AXI_BREADY  = 0;
    S_AXI_ARVALID = 0;
    S_AXI_RREADY  = 0;
    S_AXI_AWPROT  = 0;
    S_AXI_ARPROT  = 0;
    S_AXI_WSTRB   = 4'hF;
end

// =====================================
// AXI TASKS
// =====================================

task axi_write;
input [3:0] addr;
input [31:0] data;
begin
    @(posedge clk);
    S_AXI_AWADDR  <= addr;
    S_AXI_WDATA   <= data;
    S_AXI_AWVALID <= 1;
    S_AXI_WVALID  <= 1;

    wait(S_AXI_AWREADY && S_AXI_WREADY);

    @(posedge clk);
    S_AXI_AWVALID <= 0;
    S_AXI_WVALID  <= 0;

    S_AXI_BREADY <= 1;
    wait(S_AXI_BVALID);
    @(posedge clk);
    S_AXI_BREADY <= 0;

    $display("WRITE OK addr=%h data=%h", addr, data);
end
endtask


task axi_read;
input [3:0] addr;
begin
    @(posedge clk);
    S_AXI_ARADDR  <= addr;
    S_AXI_ARVALID <= 1;

    wait(S_AXI_ARREADY);
    @(posedge clk);
    S_AXI_ARVALID <= 0;

    S_AXI_RREADY <= 1;
    wait(S_AXI_RVALID);

    $display("READ addr=%h data=%h", addr, S_AXI_RDATA);

    @(posedge clk);
    S_AXI_RREADY <= 0;
end
endtask

// =====================================
// TESTE PRINCIPAL
// =====================================
initial begin

    wait(resetn);
    #50;

    $display("TESTE CONTROL");
    axi_write(4'h0, 32'h00080000);

    #50;
    axi_read(4'h0);

    $display("TESTE CKCOUNT");
    axi_write(4'hC, 32'd200);

    #50;
    axi_read(4'hC);

    $display("TESTE ADDRESS");
    axi_write(4'h8, 32'h00000050);

    #50;
    axi_read(4'h8);

    #1000;

    $display("Fim da simulacao");
    $stop;
end

endmodule
