// constraint_mode() 可以用來關閉 constraint 
// .constraint_mode(0)   -> 關閉
// .constraint_mode(1)   -> 開啟
// .constraint_mode() => 不帶任何參數，回傳目前 constraint 狀態  0 -> disable, 1 -> enable

// 常搭配 pre_randomize() 來決定是否開啟 constraint


class Fruits;
  rand bit[3:0]  num; 				// Declare a 4-bit variable that can be randomized

  constraint c_num { num > 4;  		// Constraint is by default enabled, and applied
                    num < 9; }; 	// during randomization giving num a value between 4 and 9
endclass

module tb;
  initial begin
    Fruits f = new ();
    $display ("Before randomization num = %0d", f.num);

    // Disable constraint
    f.c_num.constraint_mode(0);

    if (f.c_num.constraint_mode ())
      $display ("Constraint c_num is enabled");
    else
      $display ("Constraint c_num is disabled");

    // Randomize the variable and display
    f.randomize ();
    $display ("After randomization num = %0d", f.num);
  end
endmodule


/*
Before randomization num = 0
Constraint c_num is disabled
After randomization num = 17    // 超出 constraint c_num{} 範圍，代表 constraint 被關閉
*/