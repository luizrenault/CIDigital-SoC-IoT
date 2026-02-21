// ARQUIVO: uart_base_test.sv
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Teste Base UVM.
//            Configura o ambiente e inicia a execução das sequências.

class uart_base_test extends uvm_test;

    uart_env env;

    `uvm_component_utils(uart_base_test)

    // Construtor
    function new(string name = "uart_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Fase de Build: Instancia o ambiente de verificação
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = uart_env::type_id::create("env", this);
    endfunction

    // Fase de End of Elaboration: Imprime a topologia para conferência
    virtual function void end_of_elaboration_phase(uvm_phase phase);
        `uvm_info("TEST_TOP", "Topologia do Testbench:", UVM_LOW)
        this.print();
    endfunction

    // Fase de Run: Define o tempo limite (timeout) e o fluxo de execução
    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        
        `uvm_info("TEST_START", "Iniciando o Teste Base...", UVM_LOW)
        
        // No teste base, geralmente apenas verificamos se o ambiente "sobe"
        // conforme definido no critério de conclusão da Fase 5.
        #100ns; 

        `uvm_info("TEST_END", "Teste Base finalizado.", UVM_LOW)
        phase.drop_objection(this);
    endtask

endclass

