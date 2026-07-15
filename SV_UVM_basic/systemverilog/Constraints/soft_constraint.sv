// soft constraint
// soft constraint 是一種 弱約束條件
// 如果該變數沒有其他會與soft constraint牴觸的限制，soft constraint 會生效
// 如果有其他強制 constraint、直接指定值或使用 .randomize() with {}，那麼 soft constraint 就會被忽略。


class ABC;
  rand bit [3:0] data;

  // This constraint is defined as "soft"
  constraint c_data { soft data >= 4;
                     data <= 12; }
endclass

module tb;
  ABC abc;

  initial begin
    abc = new;
    for (int i = 0; i < 5; i++) begin
      abc.randomize() with { data == 2; };
      $display ("abc = 0x%0h", abc.data);
    end
  end
endmodule

/*
abc = 0x2   // 因為 data >= 4; 是 soft constraint 所以優先使用 abc.randomize() with { data == 2; }; 
abc = 0x2
abc = 0x2
abc = 0x2
abc = 0x2
*/