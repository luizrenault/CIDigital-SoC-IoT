// ARQUIVO: axi_agent.sv
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Agente AXI4-Lite.
//            Instancia Sequencer, Driver e Monitor AXI.

class axi_agent extends uvm_agent;
    
    axi_sequencer  sqr;
    axi_driver     drv;
    axi_monitor    mon;

    `uvm_component_utils(axi_agent)

    function new(string name = "axi_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // O Monitor é sempre instanciado (Ativo ou Passivo)
        mon = axi_monitor::type_id::create("mon", this);

        // Instancia Driver e Sequencer apenas se o agente for ATIVO
        if (get_is_active() == UVM_ACTIVE) begin
            sqr = axi_sequencer::type_id::create("sqr", this);
            drv = axi_driver::type_id::create("drv", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Conecta o Driver ao Sequencer apenas se o agente for ATIVO
        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction
endclass
