`include "interface.sv"
`include "transaction.sv"
`include "monitor.sv"
`include "driver.sv"

module top_tb;
    parameter BITWIDTH = 8;

  	bit clk;
  	logic rst_n;
  	always #5 clk = ~clk;
  
  
  	int repeat_count = 5;
    alu_monitor #(.WIDTH(BITWIDTH)) alu_mon;
  	alu_driver alu_drv;
  	mailbox #(alu_transaction) mbx;

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
  
    // 3. 簡單的測試邏輯
    initial begin
      	mbx = new();
        alu_mon = new(dut_if);
      	alu_drv = new(dut_if, mbx); 

        fork
          alu_mon.run();
          alu_drv.run();
        join_none

      	rst_n = 0; 
      	#10;
      	rst_n = 1;
      
      
      	repeat(repeat_count) begin
          	alu_transaction #(.WIDTH(BITWIDTH)) tx;
          	tx = new();
          	
          	// 隨機產生一些資料 (或是手動指定)
          	tx.a = $urandom_range(8'h7F, 8'h80);
            tx.b = $urandom_range(8'h7F, 8'h80);
            tx.op = $urandom_range(0, 1);
            
            mbx.put(tx); // 丟進信箱，Driver 會自己去領
      	end
      
       	#60;
        $finish;
    end
endmodule