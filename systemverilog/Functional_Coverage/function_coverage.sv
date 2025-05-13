module tb;

  // 宣告兩個參數去做 random，來收集覆蓋率
  logic [1:0] mode;
  logic [2:0] cfg;

  // Declare a clock to act as an event that can be used to sample
  // coverage points within the covergroup
  bit clk;
  always #20 clk = ~clk;

  // "cg" 在 clk 正緣觸發
  covergroup cg @ (posedge clk);
    // 使用 coverpoint 去收集 cfg 出現過的數值，會有 0~7 種可能
    coverpoint cfg; 
  endgroup

  // Create an instance of the covergroup
  cg  cg_inst;

  initial begin
    // Instantiate the covergroup object similar to a class object
    cg_inst= new();

    // Stimulus : Simply assign random values to the coverage variables
    // so that different values can be sampled by the covergroup object
    for (int i = 0; i < 5; i++) begin
      @(negedge clk);
      mode = $random;
      cfg  = $random;
      $display ("[%0t] mode=0x%0h cfg=0x%0h", $time, mode, cfg);
    end
  end

  // At the end of 500ns, terminate test and print collected coverage
  initial begin
    #500 $display ("Coverage = %0.2f %%", cg_inst.get_inst_coverage());
    $finish;
  end
endmodule


/*
[40] mode=0x0 cfg=0x1
[80] mode=0x1 cfg=0x3
[120] mode=0x1 cfg=0x5
[160] mode=0x1 cfg=0x2
[200] mode=0x1 cfg=0x5
Coverage = 50.00 %       // 因為 cfg 只出現 1 2 3 5，所以覆蓋率為 4/8 = 50%
*/





module tb;

  bit [1:0] mode;
  bit [2:0] cfg;

  bit clk;
  always #20 clk = ~clk;

  covergroup cg @ (posedge clk);

    // 使用 : 幫 Coverpoint 賦予名稱
    cp_mode    : coverpoint mode;           
    cp_cfg_10  : coverpoint cfg[1:0];      // cp_cfg_10 只關心 cfg 的最低兩個 bit，cp_cfg_10 可能的值為 0~3
    cp_cfg_lsb : coverpoint cfg[0];        // cp_cfg_lsb 只關心 cfg 的LSB，cp_cfg_lsb 可能的值為 0~1
    cp_sum     : coverpoint (mode + cfg);  // mode + cfg 0~7
  endgroup

  cg  cg_inst;

  initial begin
    cg_inst= new();

    for (int i = 0; i < 5; i++) begin
      @(negedge clk);  // 負緣觸發，產生新的 random 值
      mode = $random;
      cfg  = $random;
      $display ("[%0t] mode=0x%0h cfg=0x%0h", $time, mode, cfg);
    end
  end

  initial begin
    // 使用 .get_inst_coverage() 去取得覆蓋率
    #500 $display ("Coverage = %0.2f %%", cg_inst.get_inst_coverage());
    $finish;
  end
endmodule


