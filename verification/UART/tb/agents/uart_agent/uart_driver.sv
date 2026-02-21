// ARQUIVO: uart_driver.sv
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Driver UART.
//            Serializa o byte de dados para a entrada RX do DUT.

class uart_driver extends uvm_driver #(uart_seq_item);

    virtual uart_if vif;
    
    // Parâmetro de baud rate (simplificado: tempo por bit em ns)
    // Para 115200 bps com clock de 50MHz, use o divisor do registro 0x0C
    real bit_period = 8680ns; // Exemplo para 115200 bps

    `uvm_component_utils(uart_driver)

    function new(string name = "uart_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "Não foi possível obter a interface virtual uart_if")
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.rxd <= 1'b1; // UART IDLE state
        wait(vif.rst_n);

        forever begin
            seq_item_port.get_next_item(req);
            send_uart_frame(req);
            seq_item_port.item_done();
        end
    endtask

    task send_uart_frame(uart_seq_item item);
        // Start Bit
        vif.rxd <= 1'b0;
        #(bit_period);

        // Data Bits (LSB First)
        for (int i=0; i<8; i++) begin
            vif.rxd <= item.data[i];
            #(bit_period);
        end

        // Stop Bit
        vif.rxd <= 1'b1;
        #(bit_period);
    endtask
endclass