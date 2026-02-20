// ARQUIVO: single_read_test.sv
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Teste T03 - Leitura Única.
//            Verifica a recepção UART e a posterior leitura via AXI.

// -------------------------------------------------------------------------
// 1. Sequência UART: Injeta o frame serial no pino RX do DUT
// -------------------------------------------------------------------------
class uart_rx_seq extends uart_base_seq;
    `uvm_object_utils(uart_rx_seq)
    
    function new(string name="uart_rx_seq"); 
        super.new(name); 
    endfunction

    virtual task body();
        `uvm_info("SEQ_UART", "Enviando byte 0x5A para o RX do DUT...", UVM_LOW)
        // Usamos a task base para enviar um valor fixo (random = 0)
        send_byte(8'h5A, 0); 
    endtask
endclass

// -------------------------------------------------------------------------
// 2. Sequência AXI: Lê o dado do registrador RX (Assumindo Endereço 0x4)
// -------------------------------------------------------------------------
class axi_rx_read_seq extends axi_base_seq;
    `uvm_object_utils(axi_rx_read_seq)
    
    function new(string name="axi_rx_read_seq"); 
        super.new(name); 
    endfunction

    logic [31:0] rdata;

    virtual task body();
        `uvm_info("SEQ_AXI", "Lendo registrador RX (0x4)...", UVM_LOW)
        read_reg(4'h4, rdata);
        `uvm_info("SEQ_AXI", $sformatf("Dado lido do DUT: 0x%0h", rdata), UVM_LOW)
    endtask
endclass

// -------------------------------------------------------------------------
// 3. Orquestração: Teste T03
// -------------------------------------------------------------------------
class single_read_test extends uart_base_test;

    `uvm_component_utils(single_read_test)

    function new(string name = "single_read_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Instancia as duas sequências específicas
        uart_rx_seq     uart_seq = uart_rx_seq::type_id::create("uart_seq");
        axi_rx_read_seq axi_seq  = axi_rx_read_seq::type_id::create("axi_seq");

        phase.raise_objection(this);
        
        `uvm_info("TEST_T03", "Iniciando T03: single_read_test", UVM_LOW)

        // 1. Aplica Reset e aguarda o ambiente estabilizar
        #100ns;

        // 2. O Agente UART inicia o envio serial para o DUT
        uart_seq.start(env.uart_agt.sqr);

        // 3. Aguarda o tempo de serialização (aprox 10 bits a 115200 bps = ~87us)
        #100us;

        // 4. O Agente AXI realiza a leitura do dado que foi armazenado no DUT
        axi_seq.start(env.axi_agt.sqr);

        `uvm_info("TEST_T03", "Finalizando T03.", UVM_LOW)
        
        phase.drop_objection(this);
    endtask

endclass