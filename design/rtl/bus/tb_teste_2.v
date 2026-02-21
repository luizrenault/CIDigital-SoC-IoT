`timescale 1ns/1ps
`include "soc_addr_map.vh"

module tb_soc_mem_periph;

  // ----------------------------
  // Clock / Reset
  // ----------------------------
  reg aclk;
  reg aresetn;

  initial begin
    aclk = 1'b0;
    forever #5 aclk = ~aclk; // 100 MHz
  end

  // ----------------------------
  // AXI-Lite Master (TB -> DUT)
  // ----------------------------
  reg  [31:0] m_axi_awaddr;
  reg         m_axi_awvalid;
  wire        m_axi_awready;
  reg  [2:0]  m_axi_awprot;

  reg  [31:0] m_axi_wdata;
  reg  [3:0]  m_axi_wstrb;
  reg         m_axi_wvalid;
  wire        m_axi_wready;

  wire        m_axi_bvalid;
  reg         m_axi_bready;

  reg  [31:0] m_axi_araddr;
  reg         m_axi_arvalid;
  wire        m_axi_arready;
  reg  [2:0]  m_axi_arprot;

  wire        m_axi_rvalid;
  reg         m_axi_rready;
  wire [31:0] m_axi_rdata;

  // ----------------------------
  // DUT: top com root 1x2 + RAM + 1x6 + regs
  // ----------------------------
  soc_top_teste_mem_periph dut (
    .aclk(aclk),
    .aresetn(aresetn),

    .m_axi_awaddr (m_axi_awaddr),
    .m_axi_awvalid(m_axi_awvalid),
    .m_axi_awready(m_axi_awready),
    .m_axi_awprot (m_axi_awprot),

    .m_axi_wdata  (m_axi_wdata),
    .m_axi_wstrb  (m_axi_wstrb),
    .m_axi_wvalid (m_axi_wvalid),
    .m_axi_wready (m_axi_wready),

    .m_axi_bvalid (m_axi_bvalid),
    .m_axi_bready (m_axi_bready),

    .m_axi_araddr (m_axi_araddr),
    .m_axi_arvalid(m_axi_arvalid),
    .m_axi_arready(m_axi_arready),
    .m_axi_arprot (m_axi_arprot),

    .m_axi_rvalid (m_axi_rvalid),
    .m_axi_rready (m_axi_rready),
    .m_axi_rdata  (m_axi_rdata)
  );

  // ----------------------------
  // AXI-Lite helper tasks
  // ----------------------------
  task axi_write32;
    input [31:0] addr;
    input [31:0] data;
    begin
      // AW
      m_axi_awaddr  = addr;
      m_axi_awprot  = 3'b000;
      m_axi_awvalid = 1'b1;
      while (!m_axi_awready) @(posedge aclk);
      @(posedge aclk);
      m_axi_awvalid = 1'b0;
      m_axi_awaddr  = 32'h0;

      // W
      m_axi_wdata   = data;
      m_axi_wstrb   = 4'hF;
      m_axi_wvalid  = 1'b1;
      while (!m_axi_wready) @(posedge aclk);
      @(posedge aclk);
      m_axi_wvalid  = 1'b0;
      m_axi_wdata   = 32'h0;
      m_axi_wstrb   = 4'h0;

      // B
      m_axi_bready  = 1'b1;
      while (!m_axi_bvalid) @(posedge aclk);
      @(posedge aclk);
      m_axi_bready  = 1'b0;
    end
  endtask

  task axi_read32;
    input  [31:0] addr;
    output [31:0] data_out;
    begin
      // AR
      m_axi_araddr  = addr;
      m_axi_arprot  = 3'b000;
      m_axi_arvalid = 1'b1;
      while (!m_axi_arready) @(posedge aclk);
      @(posedge aclk);
      m_axi_arvalid = 1'b0;
      m_axi_araddr  = 32'h0;

      // R
      m_axi_rready  = 1'b1;
      while (!m_axi_rvalid) @(posedge aclk);
      data_out = m_axi_rdata;
      @(posedge aclk);
      m_axi_rready  = 1'b0;
    end
  endtask

  // helper: base por índice (perif)
  function [31:0] periph_base_of;
    input [2:0] idx;
    begin
      case (idx)
        3'd0: periph_base_of = `AXI_GPIO_BASE;
        3'd1: periph_base_of = `AXI_TIMER_BASE;
        3'd2: periph_base_of = `AXI_UART_BASE;
        3'd3: periph_base_of = `AXI_SPI_BASE;
        3'd4: periph_base_of = `AXI_I2C_BASE;
        3'd5: periph_base_of = `AXI_INTR_BASE;
        default: periph_base_of = 32'h0;
      endcase
    end
  endfunction

  // ----------------------------
  // Test sequence
  // ----------------------------
  reg [31:0] rd;
  reg [31:0] addr;
  reg [31:0] wr;
  integer p, k;

  initial begin
    // init
    m_axi_awaddr  = 0; m_axi_awvalid = 0; m_axi_awprot = 0;
    m_axi_wdata   = 0; m_axi_wstrb   = 0; m_axi_wvalid = 0;
    m_axi_bready  = 0;
    m_axi_araddr  = 0; m_axi_arvalid = 0; m_axi_arprot = 0;
    m_axi_rready  = 0;

    // reset
    aresetn = 0;
    repeat (10) @(posedge aclk);
    aresetn = 1;
    repeat (5) @(posedge aclk);

    // =========================================================
// DUMP INICIAL DA MEMÓRIA
// =========================================================
$display("====================================================");
$display(" DUMP INICIAL DA ROM E RAM");
$display("====================================================");

// ---------------- ROM ----------------
$display("---- ROM (0x00000000) ----");
for (k = 0; k < 30; k = k + 1) begin
  addr = `AXI_ROM_BASE + (k * 32'h4);
  axi_read32(addr, rd);
  $display("[ROM] addr=%08h data=%08h", addr, rd);
end

// ---------------- RAM ----------------
$display("---- RAM (AXI_RAM_BASE) ----");
for (k = 0; k < 30; k = k + 1) begin
  addr = `AXI_RAM_BASE + (k * 32'h4);
  axi_read32(addr, rd);
  $display("[RAM] addr=%08h data=%08h", addr, rd);
end

$display("====================================================");


    // =========================================================
    // 1) Teste RAM (write/read)
    // =========================================================
    $display("---- TESTE RAM WRITE/READ ----");
    for (k = 0; k < 4; k = k + 1) begin
      addr = `AXI_RAM_BASE + (k * 32'h4);
      wr   = 32'hCAFE_0000 | k;

      $display("[TB][RAM] WRITE addr=0x%08h data=0x%08h", addr, wr);
      axi_write32(addr, wr);

      axi_read32(addr, rd);
      $display("[TB][RAM] READ  addr=0x%08h data=0x%08h", addr, rd);

      if (rd !== wr) begin
        $display("[TB][RAM][FAIL] Mismatch addr=0x%08h wrote=0x%08h read=0x%08h", addr, wr, rd);
        $finish;
      end
    end
    $display("[TB][RAM] PASS");

    // =========================================================
    // 2) Teste periféricos (varredura 6 portas)
    // =========================================================
    $display("---- TESTE PERIFERICOS (6 portas) ----");

    for (p = 0; p < 6; p = p + 1) begin
      for (k = 0; k < 3; k = k + 1) begin
        addr = periph_base_of(p[2:0]) + (k * 32'h4);
        wr   = 32'hA5A5_0000 | (p << 8) | k;

        $display("[TB][P%0d] WRITE addr=0x%08h data=0x%08h", p, addr, wr);
        axi_write32(addr, wr);

        axi_read32(addr, rd);
        $display("[TB][P%0d] READ  addr=0x%08h data=0x%08h", p, addr, rd);

        if (rd !== wr) begin
          $display("[TB][PERIPH][FAIL] Mismatch p=%0d addr=0x%08h wrote=0x%08h read=0x%08h", p, addr, wr, rd);
          $finish;
        end
      end
    end
    $display("[TB][PERIPH] PASS");

    $display("====================================================");
    $display(" TB PASS: dump inicial OK + RAM + 6 periféricos OK!");
    $display("====================================================");

    $finish;
  end

endmodule
