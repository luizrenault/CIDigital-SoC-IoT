// -----------------------------------------------------------------------------
// soc_top_teste_mem_periph.v
//
// Top de teste com:
//   Master AXI-Lite (externo / TB) ->
//     axi_lite_ic_1x2 (root: MEM vs PERIPH) ->
//        S0: axi_lite_ram (RAM)
//        S1: axi_lite_interconnect_1x6 -> axi_lite_slaves_6regs (regs)
//
// Usa soc_addr_map.vh para endereços/máscaras.
// -----------------------------------------------------------------------------

`include "soc_addr_map.vh"

module soc_top_teste_mem_periph #(
    parameter integer ADDR_WIDTH = 32,
    parameter integer DATA_WIDTH = 32,

    localparam NUM_SS_BITS = 1, //para o SPI Master (1 chip select)
    localparam C_AXI_ADDR_WIDTH = 5, // Para os periféricos GPIO. O módulo pode truncar os bits mais altos.

    // Tamanho pedido da RAM (o módulo arredonda pra potência de 2 internamente)
    parameter integer RAM_BYTES_REQ = 64*1024,

    // Quantos registradores de 32b por periférico fake
    parameter integer REG_COUNT_PER_PORT = 64    
)(
    input  wire                      aclk,
    input  wire                      aresetn,

    // UART
    input  uart_rx,
    output uart_tx,
    /////////////////////////////////
    // GPIO
    input  wire [4:0]  gpio_i, // Exemplo: 5 botões
    output wire [29:0] gpio_o, // Exemplo: 30 LEDs/Sinais
    ////////////////////////////////
    // SPI
    output wire       spi_sclk_o,
    output wire       spi_mosi_o,
    input  wire       spi_miso_i,
    output wire [NUM_SS_BITS-1:0] spi_ss_n_o, // Chip Select (vetor, pois NUM_SS_BITS=1)
    /////////////////////////////////
    // --- I2C (Bidirecionais) ---
    inout wire i2c_sda,
    inout wire i2c_scl,
    // ---------------------------
    output wire trap // output do PICORV32 / Sinal de Debug / Trap (Opcional, útil para ver se travou)
);
    // -----------------------------------------------------------
    // Sinais internos para conectar CPU <-> Interconnect
    // -----------------------------------------------------------
    wire cpu_awvalid; wire cpu_awready; wire [ADDR_WIDTH-1:0] cpu_awaddr; wire [2:0] cpu_awprot;
    wire cpu_wvalid;  wire cpu_wready;  wire [DATA_WIDTH-1:0] cpu_wdata;  wire [(DATA_WIDTH/8)-1:0] cpu_wstrb;
    wire cpu_bvalid;  wire cpu_bready;
    wire cpu_arvalid; wire cpu_arready; wire [ADDR_WIDTH-1:0] cpu_araddr; wire [2:0] cpu_arprot;
    wire cpu_rvalid;  wire cpu_rready;  wire [DATA_WIDTH-1:0] cpu_rdata;

    // Fio global que sai do INTC e entra na CPU
    wire cpu_global_irq;

    // -----------------------------------------------------------
    // Instância do PicoRV32 com Wrapper AXI
    // -----------------------------------------------------------
    picorv32_axi #(
        .PROGADDR_RESET(32'h0000_0000), // Onde o código começa (sua ROM/RAM base)
        .PROGADDR_IRQ(32'h0000_0010),   // Endereço de interrupção
        .BARREL_SHIFTER(1),
        .ENABLE_MUL(1),
        .ENABLE_DIV(1)
    ) u_cpu (
        .clk            (aclk),
        .resetn         (aresetn),
        .trap           (trap),

        .irq    ({31'b0, cpu_global_irq}),

        // Conexão AXI Master (Saída da CPU)
        .mem_axi_awvalid(cpu_awvalid),
        .mem_axi_awready(cpu_awready),
        .mem_axi_awaddr (cpu_awaddr),
        .mem_axi_awprot (cpu_awprot),

        .mem_axi_wvalid (cpu_wvalid),
        .mem_axi_wready (cpu_wready),
        .mem_axi_wdata  (cpu_wdata),
        .mem_axi_wstrb  (cpu_wstrb),

        .mem_axi_bready (cpu_bready),
        .mem_axi_bvalid (cpu_bvalid),
        
        .mem_axi_arvalid(cpu_arvalid),
        .mem_axi_arready(cpu_arready),
        .mem_axi_araddr (cpu_araddr),
        .mem_axi_arprot (cpu_arprot),

        .mem_axi_rready (cpu_rready),
        .mem_axi_rvalid (cpu_rvalid),
        .mem_axi_rdata  (cpu_rdata)
    );


    // =========================================================================
    // Root interconnect 1x2 wires (MEM=S0, PERIPH=S1)
    // =========================================================================
    // S0 (MEM)
    wire        mem_awvalid; wire mem_awready; wire [ADDR_WIDTH-1:0] mem_awaddr; wire [2:0] mem_awprot;
    wire        mem_wvalid;  wire mem_wready;  wire [DATA_WIDTH-1:0] mem_wdata;  wire [(DATA_WIDTH/8)-1:0] mem_wstrb;
    wire        mem_bvalid;  wire mem_bready;
    wire        mem_arvalid; wire mem_arready; wire [ADDR_WIDTH-1:0] mem_araddr; wire [2:0] mem_arprot;
    wire        mem_rvalid;  wire mem_rready;  wire [DATA_WIDTH-1:0] mem_rdata;

    // S1 (PERIPH)
    wire        per_awvalid; wire per_awready; wire [ADDR_WIDTH-1:0] per_awaddr; wire [2:0] per_awprot;
    wire        per_wvalid;  wire per_wready;  wire [DATA_WIDTH-1:0] per_wdata;  wire [(DATA_WIDTH/8)-1:0] per_wstrb;
    wire        per_bvalid;  wire per_bready;
    wire        per_arvalid; wire per_arready; wire [ADDR_WIDTH-1:0] per_araddr; wire [2:0] per_arprot;
    wire        per_rvalid;  wire per_rready;  wire [DATA_WIDTH-1:0] per_rdata;

    // =========================================================================
    // ROOT IC: axi_lite_ic_1x2 (MEM vs PERIPH)
    // =========================================================================
    axi_lite_ic_1x2 #(
        .S0_BASE(`AXI_MEM_REGION_BASE),
        .S0_MASK(`AXI_MEM_REGION_MASK),
        .S1_BASE(`AXI_PERIPH_REGION_BASE),
        .S1_MASK(`AXI_PERIPH_REGION_MASK)
    ) u_root_ic (
        .clk    (aclk),
        .resetn (aresetn),

        // Master (PICORV32)
        .m_awvalid(cpu_awvalid), .m_awready(cpu_awready),
        .m_awaddr (cpu_awaddr),  .m_awprot (cpu_awprot),
        .m_wvalid (cpu_wvalid),  .m_wready (cpu_wready),
        .m_wdata  (cpu_wdata),   .m_wstrb  (cpu_wstrb),
        .m_bvalid (cpu_bvalid),  .m_bready (cpu_bready),
        .m_arvalid(cpu_arvalid), .m_arready(cpu_arready),
        .m_araddr (cpu_araddr),  .m_arprot (cpu_arprot),
        .m_rvalid (cpu_rvalid),  .m_rready (cpu_rready),
        .m_rdata  (cpu_rdata),

        // Slave 0 = MEM
        .s0_awvalid(mem_awvalid), .s0_awready(mem_awready),
        .s0_awaddr (mem_awaddr),  .s0_awprot (mem_awprot),
        .s0_wvalid (mem_wvalid),  .s0_wready (mem_wready),
        .s0_wdata  (mem_wdata),   .s0_wstrb  (mem_wstrb),
        .s0_bvalid (mem_bvalid),  .s0_bready (mem_bready),
        .s0_arvalid(mem_arvalid), .s0_arready(mem_arready),
        .s0_araddr (mem_araddr),  .s0_arprot (mem_arprot),
        .s0_rvalid (mem_rvalid),  .s0_rready (mem_rready),
        .s0_rdata  (mem_rdata),

        // Slave 1 = PERIPH
        .s1_awvalid(per_awvalid), .s1_awready(per_awready),
        .s1_awaddr (per_awaddr),  .s1_awprot (per_awprot),
        .s1_wvalid (per_wvalid),  .s1_wready (per_wready),
        .s1_wdata  (per_wdata),   .s1_wstrb  (per_wstrb),
        .s1_bvalid (per_bvalid),  .s1_bready (per_bready),
        .s1_arvalid(per_arvalid), .s1_arready(per_arready),
        .s1_araddr (per_araddr),  .s1_arprot (per_arprot),
        .s1_rvalid (per_rvalid),  .s1_rready (per_rready),
        .s1_rdata  (per_rdata)
    );

    // =========================================================================
    // MEM: AXI-Lite RAM (S0)
    // =========================================================================
    axi_lite_ram #(
        .MEM_BYTES_REQ(RAM_BYTES_REQ),
        .BASE_ADDR(`AXI_RAM_BASE),
        .INIT_FILE("firmware.hex")
    ) u_ram (
        .clk    (aclk),
        .resetn (aresetn),

        .awvalid(mem_awvalid), .awready(mem_awready),
        .awaddr (mem_awaddr),  .awprot (mem_awprot),
        .wvalid (mem_wvalid),  .wready (mem_wready),
        .wdata  (mem_wdata),   .wstrb  (mem_wstrb),
        .bvalid (mem_bvalid),  .bready (mem_bready),
        .arvalid(mem_arvalid), .arready(mem_arready),
        .araddr (mem_araddr),  .arprot (mem_arprot),
        .rvalid (mem_rvalid),  .rready (mem_rready),
        .rdata  (mem_rdata)
    );

    // =========================================================================
    // PERIPH: Interconnect 1x6 + 6 reg slaves
    // =========================================================================


    // 1x6 outputs -> 6 slaves inputs
    wire [ADDR_WIDTH-1:0] x_m0_awaddr, x_m1_awaddr, x_m2_awaddr, x_m3_awaddr, x_m4_awaddr, x_m5_awaddr;
    wire                  x_m0_awvalid, x_m1_awvalid, x_m2_awvalid, x_m3_awvalid, x_m4_awvalid, x_m5_awvalid;
    wire                  x_m0_awready, x_m1_awready, x_m2_awready, x_m3_awready, x_m4_awready, x_m5_awready;

    wire [DATA_WIDTH-1:0] x_m0_wdata, x_m1_wdata, x_m2_wdata, x_m3_wdata, x_m4_wdata, x_m5_wdata;
    wire [(DATA_WIDTH/8)-1:0] x_m0_wstrb, x_m1_wstrb, x_m2_wstrb, x_m3_wstrb, x_m4_wstrb, x_m5_wstrb;
    wire                  x_m0_wvalid, x_m1_wvalid, x_m2_wvalid, x_m3_wvalid, x_m4_wvalid, x_m5_wvalid;
    wire                  x_m0_wready, x_m1_wready, x_m2_wready, x_m3_wready, x_m4_wready, x_m5_wready;

    wire [1:0]            x_m0_bresp, x_m1_bresp, x_m2_bresp, x_m3_bresp, x_m4_bresp, x_m5_bresp;
    wire                  x_m0_bvalid, x_m1_bvalid, x_m2_bvalid, x_m3_bvalid, x_m4_bvalid, x_m5_bvalid;
    wire                  x_m0_bready, x_m1_bready, x_m2_bready, x_m3_bready, x_m4_bready, x_m5_bready;

    wire [ADDR_WIDTH-1:0] x_m0_araddr, x_m1_araddr, x_m2_araddr, x_m3_araddr, x_m4_araddr, x_m5_araddr;
    wire                  x_m0_arvalid, x_m1_arvalid, x_m2_arvalid, x_m3_arvalid, x_m4_arvalid, x_m5_arvalid;
    wire                  x_m0_arready, x_m1_arready, x_m2_arready, x_m3_arready, x_m4_arready, x_m5_arready;

    wire [DATA_WIDTH-1:0] x_m0_rdata, x_m1_rdata, x_m2_rdata, x_m3_rdata, x_m4_rdata, x_m5_rdata;
    wire [1:0]            x_m0_rresp, x_m1_rresp, x_m2_rresp, x_m3_rresp, x_m4_rresp, x_m5_rresp;
    wire                  x_m0_rvalid, x_m1_rvalid, x_m2_rvalid, x_m3_rvalid, x_m4_rvalid, x_m5_rvalid;
    wire                  x_m0_rready, x_m1_rready, x_m2_rready, x_m3_rready, x_m4_rready, x_m5_rready;

    axi_lite_interconnect_1x6 #(
        .S_AXI_ADDR_WIDTH(ADDR_WIDTH),
        .S_AXI_DATA_WIDTH(DATA_WIDTH),

        .SLV0_BASE(`AXI_GPIO_BASE), .SLV0_MASK(`AXI_GPIO_MASK),
        .SLV1_BASE(`AXI_TIMER_BASE),.SLV1_MASK(`AXI_TIMER_MASK),
        .SLV2_BASE(`AXI_UART_BASE), .SLV2_MASK(`AXI_UART_MASK),
        .SLV3_BASE(`AXI_SPI_BASE),  .SLV3_MASK(`AXI_SPI_MASK),
        .SLV4_BASE(`AXI_I2C_BASE),  .SLV4_MASK(`AXI_I2C_MASK),
        .SLV5_BASE(`AXI_INTR_BASE), .SLV5_MASK(`AXI_INTR_MASK)
    ) u_periph_xbar (
        .aclk   (aclk),
        .aresetn(aresetn),

        // Master side of 1x6 comes from PERIPH channel of root IC
        .s_axi_awaddr (per_awaddr),
        .s_axi_awvalid(per_awvalid),
        .s_axi_awready(per_awready),

        .s_axi_wdata  (per_wdata),
        .s_axi_wstrb  (per_wstrb),
        .s_axi_wvalid (per_wvalid),
        .s_axi_wready (per_wready),

        .s_axi_bresp  (per_bresp),             
        .s_axi_bvalid (per_bvalid),
        .s_axi_bready (per_bready),

        .s_axi_araddr (per_araddr),
        .s_axi_arvalid(per_arvalid),
        .s_axi_arready(per_arready),

        .s_axi_rdata  (per_rdata),
        .s_axi_rresp  (per_rresp),
        .s_axi_rvalid (per_rvalid),
        .s_axi_rready (per_rready),

        // Port 0
        .m0_axi_awaddr (x_m0_awaddr),  .m0_axi_awvalid(x_m0_awvalid), .m0_axi_awready(x_m0_awready),
        .m0_axi_wdata  (x_m0_wdata),   .m0_axi_wstrb  (x_m0_wstrb),   .m0_axi_wvalid(x_m0_wvalid), .m0_axi_wready(x_m0_wready),
        .m0_axi_bvalid (x_m0_bvalid),  .m0_axi_bready(x_m0_bready),    
        .m0_axi_araddr (x_m0_araddr),  .m0_axi_arvalid(x_m0_arvalid), .m0_axi_arready(x_m0_arready),
        .m0_axi_rdata  (x_m0_rdata),   .m0_axi_rvalid(x_m0_rvalid),   .m0_axi_rready(x_m0_rready), 

        // Port 1
        .m1_axi_awaddr (x_m1_awaddr),  .m1_axi_awvalid(x_m1_awvalid), .m1_axi_awready(x_m1_awready),
        .m1_axi_wdata  (x_m1_wdata),   .m1_axi_wstrb  (x_m1_wstrb),   .m1_axi_wvalid(x_m1_wvalid), .m1_axi_wready(x_m1_wready),
        .m1_axi_bvalid (x_m1_bvalid),  .m1_axi_bready(x_m1_bready),  
        .m1_axi_araddr (x_m1_araddr),  .m1_axi_arvalid(x_m1_arvalid), .m1_axi_arready(x_m1_arready), 
        .m1_axi_rdata  (x_m1_rdata),   .m1_axi_rvalid(x_m1_rvalid),   .m1_axi_rready(x_m1_rready), 

        // Port 2
        
        .m2_axi_awaddr (x_m2_awaddr),  .m2_axi_awvalid(x_m2_awvalid), .m2_axi_awready(x_m2_awready), 
        .m2_axi_wdata  (x_m2_wdata),   .m2_axi_wstrb  (x_m2_wstrb),   .m2_axi_wvalid(x_m2_wvalid), .m2_axi_wready(x_m2_wready),
        .m2_axi_bvalid (x_m2_bvalid),  .m2_axi_bready(x_m2_bready),    
        .m2_axi_araddr (x_m2_araddr),  .m2_axi_arvalid(x_m2_arvalid), .m2_axi_arready(x_m2_arready),
        .m2_axi_rdata  (x_m2_rdata),   .m2_axi_rvalid(x_m2_rvalid),   .m2_axi_rready(x_m2_rready),

        // Port 3
        .m3_axi_awaddr (x_m3_awaddr),  .m3_axi_awvalid(x_m3_awvalid), .m3_axi_awready(x_m3_awready), 
        .m3_axi_wdata  (x_m3_wdata),   .m3_axi_wstrb  (x_m3_wstrb),   .m3_axi_wvalid(x_m3_wvalid), .m3_axi_wready(x_m3_wready),
        .m3_axi_bvalid (x_m3_bvalid),  .m3_axi_bready(x_m3_bready),   
        .m3_axi_araddr (x_m3_araddr),  .m3_axi_arvalid(x_m3_arvalid), .m3_axi_arready(x_m3_arready), 
        .m3_axi_rdata  (x_m3_rdata),   .m3_axi_rvalid(x_m3_rvalid),   .m3_axi_rready(x_m3_rready), 

        // Port 4
        .m4_axi_awaddr (x_m4_awaddr),  .m4_axi_awvalid(x_m4_awvalid), .m4_axi_awready(x_m4_awready),
        .m4_axi_wdata  (x_m4_wdata),   .m4_axi_wstrb  (x_m4_wstrb),   .m4_axi_wvalid(x_m4_wvalid), .m4_axi_wready(x_m4_wready),
        .m4_axi_bvalid (x_m4_bvalid),  .m4_axi_bready(x_m4_bready),  
        .m4_axi_araddr (x_m4_araddr),  .m4_axi_arvalid(x_m4_arvalid), .m4_axi_arready(x_m4_arready), 
        .m4_axi_rdata  (x_m4_rdata),   .m4_axi_rvalid(x_m4_rvalid),   .m4_axi_rready(x_m4_rready),

        // Port 5
        .m5_axi_awaddr (x_m5_awaddr),  .m5_axi_awvalid(x_m5_awvalid), .m5_axi_awready(x_m5_awready),   
        .m5_axi_wdata  (x_m5_wdata),   .m5_axi_wstrb  (x_m5_wstrb),   .m5_axi_wvalid(x_m5_wvalid), .m5_axi_wready(x_m5_wready),
        .m5_axi_bvalid (x_m5_bvalid),  .m5_axi_bready(x_m5_bready),    
        .m5_axi_araddr (x_m5_araddr),  .m5_axi_arvalid(x_m5_arvalid), .m5_axi_arready(x_m5_arready),   
        .m5_axi_rdata  (x_m5_rdata),   .m5_axi_rvalid(x_m5_rvalid),   .m5_axi_rready(x_m5_rready)
    );

    // -------------------------------------------------------------------------
    // GPIO (Porta 0 - Base 0x4000_0000)
    // -------------------------------------------------------------------------
    wire gpio_irq; // Conectar ao futuro controlador de interrupções
    axilgpio #(
        .C_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH),  // Endereçamento interno pequeno
        //.C_AXI_DATA_WIDTH(32)// localparam no módulo
        .NOUT(30),             // 30 Saídas
        .NIN(5)                // 5 Entradas
    ) u_gpio (
        .S_AXI_ACLK    (aclk),
        .S_AXI_ARESETN (aresetn),

        // Conexões AXI (Vindas do x_m0 do Interconnect 1x6)
        // Nota: Truncamos o endereço para [4:0]
        .S_AXI_AWVALID (x_m0_awvalid),
        .S_AXI_AWREADY (x_m0_awready),
        .S_AXI_AWADDR  (x_m0_awaddr[C_AXI_ADDR_WIDTH-1:0]),
        //.S_AXI_AWPROT  (x_m0_awprot),

        .S_AXI_WVALID  (x_m0_wvalid),
        .S_AXI_WREADY  (x_m0_wready),
        .S_AXI_WDATA   (x_m0_wdata),
        .S_AXI_WSTRB   (x_m0_wstrb),

        .S_AXI_BVALID  (x_m0_bvalid),
        .S_AXI_BREADY  (x_m0_bready),
        .S_AXI_BRESP   (x_m0_bresp),

        .S_AXI_ARVALID (x_m0_arvalid),
        .S_AXI_ARREADY (x_m0_arready),
        .S_AXI_ARADDR  (x_m0_araddr[C_AXI_ADDR_WIDTH-1:0]), 
        //.S_AXI_ARPROT  (x_m0_arprot), 

        .S_AXI_RVALID  (x_m0_rvalid),
        .S_AXI_RREADY  (x_m0_rready),
        .S_AXI_RDATA   (x_m0_rdata),
        .S_AXI_RRESP   (x_m0_rresp),

        // Pinos Físicos
        .i_gpio (gpio_i),
        .o_gpio (gpio_o),
        .o_int  (gpio_irq) 
    );

    // -------------------------------------------------------------------------
    // TIMER (Porta 1 - Base 0x4000_1000)
    // -------------------------------------------------------------------------
    wire timer_irq;

    timer u_timer (
        .clk_i          (aclk),
        .rst_i          (!aresetn), // Inverte: SoC(0)=Reset -> Timer(1)=Reset

        // Interface AXI-Lite (Conectada aos fios x_m1 do interconnect)
        // Canal de Escrita (Write Address & Data)
        .cfg_awvalid_i  (x_m1_awvalid),
        .cfg_awaddr_i   (x_m1_awaddr),
        .cfg_awready_o  (x_m1_awready),
        
        .cfg_wvalid_i   (x_m1_wvalid),
        .cfg_wdata_i    (x_m1_wdata),
        .cfg_wstrb_i    (x_m1_wstrb),
        .cfg_wready_o   (x_m1_wready),
        
        // Canal de Resposta de Escrita
        .cfg_bvalid_o   (x_m1_bvalid),
        .cfg_bresp_o    (x_m1_bresp),
        .cfg_bready_i   (x_m1_bready),

        // Canal de Leitura (Read Address & Data)
        .cfg_arvalid_i  (x_m1_arvalid),
        .cfg_araddr_i   (x_m1_araddr),
        .cfg_arready_o  (x_m1_arready),
        
        .cfg_rvalid_o   (x_m1_rvalid),
        .cfg_rdata_o    (x_m1_rdata),
        .cfg_rresp_o    (x_m1_rresp),
        .cfg_rready_i   (x_m1_rready),

        // Interrupção
        .intr_o   (timer_irq)
    );
    

    // -------------------------------------------------------------------------
    // UART LITE (Porta 2 - Base 0x4000_2000)
    // -------------------------------------------------------------------------
    wire uart_irq;
    uart_lite u_uart (
        .clk_i          (aclk),
        .rst_i          (!aresetn),     // Inverte reset (UART usa ativo alto)
        
        // Pinos Externos
        .rx_i           (uart_rx),
        .tx_o           (uart_tx),
        .intr_o         (uart_irq),

        // Interface AXI-Lite (Conectada aos fios x_m2 do interconnect)
        // Canal AW
        .cfg_awvalid_i(x_m2_awvalid), .cfg_awaddr_i(x_m2_awaddr), .cfg_awready_o(x_m2_awready), 
        // Canal W
        .cfg_wvalid_i(x_m2_wvalid), .cfg_wdata_i(x_m2_wdata), .cfg_wstrb_i(x_m2_wstrb), .cfg_wready_o(x_m2_wready),
        // Canal B
        .cfg_bvalid_o(x_m2_bvalid), .cfg_bready_i(x_m2_bready), .cfg_bresp_o(x_m2_bresp),
        // Canal AR
        .cfg_arvalid_i(x_m2_arvalid), .cfg_araddr_i(x_m2_araddr), .cfg_arready_o(x_m2_arready), 
        // Canal R
        .cfg_rvalid_o(x_m2_rvalid), .cfg_rdata_o(x_m2_rdata), .cfg_rresp_o(x_m2_rresp), .cfg_rready_i(x_m2_rready)
    );

    // -------------------------------------------------------------------------
    // SPI MASTER (Porta 3 - Base 0x4000_3000)
    // -------------------------------------------------------------------------
    wire spi_irq; // Conectar ao futuro controlador de interrupções

    spi_master_axil #(
        .NUM_SS_BITS(NUM_SS_BITS),    // Apenas 1 escravo (Flash)
        .FIFO_EXIST(1),     // Habilita a FIFO
        .FIFO_DEPTH(16),    // Tamanho do buffer (16 palavras)
        .AXIL_ADDR_WIDTH(ADDR_WIDTH) // Endereçamento do barramento
    ) u_spi (
        .clk            (aclk),
        .rst            (!aresetn), // Atenção: Este módulo usa Reset ATIVO ALTO

        .irq            (spi_irq),

        // Conexão AXI-Lite (Vinda do Interconnect Porta 3)
        .s_axil_awaddr  (x_m3_awaddr),
        //.s_axil_awprot  (x_m3_awprot),
        .s_axil_awvalid (x_m3_awvalid),
        .s_axil_awready (x_m3_awready),
        
        .s_axil_wdata   (x_m3_wdata),
        .s_axil_wstrb   (x_m3_wstrb),
        .s_axil_wvalid  (x_m3_wvalid),
        .s_axil_wready  (x_m3_wready),
        
        .s_axil_bresp   (x_m3_bresp),
        .s_axil_bvalid  (x_m3_bvalid),
        .s_axil_bready  (x_m3_bready),
        
        .s_axil_araddr  (x_m3_araddr),
        //.s_axil_arprot  (x_m3_arprot),
        .s_axil_arvalid (x_m3_arvalid),
        .s_axil_arready (x_m3_arready),
        
        .s_axil_rdata   (x_m3_rdata),
        .s_axil_rresp   (x_m3_rresp),
        .s_axil_rvalid  (x_m3_rvalid),
        .s_axil_rready  (x_m3_rready),

        // Interface Física SPI
        .spi_sclk_o         (spi_sclk_o),
        .spi_mosi_o         (spi_mosi_o),
        .spi_miso           (spi_miso_i),
        .spi_ncs_o          (spi_ss_n_o)  // Chip Select (Ativo Baixo)
    );

    // -------------------------------------------------------------------------
    // I2C MASTER (Porta 4 - Base 0x4000_4000)
    // -------------------------------------------------------------------------
    wire i2c_irq;
    
    // Sinais internos para lidar com o Tri-state
    wire scl_i, scl_o, scl_t;
    wire sda_i, sda_o, sda_t;

    // --- INSTÂNCIA DO CONTROLADOR ---
    i2c_master_axil #(
        .DEFAULT_PRESCALE(1), // Configura velocidade (ajustável via software depois)
        .FIXED_PRESCALE(0),
        .CMD_FIFO(1),         // Habilita FIFO de comandos
        .CMD_FIFO_DEPTH(32),
        .WRITE_FIFO(1),
        .WRITE_FIFO_DEPTH(32),
        .READ_FIFO(1),
        .READ_FIFO_DEPTH(32)
    ) u_i2c (
        .clk(aclk),
        .rst(!aresetn), // <--- (Módulo usa Ativo Alto)
        //.irq(i2c_irq),

        // Conexão AXI-Lite (Porta 4)
        .s_axil_awaddr  (x_m4_awaddr),
        //.s_axil_awprot  (x_m4_awprot),
        .s_axil_awvalid (x_m4_awvalid),
        .s_axil_awready (x_m4_awready),
        .s_axil_wdata   (x_m4_wdata),
        .s_axil_wstrb   (x_m4_wstrb),
        .s_axil_wvalid  (x_m4_wvalid),
        .s_axil_wready  (x_m4_wready),
        .s_axil_bresp   (x_m4_bresp),
        .s_axil_bvalid  (x_m4_bvalid),
        .s_axil_bready  (x_m4_bready),
        .s_axil_araddr  (x_m4_araddr),
        //.s_axil_arprot  (x_m4_arprot),
        .s_axil_arvalid (x_m4_arvalid),
        .s_axil_arready (x_m4_arready),
        .s_axil_rdata   (x_m4_rdata),
        .s_axil_rresp   (x_m4_rresp),
        .s_axil_rvalid  (x_m4_rvalid),
        .s_axil_rready  (x_m4_rready),

        // Sinais Internos (IOBUF)
        .i2c_scl_i(scl_i), .i2c_scl_o(scl_o), .i2c_scl_t(scl_t),
        .i2c_sda_i(sda_i), .i2c_sda_o(sda_o), .i2c_sda_t(sda_t)
    );
    assign i2c_irq = 1'b0; // Desabilita temporariamente a interrupção do I2C

    // --- LÓGICA TRI-STATE (IO BUFFERS) ---
    // O I2C funciona como Open-Drain:
    // Se Output for 0 -> Força 0 no pino.
    // Se Output for 1 -> Deixa flutuando (Z), o resistor de pull-up sobe pra 1.
    // O sinal "_t" (tristate) geralmente é 1 para Input/Float e 0 para Output.
    
    // Implementação Genérica de IOBUF:
    // "Se scl_t for 1 (input mode), pino fica Z. Caso contrário, assume scl_o"
    // Nota: No I2C, scl_o será sempre 0 quando ativo.
    
    assign i2c_scl = (scl_t) ? 1'bz : scl_o;
    assign scl_i   = i2c_scl; // Lê o estado real do pino de volta para o núcleo

    assign i2c_sda = (sda_t) ? 1'bz : sda_o;
    assign sda_i   = i2c_sda; // Lê o estado real do pino de volta para o núcleo

    // -------------------------------------------------------------------------
    // INTERRUPT CONTROLLER (Porta 5 - Base 0x4000_5000)
    // -------------------------------------------------------------------------

    // Vetor de Interrupções (8 bits)
    // Organizado sequencialmente: GPIO(0), Timer(1), UART(2), SPI(3), I2C(4)
    // -------------------------------------------------------------------------
    wire [7:0] irq_sources = {
        3'b000,      // Bits 7-5: Reservados (0)
        i2c_irq,     // Bit 4: I2C
        spi_irq,     // Bit 3: SPI
        uart_irq,    // Bit 2: UART
        timer_irq,   // Bit 1: Timer
        gpio_irq     // Bit 0: GPIO
    };

    axil_intc #(
        .IRQ_WIDTH(8)
    ) u_intc (
        .S_AXI_ACLK    (aclk),
        .S_AXI_ARESETN (aresetn),

        // Conexão AXI-Lite (Porta 5)
        .S_AXI_AWADDR  (x_m5_awaddr),
        .S_AXI_AWVALID (x_m5_awvalid),
        .S_AXI_AWREADY (x_m5_awready),
        //.S_AXI_AWPROT  (x_m5_awprot),
        .S_AXI_WDATA   (x_m5_wdata),
        .S_AXI_WSTRB   (x_m5_wstrb),
        .S_AXI_WVALID  (x_m5_wvalid),
        .S_AXI_WREADY  (x_m5_wready),
        .S_AXI_BRESP   (x_m5_bresp),
        .S_AXI_BVALID  (x_m5_bvalid),
        .S_AXI_BREADY  (x_m5_bready),
        .S_AXI_ARADDR  (x_m5_araddr),
        .S_AXI_ARVALID (x_m5_arvalid),
        .S_AXI_ARREADY (x_m5_arready),
        //.S_AXI_ARPROT  (x_m5_arprot),
        .S_AXI_RDATA   (x_m5_rdata),
        .S_AXI_RRESP   (x_m5_rresp),
        .S_AXI_RVALID  (x_m5_rvalid),
        .S_AXI_RREADY  (x_m5_rready),

        // Sinais de Interrupção
        .irq_inputs_i  (irq_sources),
        .irq_output_o  (cpu_global_irq)
    );

endmodule
