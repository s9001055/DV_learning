`timescale 1ns/1ps
`include "uvm_macros.svh"

import uvm_pkg::*;
`include "my_driver.sv"

module top_tb;
    reg clk;
    reg rst_n;
    reg[7:0] rxd;
    reg rx_dv;
    wire[7:0] txd;
    wire tx_en;

    my_if input_if(clk, rst_n);
    my_if output_if(clk, rst_n);

dut my_dut( .clk(clk),
            .rst_n(rst_n),
            .rxd(input_if.data),
            .rx_dv(input_if.valid),
            .txd(output_if.data),
            .tx_en(output_if.valid));

initial begin
    run_test("my_env");
end

initial begin
    // 由於 run_test("my_env"); 是由 my_env 開始建立，所以路徑變為 uvm_test_top.drv
    // my_env 成為 uvm_test_top
    // uvm_test_top是UVM自動創建的樹根的名字
    // 而drv則是在my_env的build_phase中產生實體drv時傳遞過去的名字
    uvm_config_db#(virtual my_if)::set(null, "uvm_test_top.drv", "vif", input_if);  
    uvm_config_db#(virtual my_if)::set(null, "uvm_test_top.i_mon", "vif", input_if);
    uvm_config_db#(virtual my_if)::set(null, "uvm_test_top.o_mon", "vif2", output_if);
end

initial begin
    clk = 0;
    forever begin
        #100 clk = ~clk;
    end
end

initial begin
    rst_n = 1'b0;
    #1000;
    rst_n = 1'b1;
end

endmodule