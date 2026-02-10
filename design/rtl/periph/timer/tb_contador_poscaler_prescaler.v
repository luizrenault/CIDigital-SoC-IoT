`timescale 1ns/1ps

module tb_timer_presc_then_post;

  // Clock / Reset
  reg clk = 0;
  reg rst = 1;

  always #5 clk = ~clk; // 100 MHz

  initial begin
    repeat (10) @(posedge clk);
    rst = 0;
  end

  // AXI-lite subset
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

  `include "timer_defs.v"

  timer dut (
    .clk_i(clk),
    .rst_i(rst),

    .cfg_awvalid_i(cfg_awvalid_i),
    .cfg_awaddr_i(cfg_awaddr_i),
    .cfg_wvalid_i(cfg_wvalid_i),
    .cfg_wdata_i(cfg_wdata_i),
    .cfg_wstrb_i(cfg_wstrb_i),
    .cfg_bready_i(cfg_bready_i),

    .cfg_arvalid_i(cfg_arvalid_i),
    .cfg_araddr_i(cfg_araddr_i),
    .cfg_rready_i(cfg_rready_i),

    .cfg_awready_o(cfg_awready_o),
    .cfg_wready_o(cfg_wready_o),
    .cfg_bvalid_o(cfg_bvalid_o),
    .cfg_bresp_o(cfg_bresp_o),

    .cfg_arready_o(cfg_arready_o),
    .cfg_rvalid_o(cfg_rvalid_o),
    .cfg_rdata_o(cfg_rdata_o),
    .cfg_rresp_o(cfg_rresp_o),

    .intr_o(intr_o)
  );

  // ------------------------------------------------------------
  // AXI helpers
  // ------------------------------------------------------------
  task axi_idle;
    begin
      cfg_awvalid_i = 0;
      cfg_awaddr_i  = 0;
      cfg_wvalid_i  = 0;
      cfg_wdata_i   = 0;
      cfg_wstrb_i   = 4'hF;
      cfg_bready_i  = 0;

      cfg_arvalid_i = 0;
      cfg_araddr_i  = 0;
      cfg_rready_i  = 0;
    end
  endtask

  task axi_write32;
    input [31:0] addr;
    input [31:0] data;
    integer cyc;
    begin
      cfg_arvalid_i = 0;

      cfg_awaddr_i  = addr;
      cfg_wdata_i   = data;
      cfg_wstrb_i   = 4'hF;

      cfg_awvalid_i = 1;
      cfg_wvalid_i  = 1;

      cyc = 0;
      while (!(cfg_awvalid_i && cfg_awready_o)) begin
        @(posedge clk);
        cyc = cyc + 1;
        if (cyc > 5000) begin
          $display("[%0t] ERROR: timeout esperando AWREADY (addr=0x%08x)", $time, addr);
          $finish;
        end
      end

      @(posedge clk);
      cfg_awvalid_i = 0;
      cfg_wvalid_i  = 0;

      cyc = 0;
      while (!cfg_bvalid_o) begin
        @(posedge clk);
        cyc = cyc + 1;
        if (cyc > 5000) begin
          $display("[%0t] ERROR: timeout esperando BVALID (addr=0x%08x)", $time, addr);
          $finish;
        end
      end

      cfg_bready_i = 1;
      @(posedge clk);
      cfg_bready_i = 0;

      @(posedge clk);
    end
  endtask

  task axi_read32;
    input  [31:0] addr;
    output [31:0] data;
    integer cyc;
    begin
      cfg_awvalid_i = 0;
      cfg_wvalid_i  = 0;

      cfg_araddr_i  = addr;
      cfg_arvalid_i = 1;

      cyc = 0;
      while (!(cfg_arvalid_i && cfg_arready_o)) begin
        @(posedge clk);
        cyc = cyc + 1;
        if (cyc > 5000) begin
          $display("[%0t] ERROR: timeout esperando ARREADY (addr=0x%08x)", $time, addr);
          $finish;
        end
      end

      @(posedge clk);
      cfg_arvalid_i = 0;

      cyc = 0;
      while (!cfg_rvalid_o) begin
        @(posedge clk);
        cyc = cyc + 1;
        if (cyc > 5000) begin
          $display("[%0t] ERROR: timeout esperando RVALID (addr=0x%08x)", $time, addr);
          $finish;
        end
      end

      data = cfg_rdata_o;

      cfg_rready_i = 1;
      @(posedge clk);
      cfg_rready_i = 0;

      @(posedge clk);
    end
  endtask

  // ------------------------------------------------------------
  // Helpers STATUS0 (W1C)
  // ------------------------------------------------------------
  task clear_status0;
    begin
`ifdef TIMER_STATUS0
      axi_write32({24'b0, `TIMER_STATUS0}, 32'h0000_0003); // limpa match + irq
`endif
    end
  endtask

  task clear_irq_pend;
    begin
`ifdef TIMER_STATUS0
      axi_write32({24'b0, `TIMER_STATUS0}, 32'h0000_0002); // limpa irq_pend
`endif
    end
  endtask

  // Wait IRQ com timeout (Verilog puro) - usando contador simples
  task wait_irq_or_timeout;
    input integer timeout_ns;
    output reg got_irq;
    integer elapsed_ns;
    begin
      got_irq = 0;
      elapsed_ns = 0;
      while (!intr_o && (elapsed_ns < timeout_ns)) begin
        #1;
        elapsed_ns = elapsed_ns + 1;
      end
      if (intr_o)
        got_irq = 1;
    end
  endtask

  // ------------------------------------------------------------
  // Configs
  // ------------------------------------------------------------
  // Fast simulation settings (was originally 12ms/500us)
  localparam integer PRESC_DIV = 1;        // No prescaling (10ns tick)
  localparam integer CMP_FAST  = 20;       // 20 ticks = 200ns
  localparam integer CMP_PERIOD = 5;       // 5 ticks = 50ns base
  localparam integer POST_1    = 1;
  localparam integer POST_5    = 5;

  // CTRL bits (from timer_defs.v):
  // bit1: TIMER_CTRL0_INTERRUPT, bit2: TIMER_CTRL0_ENABLE, bit3: TIMER_CTRL0_AUTORELOAD
  localparam [31:0] CTRL_ENABLE_IRQ        = 32'h0000_0006; // IRQ_EN=1, ENABLE=1, AUTO_RELOAD=0
  localparam [31:0] CTRL_ENABLE_IRQ_AR     = 32'h0000_000E; // IRQ_EN=1, ENABLE=1, AUTO_RELOAD=1

  time t0, t1;
  reg got_irq;
  reg [31:0] rdata;

  initial begin
    axi_idle();
    $dumpfile("tb_timer_presc_then_post.vcd");
    $dumpvars(0, tb_timer_presc_then_post);

    @(negedge rst);
    $display("[%0t] Reset liberado", $time);

`ifndef TIMER_PRESCALE0
    $display("FATAL: TIMER_PRESCALE0 não definido em timer_defs.v");
    $finish;
`endif
`ifndef TIMER_POSTSCALE0
    $display("FATAL: TIMER_POSTSCALE0 não definido em timer_defs.v");
    $finish;
`endif
`ifndef TIMER_STATUS0
    $display("FATAL: TIMER_STATUS0 não definido em timer_defs.v");
    $finish;
`endif
`ifndef TIMER_CTRL0_AUTORELOAD_R
    $display("FATAL: CTRL0_AUTORELOAD não definido em timer_defs.v");
    $finish;
`endif

    // ==========================================================
    // FASE 1: testar PRESCALER (~200ns)
    // PRESC_DIV=1 (10ns period) * CMP_FAST=20 = 200ns
    // ==========================================================
    $display("\n=== FASE 1: Prescaler -> IRQ em ~200ns ===");

    // disable e limpa
    axi_write32({24'b0, `TIMER_CTRL0}, 32'h0);
    clear_status0();

    // no prescaling (10ns tick)
    axi_write32({24'b0, `TIMER_PRESCALE0}, PRESC_DIV);
    axi_write32({24'b0, `TIMER_POSTSCALE0}, POST_1);

    // one-shot: autoreload = 0
    axi_write32({24'b0, `TIMER_VAL0}, 32'd0);
    axi_write32({24'b0, `TIMER_CMP0}, CMP_FAST);

    // enable + irq
    axi_write32({24'b0, `TIMER_CTRL0}, CTRL_ENABLE_IRQ);

    // espera IRQ
    t0 = $time;
    wait_irq_or_timeout(5_000, got_irq); // 5us timeout (plenty)

    if (!got_irq) begin
      $display("[%0t] ERROR: timeout IRQ fase 1", $time);
      $finish;
    end

    t1 = $time;
    $display("[%0t] IRQ fase 1 OK. Delta = %0t ns (esperado ~200 ns)", $time, (t1 - t0));

    // limpa IRQ para intr_o cair
    clear_irq_pend();
    repeat (5) @(posedge clk);

    // ==========================================================
    // FASE 2: testar POSTSCALER (~250ns)
    // Base: match a cada 50ns (CMP_PERIOD=5 com 10ns tick e AUTO_RELOAD=1)
    // Post: 5 matches => 50ns * 5 = 250ns
    // ==========================================================
    $display("\n=== FASE 2: Postscaler -> IRQ em ~250ns ===");

    // disable e limpa
    axi_write32({24'b0, `TIMER_CTRL0}, 32'h0);
    clear_status0();

    // mantém sem prescaling
    axi_write32({24'b0, `TIMER_PRESCALE0}, PRESC_DIV);

    // postscaler divide por 5
    axi_write32({24'b0, `TIMER_POSTSCALE0}, POST_5);

    // período base 50ns com autoreload
    axi_write32({24'b0, `TIMER_VAL0}, 32'd0);
    axi_write32({24'b0, `TIMER_CMP0}, CMP_PERIOD);

    // enable + irq + autoreload
    axi_write32({24'b0, `TIMER_CTRL0}, CTRL_ENABLE_IRQ_AR);

    // espera IRQ (~250ns). Timeout 5us.
    t0 = $time;
    wait_irq_or_timeout(5_000, got_irq);

    if (!got_irq) begin
      $display("[%0t] ERROR: timeout IRQ fase 2", $time);
      $finish;
    end

    t1 = $time;
    $display("[%0t] IRQ fase 2 OK. Delta = %0t ns (esperado ~250 ns)", $time, (t1 - t0));

    // limpa IRQ e termina
    clear_irq_pend();
    #1000;
    $finish;
  end

endmodule
