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