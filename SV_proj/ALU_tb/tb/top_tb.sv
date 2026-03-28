`include "rtl\eight_bit_alu.v"

`include "interface.sv"
`include "transaction.sv"
`include "in_monitor.sv"
`include "out_monitor.sv"
`include "driver.sv"
`include "ref_model.sv"
`include "scoreboard.sv"
`include "generator.sv"
`include "env.sv"

module top_tb;
    parameter BITWIDTH = 8;

  	bit clk;
  	logic rst_n;
  	always #5 clk = ~clk;
  
  	int repeat_count = 5;
    
    // 實例化 Interface
    alu_if #(.WIDTH(BITWIDTH)) dut_if(
      .clk		(clk),
      .rst_n	(rst_n)
    );

    // 實例化 ALU 並連接 Interface
    eight_bit_alu #(.WIDTH(BITWIDTH)) dut (
      .clk		(clk),
      .rst_n	(rst_n),
      .a		(dut_if.dut_port.a),
      .b		(dut_if.dut_port.b),
      .op		(dut_if.dut_port.op),
      .result	(dut_if.dut_port.result),
      .overflow	(dut_if.dut_port.overflow)
    );

    // 宣告 alu_env
    alu_env			#(.WIDTH(BITWIDTH)) alu_env;

    // 測試邏輯
    initial begin
        //$dumpvars; // for edaplayground waveform

        alu_env = new(dut_if, repeat_count);

        // reset
      	rst_n = 0; 
      	#1;
      	rst_n = 1;

        // 啟動 alu_env
        alu_env.run();

        #100;
        //$dumpvars; // for edaplayground waveform

        // 印出結果
        alu_env.report();
        $finish;
    end
endmodule