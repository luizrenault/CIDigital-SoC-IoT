// ARQUIVO: uart_base_seq.sv
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Sequência base para a interface UART.
//            Gera frames de dados para serem enviados ao DUT.

class uart_base_seq extends uvm_sequence #(uart_seq_item);

    `uvm_object_utils(uart_base_seq)

    function new(string name = "uart_base_seq");
        super.new(name);
    endfunction

    // Gera um envio de byte aleatório ou específico
    task send_byte(input logic [7:0] val = 8'h00, input bit random = 1);
        req = uart_seq_item::type_id::create("req");
        start_item(req);
        if (random) begin
            if (!req.randomize()) `uvm_error("SEQ", "Falha na randomização do byte UART")
        end else begin
            req.data = val;
        end
        finish_item(req);
    endtask

endclass