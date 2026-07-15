module tb;
  logic [2:0] mode;

  // This covergroup does not get sample automatically because
  // the sample event is missing in declaration
  covergroup cg;
    coverpoint mode {
        // 只要兩個 bin 都達成，覆蓋率為 100%，只達成一個 50%
        bins two = {2};                 // 只要 random 出 2，這個 bin 代表成功
    	  bins five = {5};                // 只要 random 出 2，這個 bin 代表成功
        // bins six_seven = {[6:7]};    // 只要 random 出 6 or 7，這個 bin 代表成功
        // bins range[] = {[0:$]};      // 會直接分成8個bins，每個 bins 分別為 0, 1, 2, ... , 7
        // bins range[4] = {[0:$]};     // 會分成 4 個bins，每個 bins 分別為 [0:1], [2:3], [4:5], [6:7]
        // bins range[3] = {[1:4], 7};  // bin1->[1,2] bin2->[3,4], bin3->7
    }
  endgroup

  initial begin
    cg cg_inst = new();
    for (int i = 0; i < 5; i++) begin
	  #10 mode = $random;
      $display ("[%0t] mode = 0x%0h", $time, mode);
      cg_inst.sample();  // 使用 .sample() 去觸發 covergroup
    end
    $display ("Coverage = %0.2f %%", cg_inst.get_inst_coverage());
  end

endmodule

/*
[10] mode = 0x4
[20] mode = 0x1
[30] mode = 0x1
[40] mode = 0x3
[50] mode = 0x5
Coverage = 50.00 %   // 因為只出現 5 沒有出現 2，所以覆蓋率為 50%
*/