// ARQUIVO: uart_if.sv
// PROJETO: Ponte UART-AXI (XCMG Training Project)
// DESCRIÇÃO: Definição da Interface UART Física.
//            Define os sinais TX e RX para comunicação serial.

interface uart_if (
    input logic clk,    // Clock do sistema (usado para sincronização do TB)
    input logic rst_n   // Reset ativo baixo
);

    // -------------------------------------------------------------------------
    // Sinais Físicos da UART
    // -------------------------------------------------------------------------
    
    // TXD: Transmit Data (Saída do DUT -> Entrada do Agente UART)
    logic txd;

    // RXD: Receive Data (Entrada do DUT <- Saída do Agente UART)
    logic rxd;

    // -------------------------------------------------------------------------
    // Modports (Direcionamento de Sinais)
    // -------------------------------------------------------------------------

    // Modport para o Driver UART (Atua como o dispositivo externo/parceiro)
    // O driver "escreve" no rxd (que é entrada do DUT) e "lê" do txd.
    modport driver (
        input  clk, rst_n,
        output rxd,
        input  txd
    );

    // Modport para o Monitor UART (Passivo)
    // Observa ambas as linhas para reconstruir as transações.
    modport monitor (
        input clk, rst_n,
        input txd,
        input rxd
    );

endinterface