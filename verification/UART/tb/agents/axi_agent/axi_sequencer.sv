// ARQUIVO: axi_sequencer.sv
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Sequenciador AXI.
//            Controla o fluxo de axi_seq_item entre as sequences e o driver.

class axi_sequencer extends uvm_sequencer #(axi_seq_item);
    
    // Registro na factory do UVM
    `uvm_component_utils(axi_sequencer)

    // Constructor padrão
    function new(string name = "axi_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass
