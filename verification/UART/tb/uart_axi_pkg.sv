// ARQUIVO: uart_axi_pkg.sv
// DESENVOLVEDOR: Igor Cintra
// DESCRIÇÃO: Pacote do projeto de verificação com caminhos mapeados.

package uart_axi_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // -------------------------------------------------------------------------
    // 1. Inclusão dos componentes do Agente AXI
    // -------------------------------------------------------------------------
    `include "agents/axi_agent/axi_seq_item.sv"
    `include "agents/axi_agent/axi_sequencer.sv"
    `include "agents/axi_agent/axi_driver.sv"
    `include "agents/axi_agent/axi_monitor.sv"
    `include "agents/axi_agent/axi_agent.sv"

    // -------------------------------------------------------------------------
    // 2. Inclusão dos componentes do Agente UART
    // -------------------------------------------------------------------------
    `include "agents/uart_agent/uart_seq_item.sv"
    `include "agents/uart_agent/uart_sequencer.sv"
    `include "agents/uart_agent/uart_driver.sv"
    `include "agents/uart_agent/uart_monitor.sv"
    `include "agents/uart_agent/uart_agent.sv"

    // -------------------------------------------------------------------------
    // 3. Componentes de Análise e Ambiente
    // -------------------------------------------------------------------------
    `include "scoreboard/uart_scoreboard.sv"
    `include "coverage/uart_coverage.sv"
    `include "env/uart_env.sv"

    // -------------------------------------------------------------------------
    // 4. Sequências
    // -------------------------------------------------------------------------
    `include "sequences/axi_base_seq.sv"
    `include "sequences/uart_base_seq.sv"

    // -------------------------------------------------------------------------
    // 5. Testes
    // -------------------------------------------------------------------------
    `include "tests/uart_base_test.sv"
    `include "tests/single_write_test.sv"
    `include "tests/single_read_test.sv"

endpackage