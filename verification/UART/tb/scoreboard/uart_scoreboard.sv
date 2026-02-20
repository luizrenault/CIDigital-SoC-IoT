// ARQUIVO: uart_scoreboard.sv
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Scoreboard UVM (Corrigido para Full-Duplex).
//            Compara as transações AXI com os frames UART identificados (TX/RX).

// Declaração de macros para as portas de análise
`uvm_analysis_imp_decl(_axi)
`uvm_analysis_imp_decl(_uart)

class uart_scoreboard extends uvm_scoreboard;

    // Portas para receber dados dos Monitores
    uvm_analysis_imp_axi  #(axi_seq_item,  uart_scoreboard) axi_export;
    uvm_analysis_imp_uart #(uart_seq_item, uart_scoreboard) uart_export;

    // Queues para armazenamento temporário de dados (Golden Model)
    logic [7:0] expected_tx_data[$];
    logic [7:0] expected_rx_data[$];

    `uvm_component_utils(uart_scoreboard)

    function new(string name = "uart_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        axi_export  = new("axi_export", this);
        uart_export = new("uart_export", this);
    endfunction

    // -------------------------------------------------------------------------
    // Callback para transações AXI (Lado Master/Processador)
    // -------------------------------------------------------------------------
    virtual function void write_axi(axi_seq_item item);
        // Se for uma escrita no endereço 0x0, o DUT deve transmitir via UART (TX)
        if (item.op == axi_seq_item::WRITE && item.addr == 4'h0) begin
            `uvm_info("SCB_AXI", $sformatf("Capturada escrita AXI: Data=0x%0h. Adicionando ao modelo esperado de TX.", item.data[7:0]), UVM_MEDIUM)
            expected_tx_data.push_back(item.data[7:0]);
        end
        
        // Se for uma leitura do endereço 0x4, verificamos se o dado lido (RX)
        // corresponde ao que o modelo esperava ter recebido via UART
        if (item.op == axi_seq_item::READ && item.addr == 4'h4) begin
            if (expected_rx_data.size() > 0) begin
                logic [7:0] exp = expected_rx_data.pop_front();
                if (item.data[7:0] == exp) begin
                    `uvm_info("SCB_MATCH", $sformatf("Sucesso! Leitura AXI 0x%0h coincide com UART RX 0x%0h.", item.data[7:0], exp), UVM_LOW)
                end else begin
                    `uvm_error("SCB_MISMATCH", $sformatf("Erro! Lido AXI=0x%0h, Esperado UART RX=0x%0h", item.data[7:0], exp))
                end
            end else begin
                 `uvm_error("SCB_EMPTY", "O AXI tentou ler do RX, mas não havia dados recebidos pela UART!")
            end
        end
    endfunction

    // -------------------------------------------------------------------------
    // Callback para transações UART (Lado Físico/Serial) - CORRIGIDO
    // -------------------------------------------------------------------------
    virtual function void write_uart(uart_seq_item item);
        
        if (item.is_tx) begin
            // O pacote veio do pino de saída (TXD) do DUT.
            // Precisamos comparar com o que o AXI enviou.
            if (expected_tx_data.size() > 0) begin
                logic [7:0] exp = expected_tx_data.pop_front();
                if (item.data == exp) begin
                    `uvm_info("SCB_MATCH", $sformatf("Sucesso! Saída UART TX 0x%0h coincide com escrita AXI 0x%0h.", item.data, exp), UVM_LOW)
                end else begin
                    `uvm_error("SCB_MISMATCH", $sformatf("Erro! Saída UART TX=0x%0h, Esperado AXI=0x%0h", item.data, exp))
                end
            end else begin
                `uvm_error("SCB_UNEXPECTED", $sformatf("Dado 0x%0h transmitido via TXD, mas não havia nenhuma escrita AXI pendente!", item.data))
            end
            
        end else begin
            // O pacote veio do pino de entrada (RXD) do DUT.
            // Precisamos guardar para que o AXI o leia depois.
            `uvm_info("SCB_UART", $sformatf("Dado recebido via UART RXD: 0x%0h. Armazenando e aguardando leitura AXI.", item.data), UVM_MEDIUM)
            expected_rx_data.push_back(item.data);
        end
        
    endfunction

    virtual function void report_phase(uvm_phase phase);
        if (expected_tx_data.size() != 0) begin
            `uvm_warning("SCB_PENDING_TX", $sformatf("Simulação terminou com %0d bytes AXI que nunca saíram pela UART!", expected_tx_data.size()))
        end
        if (expected_rx_data.size() != 0) begin
            `uvm_warning("SCB_PENDING_RX", $sformatf("Simulação terminou com %0d bytes UART recebidos que o AXI nunca leu!", expected_rx_data.size()))
        end
    endfunction

endclass