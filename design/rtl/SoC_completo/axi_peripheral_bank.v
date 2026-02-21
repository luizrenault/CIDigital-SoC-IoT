// -----------------------------------------------------------------------------
// axi_lite_slaves_6regs.v
//
// 6x AXI4-Lite Slave register banks to connect to axi_lite_interconnect_1x6.
// Each port exposes a simple register file (word addressed) for TB read/write.
// - 1 outstanding write and 1 outstanding read per port
// - WSTRB supported
// - Registers addressed by addr[11:2] (4KB window -> 1024 words max)
// -----------------------------------------------------------------------------

module axi_lite_slaves_6regs #(
    parameter integer ADDR_WIDTH = 32,
    parameter integer DATA_WIDTH = 32,

    // How many 32-bit registers to actually implement per port (starting at 0x00).
    // Accesses beyond this count return 0 on reads and still OKAY on writes (by default).
    parameter integer REG_COUNT_PER_PORT = 64  // 64 regs => 256 bytes implemented (still inside 4KB window)
)(
    input  wire                   aclk,
    input  wire                   aresetn,

    // ---------------- Port 0 AXI-Lite Slave ----------------
    input  wire [ADDR_WIDTH-1:0]  s0_axi_awaddr,
    input  wire                   s0_axi_awvalid,
    output wire                   s0_axi_awready,
    input  wire [DATA_WIDTH-1:0]  s0_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s0_axi_wstrb,
    input  wire                   s0_axi_wvalid,
    output wire                   s0_axi_wready,
    output wire [1:0]             s0_axi_bresp,
    output wire                   s0_axi_bvalid,
    input  wire                   s0_axi_bready,
    input  wire [ADDR_WIDTH-1:0]  s0_axi_araddr,
    input  wire                   s0_axi_arvalid,
    output wire                   s0_axi_arready,
    output wire [DATA_WIDTH-1:0]  s0_axi_rdata,
    output wire [1:0]             s0_axi_rresp,
    output wire                   s0_axi_rvalid,
    input  wire                   s0_axi_rready,

    // ---------------- Port 1 AXI-Lite Slave ----------------
    input  wire [ADDR_WIDTH-1:0]  s1_axi_awaddr,
    input  wire                   s1_axi_awvalid,
    output wire                   s1_axi_awready,
    input  wire [DATA_WIDTH-1:0]  s1_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s1_axi_wstrb,
    input  wire                   s1_axi_wvalid,
    output wire                   s1_axi_wready,
    output wire [1:0]             s1_axi_bresp,
    output wire                   s1_axi_bvalid,
    input  wire                   s1_axi_bready,
    input  wire [ADDR_WIDTH-1:0]  s1_axi_araddr,
    input  wire                   s1_axi_arvalid,
    output wire                   s1_axi_arready,
    output wire [DATA_WIDTH-1:0]  s1_axi_rdata,
    output wire [1:0]             s1_axi_rresp,
    output wire                   s1_axi_rvalid,
    input  wire                   s1_axi_rready,

    // ---------------- Port 2 AXI-Lite Slave ----------------
    input  wire [ADDR_WIDTH-1:0]  s2_axi_awaddr,
    input  wire                   s2_axi_awvalid,
    output wire                   s2_axi_awready,
    input  wire [DATA_WIDTH-1:0]  s2_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s2_axi_wstrb,
    input  wire                   s2_axi_wvalid,
    output wire                   s2_axi_wready,
    output wire [1:0]             s2_axi_bresp,
    output wire                   s2_axi_bvalid,
    input  wire                   s2_axi_bready,
    input  wire [ADDR_WIDTH-1:0]  s2_axi_araddr,
    input  wire                   s2_axi_arvalid,
    output wire                   s2_axi_arready,
    output wire [DATA_WIDTH-1:0]  s2_axi_rdata,
    output wire [1:0]             s2_axi_rresp,
    output wire                   s2_axi_rvalid,
    input  wire                   s2_axi_rready,

    // ---------------- Port 3 AXI-Lite Slave ----------------
    input  wire [ADDR_WIDTH-1:0]  s3_axi_awaddr,
    input  wire                   s3_axi_awvalid,
    output wire                   s3_axi_awready,
    input  wire [DATA_WIDTH-1:0]  s3_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s3_axi_wstrb,
    input  wire                   s3_axi_wvalid,
    output wire                   s3_axi_wready,
    output wire [1:0]             s3_axi_bresp,
    output wire                   s3_axi_bvalid,
    input  wire                   s3_axi_bready,
    input  wire [ADDR_WIDTH-1:0]  s3_axi_araddr,
    input  wire                   s3_axi_arvalid,
    output wire                   s3_axi_arready,
    output wire [DATA_WIDTH-1:0]  s3_axi_rdata,
    output wire [1:0]             s3_axi_rresp,
    output wire                   s3_axi_rvalid,
    input  wire                   s3_axi_rready,

    // ---------------- Port 4 AXI-Lite Slave ----------------
    input  wire [ADDR_WIDTH-1:0]  s4_axi_awaddr,
    input  wire                   s4_axi_awvalid,
    output wire                   s4_axi_awready,
    input  wire [DATA_WIDTH-1:0]  s4_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s4_axi_wstrb,
    input  wire                   s4_axi_wvalid,
    output wire                   s4_axi_wready,
    output wire [1:0]             s4_axi_bresp,
    output wire                   s4_axi_bvalid,
    input  wire                   s4_axi_bready,
    input  wire [ADDR_WIDTH-1:0]  s4_axi_araddr,
    input  wire                   s4_axi_arvalid,
    output wire                   s4_axi_arready,
    output wire [DATA_WIDTH-1:0]  s4_axi_rdata,
    output wire [1:0]             s4_axi_rresp,
    output wire                   s4_axi_rvalid,
    input  wire                   s4_axi_rready,

    // ---------------- Port 5 AXI-Lite Slave ----------------
    input  wire [ADDR_WIDTH-1:0]  s5_axi_awaddr,
    input  wire                   s5_axi_awvalid,
    output wire                   s5_axi_awready,
    input  wire [DATA_WIDTH-1:0]  s5_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s5_axi_wstrb,
    input  wire                   s5_axi_wvalid,
    output wire                   s5_axi_wready,
    output wire [1:0]             s5_axi_bresp,
    output wire                   s5_axi_bvalid,
    input  wire                   s5_axi_bready,
    input  wire [ADDR_WIDTH-1:0]  s5_axi_araddr,
    input  wire                   s5_axi_arvalid,
    output wire                   s5_axi_arready,
    output wire [DATA_WIDTH-1:0]  s5_axi_rdata,
    output wire [1:0]             s5_axi_rresp,
    output wire                   s5_axi_rvalid,
    input  wire                   s5_axi_rready
);

    axi_lite_regs_slave #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .REG_COUNT(REG_COUNT_PER_PORT)) u_slv0 (
        .aclk(aclk), .aresetn(aresetn),
        .s_axi_awaddr(s0_axi_awaddr), .s_axi_awvalid(s0_axi_awvalid), .s_axi_awready(s0_axi_awready),
        .s_axi_wdata(s0_axi_wdata), .s_axi_wstrb(s0_axi_wstrb), .s_axi_wvalid(s0_axi_wvalid), .s_axi_wready(s0_axi_wready),
        .s_axi_bresp(s0_axi_bresp), .s_axi_bvalid(s0_axi_bvalid), .s_axi_bready(s0_axi_bready),
        .s_axi_araddr(s0_axi_araddr), .s_axi_arvalid(s0_axi_arvalid), .s_axi_arready(s0_axi_arready),
        .s_axi_rdata(s0_axi_rdata), .s_axi_rresp(s0_axi_rresp), .s_axi_rvalid(s0_axi_rvalid), .s_axi_rready(s0_axi_rready)
    );

    axi_lite_regs_slave #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .REG_COUNT(REG_COUNT_PER_PORT)) u_slv1 (
        .aclk(aclk), .aresetn(aresetn),
        .s_axi_awaddr(s1_axi_awaddr), .s_axi_awvalid(s1_axi_awvalid), .s_axi_awready(s1_axi_awready),
        .s_axi_wdata(s1_axi_wdata), .s_axi_wstrb(s1_axi_wstrb), .s_axi_wvalid(s1_axi_wvalid), .s_axi_wready(s1_axi_wready),
        .s_axi_bresp(s1_axi_bresp), .s_axi_bvalid(s1_axi_bvalid), .s_axi_bready(s1_axi_bready),
        .s_axi_araddr(s1_axi_araddr), .s_axi_arvalid(s1_axi_arvalid), .s_axi_arready(s1_axi_arready),
        .s_axi_rdata(s1_axi_rdata), .s_axi_rresp(s1_axi_rresp), .s_axi_rvalid(s1_axi_rvalid), .s_axi_rready(s1_axi_rready)
    );

    axi_lite_regs_slave #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .REG_COUNT(REG_COUNT_PER_PORT)) u_slv2 (
        .aclk(aclk), .aresetn(aresetn),
        .s_axi_awaddr(s2_axi_awaddr), .s_axi_awvalid(s2_axi_awvalid), .s_axi_awready(s2_axi_awready),
        .s_axi_wdata(s2_axi_wdata), .s_axi_wstrb(s2_axi_wstrb), .s_axi_wvalid(s2_axi_wvalid), .s_axi_wready(s2_axi_wready),
        .s_axi_bresp(s2_axi_bresp), .s_axi_bvalid(s2_axi_bvalid), .s_axi_bready(s2_axi_bready),
        .s_axi_araddr(s2_axi_araddr), .s_axi_arvalid(s2_axi_arvalid), .s_axi_arready(s2_axi_arready),
        .s_axi_rdata(s2_axi_rdata), .s_axi_rresp(s2_axi_rresp), .s_axi_rvalid(s2_axi_rvalid), .s_axi_rready(s2_axi_rready)
    );

    axi_lite_regs_slave #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .REG_COUNT(REG_COUNT_PER_PORT)) u_slv3 (
        .aclk(aclk), .aresetn(aresetn),
        .s_axi_awaddr(s3_axi_awaddr), .s_axi_awvalid(s3_axi_awvalid), .s_axi_awready(s3_axi_awready),
        .s_axi_wdata(s3_axi_wdata), .s_axi_wstrb(s3_axi_wstrb), .s_axi_wvalid(s3_axi_wvalid), .s_axi_wready(s3_axi_wready),
        .s_axi_bresp(s3_axi_bresp), .s_axi_bvalid(s3_axi_bvalid), .s_axi_bready(s3_axi_bready),
        .s_axi_araddr(s3_axi_araddr), .s_axi_arvalid(s3_axi_arvalid), .s_axi_arready(s3_axi_arready),
        .s_axi_rdata(s3_axi_rdata), .s_axi_rresp(s3_axi_rresp), .s_axi_rvalid(s3_axi_rvalid), .s_axi_rready(s3_axi_rready)
    );

    axi_lite_regs_slave #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .REG_COUNT(REG_COUNT_PER_PORT)) u_slv4 (
        .aclk(aclk), .aresetn(aresetn),
        .s_axi_awaddr(s4_axi_awaddr), .s_axi_awvalid(s4_axi_awvalid), .s_axi_awready(s4_axi_awready),
        .s_axi_wdata(s4_axi_wdata), .s_axi_wstrb(s4_axi_wstrb), .s_axi_wvalid(s4_axi_wvalid), .s_axi_wready(s4_axi_wready),
        .s_axi_bresp(s4_axi_bresp), .s_axi_bvalid(s4_axi_bvalid), .s_axi_bready(s4_axi_bready),
        .s_axi_araddr(s4_axi_araddr), .s_axi_arvalid(s4_axi_arvalid), .s_axi_arready(s4_axi_arready),
        .s_axi_rdata(s4_axi_rdata), .s_axi_rresp(s4_axi_rresp), .s_axi_rvalid(s4_axi_rvalid), .s_axi_rready(s4_axi_rready)
    );

    axi_lite_regs_slave #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .REG_COUNT(REG_COUNT_PER_PORT)) u_slv5 (
        .aclk(aclk), .aresetn(aresetn),
        .s_axi_awaddr(s5_axi_awaddr), .s_axi_awvalid(s5_axi_awvalid), .s_axi_awready(s5_axi_awready),
        .s_axi_wdata(s5_axi_wdata), .s_axi_wstrb(s5_axi_wstrb), .s_axi_wvalid(s5_axi_wvalid), .s_axi_wready(s5_axi_wready),
        .s_axi_bresp(s5_axi_bresp), .s_axi_bvalid(s5_axi_bvalid), .s_axi_bready(s5_axi_bready),
        .s_axi_araddr(s5_axi_araddr), .s_axi_arvalid(s5_axi_arvalid), .s_axi_arready(s5_axi_arready),
        .s_axi_rdata(s5_axi_rdata), .s_axi_rresp(s5_axi_rresp), .s_axi_rvalid(s5_axi_rvalid), .s_axi_rready(s5_axi_rready)
    );

endmodule


// -----------------------------------------------------------------------------
// Simple AXI4-Lite register slave
// - Accepts 1 outstanding write and 1 outstanding read
// - Word addressing: index = addr[11:2] (inside 4KB window)
// -----------------------------------------------------------------------------
module axi_lite_regs_slave #(
    parameter integer ADDR_WIDTH = 32,
    parameter integer DATA_WIDTH = 32,
    parameter integer REG_COUNT  = 64
)(
    input  wire                   aclk,
    input  wire                   aresetn,

    // AXI-Lite Slave Interface
    input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire                   s_axi_awvalid,
    output reg                    s_axi_awready,

    input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire [(DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                   s_axi_wvalid,
    output reg                    s_axi_wready,

    output reg  [1:0]             s_axi_bresp,
    output reg                    s_axi_bvalid,
    input  wire                   s_axi_bready,

    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire                   s_axi_arvalid,
    output reg                    s_axi_arready,

    output reg  [DATA_WIDTH-1:0]  s_axi_rdata,
    output reg  [1:0]             s_axi_rresp,
    output reg                    s_axi_rvalid,
    input  wire                   s_axi_rready
);

    localparam [1:0] RESP_OKAY = 2'b00;

    // Register file
    reg [DATA_WIDTH-1:0] regs [0:REG_COUNT-1];

    integer i;
    always @(posedge aclk) begin
        if (!aresetn) begin
            for (i = 0; i < REG_COUNT; i = i + 1)
                regs[i] <= {DATA_WIDTH{1'b0}};
        end
    end

    // ---------------- Write handling ----------------
    reg                  w_pending;
    reg [ADDR_WIDTH-1:0] awaddr_hold;

    wire aw_hs = s_axi_awvalid && s_axi_awready;
    wire w_hs  = s_axi_wvalid  && s_axi_wready;
    wire b_hs  = s_axi_bvalid  && s_axi_bready;

    // Ready logic: accept AW only when not pending; accept W only when pending
    always @(*) begin
        if (!aresetn) begin
            s_axi_awready = 1'b0;
            s_axi_wready  = 1'b0;
        end else begin
            s_axi_awready = !w_pending;   // grab address first
            s_axi_wready  =  w_pending;   // then accept data
        end
    end

    // Capture address
    always @(posedge aclk) begin
        if (!aresetn) begin
            w_pending   <= 1'b0;
            awaddr_hold <= {ADDR_WIDTH{1'b0}};
        end else begin
            if (aw_hs) begin
                w_pending   <= 1'b1;
                awaddr_hold <= s_axi_awaddr;
            end

            // When W accepted, perform write and issue B
            if (w_hs) begin
                w_pending <= 1'b0;
            end

            if (b_hs) begin
                // B handshake completes response
            end
        end
    end

    // Write into regs on W handshake (using stored awaddr_hold)
    wire [9:0] w_word_index = awaddr_hold[11:2]; // 4KB window -> 1024 words
    integer b;
    always @(posedge aclk) begin
        if (!aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp  <= RESP_OKAY;
        end else begin
            if (w_hs) begin
                if (w_word_index < REG_COUNT) begin
                    // Apply WSTRB per byte
                    for (b = 0; b < (DATA_WIDTH/8); b = b + 1) begin
                        if (s_axi_wstrb[b]) begin
                            regs[w_word_index][8*b +: 8] <= s_axi_wdata[8*b +: 8];
                        end
                    end
                end
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= RESP_OKAY;
            end else if (b_hs) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // ---------------- Read handling ----------------
    reg                  r_pending;
    reg [ADDR_WIDTH-1:0] araddr_hold;

    wire ar_hs = s_axi_arvalid && s_axi_arready;
    wire r_hs  = s_axi_rvalid  && s_axi_rready;

    always @(*) begin
        if (!aresetn) begin
            s_axi_arready = 1'b0;
        end else begin
            s_axi_arready = !r_pending;  // 1 outstanding read
        end
    end

    always @(posedge aclk) begin
        if (!aresetn) begin
            r_pending <= 1'b0;
            araddr_hold <= {ADDR_WIDTH{1'b0}};
            s_axi_rvalid <= 1'b0;
            s_axi_rresp  <= RESP_OKAY;
            s_axi_rdata  <= {DATA_WIDTH{1'b0}};
        end else begin
            if (ar_hs) begin
                r_pending   <= 1'b1;
                araddr_hold <= s_axi_araddr;

                // Respond immediately (registered)
                begin : READ_RESP
                    reg [9:0] r_word_index;
                    r_word_index = s_axi_araddr[11:2];

                    if (r_word_index < REG_COUNT)
                        s_axi_rdata <= regs[r_word_index];
                    else
                        s_axi_rdata <= {DATA_WIDTH{1'b0}};

                    s_axi_rresp  <= RESP_OKAY;
                    s_axi_rvalid <= 1'b1;
                end
            end else if (r_hs) begin
                s_axi_rvalid <= 1'b0;
                r_pending    <= 1'b0;
            end
        end
    end

endmodule
