// ARQUIVO: uart_seq_item.sv
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Objeto de transação (Sequence Item) para a interface UART.
//            Encapsula os dados serializados para o Driver e Monitor.

class uart_seq_item extends uvm_sequence_item;

    // -------------------------------------------------------------------------
    // Atributos Randomizáveis
    // -------------------------------------------------------------------------
    rand logic [7:0] data;          // Byte de dados (payload)
    rand logic       parity_bit;    // Bit de paridade (se habilitado)
    rand logic [1:0] stop_bits;      // Quantidade de bits de parada

    // -------------------------------------------------------------------------
    // Atributos de Status / Erro
    // -------------------------------------------------------------------------
    // Úteis para o Monitor sinalizar problemas detectados no frame físico
    logic parity_error;
    logic framing_error;

    bit is_tx; // <- ADICIONE ESTA LINHA: 1 = Transmissão do DUT (TXD), 0 = Recepção do DUT (RXD)

    // Registro na factory do UVM
    `uvm_object_utils_begin(uart_seq_item)
        `uvm_field_int(data,          UVM_ALL_ON)
        `uvm_field_int(parity_bit,    UVM_ALL_ON)
        `uvm_field_int(stop_bits,     UVM_ALL_ON)
        `uvm_field_int(parity_error,  UVM_ALL_ON)
        `uvm_field_int(framing_error, UVM_ALL_ON)
    `uvm_object_utils_end

    // Constructor padrão
    function new(string name = "uart_seq_item");
        super.new(name);
    endfunction

    // Restrições padrão (ajustáveis via Test/Sequence)
    constraint default_config {
        soft stop_bits == 2'b01; // Padrão: 1 stop bit
    }

endclass
