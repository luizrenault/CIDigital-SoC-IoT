// ARQUIVO: tb_top.sv
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Módulo de topo do testbench (Hardware Top).
//            Instancia o DUT, as interfaces e inicia o ambiente UVM.

module tb_top;

    import uvm_pkg::*;
    import uart_axi_pkg::*;
    `include "uvm_macros.svh"

    // -------------------------------------------------------------------------
    // Sinais de Clock e Reset
    // -------------------------------------------------------------------------
    logic clk;
    logic rst_n;

    // Geração de Clock (Exemplo: 50MHz -> Período de 20ns)
    initial begin
        clk = 0;
        forever #10ns clk = ~clk;
    end

    // Geração de Reset
    initial begin
        rst_n = 0;
        #50ns rst_n = 1;
    end

    // -------------------------------------------------------------------------
    // Instanciação das Interfaces
    // -------------------------------------------------------------------------
    axi_if  u_axi_if  (.clk(clk), .rst_n(rst_n));
    uart_if u_uart_if (.clk(clk), .rst_n(rst_n));

    initial begin
        u_uart_if.txd = 1'b1; // Linha TX em repouso (Idle)
        u_uart_if.rxd = 1'b1; // Linha RX em repouso (Idle)
    end

    // -------------------------------------------------------------------------
    // Instanciação do DUT (Design Under Test)
    // -------------------------------------------------------------------------
    // Conectando os sinais do design.v às interfaces do testbench
    uart_axi_lite_top #(
        .C_S_AXI_DATA_WIDTH(32),
        .C_S_AXI_ADDR_WIDTH(4)
    ) dut (
        .s_axi_aclk    (clk),
        .s_axi_aresetn (rst_n),
        
        // Canal de Escrita
        .s_axi_awaddr  (u_axi_if.awaddr),
        .s_axi_awvalid (u_axi_if.awvalid),
        .s_axi_awready (u_axi_if.awready),
        .s_axi_wdata   (u_axi_if.wdata),
        .s_axi_wvalid  (u_axi_if.wvalid),
        .s_axi_wready  (u_axi_if.wready),
        .s_axi_bresp   (u_axi_if.bresp),
        .s_axi_bvalid  (u_axi_if.bvalid),
        .s_axi_bready  (u_axi_if.bready),
        
        // Canal de Leitura
        .s_axi_araddr  (u_axi_if.araddr),
        .s_axi_arvalid (u_axi_if.arvalid),
        .s_axi_arready (u_axi_if.arready),
        .s_axi_rdata   (u_axi_if.rdata),
        .s_axi_rresp   (u_axi_if.rresp),
        .s_axi_rvalid  (u_axi_if.rvalid),
        .s_axi_rready  (u_axi_if.rready),
        
        // Interface UART
        .uart_txd      (u_uart_if.txd),
        .uart_rxd      (u_uart_if.rxd)
    );

    // -------------------------------------------------------------------------
    // Configuração e Início do Teste
    // -------------------------------------------------------------------------
    initial begin
        // Disponibiliza as interfaces virtuais para os componentes UVM (Drivers/Monitors)
        uvm_config_db#(virtual axi_if)::set(null, "*", "vif", u_axi_if);
        uvm_config_db#(virtual uart_if)::set(null, "*", "vif", u_uart_if);

        // Define o nível de verbosidade padrão
        uvm_top.set_report_verbosity_level(UVM_MEDIUM);

        // Inicia o teste especificado via linha de comando (+UVM_TESTNAME)
        // ou o teste padrão caso não seja especificado.
        run_test();
    end

    // Dump de ondas para debug (Opcional - dependente do simulador)
    initial begin
        $dumpfile("sim_output.vcd");
        $dumpvars(0, tb_top);
    end

endmodule
