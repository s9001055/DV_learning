`include "interface.sv"
`include "transaction.sv"
`include "monitor.sv"

module top_tb;
    parameter BITWIDTH = 8;

  	bit clk;
  	logic rst_n;
  	always #5 clk = ~clk;
  
    alu_monitor #(.WIDTH(BITWIDTH)) alu_mon;

    // 1. 實例化 Interface
    alu_if #(.WIDTH(BITWIDTH)) dut_if(
      .clk		(clk),
      .rst_n	(rst_n)
    );

    // 2. 實例化 ALU 並連接 Interface
    eight_bit_alu #(.WIDTH(BITWIDTH)) dut (
      .clk		(clk),
      .rst_n	(rst_n),
      .a		(dut_if.dut_port.a),
      .b		(dut_if.dut_port.b),
      .op		(dut_if.dut_port.op),
      .result	(dut_if.dut_port.result),
      .overflow	(dut_if.dut_port.overflow)
    );

  	// 初始為重置狀態
  	initial begin
        rst_n = 0;  
      	rst_n = 1; 
    end
  
    // 3. 簡單的測試邏輯
    initial begin
        alu_mon = new(dut_if);

        fork
          alu_mon.run();
        join_none

        // 範例： 127 + 1 (有號數溢位測試)
        dut_if.op = 0;
        dut_if.a  = 8'd127; 
        dut_if.b  = 8'd1;
		
		    @(posedge clk);
        #1;
      	$display("A: %d, B: %d, Op: %b | Result: %d, Overflow: %b, time: %t", 
                 $signed(dut_if.a), $signed(dut_if.b), dut_if.op, 
                 $signed(dut_if.result), dut_if.overflow, $time);
		
      	#20;
      
        // 範例： reset
      	rst_n = 0;
      	@(posedge clk);
      	#1;
        $display("A: %d, B: %d, Op: %b | Result: %d, Overflow: %b, time: %t", 
                 $signed(dut_if.a), $signed(dut_if.b), dut_if.op, 
                 $signed(dut_if.result), dut_if.overflow, $time);
      	
      	#20;
      	rst_n = 1;

       	
      
        // 範例： -128 - 1 (有號數溢位測試)
        dut_if.op = 1;
        dut_if.a  = 8'b1000_0000; // -128
        dut_if.b  = 8'd1;
      
		    @(posedge clk);
      	#1;	
      	$display("A: %d, B: %d, Op: %b | Result: %d, Overflow: %b, time: %t", 
                 $signed(dut_if.a), $signed(dut_if.b), dut_if.op, 
                 $signed(dut_if.result), dut_if.overflow, $time);
      
       	#30;
        $finish;

    end
endmodule