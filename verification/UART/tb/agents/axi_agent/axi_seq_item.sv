// ARQUIVO: axi_seq_item.sv
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Objeto de transação (Sequence Item) para o barramento AXI4-Lite.
//            Define os dados e operações (Read/Write) que o Agent executará.

class axi_seq_item extends uvm_sequence_item;
    
    // Tipos de operação
    typedef enum {WRITE, READ} op_type_e;

    // -------------------------------------------------------------------------
    // Atributos Randomizáveis
    // -------------------------------------------------------------------------
    rand logic [3:0]        addr;   // Endereço de 4 bits conforme design.v
    rand logic [31:0]       data;   // Dados de 32 bits
    rand op_type_e          op;     // Tipo de operação (Leitura ou Escrita)

    // -------------------------------------------------------------------------
    // Atributos de Resposta (Não randomizáveis pelo Master)
    // -------------------------------------------------------------------------
    logic [1:0]             resp;   // Resposta do Slave (OKAY, EXOKAY, SLVERR, DECERR)

    // Registro na factory do UVM
    `uvm_object_utils_begin(axi_seq_item)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_enum(op_type_e, op, UVM_ALL_ON)
        `uvm_field_int(resp, UVM_ALL_ON)
    `uvm_object_utils_end

    // Constructor padrão
    function new(string name = "axi_seq_item");
        super.new(name);
    endfunction

    // Restrição para garantir endereços alinhados (opcional, mas recomendado)
    constraint addr_alignment {
        addr[1:0] == 2'b00;
    }

endclass