`ifndef AXI_BIND_SV
`define AXI_BIND_SV

bind tb_top axi_protocol_checker #(
    .AWIDTH (32),
    .DWIDTH (64),
    .IDWIDTH(4)
) u_axi_chk (
    .aclk    (aclk),
    .aresetn (aresetn),
    .awid    (s_awid),
    .awaddr  (s_awaddr),
    .awlen   (s_awlen),
    .awsize  (s_awsize),
    .awburst (s_awburst),
    .awvalid (s_awvalid),
    .awready (s_awready),
    .wdata   (s_wdata),
    .wlast   (s_wlast),
    .wvalid  (s_wvalid),
    .wready  (s_wready),
    .bid     (s_bid),
    .bresp   (s_bresp),
    .bvalid  (s_bvalid),
    .bready  (s_bready),
    .arid    (s_arid),
    .araddr  (s_araddr),
    .arlen   (s_arlen),
    .arsize  (s_arsize),
    .arburst (s_arburst),
    .arvalid (s_arvalid),
    .arready (s_arready),
    .rid     (s_rid),
    .rresp   (s_rresp),
    .rlast   (s_rlast),
    .rvalid  (s_rvalid),
    .rready  (s_rready)
);

`endif
