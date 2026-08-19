//==============================================================================
// File   : tb_top.sv
//==============================================================================
`timescale 1ns/1ps

module tb_top;

    import uvm_pkg::*;
    import axi_pkg::*;
    import tests_pkg::*;
    `include "uvm_macros.svh"

    // Clock / reset
    logic aclk;
    logic aresetn;

    initial aclk = 0;
    always #5 aclk = ~aclk;   // 100 MHz

    initial begin
        aresetn = 0;
        #100;
        aresetn = 1;
    end

    // Interface
    axi_if #(.AWIDTH(32), .DWIDTH(64), .IDWIDTH(4)) axi_bus(aclk, aresetn);

    // SVA module
    axi_protocol_checker #(
        .AWIDTH (32),
        .DWIDTH (64),
        .IDWIDTH(4)
    ) u_axi_chk (
        .aclk    (aclk),
        .aresetn (aresetn),
        // AW
        .awid    (axi_bus.awid),
        .awaddr  (axi_bus.awaddr),
        .awlen   (axi_bus.awlen),
        .awsize  (axi_bus.awsize),
        .awburst (axi_bus.awburst),
        .awvalid (axi_bus.awvalid),
        .awready (axi_bus.awready),
        // W
        .wdata   (axi_bus.wdata),
        .wlast   (axi_bus.wlast),
        .wvalid  (axi_bus.wvalid),
        .wready  (axi_bus.wready),
        // B
        .bid     (axi_bus.bid),
        .bresp   (axi_bus.bresp),
        .bvalid  (axi_bus.bvalid),
        .bready  (axi_bus.bready),
        // AR
        .arid    (axi_bus.arid),
        .araddr  (axi_bus.araddr),
        .arlen   (axi_bus.arlen),
        .arsize  (axi_bus.arsize),
        .arburst (axi_bus.arburst),
        .arvalid (axi_bus.arvalid),
        .arready (axi_bus.arready),
        // R
        .rid     (axi_bus.rid),
        .rresp   (axi_bus.rresp),
        .rlast   (axi_bus.rlast),
        .rvalid  (axi_bus.rvalid),
        .rready  (axi_bus.rready)
    );


    // self-loop 驗 VIP 
    initial begin
        uvm_config_db#(virtual axi_if)::set(null, "*", "vif", axi_bus);
        run_test();
    end

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_top);
    end

endmodule