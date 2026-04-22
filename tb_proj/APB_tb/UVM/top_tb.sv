module top_tb;
    parameter ADDR_WIDTH = 10;
    parameter DATA_WIDTH = 32;
    parameter WAIT_CYCLES = 8;

  	bit clk;
  	logic rst_n;
  	always #5 clk = ~clk;

    // 實例化 Interface
    apb_if #(.ADDR_WIDTH(ADDR_WIDTH)) apb_if(
      .clk		(clk),
      .rst_n	(rst_n)
    );

    // 實例化 ALU 並連接 Interface
    apb_memory_slave #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH), .WAIT_CYCLES(WAIT_CYCLES)) dut (
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