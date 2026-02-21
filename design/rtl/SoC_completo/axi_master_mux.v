module axi_master_mux (
    // Controle
    input  wire        sel_bootloader, // 1 = Bootloader, 0 = CPU

    // --- Interface para a CPU (Slave side deste modulo) ---
    input  wire [31:0] cpu_awaddr,
    input  wire        cpu_awvalid,
    output wire        cpu_awready,
    input  wire [31:0] cpu_wdata,
    input  wire        cpu_wvalid,
    output wire        cpu_wready,
    // ... adicione os canais de Leitura (AR/R) e Resposta (B) ...

    // --- Interface para o Bootloader (Slave side deste modulo) ---
    input  wire [31:0] boot_awaddr,
    input  wire        boot_awvalid,
    output wire        boot_awready,
    input  wire [31:0] boot_wdata,
    input  wire        boot_wvalid,
    output wire        boot_wready,
    // ... adicione os canais de Leitura (AR/R) e Resposta (B) ...

    // --- Interface para o Interconnect (Master side deste modulo) ---
    output wire [31:0] m_awaddr,
    output wire        m_awvalid,
    input  wire        m_awready,
    output wire [31:0] m_wdata,
    output wire        m_wvalid,
    input  wire        m_wready
    // ... e o resto ...
);

    // Lógica Multiplexadora (Simples combinacional)
    // Se sel_bootloader for 1, passamos os sinais do BOOT. Se for 0, da CPU.
    
    // Saídas para o Interconnect (Mux)
    assign m_awaddr  = (sel_bootloader) ? boot_awaddr  : cpu_awaddr;
    assign m_awvalid = (sel_bootloader) ? boot_awvalid : cpu_awvalid;
    assign m_wdata   = (sel_bootloader) ? boot_wdata   : cpu_wdata;
    assign m_wvalid  = (sel_bootloader) ? boot_wvalid  : cpu_wvalid;

    // Entradas voltando do Interconnect (Demux / Broadcast)
    // O Ready só vai para quem está selecionado. O outro recebe 0.
    assign boot_awready = (sel_bootloader) ? m_awready : 1'b0;
    assign cpu_awready  = (sel_bootloader) ? 1'b0      : m_awready;

    assign boot_wready  = (sel_bootloader) ? m_wready : 1'b0;
    assign cpu_wready   = (sel_bootloader) ? 1'b0     : m_wready;

endmodule