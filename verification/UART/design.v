// =============================================================================
// PROJETO: UART AXI4-LITE (XCMG Training Project)
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Periférico UART com mapa de 4 registros de 32 bits.
// =============================================================================

// -----------------------------------------------------------------------------
// 1. BAUD RATE GENERATOR (Passo 2)
// -----------------------------------------------------------------------------
module baud_rate_gen (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [15:0] divisor,    // Vindo do Registro 0x0C (CTRL)
    output reg         baud_x16_en // Tick de amostragem (16x Baud Rate)
);
    reg [15:0] count_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_reg   <= 16'b0;
            baud_x16_en <= 1'b0;
        end else begin
            if (count_reg >= divisor) begin
                count_reg   <= 16'b0;
                baud_x16_en <= 1'b1;
            end else begin
                count_reg   <= count_reg + 1'b1;
                baud_x16_en <= 1'b0;
            end
        end
    end
endmodule

// -----------------------------------------------------------------------------
// 2. UART TRANSMITTER (Passo 3 - Corrigido com Next State)
// -----------------------------------------------------------------------------
module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       baud_x16_en,
    input  wire [7:0] tx_data,
    input  wire       tx_start,
    output reg        tx_busy,
    output reg        uart_txd
);
    localparam IDLE=2'b00, START=2'b01, DATA=2'b10, STOP=2'b11;

    reg [1:0] state_reg, state_next;
    reg [3:0] tick_reg, tick_next;
    reg [2:0] bit_reg, bit_next;
    reg [7:0] data_reg, data_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= IDLE; tick_reg <= 0; bit_reg <= 0; data_reg <= 0;
        end else begin
            state_reg <= state_next; tick_reg <= tick_next; bit_reg <= bit_next; data_reg <= data_next;
        end
    end

    always @(*) begin
        state_next = state_reg; tick_next = tick_reg; bit_next = bit_reg; data_next = data_reg;
        tx_busy = 1'b1; uart_txd = 1'b1;

        case (state_reg)
            IDLE: begin
                tx_busy = 1'b0;
                if (tx_start) begin state_next = START; tick_next = 0; data_next = tx_data; end
            end
            START: begin
                uart_txd = 1'b0;
                if (baud_x16_en) begin
                    if (tick_reg == 15) begin state_next = DATA; tick_next = 0; end
                    else tick_next = tick_reg + 1'b1;
                end
            end
            DATA: begin
                uart_txd = data_reg[0];
                if (baud_x16_en) begin
                    if (tick_reg == 15) begin
                        tick_next = 0; data_next = data_reg >> 1;
                        if (bit_reg == 7) state_next = STOP;
                        else bit_next = bit_reg + 1'b1;
                    end else tick_next = tick_reg + 1'b1;
                end
            end
            STOP: begin
                uart_txd = 1'b1;
                if (baud_x16_en) begin
                    if (tick_reg == 15) state_next = IDLE;
                    else tick_next = tick_reg + 1'b1;
                end
            end
        endcase
    end
endmodule

// -----------------------------------------------------------------------------
// 3. UART RECEIVER (Passo 4 - Corrigido com Next State)
// -----------------------------------------------------------------------------
module uart_rx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       baud_x16_en,
    input  wire       uart_rxd,
    output reg [7:0]  rx_data,
    output reg        rx_ready,
    input  wire       rx_ack
);
    localparam IDLE=2'b00, START=2'b01, DATA=2'b10, STOP=2'b11;

    reg [1:0] state_reg, state_next;
    reg [3:0] tick_reg, tick_next;
    reg [2:0] bit_reg, bit_next;
    reg [7:0] data_reg, data_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_reg <= IDLE; tick_reg <= 0; bit_reg <= 0; data_reg <= 0;
        end else begin
            state_reg <= state_next; tick_reg <= tick_next; bit_reg <= bit_next; data_reg <= data_next;
        end
    end

    always @(*) begin
        state_next = state_reg; tick_next = tick_reg; bit_next = bit_reg; data_next = data_reg;
        rx_ready = (state_reg == IDLE && data_reg != 0); // Exemplo simplificado

        case (state_reg)
            IDLE: if (~uart_rxd) begin state_next = START; tick_next = 0; end
            START: if (baud_x16_en) begin
                if (tick_reg == 7) begin state_next = DATA; tick_next = 0; end
                else tick_next = tick_reg + 1'b1;
            end
            DATA: if (baud_x16_en) begin
                if (tick_reg == 15) begin
                    tick_next = 0; data_next = {uart_rxd, data_reg[7:1]};
                    if (bit_reg == 7) state_next = STOP;
                    else bit_next = bit_reg + 1'b1;
                end else tick_next = tick_reg + 1'b1;
            end
            STOP: if (baud_x16_en) begin
                if (tick_reg == 15) begin state_next = IDLE; end
                else tick_next = tick_reg + 1'b1;
            end
        endcase
    end
    
    // Logica de saída para o Registro RX_DATA
    always @(posedge clk) begin
        if (state_reg == STOP && tick_reg == 15 && baud_x16_en) begin
            rx_data <= data_reg;
            rx_ready <= 1'b1;
        end else if (rx_ack) begin
            rx_ready <= 1'b0;
        end
    end
endmodule

// -----------------------------------------------------------------------------
// 4. TOP LEVEL WRAPPER AXI4-LITE (Passo 5)
// -----------------------------------------------------------------------------
module uart_axi_lite_top # (
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4
)(
    input  wire  s_axi_aclk,
    input  wire  s_axi_aresetn,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire  s_axi_awvalid,
    output reg   s_axi_awready,
    input  wire [C_S_AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input  wire  s_axi_wvalid,
    output reg   s_axi_wready,
    output reg  [1:0] s_axi_bresp,
    output reg   s_axi_bvalid,
    input  wire  s_axi_bready,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire  s_axi_arvalid,
    output reg   s_axi_arready,
    output reg  [C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output reg  [1:0] s_axi_rresp,
    output reg   s_axi_rvalid,
    input  wire  s_axi_rready,

    output wire  uart_txd,
    input  wire  uart_rxd
);

    reg [15:0] reg_ctrl; 
    wire [7:0] rx_data_wire;
    wire tx_busy, rx_ready;
    reg tx_start;

    // Instanciação dos sub-módulos
    wire baud_tick;
    baud_rate_gen brg_inst (.clk(s_axi_aclk), .rst_n(s_axi_aresetn), .divisor(reg_ctrl), .baud_x16_en(baud_tick));
    
    uart_tx tx_inst (.clk(s_axi_aclk), .rst_n(s_axi_aresetn), .baud_x16_en(baud_tick), 
                     .tx_data(s_axi_wdata[7:0]), .tx_start(tx_start), .tx_busy(tx_busy), .uart_txd(uart_txd));

    wire rx_read_ack = (s_axi_arvalid && s_axi_arready && s_axi_araddr[3:0] == 4'h4);
    uart_rx rx_inst (.clk(s_axi_aclk), .rst_n(s_axi_aresetn), .baud_x16_en(baud_tick), 
                     .uart_rxd(uart_rxd), .rx_data(rx_data_wire), .rx_ready(rx_ready), .rx_ack(rx_read_ack));

    // Lógica de Escrita
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            reg_ctrl <= 16'd54; 
            tx_start <= 1'b0;
        end else begin
            // Se o transmissor já começou a trabalhar, podemos baixar o sinal
            if (tx_busy) begin
                tx_start <= 1'b0;
            end 
            // Dispara quando houver escrita no endereço 0x0
            else if (s_axi_awvalid && s_axi_wvalid && !s_axi_bvalid) begin
                if (s_axi_awaddr[3:0] == 4'h0) begin
                    tx_start <= 1'b1;
                end
                if (s_axi_awaddr[3:0] == 4'hC) begin
                    reg_ctrl <= s_axi_wdata[15:0];
                end
            end
        end
    end

    // Lógica de Leitura
    always @(*) begin
        case (s_axi_araddr[3:0])
            4'h4: s_axi_rdata = {24'b0, rx_data_wire};
            4'h8: s_axi_rdata = {30'b0, rx_ready, tx_busy};
            4'hC: s_axi_rdata = {16'b0, reg_ctrl};
            default: s_axi_rdata = 32'b0;
        endcase
    end

    // Handshake AXI (Simples)
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 0; s_axi_wready <= 0; s_axi_bvalid <= 0; s_axi_arready <= 0; s_axi_rvalid <= 0;
        end else begin
            s_axi_awready <= s_axi_awvalid && s_axi_wvalid;
            s_axi_wready  <= s_axi_awvalid && s_axi_wvalid;
            s_axi_arready <= s_axi_arvalid;
            s_axi_rvalid  <= s_axi_arvalid && !s_axi_rvalid;
            s_axi_bvalid  <= s_axi_awvalid && s_axi_wvalid && !s_axi_bvalid;
        end
    end
endmodule