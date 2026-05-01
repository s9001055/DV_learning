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
    ahb_dut #(.ADDR_WIDTH(`APB_ADDR_WIDTH), .DATA_WIDTH(`APB_DATA_WIDTH)) dut (
      .PCLK		        (clk),
      .PRESETn	        (rst_n),
      .HSEL             (ahb_if.HSEL),
      .HADDR            (ahb_if.HADDR),
      .HWRITE           (ahb_if.HWRITE),
      .HSIZE            (ahb_if.HSIZE),
      .HBURST           (ahb_if.HBURST),
      .HTRANS           (ahb_if.HTRANS),
      .HWDATA           (ahb_if.HWDATA),
      .HRDATA           (ahb_if.HRDATA),
      .HREADY           (ahb_if.HREADY),
      .HRESP            (ahb_if.HRESP)
    );


endmodule