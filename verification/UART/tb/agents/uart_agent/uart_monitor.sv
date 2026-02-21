// ARQUIVO: uart_monitor.sv
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Monitor UART (Corrigido).
//            Observa os pinos TX/RX simultaneamente usando detecção de borda.

class uart_monitor extends uvm_monitor;

    virtual uart_if vif;
    uvm_analysis_port #(uart_seq_item) item_collected_port;
    
    // Ajustar conforme o baud rate configurado no DUT
    real bit_period = 17600ns; // (55 ciclos * 20ns * 16 amostras)

    `uvm_component_utils(uart_monitor)

    function new(string name = "uart_monitor", uvm_component parent = null);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "Não foi possível obter a interface virtual uart_if")
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Aguarda o reset estabilizar para não amostrar "lixo" durante a inicialização
        wait(vif.rst_n === 1'b1);

        // Dispara os dois monitores em paralelo (Full-Duplex)
        fork
            monitor_tx();
            monitor_rx();
        join_none
    endtask

    // -------------------------------------------------------------------------
    // Observa o tráfego SAINDO do DUT (Pino TXD)
    // -------------------------------------------------------------------------
    task monitor_tx();
        forever begin
            uart_seq_item item = uart_seq_item::type_id::create("item");
            
            // ALTERAÇÃO: Aguarda o repouso (1) e DEPOIS a descida (0)
            // Isso garante que o monitor esteja sincronizado com a linha ociosa
            wait(vif.txd === 1'b1);
            @(negedge vif.txd); 
            
            #(bit_period / 2.0); // Meio do Start Bit
            
            for (int i=0; i<8; i++) begin
                #(bit_period);
                item.data[i] = vif.txd;
            end
            
            #(bit_period); // Stop Bit
            if (vif.txd === 1'b1) begin
                item.is_tx = 1'b1;
                item_collected_port.write(item);
                `uvm_info("MON_TX", $sformatf("Byte capturado no pino TXD: 0x%0h", item.data), UVM_LOW)
            end else begin
                `uvm_warning("MON_TX", "Framing Error detectado no sinal TXD")
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Observa o tráfego ENTRANDO no DUT (Pino RXD)
    // -------------------------------------------------------------------------
    task monitor_rx();
    `uvm_info("MON_TX", "Tarefa monitor_tx iniciada e aguardando IDLE...", UVM_LOW)
        forever begin
            uart_seq_item item = uart_seq_item::type_id::create("item");
            
            @(negedge vif.rxd); // Aguarda Start Bit no pino RXD
            
            #(bit_period / 2.0);
            
            for (int i=0; i<8; i++) begin
                #(bit_period);
                item.data[i] = vif.rxd;
            end
            
            #(bit_period);
            if (vif.rxd === 1'b1) begin
                item.is_tx = 1'b0; // CORREÇÃO 2: Marca como pacote de RX
                item_collected_port.write(item);
            end else begin
                `uvm_warning("MON_RX", "Framing Error detectado no sinal RXD")
            end
        end
    endtask

endclass