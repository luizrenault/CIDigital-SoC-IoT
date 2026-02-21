// ARQUIVO: axi_base_seq.sv
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Sequência base para o mestre AXI.
//            Define tarefas para facilitar a escrita e leitura nos registradores.

class axi_base_seq extends uvm_sequence #(axi_seq_item);

    `uvm_object_utils(axi_base_seq)

    function new(string name = "axi_base_seq");
        super.new(name);
    endfunction

    // Tarefa para realizar uma escrita AXI
    task write_reg(input logic [3:0] addr, input logic [31:0] data);
        req = axi_seq_item::type_id::create("req");
        start_item(req);
        req.op   = axi_seq_item::WRITE;
        req.addr = addr;
        req.data = data;
        finish_item(req);
    endtask

    // Tarefa para realizar uma leitura AXI
    task read_reg(input logic [3:0] addr, output logic [31:0] data);
        req = axi_seq_item::type_id::create("req");
        start_item(req);
        req.op   = axi_seq_item::READ;
        req.addr = addr;
        finish_item(req);
        data = req.data;
    endtask

endclass
