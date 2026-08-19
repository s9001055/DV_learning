`ifndef AXI_PROTOCOL_CHECKER_SV
`define AXI_PROTOCOL_CHECKER_SV

module axi_protocol_checker #(
    parameter int AWIDTH  = 32,
    parameter int DWIDTH  = 64,
    parameter int IDWIDTH = 4
) (
    input logic aclk, aresetn,
    // AW
    input logic [IDWIDTH-1:0] awid, 
    input logic [AWIDTH-1:0] awaddr,
    input logic [7:0] awlen, 
    input logic [2:0] awsize, 
    input logic [1:0] awburst,
    input logic awvalid, awready,
    // W
    input logic [DWIDTH-1:0] wdata, 
    input logic wlast, wvalid, wready,
    // B
    input logic [IDWIDTH-1:0] bid, 
    input logic [1:0] bresp, 
    input logic bvalid, bready,
    // AR
    input logic [IDWIDTH-1:0] arid, 
    input logic [AWIDTH-1:0] araddr,
    input logic [7:0] arlen, 
    input logic [2:0] arsize, 
    input logic [1:0] arburst,
    input logic arvalid, arready,
    // R
    input logic [IDWIDTH-1:0] rid, 
    input logic [1:0] rresp, 
    input logic rlast, rvalid, rready
);

    // default clocking cb @(posedge aclk); endclocking
    // default disable iff (!aresetn);

    //--------------------------------------------------------------------------
    // SVA_AXI_001 : AWVALID stable until AWREADY (payload hold)
    //--------------------------------------------------------------------------
    property p_aw_valid_stable;
        @(posedge aclk) disable iff (!aresetn)
        awvalid && !awready |=> awvalid;
    endproperty
    A_AW_VALID_STABLE: assert property (p_aw_valid_stable)
        else $error("[SVA_AXI_001] AWVALID dropped before AWREADY");

    property p_aw_payload_stable;
        @(posedge aclk) disable iff (!aresetn)
        awvalid && !awready |=>
            $stable(awid) && $stable(awaddr) && $stable(awlen) &&
            $stable(awsize) && $stable(awburst);
    endproperty
    A_AW_PAYLOAD_STABLE: assert property (p_aw_payload_stable)
        else $error("[SVA_AXI_002] AW payload changed while VALID && !READY");

    // 當 arvalid == HIGH 且 !arready 時，arvalid 要 stable
    property p_ar_valid_stable;
        @(posedge aclk) disable iff (!aresetn)
        arvalid && !arready |=> arvalid;
    endproperty
    A_AR_VALID_STABLE: assert property (p_ar_valid_stable)
        else $error("[SVA_AXI_003a] ARVALID dropped before ARREADY");

    property p_w_valid_stable;
        @(posedge aclk) disable iff (!aresetn)
        wvalid && !wready |=> wvalid;
    endproperty
    A_W_VALID_STABLE: assert property (p_w_valid_stable)
        else $error("[SVA_AXI_003b] WVALID dropped before WREADY");

    property p_r_valid_stable;
        @(posedge aclk) disable iff (!aresetn)
        rvalid && !rready |=> rvalid;
    endproperty
    A_W_VALID_STABLE: assert property (p_r_valid_stable)
        else $error("[SVA_AXI_003c] RVALID dropped before RREADY");

    //--------------------------------------------------------------------------
    // SVA_AXI_004 : Reset 時 all 所有 valid 必須為 0
    //--------------------------------------------------------------------------
    A_RESET_LOW_AWVALID: assert property (@(posedge aclk) !aresetn |-> !awvalid)
        else $error("[SVA_AXI_004a] AWVALID asserted during reset");
    A_RESET_LOW_WVALID : assert property (@(posedge aclk) !aresetn |-> !wvalid)
        else $error("[SVA_AXI_004b] WVALID asserted during reset");
    A_RESET_LOW_BVALID : assert property (@(posedge aclk) !aresetn |-> !bvalid)
        else $error("[SVA_AXI_004c] BVALID asserted during reset");
    A_RESET_LOW_ARVALID: assert property (@(posedge aclk) !aresetn |-> !arvalid)
        else $error("[SVA_AXI_004d] ARVALID asserted during reset");
    A_RESET_LOW_RVALID : assert property (@(posedge aclk) !aresetn |-> !rvalid)
        else $error("[SVA_AXI_004e] RVALID asserted during reset");

    //--------------------------------------------------------------------------
    // SVA_AXI_005 : WRAP burst length {2,4,8,16} 對應 awlen ∈ {1,3,7,15}
    //--------------------------------------------------------------------------
    property p_wrap_len(valid, len, burst);
        @(posedge aclk) disable iff (!aresetn)
        (valid && burst == 2'b10) |-> len inside {8'd1, 8'd3, 8'd7, 8'd15};
    endproperty
    A_AW_WRAP_LEN: assert property (p_wrap_len(awvalid, awlen, awburst))
        else $error("[SVA_AXI_005a] AW WRAP length illegal: %0d", awlen);
    A_AR_WRAP_LEN: assert property (p_wrap_len(arvalid, arlen, arburst))
        else $error("[SVA_AXI_005b] AR WRAP length illegal: %0d", arlen);

    //--------------------------------------------------------------------------
    // SVA_AXI_006 : WRAP address alignment
    //--------------------------------------------------------------------------
    property p_wrap_align(valid, addr, size, burst);
        @(posedge aclk) disable iff (!aresetn)
        (burst == 2'b10 && valid == 1'b1) |-> ((addr & ((1 << size) - 1)) == 0);
    endproperty
    A_AW_WRAP_ALIGN: assert property (p_wrap_align(awvalid, awaddr, awsize, awburst))
        else $error("[SVA_AXI_006a] AW WRAP addr not aligned");
    A_AR_WRAP_ALIGN: assert property (p_wrap_align(arvalid, araddr, arsize, arburst))
        else $error("[SVA_AXI_006b] AR WRAP addr not aligned");

    //--------------------------------------------------------------------------
    // SVA_AXI_007 : INCR burst must not cross 4KB boundary
    //--------------------------------------------------------------------------
    property p_4kb_boundary(valid, addr, len, size, burst);
        @(posedge aclk) disable iff (!aresetn)
        (burst == 2'b01 && valid == 1'b1) |->
            ((14'h0 + addr[11:0] + ((len + 1) << size)) <= 14'h1000);  // 取 addr 後 12 bits 跟 len 和 size 做計算, 必須小於 4KB; 14'h0 避免加法 overflow
    endproperty
    A_AW_4KB: assert property (p_4kb_boundary(awvalid, awaddr, awlen, awsize, awburst))
        else $error("[SVA_AXI_007a] AW INCR burst crosses 4KB boundary");
    A_AR_4KB: assert property (p_4kb_boundary(arvalid, araddr, arlen, arsize, arburst))
        else $error("[SVA_AXI_007b] AR INCR burst crosses 4KB boundary");

endmodule : axi_protocol_checker

`endif
