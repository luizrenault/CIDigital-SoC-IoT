// ARQUIVO: axi_driver.sv
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Driver AXI4-Lite Master.
//            Converte transações AXI em ciclos de barramento na interface.

class axi_driver extends uvm_driver #(axi_seq_item);
    
    virtual axi_if vif; // Interface virtual para conexão com o hardware

    `uvm_component_utils(axi_driver)

    function new(string name = "axi_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "Não foi possível obter a interface virtual axi_if")
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Inicialização dos sinais
        vif.awvalid <= 0;
        vif.wvalid  <= 0;
        vif.arvalid <= 0;
        vif.bready  <= 0;
        vif.rready  <= 0;

        wait(vif.rst_n); // Aguarda o fim do reset

        forever begin
            seq_item_port.get_next_item(req);
            drive_transfer(req);
            seq_item_port.item_done();
        end
    endtask

    task drive_transfer(axi_seq_item item);
        if (item.op == axi_seq_item::WRITE) begin
            // Escrita AXI4-Lite simplificada (AW e W simultâneos conforme design.v)
            vif.awaddr  <= item.addr;
            vif.awvalid <= 1;
            vif.wdata   <= item.data;
            vif.wvalid  <= 1;
            vif.bready  <= 1;

            fork
                wait(vif.awready);
                wait(vif.wready);
            join
            
            @(posedge vif.clk);
            vif.awvalid <= 0;
            vif.wvalid  <= 0;
            
            wait(vif.bvalid);
            item.resp = vif.bresp;
            @(posedge vif.clk);
            vif.bready <= 0;
        end else begin
            // Leitura AXI4-Lite
            vif.araddr  <= item.addr;
            vif.arvalid <= 1;
            vif.rready  <= 1;

            wait(vif.arready);
            @(posedge vif.clk);
            vif.arvalid <= 0;

            wait(vif.rvalid);
            item.data = vif.rdata;
            item.resp = vif.rresp;
            @(posedge vif.clk);
            vif.rready <= 0;
        end
    endtask
endclass
