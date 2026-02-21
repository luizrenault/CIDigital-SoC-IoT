// ARQUIVO: single_write_test.sv
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Teste T02 - Escrita Única (Corrigido para fluxo UVM).

// 1. Criamos a sequência específica do cenário
class single_write_seq extends axi_base_seq;
    `uvm_object_utils(single_write_seq)
    
    function new(string name="single_write_seq"); 
        super.new(name); 
    endfunction

    virtual task body();
        `uvm_info("SEQ", "Executando escrita AXI 0xAB no endereço 0x0...", UVM_LOW)
        write_reg(4'h0, 32'hAB);
    endtask
endclass

// 2. O Teste apenas orquestra
class single_write_test extends uart_base_test;
    `uvm_component_utils(single_write_test)

    function new(string name = "single_write_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Instancia a nova sequência
        single_write_seq seq = single_write_seq::type_id::create("seq");
        
        phase.raise_objection(this);
        `uvm_info("TEST_T02", "Iniciando T02: single_write_test", UVM_LOW)

        // 1. Aguarda estabilização do Reset
        #100ns;

        // 2. INICIA A SEQUÊNCIA NO SEQUENCER CORRETO (Isso evita o Fatal Error!)
        seq.start(env.axi_agt.sqr);
        
        `uvm_info("TEST_T02", "Escrita enviada. Aguardando processamento da UART...", UVM_MEDIUM)

        // 3. Aguarda tempo de serialização
        #200us;

        `uvm_info("TEST_T02", "Finalizando T02.", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass