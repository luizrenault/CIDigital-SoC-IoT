
module axil_intc #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 32,
    parameter integer IRQ_WIDTH = 8 // Suporta até 8 periféricos
)(
    input  wire                                  S_AXI_ACLK,
    input  wire                                  S_AXI_ARESETN,
    // Interface AXI-Lite Slave
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]         S_AXI_AWADDR,
    input  wire                                  S_AXI_AWVALID,
    output wire                                  S_AXI_AWREADY,
    input  wire [C_S_AXI_DATA_WIDTH-1:0]         S_AXI_WDATA,
    input  wire [C_S_AXI_DATA_WIDTH/8-1:0]       S_AXI_WSTRB,
    input  wire                                  S_AXI_WVALID,
    output wire                                  S_AXI_WREADY,
    output wire [1:0]                            S_AXI_BRESP,
    output wire                                  S_AXI_BVALID,
    input  wire                                  S_AXI_BREADY,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]         S_AXI_ARADDR,
    input  wire                                  S_AXI_ARVALID,
    output wire                                  S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0]         S_AXI_RDATA,
    output wire [1:0]                            S_AXI_RRESP,
    output wire                                  S_AXI_RVALID,
    input  wire                                  S_AXI_RREADY,
    // Interrupções
    input  wire [IRQ_WIDTH-1:0]                  irq_inputs_i, // Vetor de entradas
    output wire                                  irq_output_o  // Saída única para CPU
);

    // Registradores
    reg [IRQ_WIDTH-1:0] irq_enable_reg; // 0x00: Enable
    // Leitura em 0x04: Raw Status (irq_inputs_i)
    // Leitura em 0x08: Pending (irq_inputs_i & irq_enable_reg)

    reg axi_awready, axi_wready, axi_bvalid, axi_arready, axi_rvalid;
    reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;

    // Lógica da Interrupção (Combinacional)
    // Interrupção dispara se (Input Ativo) AND (Enable Ativo)
    assign irq_output_o = |(irq_inputs_i & irq_enable_reg);

    // Lógica AXI
    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            axi_awready <= 0; axi_wready <= 0; axi_bvalid <= 0;
            axi_arready <= 0; axi_rvalid <= 0;
            irq_enable_reg <= 0;
        end else begin
            // Escrita (Write)
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID) begin
                axi_awready <= 1; axi_wready <= 1;
                if (S_AXI_AWADDR[3:0] == 4'h0) irq_enable_reg <= S_AXI_WDATA[IRQ_WIDTH-1:0];
            end else begin
                axi_awready <= 0; axi_wready <= 0;
            end

            if (axi_awready && S_AXI_AWVALID && axi_wready && S_AXI_WVALID && ~axi_bvalid)
                axi_bvalid <= 1;
            else if (S_AXI_BREADY && axi_bvalid)
                axi_bvalid <= 0;

            // Leitura (Read)
            if (~axi_arready && S_AXI_ARVALID) begin
                axi_arready <= 1;
                case (S_AXI_ARADDR[3:0])
                    4'h0: axi_rdata <= irq_enable_reg;
                    4'h4: axi_rdata <= irq_inputs_i; // Status Bruto
                    4'h8: axi_rdata <= irq_inputs_i & irq_enable_reg; // Pendentes
                    default: axi_rdata <= 0;
                endcase
            end else begin
                axi_arready <= 0;
            end

            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
                axi_rvalid <= 1;
            else if (axi_rvalid && S_AXI_RREADY)
                axi_rvalid <= 0;
        end
    end

    // Assigns de saída
    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = 2'b00;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = 2'b00;
    assign S_AXI_RVALID  = axi_rvalid;

endmodule