// ARQUIVO: axi_monitor.sv
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Monitor AXI4-Lite.
//            Observa passivamente a interface e reconstrói as transações.

class axi_monitor extends uvm_monitor;
    
    virtual axi_if vif;
    uvm_analysis_port #(axi_seq_item) item_collected_port; // Porta de saída para o Scoreboard

    `uvm_component_utils(axi_monitor)

    function new(string name = "axi_monitor", uvm_component parent = null);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "Não foi possível obter a interface virtual axi_if")
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            axi_seq_item item = axi_seq_item::type_id::create("item");
            
            @(posedge vif.clk);
            if (vif.rst_n) begin
                // Captura de Escrita
                if (vif.awvalid && vif.awready) begin
                    item.op   = axi_seq_item::WRITE;
                    item.addr = vif.awaddr;
                    item.data = vif.wdata;
                    wait(vif.bvalid && vif.bready);
                    item.resp = vif.bresp;
                    item_collected_port.write(item);
                end
                // Captura de Leitura
                else if (vif.arvalid && vif.arready) begin
                    item.op   = axi_seq_item::READ;
                    item.addr = vif.araddr;
                    wait(vif.rvalid && vif.rready);
                    item.data = vif.rdata;
                    item.resp = vif.rresp;
                    item_collected_port.write(item);
                end
            end
        end
    endtask
endclass
