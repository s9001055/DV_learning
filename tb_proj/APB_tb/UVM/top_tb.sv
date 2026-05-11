import uvm_pkg::*;
`include "uvm_macros.svh"

`include "apb_defines.svh"

// `include "apb_item.sv"
// `include "interface.sv"
// `include "apb_driver.sv"
// `include "apb_monitor.sv"
// `include "apb_scoreboard.sv"
// // `include "apb_coverage.sv"
// `include "apb_agent.sv"
// `include "apb_env.sv"
// `include "apb_sequence.sv"
// `include "base_test.sv"


module top_tb;
  	bit clk;
  	logic rst_n;
  	always #5 clk = ~clk;

    // 實例化 Interface
    apb_if apb_if(
      .PCLK		(clk),
      .PRESETn	(rst_n)
    );

    // 實例化 DUT 並連接 Interface
    apb_memory_slave #(.ADDR_WIDTH(`APB_ADDR_WIDTH), .DATA_WIDTH(`APB_DATA_WIDTH), .WAIT_CYCLES(`APB_WAIT_CYCLES)) dut (
      .PCLK		      (clk),
      .PRESETn	    (rst_n),
      .PADDR		    (apb_if.PADDR),
      .PSEL		      (apb_if.PSEL),
      .PENABLE	  	(apb_if.PENABLE),
      .PWRITE	      (apb_if.PWRITE),
      .PWDATA	      (apb_if.PWDATA),
      .PSTRB        (apb_if.PSTRB),
      .PRDATA       (apb_if.PRDATA),
      .PREADY       (apb_if.PREADY),
      .PSLVERR      (apb_if.PSLVERR)
    );


    // -------------------------------------------------------------------------
    // 將 Interface 傳入 UVM Config DB
    // -------------------------------------------------------------------------
    initial begin
        uvm_config_db #(virtual apb_if.master_mp)::set(
            null, "uvm_test_top.env.agent.driver",  "vif", apb_if.master_mp);
        uvm_config_db #(virtual apb_if.monitor_mp)::set(
            null, "uvm_test_top.env.agent.monitor", "vif", apb_if.monitor_mp);

        // 啟動 UVM（透過 +UVM_TESTNAME 指定 test class）
        // run_test() 內部會自己去讀 +UVM_TESTNAME
        // run_test();
        run_test("apb_test_wr_rd");
    end
    
endmodule