module boot_fsm_axi (
    input  wire        clk,
    input  wire        resetn,
    input  wire        mode_select, // 0 = Copy, 1 = Update UART
    input  wire        uart_rx,     // Pino RX direto (para facilitar o update)
    
    // Controle da CPU
    output reg         cpu_reset_release, // 0 = Segura CPU, 1 = Solta CPU
    
    // Interface AXI Master (simples) para controlar a memória
    output reg [31:0]  m_awaddr,
    output reg         m_awvalid,
    input  wire        m_awready,
    output reg [31:0]  m_wdata,
    output reg         m_wvalid,
    input  wire        m_wready,
    // (Simplificação: ignorando canais de leitura AR/R complexos e burst)
    
    output reg         boot_busy // Indica que o bootloader está usando o barramento
);

    // Parâmetros
    localparam ROM_BASE = 32'h0000_0000;
    localparam RAM_BASE = 32'h0001_0000;
    localparam COPY_SIZE = 1024; // Exemplo: Copiar 1KB (256 palavras)

    // Estados
    localparam S_IDLE       = 0;
    localparam S_COPY_READ  = 1; // Em AXI real, precisaríamos ler. Aqui vou simplificar.
    localparam S_COPY_WRITE = 2;
    localparam S_UART_WAIT  = 3;
    localparam S_UART_WRITE = 4;
    localparam S_RELEASE    = 5;
    localparam S_DONE_STOP  = 6;

    reg [3:0] state;
    reg [31:0] addr_counter;
    
    // ... Lógica de deserialização da UART (Shift Register) omitida para brevidade ...
    reg [7:0] uart_byte;
    reg       uart_byte_valid;

    always @(posedge clk) begin
        if (!resetn) begin
            state <= S_IDLE;
            cpu_reset_release <= 0;
            boot_busy <= 1;
            m_awvalid <= 0;
            m_wvalid <= 0;
            addr_counter <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    boot_busy <= 1;
                    cpu_reset_release <= 0;
                    if (mode_select == 0) state <= S_COPY_WRITE; // Simplificado: Assumindo que dados ja existem
                    else state <= S_UART_WAIT;
                end

                // --- ESTADO 0: COPY (Fake Copy - Apenas escreve um padrão para teste) ---
                // Nota: Uma cópia real exigiria Ler (AR/R) guardar no reg, depois escrever (AW/W).
                S_COPY_WRITE: begin
                    // Lógica AXI Master Write
                    if (!m_awvalid && !m_wvalid) begin
                        m_awaddr <= RAM_BASE + addr_counter;
                        m_awvalid <= 1;
                        m_wdata  <= 32'h13000000; // Escreve NOPs (exemplo)
                        m_wvalid <= 1;
                    end
                    
                    if (m_awvalid && m_awready) m_awvalid <= 0;
                    if (m_wvalid && m_wready)   m_wvalid  <= 0;

                    if (!m_awvalid && !m_wvalid) begin // Transação terminou
                        addr_counter <= addr_counter + 4;
                        if (addr_counter >= COPY_SIZE) state <= S_RELEASE;
                    end
                end

                // --- ESTADO 1: UART UPDATE ---
                S_UART_WAIT: begin
                    if (uart_byte_valid) begin // Se chegou byte na UART
                         state <= S_UART_WRITE;
                    end
                end
                
                S_UART_WRITE: begin
                     // Escreve o byte recebido na ROM (Base 0)
                     // ... Mesma lógica AXI Write acima ...
                     // Voltar para S_UART_WAIT depois
                end

                S_RELEASE: begin
                    boot_busy <= 0;       // Libera o barramento
                    cpu_reset_release <= 1; // Acorda a CPU
                end

                S_DONE_STOP: begin
                    boot_busy <= 1;
                    cpu_reset_release <= 0; // Mantém CPU parada
                end
            endcase
        end
    end
endmodule