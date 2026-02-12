`timescale 1ns/1ps
module axi_lite_ic_1x4 #(
    parameter [31:0] S0_BASE = 32'h0000_0000,
    parameter [31:0] S0_MASK = 32'hFFFF_F000, // 4 KiB
    parameter [31:0] S1_BASE = 32'hFFFF_FFFE, // disabled por padrão
    parameter [31:0] S1_MASK = 32'hFFFF_F000,
    parameter [31:0] S2_BASE = 32'hFFFF_FFFE, // disabled
    parameter [31:0] S2_MASK = 32'hFFFF_F000,
    parameter [31:0] S3_BASE = 32'hFFFF_FFFE, // disabled
    parameter [31:0] S3_MASK = 32'hFFFF_F000
)(
    input  wire clk,
    input  wire resetn,

    // Master
    input  wire        m_awvalid, output wire m_awready,
    input  wire [31:0] m_awaddr,  input  wire [2:0] m_awprot,
    input  wire        m_wvalid,  output wire m_wready,
    input  wire [31:0] m_wdata,   input  wire [3:0] m_wstrb,
    output wire        m_bvalid,  input  wire       m_bready,

    input  wire        m_arvalid, output wire m_arready,
    input  wire [31:0] m_araddr,  input  wire [2:0] m_arprot,
    output wire        m_rvalid,  input  wire       m_rready,
    output wire [31:0] m_rdata,

    // Slave 0
    output wire        s0_awvalid, input  wire s0_awready,
    output wire [31:0] s0_awaddr,  output wire [2:0] s0_awprot,
    output wire        s0_wvalid,  input  wire s0_wready,
    output wire [31:0] s0_wdata,   output wire [3:0] s0_wstrb,
    input  wire        s0_bvalid,  output wire       s0_bready,

    output wire        s0_arvalid, input  wire s0_arready,
    output wire [31:0] s0_araddr,  output wire [2:0] s0_arprot,
    input  wire        s0_rvalid,  output wire       s0_rready,
    input  wire [31:0] s0_rdata,

    // Slave 1
    output wire        s1_awvalid, input  wire s1_awready,
    output wire [31:0] s1_awaddr,  output wire [2:0] s1_awprot,
    output wire        s1_wvalid,  input  wire s1_wready,
    output wire [31:0] s1_wdata,   output wire [3:0] s1_wstrb,
    input  wire        s1_bvalid,  output wire       s1_bready,

    output wire        s1_arvalid, input  wire s1_arready,
    output wire [31:0] s1_araddr,  output wire [2:0] s1_arprot,
    input  wire        s1_rvalid,  output wire       s1_rready,
    input  wire [31:0] s1_rdata,

    // Slave 2
    output wire        s2_awvalid, input  wire s2_awready,
    output wire [31:0] s2_awaddr,  output wire [2:0] s2_awprot,
    output wire        s2_wvalid,  input  wire s2_wready,
    output wire [31:0] s2_wdata,   output wire [3:0] s2_wstrb,
    input  wire        s2_bvalid,  output wire       s2_bready,

    output wire        s2_arvalid, input  wire s2_arready,
    output wire [31:0] s2_araddr,  output wire [2:0] s2_arprot,
    input  wire        s2_rvalid,  output wire       s2_rready,
    input  wire [31:0] s2_rdata,

    // Slave 3
    output wire        s3_awvalid, input  wire s3_awready,
    output wire [31:0] s3_awaddr,  output wire [2:0] s3_awprot,
    output wire        s3_wvalid,  input  wire s3_wready,
    output wire [31:0] s3_wdata,   output wire [3:0] s3_wstrb,
    input  wire        s3_bvalid,  output wire       s3_bready,

    output wire        s3_arvalid, input  wire s3_arready,
    output wire [31:0] s3_araddr,  output wire [2:0] s3_arprot,
    input  wire        s3_rvalid,  output wire       s3_rready,
    input  wire [31:0] s3_rdata
);
    // --- decode ---
    wire hit0_aw = ((m_awaddr & S0_MASK) == (S0_BASE & S0_MASK));
    wire hit1_aw = ((m_awaddr & S1_MASK) == (S1_BASE & S1_MASK));
    wire hit2_aw = ((m_awaddr & S2_MASK) == (S2_BASE & S2_MASK));
    wire hit3_aw = ((m_awaddr & S3_MASK) == (S3_BASE & S3_MASK));

    wire hit0_ar = ((m_araddr & S0_MASK) == (S0_BASE & S0_MASK));
    wire hit1_ar = ((m_araddr & S1_MASK) == (S1_BASE & S1_MASK));
    wire hit2_ar = ((m_araddr & S2_MASK) == (S2_BASE & S2_MASK));
    wire hit3_ar = ((m_araddr & S3_MASK) == (S3_BASE & S3_MASK));

    // ---------------- WRITE path (AW/W/B) ----------------
    reg wr_have_aw, wr_have_w;
    reg [1:0] wr_sel;  // 0..3
    reg       wr_oob;  // fora de faixa

    // AW → roteia só quando ainda não temos AW latched
    assign s0_awvalid = m_awvalid && !wr_have_aw &&  hit0_aw;
    assign s1_awvalid = m_awvalid && !wr_have_aw &&  hit1_aw;
    assign s2_awvalid = m_awvalid && !wr_have_aw &&  hit2_aw;
    assign s3_awvalid = m_awvalid && !wr_have_aw &&  hit3_aw;

    assign s0_awaddr  = m_awaddr;
    assign s1_awaddr  = m_awaddr;
    assign s2_awaddr  = m_awaddr;
    assign s3_awaddr  = m_awaddr;

    assign s0_awprot  = m_awprot;
    assign s1_awprot  = m_awprot;
    assign s2_awprot  = m_awprot;
    assign s3_awprot  = m_awprot;

    assign m_awready  = (!wr_have_aw) ?
                        ( hit0_aw ? s0_awready :
                          hit1_aw ? s1_awready :
                          hit2_aw ? s2_awready :
                          hit3_aw ? s3_awready : 1'b1 ) : 1'b0;

    always @(posedge clk) begin
        if (!resetn) begin
            wr_have_aw <= 1'b0;
            wr_sel     <= 2'd0;
            wr_oob     <= 1'b0;
        end else begin
            if (!wr_have_aw && m_awvalid && m_awready) begin
                wr_have_aw <= 1'b1;
                wr_oob     <= !(hit0_aw || hit1_aw || hit2_aw || hit3_aw);
                wr_sel     <= hit0_aw ? 2'd0 :
                              hit1_aw ? 2'd1 :
                              hit2_aw ? 2'd2 : 2'd3;
            end
            // limpo no B
        end
    end

    // W → segue a seleção do AW
    assign s0_wvalid = m_wvalid && wr_have_aw && !wr_have_w && (wr_sel==2'd0) && !wr_oob;
    assign s1_wvalid = m_wvalid && wr_have_aw && !wr_have_w && (wr_sel==2'd1) && !wr_oob;
    assign s2_wvalid = m_wvalid && wr_have_aw && !wr_have_w && (wr_sel==2'd2) && !wr_oob;
    assign s3_wvalid = m_wvalid && wr_have_aw && !wr_have_w && (wr_sel==2'd3) && !wr_oob;

    assign s0_wdata  = m_wdata;
    assign s1_wdata  = m_wdata;
    assign s2_wdata  = m_wdata;
    assign s3_wdata  = m_wdata;

    assign s0_wstrb  = m_wstrb;
    assign s1_wstrb  = m_wstrb;
    assign s2_wstrb  = m_wstrb;
    assign s3_wstrb  = m_wstrb;

    assign m_wready  = (wr_have_aw && !wr_have_w) ?
                       ( wr_oob ? 1'b1 :
                         (wr_sel==2'd0 ? s0_wready :
                          wr_sel==2'd1 ? s1_wready :
                          wr_sel==2'd2 ? s2_wready : s3_wready) ) : 1'b0;

    always @(posedge clk) begin
        if (!resetn) begin
            wr_have_w <= 1'b0;
        end else begin
            if (!wr_have_w && m_wvalid && m_wready) wr_have_w <= 1'b1;
            // limpo no B
        end
    end

    // B → do slave escolhido, ou interno se OOB
    reg bvalid_int;
    assign m_bvalid = wr_oob ? bvalid_int :
                      (wr_sel==2'd0 ? s0_bvalid :
                       wr_sel==2'd1 ? s1_bvalid :
                       wr_sel==2'd2 ? s2_bvalid : s3_bvalid);

    assign s0_bready = (!wr_oob && (wr_sel==2'd0)) ? m_bready : 1'b0;
    assign s1_bready = (!wr_oob && (wr_sel==2'd1)) ? m_bready : 1'b0;
    assign s2_bready = (!wr_oob && (wr_sel==2'd2)) ? m_bready : 1'b0;
    assign s3_bready = (!wr_oob && (wr_sel==2'd3)) ? m_bready : 1'b0;

    always @(posedge clk) begin
        if (!resetn) begin
            bvalid_int <= 1'b0;
            wr_have_aw <= 1'b0;
            wr_have_w  <= 1'b0;
        end else begin
            if (wr_oob) begin
                if (!bvalid_int && wr_have_aw && wr_have_w)
                    bvalid_int <= 1'b1;
                if (bvalid_int && m_bready) begin
                    bvalid_int <= 1'b0;
                    wr_have_aw <= 1'b0;
                    wr_have_w  <= 1'b0;
                end
            end else begin
                if (m_bvalid && m_bready) begin
                    wr_have_aw <= 1'b0;
                    wr_have_w  <= 1'b0;
                end
            end
        end
    end

    // ---------------- READ path (AR/R) ----------------
    reg       rd_busy;
    reg [1:0] rd_sel;
    reg       rd_oob;
    reg       rvalid_int;
    reg [31:0] rdata_int;

    assign s0_arvalid = m_arvalid && !rd_busy &&  hit0_ar;
    assign s1_arvalid = m_arvalid && !rd_busy &&  hit1_ar;
    assign s2_arvalid = m_arvalid && !rd_busy &&  hit2_ar;
    assign s3_arvalid = m_arvalid && !rd_busy &&  hit3_ar;

    assign s0_araddr  = m_araddr;
    assign s1_araddr  = m_araddr;
    assign s2_araddr  = m_araddr;
    assign s3_araddr  = m_araddr;

    assign s0_arprot  = m_arprot;
    assign s1_arprot  = m_arprot;
    assign s2_arprot  = m_arprot;
    assign s3_arprot  = m_arprot;

    assign m_arready  = (!rd_busy) ?
                        ( hit0_ar ? s0_arready :
                          hit1_ar ? s1_arready :
                          hit2_ar ? s2_arready :
                          hit3_ar ? s3_arready : 1'b1 ) : 1'b0;

    always @(posedge clk) begin
        if (!resetn) begin
            rd_busy    <= 1'b0;
            rd_sel     <= 2'd0;
            rd_oob     <= 1'b0;
            rvalid_int <= 1'b0;
            rdata_int  <= 32'h0;
        end else begin
            if (!rd_busy && m_arvalid && m_arready) begin
                rd_busy <= 1'b1;
                rd_oob  <= !(hit0_ar || hit1_ar || hit2_ar || hit3_ar);
                rd_sel  <= hit0_ar ? 2'd0 :
                           hit1_ar ? 2'd1 :
                           hit2_ar ? 2'd2 : 2'd3;
                if (!(hit0_ar || hit1_ar || hit2_ar || hit3_ar)) begin
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

    assign m_rvalid = rd_oob ? rvalid_int :
                      (rd_sel==2'd0 ? s0_rvalid :
                       rd_sel==2'd1 ? s1_rvalid :
                       rd_sel==2'd2 ? s2_rvalid : s3_rvalid);

    assign m_rdata  = rd_oob ? rdata_int :
                      (rd_sel==2'd0 ? s0_rdata  :
                       rd_sel==2'd1 ? s1_rdata  :
                       rd_sel==2'd2 ? s2_rdata  : s3_rdata );

    assign s0_rready = (!rd_oob && (rd_sel==2'd0)) ? m_rready : 1'b0;
    assign s1_rready = (!rd_oob && (rd_sel==2'd1)) ? m_rready : 1'b0;
    assign s2_rready = (!rd_oob && (rd_sel==2'd2)) ? m_rready : 1'b0;
    assign s3_rready = (!rd_oob && (rd_sel==2'd3)) ? m_rready : 1'b0;

endmodule
