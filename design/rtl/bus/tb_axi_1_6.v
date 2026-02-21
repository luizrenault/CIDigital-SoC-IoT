`timescale 1ns/1ps
`include "soc_addr_map.vh"

module tb_axi_1_6;

  // params (Verilog puro)
  parameter ADDR_WIDTH = 32;
  parameter DATA_WIDTH = 32;

  reg aclk;
  reg aresetn;

  // AXI-Lite Master signals
  reg  [ADDR_WIDTH-1:0]     s_axi_awaddr;
  reg                       s_axi_awvalid;
  wire                      s_axi_awready;

  reg  [DATA_WIDTH-1:0]     s_axi_wdata;
  reg  [(DATA_WIDTH/8)-1:0] s_axi_wstrb;
  reg                       s_axi_wvalid;
  wire                      s_axi_wready;

  wire [1:0]                s_axi_bresp;
  wire                      s_axi_bvalid;
  reg                       s_axi_bready;

  reg  [ADDR_WIDTH-1:0]     s_axi_araddr;
  reg                       s_axi_arvalid;
  wire                      s_axi_arready;

  wire [DATA_WIDTH-1:0]     s_axi_rdata;
  wire [1:0]                s_axi_rresp;
  wire                      s_axi_rvalid;
  reg                       s_axi_rready;

  // DUT
  soc_xbar_regs_top #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
    .REG_COUNT_PER_PORT(64)
  ) dut (
    .aclk(aclk),
    .aresetn(aresetn),

    .s_axi_awaddr (s_axi_awaddr),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),

    .s_axi_wdata  (s_axi_wdata),
    .s_axi_wstrb  (s_axi_wstrb),
    .s_axi_wvalid (s_axi_wvalid),
    .s_axi_wready (s_axi_wready),

    .s_axi_bresp  (s_axi_bresp),
    .s_axi_bvalid (s_axi_bvalid),
    .s_axi_bready (s_axi_bready),

    .s_axi_araddr (s_axi_araddr),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),

    .s_axi_rdata  (s_axi_rdata),
    .s_axi_rresp  (s_axi_rresp),
    .s_axi_rvalid (s_axi_rvalid),
    .s_axi_rready (s_axi_rready)
  );

  // Clock
  initial begin
    aclk = 1'b0;
    forever #5 aclk = ~aclk;
  end

  // ----------------------------
  // AXI-Lite tasks (sequenciais)
  // ----------------------------
  task axi_write32;
    input [31:0] addr;
    input [31:0] data;
    begin
      // AW
      s_axi_awaddr  = addr;
      s_axi_awvalid = 1'b1;
      while (!s_axi_awready) @(posedge aclk);
      @(posedge aclk);
      s_axi_awvalid = 1'b0;
      s_axi_awaddr  = 32'h0;

      // W
      s_axi_wdata   = data;
      s_axi_wstrb   = 4'hF;
      s_axi_wvalid  = 1'b1;
      while (!s_axi_wready) @(posedge aclk);
      @(posedge aclk);
      s_axi_wvalid  = 1'b0;
      s_axi_wdata   = 32'h0;
      s_axi_wstrb   = 4'h0;

      // B
      s_axi_bready  = 1'b1;
      while (!s_axi_bvalid) @(posedge aclk);
      if (s_axi_bresp !== 2'b00) begin
        $display("[TB][WRITE] FAIL addr=0x%08h bresp=%b", addr, s_axi_bresp);
        $finish;
      end
      @(posedge aclk);
      s_axi_bready  = 1'b0;
    end
  endtask

  task axi_read32;
    input  [31:0] addr;
    output [31:0] data_out;
    begin
      // AR
      s_axi_araddr  = addr;
      s_axi_arvalid = 1'b1;
      while (!s_axi_arready) @(posedge aclk);
      @(posedge aclk);
      s_axi_arvalid = 1'b0;
      s_axi_araddr  = 32'h0;

      // R
      s_axi_rready  = 1'b1;
      while (!s_axi_rvalid) @(posedge aclk);
      if (s_axi_rresp !== 2'b00) begin
        $display("[TB][READ] FAIL addr=0x%08h rresp=%b", addr, s_axi_rresp);
        $finish;
      end
      data_out = s_axi_rdata;
      @(posedge aclk);
      s_axi_rready = 1'b0;
    end
  endtask

  // helper: get base by index 0..5 using soc_addr_map defines
  function [31:0] base_of;
    input [2:0] idx;
    begin
      case (idx)
        3'd0: base_of = `AXI_GPIO_BASE;
        3'd1: base_of = `AXI_TIMER_BASE;
        3'd2: base_of = `AXI_UART_BASE;
        3'd3: base_of = `AXI_SPI_BASE;
        3'd4: base_of = `AXI_I2C_BASE;
        3'd5: base_of = `AXI_INTR_BASE;
        default: base_of = 32'h0;
      endcase
    end
  endfunction

  // Test
  reg [31:0] rd;
  reg [31:0] addr;
  reg [31:0] wr;
  integer p, k;

  initial begin
    // init
    s_axi_awaddr  = 0; s_axi_awvalid = 0;
    s_axi_wdata   = 0; s_axi_wstrb   = 0; s_axi_wvalid = 0;
    s_axi_bready  = 0;
    s_axi_araddr  = 0; s_axi_arvalid = 0;
    s_axi_rready  = 0;

    aresetn = 0;
    repeat (10) @(posedge aclk);
    aresetn = 1;
    repeat (2) @(posedge aclk);

    $display("=== TB: varrendo 6 perifericos e 3 offsets ===");

    for (p = 0; p < 6; p = p + 1) begin
      for (k = 0; k < 3; k = k + 1) begin
        addr = base_of(p[2:0]) + (k * 32'h4);
        wr   = 32'hA5A5_0000 | (p << 8) | k;

        $display("[TB] P%0d WRITE addr=0x%08h data=0x%08h", p, addr, wr);
        axi_write32(addr, wr);

        axi_read32(addr, rd);
        $display("[TB] P%0d READ  addr=0x%08h data=0x%08h", p, addr, rd);

        if (rd !== wr) begin
          $display("[TB][FAIL] MISMATCH p=%0d addr=0x%08h wrote=0x%08h read=0x%08h", p, addr, wr, rd);
          $finish;
        end
      end
    end

    $display("=== TB PASS: todos os perifericos OKAY e dados bateram ===");

    // Teste endereço inválido -> DECERR esperado do interconnect
    addr = 32'h5000_0000;
    $display("[TB] Teste DECERR (write/read) addr=0x%08h", addr);

    // Write inválido: espera bresp=11
    s_axi_awaddr  = addr; s_axi_awvalid = 1;
    while (!s_axi_awready) @(posedge aclk);
    @(posedge aclk); s_axi_awvalid = 0;

    s_axi_wdata = 32'hDEAD_BEEF; s_axi_wstrb = 4'hF; s_axi_wvalid = 1;
    while (!s_axi_wready) @(posedge aclk);
    @(posedge aclk); s_axi_wvalid = 0;

    s_axi_bready = 1;
    while (!s_axi_bvalid) @(posedge aclk);
    if (s_axi_bresp !== 2'b11) begin
      $display("[TB][FAIL] Esperava DECERR (11), veio bresp=%b", s_axi_bresp);
      $finish;
    end
    @(posedge aclk); s_axi_bready = 0;

    // Read inválido: espera rresp=11
    s_axi_araddr = addr; s_axi_arvalid = 1;
    while (!s_axi_arready) @(posedge aclk);
    @(posedge aclk); s_axi_arvalid = 0;

    s_axi_rready = 1;
    while (!s_axi_rvalid) @(posedge aclk);
    if (s_axi_rresp !== 2'b11) begin
      $display("[TB][FAIL] Esperava DECERR (11), veio rresp=%b", s_axi_rresp);
      $finish;
    end
    @(posedge aclk); s_axi_rready = 0;

    $display("[TB] DECERR OK.");
    $finish;
  end

endmodule
