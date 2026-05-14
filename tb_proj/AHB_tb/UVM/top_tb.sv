import uvm_pkg::*;
`include "uvm_macros.svh"

`include "ahb_defines.svh"

module top_tb;
  	bit clk;
  	logic rst_n;
  	always #5 clk = ~clk;

    // 實例化 Interface
    ahb_if ahb_if(
      .HCLK		(clk),
      .HRESETn	(rst_n)
    );

    // 實例化 DUT 並連接 Interface
    ahb_dut #(.ADDR_WIDTH(`AHB_ADDR_WIDTH), .DATA_WIDTH(`AHB_DATA_WIDTH)) dut (
      .HCLK		        (clk),
      .HRESETn	        (rst_n),
      .HSEL             (ahb_if.HSEL),
      .HADDR            (ahb_if.HADDR),
      .HWRITE           (ahb_if.HWRITE),
      .HSIZE            (ahb_if.HSIZE),
      .HBURST           (ahb_if.HBURST),
      .HTRANS           (ahb_if.HTRANS),
      .HWDATA           (ahb_if.HWDATA),
      .HRDATA           (ahb_if.HRDATA),
      .HREADYOUT        (ahb_if.HREADYOUT),
      .HRESP            (ahb_if.HRESP)
    );

    // -------------------------------------------------------------------------
    // 將 Interface 傳入 UVM Config DB
    // -------------------------------------------------------------------------
    initial begin
        uvm_config_db #(virtual ahb_if)::set(
            null, "uvm_test_top.env.agent.driver",  "vif", ahb_if);
        uvm_config_db #(virtual ahb_if)::set(
            null, "uvm_test_top.env.agent.monitor", "vif", ahb_if);

        // 啟動 UVM（透過 +UVM_TESTNAME 指定 test class）
        // run_test() 內部會自己去讀 +UVM_TESTNAME
        run_test();
    end

    initial begin
        rst_n = 1'b0;
        #5;
        rst_n = 1'b1;
    end

    // -------------------------------------------------------------------------
    // Optional: waveform dump
    // -------------------------------------------------------------------------
    initial begin
        $shm_open("top_tb.shm");
        $shm_probe(top_tb,"AS");
    end
endmodule