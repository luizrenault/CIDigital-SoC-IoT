// ARQUIVO: uart_agent.sv
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Agente UART.
//            Instancia Sequencer, Driver e Monitor UART.

class uart_agent extends uvm_agent;

    uart_sequencer sqr;
    uart_driver    drv;
    uart_monitor   mon;

    `uvm_component_utils(uart_agent)

    function new(string name = "uart_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon = uart_monitor::type_id::create("mon", this);

        if (get_is_active() == UVM_ACTIVE) begin
            sqr = uart_sequencer::type_id::create("sqr", this);
            drv = uart_driver::type_id::create("drv", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction
endclass
