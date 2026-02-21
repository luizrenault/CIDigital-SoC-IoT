// ARQUIVO: axi_if.sv
// PROJETO: Ponte UART-AXI (XCMG Training Project)
// DESCRIÇÃO: Definição da Interface AXI4-Lite.
//            Conecta o Driver/Monitor AXI ao DUT.

interface axi_if #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 4
) (
    input logic clk,
    input logic rst_n
);

    // -------------------------------------------------------------------------
    // Sinais do Barramento AXI4-Lite
    // -------------------------------------------------------------------------
    
    // Canal de Endereço de Escrita (Write Address Channel - AW)
    logic [ADDR_WIDTH-1:0] awaddr;
    logic                  awvalid;
    logic                  awready;
    logic [2:0]            awprot; // Opcional (não usado pelo DUT atual, mas padrão)

    // Canal de Dados de Escrita (Write Data Channel - W)
    logic [DATA_WIDTH-1:0] wdata;
    logic                  wvalid;
    logic                  wready;
    logic [(DATA_WIDTH/8)-1:0] wstrb; // Byte Enable (não usado pelo DUT atual)

    // Canal de Resposta de Escrita (Write Response Channel - B)
    logic [1:0]            bresp;
    logic                  bvalid;
    logic                  bready;

    // Canal de Endereço de Leitura (Read Address Channel - AR)
    logic [ADDR_WIDTH-1:0] araddr;
    logic                  arvalid;
    logic                  arready;
    logic [2:0]            arprot; // Opcional

    // Canal de Dados de Leitura (Read Data Channel - R)
    logic [DATA_WIDTH-1:0] rdata;
    logic [1:0]            rresp;
    logic                  rvalid;
    logic                  rready;

    // -------------------------------------------------------------------------
    // Modports (Direcionamento de Sinais)
    // -------------------------------------------------------------------------

    // Modport para o Driver (Atua como AXI Master)
    modport master (
        input  clk, rst_n,
        output awaddr, awvalid, awprot,
        input  awready,
        output wdata, wvalid, wstrb,
        input  wready,
        input  bresp, bvalid,
        output bready,
        output araddr, arvalid, arprot,
        input  arready,
        input  rdata, rresp, rvalid,
        output rready
    );

    // Modport para o Monitor (Passivo)
    modport monitor (
        input clk, rst_n,
        input awaddr, awvalid, awprot, awready,
        input wdata, wvalid, wstrb, wready,
        input bresp, bvalid, bready,
        input araddr, arvalid, arprot, arready,
        input rdata, rresp, rvalid, rready
    );

    // Modport para conexão com DUT (Slave) - Apenas para referência/teste
    modport slave (
        input  clk, rst_n,
        input  awaddr, awvalid, awprot,
        output awready,
        input  wdata, wvalid, wstrb,
        output wready,
        output bresp, bvalid,
        input  bready,
        input  araddr, arvalid, arprot,
        output arready,
        output rdata, rresp, rvalid,
        input  rready
    );

endinterface