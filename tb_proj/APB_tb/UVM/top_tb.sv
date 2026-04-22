`include "apb_defines.svh"

module top_tb;
  	bit clk;
  	logic rst_n;
  	always #5 clk = ~clk;

    // 實例化 Interface
    apb_if apb_if(
      .clk		(clk),
      .rst_n	(rst_n)
    );

    // 實例化 ALU 並連接 Interface
    apb_memory_slave #(.ADDR_WIDTH(APB_ADDR_WIDTH), .DATA_WIDTH(APB_DATA_WIDTH), .WAIT_CYCLES(APB_WAIT_CYCLES)) dut (
      .PCLK		    (clk),
      .PRESETn	    (rst_n),
      .PADDR		(apb_if.dut_port.PADDR),
      .PSEL		    (apb_if.dut_port.PSEL),
      .PENABLE		(apb_if.dut_port.PENABLE),
      .PWRITE	    (apb_if.dut_port.PWRITE),
      .PWDATA	    (apb_if.dut_port.PWDATA),
      .PSTRB        (apb_if.dut_port.PSTRB),
      .PRDATA       (apb_if.dut_port.PRDATA),
      .PREADY       (apb_if.dut_port.PREADY),
      .PSLVERR      (apb_if.dut_port.PSLVERR)
    );
    
endmodule