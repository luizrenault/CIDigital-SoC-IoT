// ARQUIVO: uart_sequencer.sv
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Sequenciador UART.
//            Controla o fluxo de uart_seq_item entre as sequences e o driver.

class uart_sequencer extends uvm_sequencer #(uart_seq_item);
    
    // Registro na factory do UVM
    `uvm_component_utils(uart_sequencer)

    // Constructor padrão
    function new(string name = "uart_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass