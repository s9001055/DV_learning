`ifndef AXI_IF_SV
`define AXI_IF_SV

interface axi_if #(
    parameter int AWIDTH  = 32,
    parameter int DWIDTH  = 64,
    parameter int IDWIDTH = 4
) (
    input logic aclk,
    input logic aresetn
);

    localparam int STRB_W = DWIDTH / 8;

    // -------- Write Address Channel --------
    logic [IDWIDTH-1:0] awid;
    logic [AWIDTH-1:0]  awaddr;
    logic [7:0]         awlen;
    logic [2:0]         awsize;
    logic [1:0]         awburst;
    logic               awlock;
    logic [3:0]         awcache;
    logic [2:0]         awprot;
    logic               awvalid;
    logic               awready;

    // -------- Write Data Channel --------
    logic [DWIDTH-1:0]  wdata;
    logic [STRB_W-1:0]  wstrb;
    logic               wlast;
    logic               wvalid;
    logic               wready;

    // -------- Write Response Channel --------
    logic [IDWIDTH-1:0] bid;
    logic [1:0]         bresp;
    logic               bvalid;
    logic               bready;

    // -------- Read Address Channel --------
    logic [IDWIDTH-1:0] arid;
    logic [AWIDTH-1:0]  araddr;
    logic [7:0]         arlen;
    logic [2:0]         arsize;
    logic [1:0]         arburst;
    logic               arlock;
    logic [3:0]         arcache;
    logic [2:0]         arprot;
    logic               arvalid;
    logic               arready;

    // -------- Read Data Channel --------
    logic [IDWIDTH-1:0] rid;
    logic [DWIDTH-1:0]  rdata;
    logic [1:0]         rresp;
    logic               rlast;
    logic               rvalid;
    logic               rready;

    // ---- Master driver clocking ----
    // Drive on posedge, output skew = 1 to avoid race with monitor sampling.
    clocking mst_drv_cb @(posedge aclk);
        default input #1step output #1;
        output awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awvalid;
        output wdata, wstrb, wlast, wvalid;
        output bready;
        output arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arvalid;
        output rready;
        input  awready, wready, bvalid, bid, bresp, arready;
        input  rvalid, rid, rdata, rresp, rlast;
    endclocking

    // ---- Slave driver clocking ----
    clocking slv_drv_cb @(posedge aclk);
        default input #1step output #1;
        output awready, wready;
        output bvalid, bid, bresp;
        output arready;
        output rvalid, rid, rdata, rresp, rlast;
        input  awvalid, awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot;
        input  wvalid, wdata, wstrb, wlast;
        input  bready;
        input  arvalid, arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot;
        input  rready;
    endclocking

    // ---- Monitor clocking (all inputs, sampling before drivers change) ----
    clocking mon_cb @(posedge aclk);
        default input #1step;
        input awid, awaddr, awlen, awsize, awburst, awlock, awcache, awprot, awvalid, awready;
        input wdata, wstrb, wlast, wvalid, wready;
        input bid, bresp, bvalid, bready;
        input arid, araddr, arlen, arsize, arburst, arlock, arcache, arprot, arvalid, arready;
        input rid, rdata, rresp, rlast, rvalid, rready;
    endclocking

    modport MST (clocking mst_drv_cb, input aclk, aresetn);
    modport SLV (clocking slv_drv_cb, input aclk, aresetn);
    modport MON (clocking mon_cb,     input aclk, aresetn);

endinterface : axi_if

`endif
