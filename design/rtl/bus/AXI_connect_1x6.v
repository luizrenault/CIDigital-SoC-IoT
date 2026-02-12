// -----------------------------------------------------------------------------
// AXI4-Lite Interconnect 1x6
// One master -> six slaves (address decoded)
// - AXI4-Lite only (no bursts, no IDs)
// - Independent read/write paths
// - Latches target on AW/AR handshake to route W/B and R
// - Unmapped access returns DECERR
// - Parameterizable base/mask per slave
// -----------------------------------------------------------------------------

module axi_lite_interconnect_1x6 #(
    parameter integer S_AXI_ADDR_WIDTH = 32,
    parameter integer S_AXI_DATA_WIDTH = 32,

    // Address decode: (addr & MASK) == BASE -> selects slave
    parameter [31:0] SLV0_BASE = 32'h4000_0000,
    parameter [31:0] SLV0_MASK = 32'hFFFF_F000, // 4KB region

    parameter [31:0] SLV1_BASE = 32'h4000_1000,
    parameter [31:0] SLV1_MASK = 32'hFFFF_F000,

    parameter [31:0] SLV2_BASE = 32'h4000_2000,
    parameter [31:0] SLV2_MASK = 32'hFFFF_F000,

    parameter [31:0] SLV3_BASE = 32'h4000_3000,
    parameter [31:0] SLV3_MASK = 32'hFFFF_F000,

    parameter [31:0] SLV4_BASE = 32'h4000_4000,
    parameter [31:0] SLV4_MASK = 32'hFFFF_F000,

    parameter [31:0] SLV5_BASE = 32'h4000_5000,
    parameter [31:0] SLV5_MASK = 32'hFFFF_F000
) (
    input  wire                           aclk,
    input  wire                           aresetn,

    // ---------------- Master side (S = Slave of the interconnect) ----------------
    // Write address channel
    input  wire [S_AXI_ADDR_WIDTH-1:0]    s_axi_awaddr,
    input  wire                           s_axi_awvalid,
    output reg                            s_axi_awready,

    // Write data channel
    input  wire [S_AXI_DATA_WIDTH-1:0]    s_axi_wdata,
    input  wire [(S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                           s_axi_wvalid,
    output reg                            s_axi_wready,

    // Write response channel
    output reg  [1:0]                     s_axi_bresp,
    output reg                            s_axi_bvalid,
    input  wire                           s_axi_bready,

    // Read address channel
    input  wire [S_AXI_ADDR_WIDTH-1:0]    s_axi_araddr,
    input  wire                           s_axi_arvalid,
    output reg                            s_axi_arready,

    // Read data channel
    output reg  [S_AXI_DATA_WIDTH-1:0]    s_axi_rdata,
    output reg  [1:0]                     s_axi_rresp,
    output reg                            s_axi_rvalid,
    input  wire                           s_axi_rready,

    // ---------------- Slave side (M = Master of the interconnect) ----------------
    // Port 0
    output wire [S_AXI_ADDR_WIDTH-1:0]    m0_axi_awaddr,
    output wire                           m0_axi_awvalid,
    input  wire                           m0_axi_awready,
    output wire [S_AXI_DATA_WIDTH-1:0]    m0_axi_wdata,
    output wire [(S_AXI_DATA_WIDTH/8)-1:0] m0_axi_wstrb,
    output wire                           m0_axi_wvalid,
    input  wire                           m0_axi_wready,
    input  wire [1:0]                     m0_axi_bresp,
    input  wire                           m0_axi_bvalid,
    output wire                           m0_axi_bready,
    output wire [S_AXI_ADDR_WIDTH-1:0]    m0_axi_araddr,
    output wire                           m0_axi_arvalid,
    input  wire                           m0_axi_arready,
    input  wire [S_AXI_DATA_WIDTH-1:0]    m0_axi_rdata,
    input  wire [1:0]                     m0_axi_rresp,
    input  wire                           m0_axi_rvalid,
    output wire                           m0_axi_rready,

    // Port 1
    output wire [S_AXI_ADDR_WIDTH-1:0]    m1_axi_awaddr,
    output wire                           m1_axi_awvalid,
    input  wire                           m1_axi_awready,
    output wire [S_AXI_DATA_WIDTH-1:0]    m1_axi_wdata,
    output wire [(S_AXI_DATA_WIDTH/8)-1:0] m1_axi_wstrb,
    output wire                           m1_axi_wvalid,
    input  wire                           m1_axi_wready,
    input  wire [1:0]                     m1_axi_bresp,
    input  wire                           m1_axi_bvalid,
    output wire                           m1_axi_bready,
    output wire [S_AXI_ADDR_WIDTH-1:0]    m1_axi_araddr,
    output wire                           m1_axi_arvalid,
    input  wire                           m1_axi_arready,
    input  wire [S_AXI_DATA_WIDTH-1:0]    m1_axi_rdata,
    input  wire [1:0]                     m1_axi_rresp,
    input  wire                           m1_axi_rvalid,
    output wire                           m1_axi_rready,

    // Port 2
    output wire [S_AXI_ADDR_WIDTH-1:0]    m2_axi_awaddr,
    output wire                           m2_axi_awvalid,
    input  wire                           m2_axi_awready,
    output wire [S_AXI_DATA_WIDTH-1:0]    m2_axi_wdata,
    output wire [(S_AXI_DATA_WIDTH/8)-1:0] m2_axi_wstrb,
    output wire                           m2_axi_wvalid,
    input  wire                           m2_axi_wready,
    input  wire [1:0]                     m2_axi_bresp,
    input  wire                           m2_axi_bvalid,
    output wire                           m2_axi_bready,
    output wire [S_AXI_ADDR_WIDTH-1:0]    m2_axi_araddr,
    output wire                           m2_axi_arvalid,
    input  wire                           m2_axi_arready,
    input  wire [S_AXI_DATA_WIDTH-1:0]    m2_axi_rdata,
    input  wire [1:0]                     m2_axi_rresp,
    input  wire                           m2_axi_rvalid,
    output wire                           m2_axi_rready,

    // Port 3
    output wire [S_AXI_ADDR_WIDTH-1:0]    m3_axi_awaddr,
    output wire                           m3_axi_awvalid,
    input  wire                           m3_axi_awready,
    output wire [S_AXI_DATA_WIDTH-1:0]    m3_axi_wdata,
    output wire [(S_AXI_DATA_WIDTH/8)-1:0] m3_axi_wstrb,
    output wire                           m3_axi_wvalid,
    input  wire                           m3_axi_wready,
    input  wire [1:0]                     m3_axi_bresp,
    input  wire                           m3_axi_bvalid,
    output wire                           m3_axi_bready,
    output wire [S_AXI_ADDR_WIDTH-1:0]    m3_axi_araddr,
    output wire                           m3_axi_arvalid,
    input  wire                           m3_axi_arready,
    input  wire [S_AXI_DATA_WIDTH-1:0]    m3_axi_rdata,
    input  wire [1:0]                     m3_axi_rresp,
    input  wire                           m3_axi_rvalid,
    output wire                           m3_axi_rready,

    // Port 4
    output wire [S_AXI_ADDR_WIDTH-1:0]    m4_axi_awaddr,
    output wire                           m4_axi_awvalid,
    input  wire                           m4_axi_awready,
    output wire [S_AXI_DATA_WIDTH-1:0]    m4_axi_wdata,
    output wire [(S_AXI_DATA_WIDTH/8)-1:0] m4_axi_wstrb,
    output wire                           m4_axi_wvalid,
    input  wire                           m4_axi_wready,
    input  wire [1:0]                     m4_axi_bresp,
    input  wire                           m4_axi_bvalid,
    output wire                           m4_axi_bready,
    output wire [S_AXI_ADDR_WIDTH-1:0]    m4_axi_araddr,
    output wire                           m4_axi_arvalid,
    input  wire                           m4_axi_arready,
    input  wire [S_AXI_DATA_WIDTH-1:0]    m4_axi_rdata,
    input  wire [1:0]                     m4_axi_rresp,
    input  wire                           m4_axi_rvalid,
    output wire                           m4_axi_rready,

    // Port 5
    output wire [S_AXI_ADDR_WIDTH-1:0]    m5_axi_awaddr,
    output wire                           m5_axi_awvalid,
    input  wire                           m5_axi_awready,
    output wire [S_AXI_DATA_WIDTH-1:0]    m5_axi_wdata,
    output wire [(S_AXI_DATA_WIDTH/8)-1:0] m5_axi_wstrb,
    output wire                           m5_axi_wvalid,
    input  wire                           m5_axi_wready,
    input  wire [1:0]                     m5_axi_bresp,
    input  wire                           m5_axi_bvalid,
    output wire                           m5_axi_bready,
    output wire [S_AXI_ADDR_WIDTH-1:0]    m5_axi_araddr,
    output wire                           m5_axi_arvalid,
    input  wire                           m5_axi_arready,
    input  wire [S_AXI_DATA_WIDTH-1:0]    m5_axi_rdata,
    input  wire [1:0]                     m5_axi_rresp,
    input  wire                           m5_axi_rvalid,
    output wire                           m5_axi_rready
);

    localparam [1:0] RESP_OKAY  = 2'b00;
    localparam [1:0] RESP_DECERR= 2'b11;

    // ---------------------- Address Decode ----------------------
    function [2:0] decode;
        input [31:0] addr;
        begin
            if ((addr & SLV0_MASK) == SLV0_BASE) decode = 3'd0;
            else if ((addr & SLV1_MASK) == SLV1_BASE) decode = 3'd1;
            else if ((addr & SLV2_MASK) == SLV2_BASE) decode = 3'd2;
            else if ((addr & SLV3_MASK) == SLV3_BASE) decode = 3'd3;
            else if ((addr & SLV4_MASK) == SLV4_BASE) decode = 3'd4;
            else if ((addr & SLV5_MASK) == SLV5_BASE) decode = 3'd5;
            else decode = 3'd7; // invalid
        end
    endfunction

    // ---------------------- Write path ----------------------
    reg        aw_captured;
    reg  [2:0] aw_sel;
    reg [S_AXI_ADDR_WIDTH-1:0] awaddr_hold;

    // Capture AW when valid/ready
    always @(posedge aclk) begin
        if (!aresetn) begin
            aw_captured <= 1'b0;
            aw_sel      <= 3'd7;
            awaddr_hold <= {S_AXI_ADDR_WIDTH{1'b0}};
        end else begin
            if (!aw_captured && s_axi_awvalid && s_axi_awready) begin
                aw_captured <= 1'b1;
                awaddr_hold <= s_axi_awaddr;
                aw_sel      <= decode(s_axi_awaddr);
            end else if (s_axi_bvalid && s_axi_bready) begin
                aw_captured <= 1'b0; // write txn completes on B handshake
            end
        end
    end

    // Generate ready based on selected path availability
    wire aw_to_valid = s_axi_awvalid && !aw_captured; // only accept a new AW when none captured

    // Per-port AWVALID
    assign m0_axi_awaddr  = s_axi_awaddr;
    assign m1_axi_awaddr  = s_axi_awaddr;
    assign m2_axi_awaddr  = s_axi_awaddr;
    assign m3_axi_awaddr  = s_axi_awaddr;
    assign m4_axi_awaddr  = s_axi_awaddr;
    assign m5_axi_awaddr  = s_axi_awaddr;

    assign m0_axi_awvalid = aw_to_valid && (decode(s_axi_awaddr) == 3'd0);
    assign m1_axi_awvalid = aw_to_valid && (decode(s_axi_awaddr) == 3'd1);
    assign m2_axi_awvalid = aw_to_valid && (decode(s_axi_awaddr) == 3'd2);
    assign m3_axi_awvalid = aw_to_valid && (decode(s_axi_awaddr) == 3'd3);
    assign m4_axi_awvalid = aw_to_valid && (decode(s_axi_awaddr) == 3'd4);
    assign m5_axi_awvalid = aw_to_valid && (decode(s_axi_awaddr) == 3'd5);

    // AWREADY mux back
    always @(*) begin
        if (!aresetn) begin
            s_axi_awready = 1'b0;
        end else begin
            case (decode(s_axi_awaddr))
                3'd0: s_axi_awready = m0_axi_awready;
                3'd1: s_axi_awready = m1_axi_awready;
                3'd2: s_axi_awready = m2_axi_awready;
                3'd3: s_axi_awready = m3_axi_awready;
                3'd4: s_axi_awready = m4_axi_awready;
                3'd5: s_axi_awready = m5_axi_awready;
                default: s_axi_awready = 1'b1; // accept to produce DECERR later
            endcase
        end
    end

    // W channel must be routed to latched aw_sel
    assign m0_axi_wdata  = s_axi_wdata;
    assign m1_axi_wdata  = s_axi_wdata;
    assign m2_axi_wdata  = s_axi_wdata;
    assign m3_axi_wdata  = s_axi_wdata;
    assign m4_axi_wdata  = s_axi_wdata;
    assign m5_axi_wdata  = s_axi_wdata;

    assign m0_axi_wstrb  = s_axi_wstrb;
    assign m1_axi_wstrb  = s_axi_wstrb;
    assign m2_axi_wstrb  = s_axi_wstrb;
    assign m3_axi_wstrb  = s_axi_wstrb;
    assign m4_axi_wstrb  = s_axi_wstrb;
    assign m5_axi_wstrb  = s_axi_wstrb;

    assign m0_axi_wvalid = s_axi_wvalid && aw_captured && (aw_sel == 3'd0);
    assign m1_axi_wvalid = s_axi_wvalid && aw_captured && (aw_sel == 3'd1);
    assign m2_axi_wvalid = s_axi_wvalid && aw_captured && (aw_sel == 3'd2);
    assign m3_axi_wvalid = s_axi_wvalid && aw_captured && (aw_sel == 3'd3);
    assign m4_axi_wvalid = s_axi_wvalid && aw_captured && (aw_sel == 3'd4);
    assign m5_axi_wvalid = s_axi_wvalid && aw_captured && (aw_sel == 3'd5);

    always @(*) begin
        case (aw_sel)
            3'd0: s_axi_wready = m0_axi_wready;
            3'd1: s_axi_wready = m1_axi_wready;
            3'd2: s_axi_wready = m2_axi_wready;
            3'd3: s_axi_wready = m3_axi_wready;
            3'd4: s_axi_wready = m4_axi_wready;
            3'd5: s_axi_wready = m5_axi_wready;
            default: s_axi_wready = 1'b1; // drop write to DECERR sink
        endcase
    end

    // B channel mux
    assign m0_axi_bready = s_axi_bready && (aw_sel == 3'd0);
    assign m1_axi_bready = s_axi_bready && (aw_sel == 3'd1);
    assign m2_axi_bready = s_axi_bready && (aw_sel == 3'd2);
    assign m3_axi_bready = s_axi_bready && (aw_sel == 3'd3);
    assign m4_axi_bready = s_axi_bready && (aw_sel == 3'd4);
    assign m5_axi_bready = s_axi_bready && (aw_sel == 3'd5);

    always @(*) begin
        case (aw_sel)
            3'd0: begin s_axi_bvalid = m0_axi_bvalid; s_axi_bresp = m0_axi_bresp; end
            3'd1: begin s_axi_bvalid = m1_axi_bvalid; s_axi_bresp = m1_axi_bresp; end
            3'd2: begin s_axi_bvalid = m2_axi_bvalid; s_axi_bresp = m2_axi_bresp; end
            3'd3: begin s_axi_bvalid = m3_axi_bvalid; s_axi_bresp = m3_axi_bresp; end
            3'd4: begin s_axi_bvalid = m4_axi_bvalid; s_axi_bresp = m4_axi_bresp; end
            3'd5: begin s_axi_bvalid = m5_axi_bvalid; s_axi_bresp = m5_axi_bresp; end
            default: begin s_axi_bvalid = aw_captured; s_axi_bresp = RESP_DECERR; end
        endcase
    end

    // ---------------------- Read path ----------------------
    reg        ar_captured;
    reg  [2:0] ar_sel;

    // Accept AR when interconnect has no pending read
    wire ar_to_valid = s_axi_arvalid && !ar_captured;

    // Per-port AR routing
    assign m0_axi_araddr  = s_axi_araddr;
    assign m1_axi_araddr  = s_axi_araddr;
    assign m2_axi_araddr  = s_axi_araddr;
    assign m3_axi_araddr  = s_axi_araddr;
    assign m4_axi_araddr  = s_axi_araddr;
    assign m5_axi_araddr  = s_axi_araddr;

    assign m0_axi_arvalid = ar_to_valid && (decode(s_axi_araddr) == 3'd0);
    assign m1_axi_arvalid = ar_to_valid && (decode(s_axi_araddr) == 3'd1);
    assign m2_axi_arvalid = ar_to_valid && (decode(s_axi_araddr) == 3'd2);
    assign m3_axi_arvalid = ar_to_valid && (decode(s_axi_araddr) == 3'd3);
    assign m4_axi_arvalid = ar_to_valid && (decode(s_axi_araddr) == 3'd4);
    assign m5_axi_arvalid = ar_to_valid && (decode(s_axi_araddr) == 3'd5);

    // ARREADY mux
    always @(*) begin
        case (decode(s_axi_araddr))
            3'd0: s_axi_arready = m0_axi_arready;
            3'd1: s_axi_arready = m1_axi_arready;
            3'd2: s_axi_arready = m2_axi_arready;
            3'd3: s_axi_arready = m3_axi_arready;
            3'd4: s_axi_arready = m4_axi_arready;
            3'd5: s_axi_arready = m5_axi_arready;
            default: s_axi_arready = 1'b1; // accept to produce DECERR
        endcase
    end

    // Latch selected slave when AR handshakes; release on R handshake
    always @(posedge aclk) begin
        if (!aresetn) begin
            ar_captured <= 1'b0;
            ar_sel      <= 3'd7;
        end else begin
            if (!ar_captured && s_axi_arvalid && s_axi_arready) begin
                ar_captured <= 1'b1;
                ar_sel      <= decode(s_axi_araddr);
            end else if (s_axi_rvalid && s_axi_rready) begin
                ar_captured <= 1'b0;
            end
        end
    end

    // R channel mux
    assign m0_axi_rready = s_axi_rready && (ar_sel == 3'd0);
    assign m1_axi_rready = s_axi_rready && (ar_sel == 3'd1);
    assign m2_axi_rready = s_axi_rready && (ar_sel == 3'd2);
    assign m3_axi_rready = s_axi_rready && (ar_sel == 3'd3);
    assign m4_axi_rready = s_axi_rready && (ar_sel == 3'd4);
    assign m5_axi_rready = s_axi_rready && (ar_sel == 3'd5);

    always @(*) begin
        case (ar_sel)
            3'd0: begin s_axi_rvalid = m0_axi_rvalid; s_axi_rdata = m0_axi_rdata; s_axi_rresp = m0_axi_rresp; end
            3'd1: begin s_axi_rvalid = m1_axi_rvalid; s_axi_rdata = m1_axi_rdata; s_axi_rresp = m1_axi_rresp; end
            3'd2: begin s_axi_rvalid = m2_axi_rvalid; s_axi_rdata = m2_axi_rdata; s_axi_rresp = m2_axi_rresp; end
            3'd3: begin s_axi_rvalid = m3_axi_rvalid; s_axi_rdata = m3_axi_rdata; s_axi_rresp = m3_axi_rresp; end
            3'd4: begin s_axi_rvalid = m4_axi_rvalid; s_axi_rdata = m4_axi_rdata; s_axi_rresp = m4_axi_rresp; end
            3'd5: begin s_axi_rvalid = m5_axi_rvalid; s_axi_rdata = m5_axi_rdata; s_axi_rresp = m5_axi_rresp; end
            default: begin s_axi_rvalid = ar_captured; s_axi_rdata = {S_AXI_DATA_WIDTH{1'b0}}; s_axi_rresp = RESP_DECERR; end
        endcase
    end

endmodule

// -----------------------------------------------------------------------------
// Example instantiation (comment):
//   axi_lite_interconnect_1x6 #(
//     .SLV0_BASE(32'h4000_0000), // GPIO
//     .SLV1_BASE(32'h4000_1000), // TIMER
//     .SLV2_BASE(32'h4000_2000), // UART
//     .SLV3_BASE(32'h4000_3000), // SPI
//     .SLV4_BASE(32'h4000_4000), // I2C
//     .SLV5_BASE(32'h4000_5000)  // INTR_CTRL
//   ) u_xbar (...);
// -----------------------------------------------------------------------------
