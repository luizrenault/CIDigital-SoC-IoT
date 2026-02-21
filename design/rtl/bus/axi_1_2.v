`timescale 1ns/1ps
`include "soc_addr_map.vh"

module axi_lite_ic_1x2 #(
    // Root decode (MEM vs PERIPH) defaults from soc_addr_map.vh
    parameter [31:0] S0_BASE = `AXI_MEM_REGION_BASE,
    parameter [31:0] S0_MASK = `AXI_MEM_REGION_MASK,

    parameter [31:0] S1_BASE = `AXI_PERIPH_REGION_BASE,
    parameter [31:0] S1_MASK = `AXI_PERIPH_REGION_MASK
)(
    input  wire clk,
    input  wire resetn,

    // ---------------- Master (CPU side) ----------------
    input  wire        m_awvalid,
    output wire        m_awready,
    input  wire [31:0] m_awaddr,
    input  wire [2:0]  m_awprot,

    input  wire        m_wvalid,
    output wire        m_wready,
    input  wire [31:0] m_wdata,
    input  wire [3:0]  m_wstrb,

    output wire        m_bvalid,
    input  wire        m_bready,

    input  wire        m_arvalid,
    output wire        m_arready,
    input  wire [31:0] m_araddr,
    input  wire [2:0]  m_arprot,

    output wire        m_rvalid,
    input  wire        m_rready,
    output wire [31:0] m_rdata,

    // ---------------- Slave 0 = MEM ----------------
    output wire        s0_awvalid,
    input  wire        s0_awready,
    output wire [31:0] s0_awaddr,
    output wire [2:0]  s0_awprot,

    output wire        s0_wvalid,
    input  wire        s0_wready,
    output wire [31:0] s0_wdata,
    output wire [3:0]  s0_wstrb,

    input  wire        s0_bvalid,
    output wire        s0_bready,

    output wire        s0_arvalid,
    input  wire        s0_arready,
    output wire [31:0] s0_araddr,
    output wire [2:0]  s0_arprot,

    input  wire        s0_rvalid,
    output wire        s0_rready,
    input  wire [31:0] s0_rdata,

    // ---------------- Slave 1 = PERIPH ----------------
    output wire        s1_awvalid,
    input  wire        s1_awready,
    output wire [31:0] s1_awaddr,
    output wire [2:0]  s1_awprot,

    output wire        s1_wvalid,
    input  wire        s1_wready,
    output wire [31:0] s1_wdata,
    output wire [3:0]  s1_wstrb,

    input  wire        s1_bvalid,
    output wire        s1_bready,

    output wire        s1_arvalid,
    input  wire        s1_arready,
    output wire [31:0] s1_araddr,
    output wire [2:0]  s1_arprot,

    input  wire        s1_rvalid,
    output wire        s1_rready,
    input  wire [31:0] s1_rdata
);

    // -------------------------------------------------------------------------
    // Decode (addr & MASK) == BASE
    // -------------------------------------------------------------------------
    wire hit_s0_aw = ((m_awaddr & S0_MASK) == (S0_BASE & S0_MASK)); // MEM
    wire hit_s1_aw = ((m_awaddr & S1_MASK) == (S1_BASE & S1_MASK)); // PERIPH

    wire hit_s0_ar = ((m_araddr & S0_MASK) == (S0_BASE & S0_MASK)); // MEM
    wire hit_s1_ar = ((m_araddr & S1_MASK) == (S1_BASE & S1_MASK)); // PERIPH

    // -------------------------------------------------------------------------
    // WRITE (AW/W/B)
    // -------------------------------------------------------------------------
    reg wr_have_aw, wr_have_w;
    reg wr_sel_s0;   // 1=MEM (S0), 0=PERIPH (S1)
    reg wr_oob;

    // AW routed only when no AW latched
    assign s0_awvalid = m_awvalid && !wr_have_aw &&  hit_s0_aw;
    assign s1_awvalid = m_awvalid && !wr_have_aw &&  hit_s1_aw;

    assign s0_awaddr  = m_awaddr;
    assign s1_awaddr  = m_awaddr;
    assign s0_awprot  = m_awprot;
    assign s1_awprot  = m_awprot;

    // m_awready: only when we are free to accept a new AW
    assign m_awready  = (!wr_have_aw) ? ( hit_s0_aw ? s0_awready
                                   : hit_s1_aw ? s1_awready
                                               : 1'b1 ) : 1'b0;

    always @(posedge clk) begin
        if (!resetn) begin
            wr_have_aw <= 1'b0;
            wr_sel_s0  <= 1'b0;
            wr_oob     <= 1'b0;
        end else begin
            if (!wr_have_aw && m_awvalid && m_awready) begin
                wr_have_aw <= 1'b1;
                // priority S0 if both match (ideally they shouldn't overlap)
                wr_sel_s0  <= hit_s0_aw;
                wr_oob     <= !(hit_s0_aw || hit_s1_aw);
            end
            // cleared on B handshake
        end
    end

    // W follows selection latched on AW
    assign s0_wvalid = m_wvalid && wr_have_aw && !wr_have_w &&  wr_sel_s0 && !wr_oob;
    assign s1_wvalid = m_wvalid && wr_have_aw && !wr_have_w && !wr_sel_s0 && !wr_oob;

    assign s0_wdata  = m_wdata;
    assign s1_wdata  = m_wdata;
    assign s0_wstrb  = m_wstrb;
    assign s1_wstrb  = m_wstrb;

    assign m_wready  = (wr_have_aw && !wr_have_w) ? ( wr_oob ? 1'b1
                                             : (wr_sel_s0 ? s0_wready
                                                          : s1_wready)) : 1'b0;

    always @(posedge clk) begin
        if (!resetn) begin
            wr_have_w <= 1'b0;
        end else begin
            if (!wr_have_w && m_wvalid && m_wready)
                wr_have_w <= 1'b1;
            // cleared on B handshake
        end
    end

    // B: from selected slave, or internal if out-of-range
    reg bvalid_int;
    assign m_bvalid  = wr_oob ? bvalid_int
                              : (wr_sel_s0 ? s0_bvalid : s1_bvalid);

    assign s0_bready = (!wr_oob &&  wr_sel_s0) ? m_bready : 1'b0;
    assign s1_bready = (!wr_oob && !wr_sel_s0) ? m_bready : 1'b0;

    always @(posedge clk) begin
        if (!resetn) begin
            bvalid_int <= 1'b0;
            wr_have_aw <= 1'b0;
            wr_have_w  <= 1'b0;
        end else begin
            if (wr_oob) begin
                // generate B once AW and W were accepted
                if (!bvalid_int && wr_have_aw && wr_have_w)
                    bvalid_int <= 1'b1;

                if (bvalid_int && m_bready) begin
                    bvalid_int <= 1'b0;
                    wr_have_aw <= 1'b0;
                    wr_have_w  <= 1'b0;
                end
            end else begin
                // normal: clear when slave response handshakes
                if (m_bvalid && m_bready) begin
                    wr_have_aw <= 1'b0;
                    wr_have_w  <= 1'b0;
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // READ (AR/R)
    // -------------------------------------------------------------------------
    reg rd_busy;
    reg rd_sel_s0;     // 1=MEM, 0=PERIPH
    reg rd_oob;
    reg        rvalid_int;
    reg [31:0] rdata_int;

    assign s0_arvalid = m_arvalid && !rd_busy && hit_s0_ar;
    assign s1_arvalid = m_arvalid && !rd_busy && hit_s1_ar;

    assign s0_araddr  = m_araddr;
    assign s1_araddr  = m_araddr;
    assign s0_arprot  = m_arprot;
    assign s1_arprot  = m_arprot;

    assign m_arready  = (!rd_busy) ? ( hit_s0_ar ? s0_arready
                                   : hit_s1_ar ? s1_arready
                                               : 1'b1 ) : 1'b0;

    always @(posedge clk) begin
        if (!resetn) begin
            rd_busy    <= 1'b0;
            rd_sel_s0  <= 1'b0;
            rd_oob     <= 1'b0;
            rvalid_int <= 1'b0;
            rdata_int  <= 32'h0;
        end else begin
            if (!rd_busy && m_arvalid && m_arready) begin
                rd_busy   <= 1'b1;
                rd_sel_s0 <= hit_s0_ar;  // priority S0 if both match
                rd_oob    <= !(hit_s0_ar || hit_s1_ar);

                if (!(hit_s0_ar || hit_s1_ar)) begin
                    rvalid_int <= 1'b1;
                    rdata_int  <= 32'hDEAD_BEEF;
                end
            end

            if (m_rvalid && m_rready) begin
                rd_busy    <= 1'b0;
                rvalid_int <= 1'b0;
            end
        end
    end

    assign m_rvalid  = rd_oob ? rvalid_int
                              : (rd_sel_s0 ? s0_rvalid : s1_rvalid);

    assign m_rdata   = rd_oob ? rdata_int
                              : (rd_sel_s0 ? s0_rdata  : s1_rdata );

    assign s0_rready = (!rd_oob &&  rd_sel_s0) ? m_rready : 1'b0;
    assign s1_rready = (!rd_oob && !rd_sel_s0) ? m_rready : 1'b0;

endmodule
