// ARQUIVO: uart_env.sv
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Ambiente de Verificação (UVM Env).
//            Instancia e conecta Agentes, Scoreboard e Cobertura.

class uart_env extends uvm_env;

    // Instâncias dos componentes do ambiente [cite: 116]
    axi_agent       axi_agt;
    uart_agent      uart_agt;
    uart_scoreboard scb;
    uart_coverage   cov;

    `uvm_component_utils(uart_env)

    // Construtor
    function new(string name = "uart_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Fase de Build: Instanciação dos subcomponentes 
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        axi_agt  = axi_agent::type_id::create("axi_agt", this);
        uart_agt = uart_agent::type_id::create("uart_agt", this);
        scb      = uart_scoreboard::type_id::create("scb", this);
        cov      = uart_coverage::type_id::create("cov", this);

        // Configura o agente AXI como ativo para gerar estímulos [cite: 116]
        uvm_config_db#(int)::set(this, "axi_agt", "is_active", UVM_ACTIVE);
        
        // Configura o agente UART como ativo para responder/enviar dados
        uvm_config_db#(int)::set(this, "uart_agt", "is_active", UVM_ACTIVE);
    endfunction

    // Fase de Conexão: Interliga as analysis ports dos monitores ao SCB e COV [cite: 116]
    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Conecta Monitor AXI ao Scoreboard e ao Coletor de Cobertura
        axi_agt.mon.item_collected_port.connect(scb.axi_export);
        axi_agt.mon.item_collected_port.connect(cov.analysis_export);

        // Conecta Monitor UART ao Scoreboard
        uart_agt.mon.item_collected_port.connect(scb.uart_export);
    endfunction

endclass

