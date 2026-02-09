module intc_axilite #(
    parameter  is = 8,
    parameter  C_AXI_DATA_WIDTH	= 32,// Width of the AXI R&W data
	parameter  C_AXI_ADDR_WIDTH	= 28,	// AXI Address width
	parameter  LGFIFO = 4,
`ifdef	FORMAL
	parameter  F_MAXSTALL = 3,
	parameter  F_MAXDELAY = 3,
`endif
	parameter  [0:0] OPT_READONLY  = 1'b0,
	parameter  [0:0] OPT_WRITEONLY = 1'b0,
	localparam AXILLSB = $clog2(C_AXI_DATA_WIDTH/8)
)(
    input wire [is:1] irq, // Interrupt Sources
// {{{
	input	wire			i_clk,	// System clock
	input	wire			i_axi_reset_n,

	// AXI write address channel signals
	// {{{
	input	wire			i_axi_awvalid,
	output	wire			o_axi_awready,
	input	wire	[C_AXI_ADDR_WIDTH-1:0]	i_axi_awaddr,
	input	wire	[2:0]		i_axi_awprot,
	// }}}
	// AXI write data channel signals
	// {{{
	input	wire				i_axi_wvalid,
	output	wire				o_axi_wready,
	input	wire	[C_AXI_DATA_WIDTH-1:0]	i_axi_wdata,
	input	wire	[C_AXI_DATA_WIDTH/8-1:0] i_axi_wstrb,
	// }}}
	// AXI write response channel signals
	// {{{
	output	wire 			o_axi_bvalid,
	input	wire			i_axi_bready,
	output	wire [1:0]		o_axi_bresp,
	// }}}
	// AXI read address channel signals
	// {{{
	input	wire			i_axi_arvalid,
	output	wire			o_axi_arready,
	input	wire	[C_AXI_ADDR_WIDTH-1:0]	i_axi_araddr,
	input	wire	[2:0]		i_axi_arprot,
	// }}}
	// AXI read data channel signals
	// {{{
	output	wire			o_axi_rvalid,
	input	wire			i_axi_rready,
	output	wire [C_AXI_DATA_WIDTH-1:0] o_axi_rdata,
	output	wire [1:0]		o_axi_rresp
	// }}}
);

// Wishbone signals
// {{{
// We'll share the clock and the reset
wire			o_reset;
wire			o_wb_cyc;
wire			o_wb_stb;
wire			o_wb_we;
wire [C_AXI_ADDR_WIDTH-AXILLSB-1:0]	o_wb_addr;
wire [C_AXI_DATA_WIDTH-1:0]		o_wb_data;
wire [C_AXI_DATA_WIDTH/8-1:0]		o_wb_sel;
wire			i_wb_stall;
wire			i_wb_ack;
wire [(C_AXI_DATA_WIDTH-1):0]		i_wb_data;
wire			i_wb_err;
wire int_o;
// }}}
// }}}

axlite2wbsp #(
	.C_AXI_DATA_WIDTH(C_AXI_DATA_WIDTH),
	.C_AXI_ADDR_WIDTH(C_AXI_ADDR_WIDTH),
	.LGFIFO(LGFIFO),
`ifdef	FORMAL
	.F_MAXSTALL(F_MAXSTALL),
	.F_MAXDELAY(F_MAXDELAY),
`endif
	.OPT_READONLY(OPT_READONLY),
	.OPT_WRITEONLY(OPT_WRITEONLY),
	.AXILLSB(AXILLSB)
) axil2wb_inst (
	.i_clk(i_clk),
	.i_axi_reset_n(i_axi_reset_n),
	.i_axi_awvalid(i_axi_awvalid),
	.o_axi_awready(o_axi_awready),
	.i_axi_awaddr(i_axi_awaddr),
	.i_axi_awprot(i_axi_awprot),
	.i_axi_wvalid(i_axi_wvalid),
	.o_axi_wready(o_axi_wready),
	.i_axi_wdata(i_axi_wdata),
	.i_axi_wstrb(i_axi_wstrb),
	.i_axi_bready(i_axi_bready),
	.o_axi_bvalid(o_axi_bvalid),
	.o_axi_bresp(o_axi_bresp),
	.i_axi_arvalid(i_axi_arvalid),
	.o_axi_arready(o_axi_arready),
	.i_axi_araddr(i_axi_araddr),
	.i_axi_arprot(i_axi_arprot),
	.i_axi_rready(i_axi_rready),
	.o_axi_rvalid(o_axi_rvalid),
	.o_axi_rresp(o_axi_rresp),
	.o_axi_rdata(o_axi_rdata),
	.o_reset(),
	.o_wb_cyc(o_wb_cyc),
	.o_wb_stb(o_wb_stb),
	.o_wb_we(o_wb_we),
	.o_wb_addr(o_wb_addr),
	.o_wb_data(o_wb_data),
	.o_wb_sel(o_wb_sel),
	.i_wb_stall(i_wb_stall),
	.i_wb_ack(i_wb_ack),
	.i_wb_data(i_wb_data),
	.i_wb_err(i_wb_err)
);

simple_pic #(
    .is(is)
) spic_inst (
	.clk_i(i_clk),
	.rst_i(i_axi_reset_n),
	.cyc_i(o_wb_cyc),
	.stb_i(o_wb_stb),
	.adr_i(o_wb_addr),
	.we_i(o_wb_we),
	.dat_i(o_wb_data),
	.dat_o(i_wb_data),
	.ack_o(i_wb_ack),
	.int_o(int_o),
	.irq(irq)
);

endmodule
