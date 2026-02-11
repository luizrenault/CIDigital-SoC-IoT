`timescale 1ns / 1ps

// =============================================================================
// DESCRICAO: Testbench para SoC RISC-V com UART Lite.
//
// FUNCIONALIDADES:
// 1. Gera Firmware Dinamicamente ou Carrega de Arquivo .HEX.
// 2. Simula Memoria RAM via barramento AXI4.
// 3. Monitora pino TX da UART e exibe no console (Tempo Real ou Bufferizado).
// =============================================================================

module tb_soc_uart_full;

    // =========================================================================
    // 1. CONFIGURACOES DO USUARIO
    // =========================================================================
    
    // -------------------------------------------------------------------------
    // PARAMETRO: MODO_OPERACAO
    // 0 = MODO GERADOR: Pega a string 'texto_msg', converte para Assembly RISC-V,
    //     preenche a RAM e salva um backup em 'firmware.hex'.
    // 1 = MODO CARREGADOR: Ignora o texto abaixo e carrega o arquivo 'firmware.hex'
    //     do disco diretamente para a RAM.
    // -------------------------------------------------------------------------
    parameter MODO_OPERACAO = 0; 

    // -------------------------------------------------------------------------
    // PARAMETRO: MODO_EXIBICAO (Monitor Serial)
    // 0 = TEMPO REAL: O console imprime cada letra assim que ela sai do pino TX.
    //     Util para ver se o timing esta correto.
    // 1 = TEXTO COMPLETO: O console guarda as letras na memoria e so imprime
    //     a frase completa no final. Util para leitura limpa.
    // -------------------------------------------------------------------------
    parameter MODO_EXIBICAO = 1; 

    // -------------------------------------------------------------------------
    // MENSAGEM DE TESTE (Apenas para MODO_OPERACAO = 0)
    // Nota: O registrador tem tamanho [8*256], permitindo ate 256 caracteres.
    // -------------------------------------------------------------------------
    reg [8*256:1] texto_msg = "TESTBENCH UART LITE!"; 

    // Configuracoes de Tempo
    // Clock 100MHz (Periodo 10ns)
    localparam CLOCK_PERIOD = 10;
    // Baud Rate: O Hardware divide o clock por 25 (configurado no uart_lite.v)
    localparam BIT_TIME     = 25 * CLOCK_PERIOD; 

    // =========================================================================
    // 2. SINAIS GLOBAIS E BARRAMENTO AXI4
    // =========================================================================
    reg clk, rst, uart_rx_i;
    wire uart_tx_o;

    // Sinais do Barramento AXI4 (Conexao entre CPU e Memoria)
    // Master (Sai da CPU) -> Slave (Entra na RAM)
    wire [31:0] mem_awaddr, mem_wdata, mem_araddr;
    wire [3:0]  mem_awid, mem_arid, mem_wstrb;
    wire [7:0]  mem_awlen, mem_arlen;
    wire [1:0]  mem_awburst, mem_arburst;
    wire        mem_awvalid, mem_wvalid, mem_wlast, mem_arvalid, mem_rready, mem_bready;
    
    // Slave (Sai da RAM) -> Master (Entra na CPU)
    wire        mem_arready, mem_awready, mem_wready; 
    reg         mem_rvalid, mem_rlast, mem_bvalid;
    reg  [31:0] mem_rdata_out;
    reg  [3:0]  mem_bid, mem_rid;

    // =========================================================================
    // 3. INSTANCIACAO DO SoC (DEVICE UNDER TEST)
    // =========================================================================
    riscv_soc u_dut (
        .clk_i(clk), 
        .rst_i(rst), 
        .reset_vector_i(32'h00000000), // CPU comeca a ler no endereco 0
        .uart_txd_i(uart_rx_i),        // Entrada RX (nao usada neste teste)
        .uart_rxd_o(uart_tx_o),        // Saida TX (Monitorada pelo TB)
        
        // --- Conexoes da Memoria AXI4 ---
        .mem_awvalid_o(mem_awvalid), .mem_awaddr_o(mem_awaddr), .mem_awid_o(mem_awid), 
        .mem_awlen_o(mem_awlen), .mem_awburst_o(mem_awburst), .mem_awready_i(mem_awready),
        .mem_wvalid_o(mem_wvalid), .mem_wdata_o(mem_wdata), .mem_wstrb_o(mem_wstrb), 
        .mem_wlast_o(mem_wlast), .mem_wready_i(mem_wready),
        .mem_bvalid_i(mem_bvalid), .mem_bresp_i(2'b00), .mem_bid_i(mem_bid), .mem_bready_o(mem_bready),
        .mem_arvalid_o(mem_arvalid), .mem_araddr_o(mem_araddr), .mem_arid_o(mem_arid), 
        .mem_arlen_o(mem_arlen), .mem_arburst_o(mem_arburst), .mem_arready_i(mem_arready),
        .mem_rvalid_i(mem_rvalid), .mem_rdata_i(mem_rdata_out), .mem_rresp_i(2'b00), 
        .mem_rid_i(mem_rid), .mem_rlast_i(mem_rlast), .mem_rready_o(mem_rready),
        
        // --- Portas Nao Utilizadas (Conexoes Dummy) ---
        // Entradas: Aterradas em 0 para nao flutuarem
        .inport_awvalid_i(1'b0), .inport_awaddr_i(32'h0), .inport_wvalid_i(1'b0), 
        .inport_wdata_i(32'h0), .inport_wstrb_i(4'h0), .inport_bready_i(1'b0), 
        .inport_arvalid_i(1'b0), .inport_araddr_i(32'h0), .inport_rready_i(1'b0), 
        .rst_cpu_i(rst), .gpio_input_i(32'h0), .spi_miso_i(1'b0),

        // Saidas: Deixadas em aberto () para evitar Warnings do ModelSim
        .inport_awready_o(), .inport_wready_o(), .inport_bvalid_o(), .inport_bresp_o(),
        .inport_arready_o(), .inport_rvalid_o(), .inport_rdata_o(), .inport_rresp_o(),
        .spi_clk_o(), .spi_mosi_o(), .spi_cs_o(), .gpio_output_o(), .gpio_output_enable_o()
    );

    // =========================================================================
    // 4. LOGICA DA MEMORIA RAM E GERADOR DE FIRMWARE
    // =========================================================================
    reg [31:0] ram [0:8191]; // 32KB de RAM
    integer ram_idx, str_idx, file_handle, loop_idx;
    reg [7:0] char_tmp;

    initial begin
        // 1. Limpa a RAM preenchendo com NOPs (No Operation = ADDI x0, x0, 0)
        //    Isso evita que a CPU execute lixo se pular para um endereco errado.
        for (ram_idx=0; ram_idx<8192; ram_idx=ram_idx+1) ram[ram_idx] = 32'h00000013;
        
        // ---------------------------------------------------------------------
        // CASO 0: MODO GERADOR (String -> Assembly -> RAM)
        // ---------------------------------------------------------------------
        if (MODO_OPERACAO == 0) begin
            $display("\n[INIT] MODO 0: Gerando firmware a partir da string...");
            ram_idx = 0;
            
            // Instrucao 1: Configura Base da UART
            // LUI x10, 0x92000 (Carrega 0x92000000 no registrador x10)
            ram[ram_idx] = 32'h92000537; ram_idx = ram_idx + 1; 

            // Loop: Percorre a string caractere por caractere
            for (str_idx = 0; str_idx < 256; str_idx = str_idx + 1) begin
                
                // Extrai o byte correto da string (logica Big Endian do Verilog)
                char_tmp = texto_msg[(256-str_idx)*8 -: 8];
                
                if (char_tmp != 0) begin // Ignora bytes nulos (fim da string)
                    
                    // A. POLLING STATUS (Espera a UART terminar de enviar o anterior)
                    // LW x5, 8(x10) -> Le o Status Register (Offset 8)
                    ram[ram_idx] = 32'h00852283; ram_idx = ram_idx + 1; 
                    // ANDI x5, x5, 8 -> Verifica se o bit 3 (TX BUSY) esta ligado
                    ram[ram_idx] = 32'h0082F293; ram_idx = ram_idx + 1; 
                    // BNE x5, x0, -8 -> Se x5 != 0 (Busy), volta 2 instrucoes (Loop)
                    ram[ram_idx] = 32'hFE029CE3; ram_idx = ram_idx + 1; 

                    // B. CARREGA O CARACTERE
                    // ADDI x11, x0, char -> Carrega o valor ASCII no registrador x11
                    // Montamos o opcode dinamicamente:
                    ram[ram_idx] = ({20'b0, char_tmp} << 20) | 32'h00000593; ram_idx = ram_idx + 1;

                    // C. ENVIA PARA UART
                    // SW x11, 4(x10) -> Escreve x11 no TX DATA Register (Offset 4)
                    ram[ram_idx] = 32'h00B52223; ram_idx = ram_idx + 1;

                    // D. SAFETY DELAY (Atraso de Seguranca)
                    // Inserimos NOPs para garantir que o hardware da UART levante
                    // a flag de Busy antes de checarmos novamente.
                    ram[ram_idx] = 32'h00000013; ram_idx = ram_idx + 1; 
                    ram[ram_idx] = 32'h00000013; ram_idx = ram_idx + 1; 
                    ram[ram_idx] = 32'h00000013; ram_idx = ram_idx + 1; 
                    ram[ram_idx] = 32'h00000013; ram_idx = ram_idx + 1; 
                end
            end
            
            // FIM: Envia Byte de Parada (0xFF)
            // Repete a logica de Polling e envio para o valor 255
            ram[ram_idx] = 32'h00852283; ram_idx = ram_idx + 1; // Polling
            ram[ram_idx] = 32'h0082F293; ram_idx = ram_idx + 1;
            ram[ram_idx] = 32'hFE029CE3; ram_idx = ram_idx + 1;
            ram[ram_idx] = 32'h0FF00593; ram_idx = ram_idx + 1; // Carrega 0xFF
            ram[ram_idx] = 32'h00B52223; ram_idx = ram_idx + 1; // Envia
            
            // Trava a CPU em Loop Infinito (Jump to self)
            ram[ram_idx] = 32'h0000006f; ram_idx = ram_idx + 1;

            // --- SALVANDO O .HEX ---
            file_handle = $fopen("firmware.hex", "w");
            if (file_handle) begin
                for (loop_idx = 0; loop_idx < ram_idx; loop_idx = loop_idx + 1)
                    $fdisplay(file_handle, "%h", ram[loop_idx]); // Escreve Hex no arquivo
                $fclose(file_handle);
                $display("[HEX] Arquivo 'firmware.hex' gerado com sucesso.");
            end
        end 
        // ---------------------------------------------------------------------
        // CASO 1: MODO CARREGADOR (Arquivo .HEX -> RAM)
        // ---------------------------------------------------------------------
        else begin
            $display("\n[INIT] MODO 1: Carregando firmware.hex do disco...");
            $readmemh("firmware.hex", ram);
            $display("[INIT] Memoria RAM carregada.");
        end
    end

    // =========================================================================
    // 5. CONTROLADOR AXI4 SLAVE (SIMULADOR DE RAM)
    // =========================================================================
    reg [7:0] r_cnt;
    reg [31:0] r_addr_lat;
    reg [3:0] r_id_lat;
    reg [7:0] r_len_lat;
    reg reading;

    // Sinais READY sao combinacionais (Respondem imediatamente se nao estiver ocupado)
    assign mem_arready = !reading && !rst;
    assign mem_awready = !rst;
    assign mem_wready  = !rst;

    // Leitura Assincrona: O dado sai assim que o endereco muda
    always @(*) mem_rdata_out = ram[(r_addr_lat >> 2) + r_cnt];

    // Maquina de Estados de Leitura
    always @(posedge clk) begin
        if (rst) begin
            mem_rvalid <= 0; mem_rlast <= 0; reading <= 0; r_cnt <= 0;
        end else begin
            // Fase de Endereco (Address Handshake)
            if (!reading && mem_arvalid) begin 
                reading    <= 1;
                r_addr_lat <= mem_araddr; // Salva o endereco
                r_id_lat   <= mem_arid;
                r_len_lat  <= mem_arlen;  // Salva o tamanho do burst
                r_cnt      <= 0;
            end
            // Fase de Dados (Data Handshake)
            if (reading) begin
                mem_rvalid <= 1;
                mem_rid    <= r_id_lat;
                mem_rlast  <= (r_cnt == r_len_lat); // Sinaliza ultimo dado
                
                // Se o mestre aceitou (rready), avanca
                if (mem_rready && mem_rvalid) begin
                    if (mem_rlast) begin 
                        reading <= 0; mem_rvalid <= 0; mem_rlast <= 0; 
                    end else begin
                        r_cnt <= r_cnt + 1; // Proximo endereco
                    end
                end
            end
        end
    end

    // Canal de Escrita (Simplificado - Apenas aceita a escrita)
    always @(posedge clk) begin
        if (rst) begin
            mem_bvalid <= 0;
        end else if (mem_wlast && mem_wvalid) begin 
            //ambos acontecem somente se a condicao for verdadeira
            mem_bvalid <= 1; 
            mem_bid <= mem_awid; 
        end else if (mem_bready) begin
            mem_bvalid <= 0;
        end
    end

    // =========================================================================
    // 6. MONITOR SERIAL (RX) - O "TERMINAL"
    // =========================================================================
    initial begin clk = 0; forever #(CLOCK_PERIOD/2) clk = ~clk; end

    initial begin
        rst = 1; uart_rx_i = 1; #1000; rst = 0;
        // Timeout de Seguranca (Caso o Stop Byte nunca chegue)
        #5000000; $display("[SIM] TIMEOUT: Stop Byte nao detectado."); $finish;
    end

    // Variaveis para decodificacao e buffer
    reg [7:0] rx_byte;
    reg [7:0] rx_buffer [0:1023]; // Armazena a mensagem inteira
    integer k;
    integer buf_idx;

    initial begin
        buf_idx = 0;
        wait(!rst);
        
        $display("--------------------------------------------------");
        if (MODO_EXIBICAO == 0)
            $display("   MONITOR SERIAL (Modo: Tempo Real)");
        else
            $display("   MONITOR SERIAL (Modo: Bufferizado / Texto Completo)");
        $display("--------------------------------------------------");
        
        forever begin
            // 1. Detecta Start Bit (Linha vai para 0)
            @(negedge uart_tx_o); 
            
            // 2. Espera 1.5 bits para amostrar no meio do Bit 0
            #(BIT_TIME * 1.5);    
            
            // 3. Amostra os 8 bits de dados
            for (k=0; k<8; k=k+1) begin 
                rx_byte[k] = uart_tx_o; #(BIT_TIME); 
            end
            
            // 4. Verifica se e o Byte de Parada (0xFF)
            if (rx_byte == 8'hFF) begin
                
                // Se estiver no Modo Texto Completo, imprime tudo agora
                if (MODO_EXIBICAO == 1) begin
                    $display("\n==================================================");
                    $display("MENSAGEM RECEBIDA:");
                    // Loop que imprime o buffer acumulado
                    for (k=0; k < buf_idx; k=k+1) begin
                        $write("%c", rx_buffer[k]);
                    end
                    $display("\n==================================================\n");
                end else begin
                    $display("\n[SIM] Fim de Transmissao Detectado.");
                end
                
                $finish; // Encerra a simulacao
            end else begin
                // 5. Se nao for parada, processa o caractere
                if (MODO_EXIBICAO == 0) begin
                    // MODO 0: Imprime na hora
                    $display("[ Tempo: %08d ns ] RX: '%c' (Hex: %h)", $time, rx_byte, rx_byte);
                    $fflush(1);
                end else begin
                    // MODO 1: Guarda no buffer
                    rx_buffer[buf_idx] = rx_byte;
                    buf_idx = buf_idx + 1;
                end
            end
        end
    end
    
    // Gera arquivo VCD para GTKWave
    initial begin
        $dumpfile("soc_uart_full.vcd");
        $dumpvars(0, tb_soc_uart_full);
    end

endmodule