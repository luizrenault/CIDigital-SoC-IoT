// ARQUIVO: uart_coverage.sv
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Coletor de Cobertura Funcional.
//            Mede a completude dos testes baseando-se nas transações observadas.

class uart_coverage extends uvm_subscriber #(axi_seq_item);

    axi_seq_item item;

    // -------------------------------------------------------------------------
    // Covergroup para Transações AXI
    // -------------------------------------------------------------------------
    covergroup cg_axi_transactions;
        option.per_instance = 1;
        option.name = "AXI Transactions Coverage";

        // Cobre os endereços acessados (0x0, 0x4, 0x8, 0xC) [cite: 158]
        cp_axi_addr: coverpoint item.addr {
            bins regs[] = {4'h0, 4'h4, 4'h8, 4'hC};
            illegal_bins inv_addr = default;
        }

        // Cobre o tipo de operação (Leitura vs Escrita) [cite: 158]
        cp_axi_rw: coverpoint item.op {
            bins read  = {axi_seq_item::READ};
            bins write = {axi_seq_item::WRITE};
        }

        // Cobre os valores de dados, focando em extremos [cite: 158]
        cp_axi_data: coverpoint item.data[7:0] {
            bins zero = {8'h00};
            bins full = {8'hFF};
            bins others = {[8'h01:8'hFE]};
        }

        // Cobertura cruzada entre tipo de operação e endereço
        cross_op_addr: cross cp_axi_rw, cp_axi_addr;
    endgroup

    // -------------------------------------------------------------------------
    // Covergroup para Configurações UART
    // -------------------------------------------------------------------------
    covergroup cg_uart_config;
        option.per_instance = 1;
        
        // Cobre diferentes baud rates configurados via registro 0xC [cite: 158]
        cp_baud_rate: coverpoint item.data[15:0] iff (item.op == axi_seq_item::WRITE && item.addr == 4'hC) {
            bins br_9600   = {16'd325};  // Exemplo para 50MHz
            bins br_115200 = {16'd27};   // Exemplo para 50MHz
            bins default_val = {16'd54}; // Valor padrão [cite: 45]
        }
    endgroup

    `uvm_component_utils(uart_coverage)

    function new(string name = "uart_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_axi_transactions = new();
        cg_uart_config = new();
    endfunction

    // Função chamada automaticamente via analysis port do Monitor
    virtual function void write(axi_seq_item t);
        this.item = t;
        cg_axi_transactions.sample();
        cg_uart_config.sample();
    endfunction

endclass