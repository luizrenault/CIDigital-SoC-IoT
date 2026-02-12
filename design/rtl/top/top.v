`timescale 1ns/1ps
// -----------------------------------------------------------------------------
// fpga_rv32 (TOP adaptado)
// - Conecta o vetor de IRQ vindo do AXI_perifericos ao PicoRV32 (.irq[31:0]).
// - Mantém o interconnect 1x2 existente: S0=RAM (0x0000_0000), S1=Periféricos (0x3000_0000).
// - Substitui o antigo GPIO simples no S1 por AXI_perifericos (GPIO+TIMER+INTCTL).
//   UART/SPI/I2C desabilitados aqui para simplificar o topo (sem pinos externos).
// -----------------------------------------------------------------------------
/*module fpga_rv32 #(
    // Compatível com seu TB: a RAM interna pode carregar via +firmware=...
    parameter [8*256-1:0] INIT_RAM_FILE = "firmware.hex.txt"
)(
    input  wire clk,
    input  wire resetn,
    output wire led
);
    // ----------------- PicoRV32 (AXI master) -----------------
    wire        m_awvalid, m_awready;
    wire [31:0] m_awaddr;  wire [2:0] m_awprot;
    wire        m_wvalid,  m_wready;
    wire [31:0] m_wdata;   wire [3:0] m_wstrb;
    wire        m_bvalid;  wire        m_bready;
    wire        m_arvalid, m_arready;
    wire [31:0] m_araddr;  wire [2:0] m_arprot;
    wire        m_rvalid;  wire        m_rready;
    wire [31:0] m_rdata;

    wire        trap;
    wire        trace_valid;
    wire [35:0] trace_data;

    // ----------------- Interconnect 1×2 -----------------
    // S0: RAM  @ 0x0000_0000 / 64 KiB
    // S1: PERIFS @ 0x3000_0000 / 4 KiB
    wire        s0_awvalid, s0_awready; wire [31:0] s0_awaddr; wire [2:0] s0_awprot;
    wire        s0_wvalid,  s0_wready;  wire [31:0] s0_wdata;  wire [3:0] s0_wstrb;
    wire        s0_bvalid,  s0_bready;
    wire        s0_arvalid, s0_arready; wire [31:0] s0_araddr; wire [2:0] s0_arprot;
    wire        s0_rvalid,  s0_rready;  wire [31:0] s0_rdata;

    wire        s1_awvalid, s1_awready; wire [31:0] s1_awaddr; wire [2:0] s1_awprot;
    wire        s1_wvalid,  s1_wready;  wire [31:0] s1_wdata;  wire [3:0] s1_wstrb;
    wire        s1_bvalid,  s1_bready;
    wire        s1_arvalid, s1_arready; wire [31:0] s1_araddr; wire [2:0] s1_arprot;
    wire        s1_rvalid,  s1_rready;  wire [31:0] s1_rdata;

    // ----------------- IRQ do subsistema de periféricos -----------------
    wire        cpu_irq;           // linha OR (debug)
    wire [31:0] irq_vec_masked;   // vetor para o PicoRV32

    // ----------------- CPU: liga IRQ ao vetor do INTCTL -----------------
    picorv32_axi #(
        .ENABLE_MUL   (1),
        .ENABLE_DIV   (1),
        .ENABLE_IRQ   (1),
        .ENABLE_TRACE (0)
        // .PROGADDR_RESET(32'h0000_0000)
        // .PROGADDR_IRQ  (32'h0000_0010)
    ) cpu (
        .clk             (clk),
        .resetn          (resetn),
        .trap            (trap),

        .mem_axi_awvalid (m_awvalid),
        .mem_axi_awready (m_awready),
        .mem_axi_awaddr  (m_awaddr),
        .mem_axi_awprot  (m_awprot),

        .mem_axi_wvalid  (m_wvalid),
        .mem_axi_wready  (m_wready),
        .mem_axi_wdata   (m_wdata),
        .mem_axi_wstrb   (m_wstrb),

        .mem_axi_bvalid  (m_bvalid),
        .mem_axi_bready  (m_bready),

        .mem_axi_arvalid (m_arvalid),
        .mem_axi_arready (m_arready),
        .mem_axi_araddr  (m_araddr),
        .mem_axi_arprot  (m_arprot),

        .mem_axi_rvalid  (m_rvalid),
        .mem_axi_rready  (m_rready),
        .mem_axi_rdata   (m_rdata),

        .irq             (irq_vec_masked),   // <<<<< NOVO: vetor do INTCTL

        .trace_valid     (trace_valid),
        .trace_data      (trace_data)
    );

    // ----------------- RAM (S0) -----------------
    // Mantém sua RAM AXI-Lite mapeada em 0x0000_0000 (64 KiB)
    AXI_mem #(
        .BASE_ADDR     (32'h0000_0000),
        .ADDR_MASK     (32'hFFFF_0000), // 64 KiB
        .INIT_RAM_FILE (INIT_RAM_FILE)
    ) ram0 (
        .clk    (clk),
        .resetn (resetn),
        .awvalid(s0_awvalid), .awready(s0_awready), .awaddr(s0_awaddr), .awprot(s0_awprot),
        .wvalid (s0_wvalid ), .wready (s0_wready ), .wdata (s0_wdata ), .wstrb (s0_wstrb ),
        .bvalid (s0_bvalid ), .bready (s0_bready ),
        .arvalid(s0_arvalid), .arready(s0_arready), .araddr(s0_araddr), .arprot(s0_arprot),
        .rvalid (s0_rvalid ), .rready (s0_rready ), .rdata (s0_rdata )
    );

    // ----------------- Periféricos (S1 @ 0x3000_0000) -----------------
    // Habilita GPIO(1bit) + TIMER + INTCTL; UART/SPI/I2C desativados
    wire [0:0] gpio_out_w;
    // dummies para portas não usadas
    wire uart_txd_w;  wire uart_rts_w;  wire spi_sclk_w; wire spi_mosi_w; wire [3:0] spi_cs_n_w; wire i2c_scl_drv_w; wire i2c_sda_drv_w;
    wire uart_rxd_w = 1'b1;  // idle
    wire uart_cts_w = 1'b0;  // CTS não usado
    wire spi_miso_w = 1'b0;  // MISO não usado
    wire i2c_scl_in_w = 1'b1, i2c_sda_in_w = 1'b1; // linhas liberadas

    AXI_perifericos #(
        .BASE_ADDR (32'h3000_0000),
        .GPIO_NBITS(1),
        .EN_GPIO   (1),
        .EN_TIMER  (1),
        .EN_UART   (0),
        .EN_SPI    (0),
        .EN_I2C    (0),
        .EN_INTCTL (1)
    ) perifs (
        .clk   (clk),
        .resetn(resetn),
        // AXI-Lite (porta S1 do xbar)
        .s_awvalid(s1_awvalid), .s_awready(s1_awready), .s_awaddr(s1_awaddr), .s_awprot(s1_awprot),
        .s_wvalid (s1_wvalid ), .s_wready (s1_wready ), .s_wdata (s1_wdata ), .s_wstrb (s1_wstrb ),
        .s_bvalid (s1_bvalid ), .s_bready (s1_bready ),
        .s_arvalid(s1_arvalid), .s_arready(s1_arready), .s_araddr(s1_araddr), .s_arprot(s1_arprot),
        .s_rvalid (s1_rvalid ), .s_rready (s1_rready ), .s_rdata (s1_rdata ),
        // IO periféricos
        .gpio_out(gpio_out_w), .led_out(led),
        .uart_txd(uart_txd_w), .uart_rxd(uart_rxd_w), .uart_cts_i(uart_cts_w), .uart_rts_o(uart_rts_w),
        .spi_sclk(spi_sclk_w), .spi_mosi(spi_mosi_w), .spi_miso(spi_miso_w), .spi_cs_n(spi_cs_n_w),
        .i2c_scl_in(i2c_scl_in_w), .i2c_scl_drive_low(i2c_scl_drv_w),
        .i2c_sda_in(i2c_sda_in_w), .i2c_sda_drive_low(i2c_sda_drv_w),
        // IRQs
        .cpu_irq(cpu_irq),
        .irq_vec_masked(irq_vec_masked)
    );

    // LED: já conectado via perifs.led_out

    // ----------------- Crossbar 1×2 -----------------
    axi_lite_ic_1x2 #(
        .S0_BASE(32'h0000_0000), .S0_MASK(32'hFFFF_0000), // 64 KiB
        .S1_BASE(32'h3000_0000), .S1_MASK(32'hFFFF_F000)  // 4 KiB
    ) xbar (
        .clk(clk), .resetn(resetn),
        // master
        .m_awvalid(m_awvalid), .m_awready(m_awready),
        .m_awaddr (m_awaddr ), .m_awprot (m_awprot ),
        .m_wvalid (m_wvalid ), .m_wready (m_wready ),
        .m_wdata  (m_wdata  ), .m_wstrb  (m_wstrb  ),
        .m_bvalid (m_bvalid ), .m_bready (m_bready ),
        .m_arvalid(m_arvalid), .m_arready(m_arready),
        .m_araddr (m_araddr ), .m_arprot (m_arprot ),
        .m_rvalid (m_rvalid ), .m_rready (m_rready ),
        .m_rdata  (m_rdata  ),
        // S0
        .s0_awvalid(s0_awvalid), .s0_awready(s0_awready),
        .s0_awaddr (s0_awaddr ), .s0_awprot (s0_awprot ),
        .s0_wvalid (s0_wvalid ), .s0_wready (s0_wready ),
        .s0_wdata  (s0_wdata  ), .s0_wstrb  (s0_wstrb  ),
        .s0_bvalid (s0_bvalid ), .s0_bready (s0_bready ),
        .s0_arvalid(s0_arvalid), .s0_arready(s0_arready),
        .s0_araddr (s0_araddr ), .s0_arprot (s0_arprot ),
        .s0_rvalid (s0_rvalid ), .s0_rready (s0_rready ),
        .s0_rdata  (s0_rdata  ),
        // S1
        .s1_awvalid(s1_awvalid), .s1_awready(s1_awready),
        .s1_awaddr (s1_awaddr ), .s1_awprot (s1_awprot ),
        .s1_wvalid (s1_wvalid ), .s1_wready (s1_wready ),
        .s1_wdata  (s1_wdata  ), .s1_wstrb  (s1_wstrb  ),
        .s1_bvalid (s1_bvalid ), .s1_bready (s1_bready ),
        .s1_arvalid(s1_arvalid), .s1_arready(s1_arready),
        .s1_araddr (s1_araddr ), .s1_arprot (s1_arprot ),
        .s1_rvalid (s1_rvalid ), .s1_rready (s1_rready ),
        .s1_rdata  (s1_rdata  )
    );

endmodule
*/

`timescale 1ns/1ps

module fpga_rv32 #(
    // Mantido para compatibilidade com o TB (override ok).
    // A RAM carrega o firmware via +firmware=... dentro do próprio módulo.
    parameter [8*256-1:0] INIT_RAM_FILE = "firmware.hex.txt"
)(
    input  wire clk,
    input  wire resetn,
    output wire led
);
    // ----------------- PicoRV32 (AXI master) -----------------
    wire        m_awvalid, m_awready;
    wire [31:0] m_awaddr;  wire [2:0] m_awprot;
    wire        m_wvalid,  m_wready;
    wire [31:0] m_wdata;   wire [3:0] m_wstrb;
    wire        m_bvalid;  wire        m_bready;
    wire        m_arvalid, m_arready;
    wire [31:0] m_araddr;  wire [2:0] m_arprot;
    wire        m_rvalid;  wire        m_rready;
    wire [31:0] m_rdata;

    wire        trap;
    wire        trace_valid;
    wire [35:0] trace_data;
    wire [31:0] irq = 32'b0;

    picorv32_axi #(
        .ENABLE_MUL     (1),
        .ENABLE_DIV     (1),
        .ENABLE_IRQ     (1),
        .ENABLE_TRACE   (0),
        .COMPRESSED_ISA (1)
        // Se disponível na tua versão:
        // ,.PROGADDR_RESET(32'h0000_0000)
        // ,.PROGADDR_IRQ  (32'h0000_0010)
    ) cpu (
        .clk             (clk),
        .resetn          (resetn),
        .trap            (trap),

        .mem_axi_awvalid (m_awvalid),
        .mem_axi_awready (m_awready),
        .mem_axi_awaddr  (m_awaddr),
        .mem_axi_awprot  (m_awprot),

        .mem_axi_wvalid  (m_wvalid),
        .mem_axi_wready  (m_wready),
        .mem_axi_wdata   (m_wdata),
        .mem_axi_wstrb   (m_wstrb),

        .mem_axi_bvalid  (m_bvalid),
        .mem_axi_bready  (m_bready),

        .mem_axi_arvalid (m_arvalid),
        .mem_axi_arready (m_arready),
        .mem_axi_araddr  (m_araddr),
        .mem_axi_arprot  (m_arprot),

        .mem_axi_rvalid  (m_rvalid),
        .mem_axi_rready  (m_rready),
        .mem_axi_rdata   (m_rdata),

        .irq             (irq),

        .trace_valid     (trace_valid),
        .trace_data      (trace_data)
    );

    // ----------------- Interconnect 1×2 -----------------
    // S0: RAM  @ 0x0000_0000 / 64 KiB
    // S1: PERIPHERALS @ 0x0020_0000 / 16 KiB (4 slots de 4 KiB)
    wire        s0_awvalid, s0_awready;
    wire [31:0] s0_awaddr;  wire [2:0] s0_awprot;
    wire        s0_wvalid,  s0_wready;
    wire [31:0] s0_wdata;   wire [3:0] s0_wstrb;
    wire        s0_bvalid;  wire        s0_bready;
    wire        s0_arvalid, s0_arready;
    wire [31:0] s0_araddr;  wire [2:0] s0_arprot;
    wire        s0_rvalid;  wire        s0_rready;
    wire [31:0] s0_rdata;

    wire        s1_awvalid, s1_awready;
    wire [31:0] s1_awaddr;  wire [2:0] s1_awprot;
    wire        s1_wvalid,  s1_wready;
    wire [31:0] s1_wdata;   wire [3:0] s1_wstrb;
    wire        s1_bvalid;  wire        s1_bready;
    wire        s1_arvalid, s1_arready;
    wire [31:0] s1_araddr;  wire [2:0] s1_arprot;
    wire        s1_rvalid;  wire        s1_rready;
    wire [31:0] s1_rdata;

    axi_lite_ic_1x2 #(
        .S0_BASE(32'h0000_0000), .S0_MASK(32'hFFFF_0000), // 64 KiB
        .S1_BASE(32'h0020_0000), .S1_MASK(32'hFFFF_C000)  // 16 KiB (0x0020_0000..0x0020_3FFF)
    ) xbar_1x2 (
        .clk(clk), .resetn(resetn),

        // master (CPU)
        .m_awvalid(m_awvalid), .m_awready(m_awready),
        .m_awaddr (m_awaddr ), .m_awprot (m_awprot ),
        .m_wvalid (m_wvalid ), .m_wready (m_wready ),
        .m_wdata  (m_wdata  ), .m_wstrb  (m_wstrb  ),
        .m_bvalid (m_bvalid ), .m_bready (m_bready ),
        .m_arvalid(m_arvalid), .m_arready(m_arready),
        .m_araddr (m_araddr ), .m_arprot (m_arprot ),
        .m_rvalid (m_rvalid ), .m_rready (m_rready ),
        .m_rdata  (m_rdata  ),

        // S0
        .s0_awvalid(s0_awvalid), .s0_awready(s0_awready),
        .s0_awaddr (s0_awaddr ), .s0_awprot (s0_awprot ),
        .s0_wvalid (s0_wvalid ), .s0_wready (s0_wready ),
        .s0_wdata  (s0_wdata  ), .s0_wstrb  (s0_wstrb  ),
        .s0_bvalid (s0_bvalid ), .s0_bready (s0_bready ),
        .s0_arvalid(s0_arvalid), .s0_arready(s0_arready),
        .s0_araddr (s0_araddr ), .s0_arprot (s0_arprot ),
        .s0_rvalid (s0_rvalid ), .s0_rready (s0_rready ),
        .s0_rdata  (s0_rdata  ),

        // S1
        .s1_awvalid(s1_awvalid), .s1_awready(s1_awready),
        .s1_awaddr (s1_awaddr ), .s1_awprot (s1_awprot ),
        .s1_wvalid (s1_wvalid ), .s1_wready (s1_wready ),
        .s1_wdata  (s1_wdata  ), .s1_wstrb  (s1_wstrb  ),
        .s1_bvalid (s1_bvalid ), .s1_bready (s1_bready ),
        .s1_arvalid(s1_arvalid), .s1_arready(s1_arready),
        .s1_araddr (s1_araddr ), .s1_arprot (s1_arprot ),
        .s1_rvalid (s1_rvalid ), .s1_rready (s1_rready ),
        .s1_rdata  (s1_rdata  )
    );

    // ----------------- S0: RAM -----------------
    // Carrega via +firmware=... (dentro do axi_lite_ram)
    axi_lite_ram #(
        .MEM_BYTES(64*1024)
    ) ram0 (
        .clk    (clk),
        .resetn (resetn),

        .awvalid(s0_awvalid),
        .awready(s0_awready),
        .awaddr (s0_awaddr),
        .awprot (s0_awprot),

        .wvalid (s0_wvalid),
        .wready (s0_wready),
        .wdata  (s0_wdata),
        .wstrb  (s0_wstrb),

        .bvalid (s0_bvalid),
        .bready (s0_bready),

        .arvalid(s0_arvalid),
        .arready(s0_arready),
        .araddr (s0_araddr),
        .arprot (s0_arprot),

        .rvalid (s0_rvalid),
        .rready (s0_rready),
        .rdata  (s0_rdata)
    );

    // ----------------- S1: bloco de periféricos -----------------
    wire led_inner;
    peripherals_axi #(
        .BASE_ADDR(32'h0020_0000),
        .ENABLE_S0(1), .ENABLE_S1(0), .ENABLE_S2(0), .ENABLE_S3(0)
    ) periph (
        .clk(clk), .resetn(resetn),

        // AXI-Lite slave (porta S1 do 1x2)
        .s_awvalid(s1_awvalid), .s_awready(s1_awready),
        .s_awaddr (s1_awaddr ), .s_awprot (s1_awprot ),
        .s_wvalid (s1_wvalid ), .s_wready (s1_wready ),
        .s_wdata  (s1_wdata  ), .s_wstrb  (s1_wstrb  ),
        .s_bvalid (s1_bvalid ), .s_bready (s1_bready ),
        .s_arvalid(s1_arvalid), .s_arready(s1_arready),
        .s_araddr (s1_araddr ), .s_arprot (s1_arprot ),
        .s_rvalid (s1_rvalid ), .s_rready (s1_rready ),
        .s_rdata  (s1_rdata  ),

        // LED do GPIO (slot 0)
        .led_out(led_inner)
    );

    assign led = led_inner; // invert if active-low

endmodule


