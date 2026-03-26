`include "interface.sv"
`include "transaction.sv"
`include "in_monitor.sv"
`include "out_monitor.sv"
`include "driver.sv"
`include "ref_model.sv"
`include "scoreboard.sv"

module top_tb;
    parameter BITWIDTH = 8;

  	bit clk;
  	logic rst_n;
  	always #5 clk = ~clk;
  
  
  	int repeat_count = 5;
  	alu_in_monitor #(.WIDTH(BITWIDTH)) alu_in_mon;
    alu_out_monitor #(.WIDTH(BITWIDTH)) alu_out_mon;
  	alu_ref_model #(.WIDTH(BITWIDTH)) alu_ref_model;
    alu_scoreboard #(.WIDTH(BITWIDTH)) alu_scb;
  	alu_driver alu_drv;
  
  	
  	mailbox #(alu_transaction) drv_mbx;
  	mailbox #(alu_transaction) in_mon_ref_mbx;
  	mailbox #(alu_transaction) out_mon_scb_mbx;
  	mailbox #(alu_transaction) ref_scb_mbx;

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
        $dumpvars;
        
        drv_mbx = new();
        in_mon_ref_mbx = new();
        out_mon_scb_mbx = new();
        ref_scb_mbx = new();
        
        alu_in_mon = new(dut_if, in_mon_ref_mbx);
        alu_out_mon = new(dut_if, out_mon_scb_mbx);
        alu_drv = new(dut_if, drv_mbx); 
        alu_ref_model = new(in_mon_ref_mbx, ref_scb_mbx);
        alu_scb = new(ref_scb_mbx, out_mon_scb_mbx);

        fork
          alu_in_mon.run();
          alu_out_mon.run();
          alu_drv.run();
          alu_ref_model.run();
          alu_scb.run();
        join_none

      	rst_n = 0; 
      	#1;
      	rst_n = 1;
      
      
      	repeat(repeat_count) begin
          	alu_transaction #(.WIDTH(BITWIDTH)) tx;
          	tx = new();
          	
          	// 隨機產生一些資料 (或是手動指定)
            tx.a = $urandom_range(8'h80, 8'h0);
            tx.b = $urandom_range(8'h80, 8'h0);
            tx.op = $urandom_range(0, 1);
            
            drv_mbx.put(tx); // 丟進信箱，Driver 會自己去領
      	end
      	 
        #100;
        $dumpvars;
        alu_scb.report();
        $finish;
    end
endmodule