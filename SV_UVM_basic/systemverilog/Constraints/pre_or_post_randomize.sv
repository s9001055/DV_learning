// ===================== pre_randomize() =====================

// 在 class 內可以覆寫 pre_randomize() 
// 物件呼叫 randomize() 後，先執行pre_randomize() 在去做 random 動作
class Beverage;
  rand bit [7:0]	beer_id;

  constraint c_beer_id { beer_id >= 10;
                        beer_id <= 50; };

  function void pre_randomize ();
  	$display ("This will be called just before randomization");
  endfunction

endclass

module tb;
   Beverage b;

    initial begin
      b = new ();
      $display ("Initial beerId = %0d", b.beer_id);
      if (b.randomize ())
      	$display ("Randomization successful !");
      $display ("After randomization beerId = %0d", b.beer_id);
    end
endmodule

/*
Initial beerId = 0
This will be called just before randomization
Randomization successful !
After randomization beerId = 25
*/





// ===================== post_randomize() =====================
// 在 class 內可以覆寫 post_randomize() 
// 物件呼叫 randomize() 後，randomize() 執行成功後，執行 post_randomize()
// 如果 randomize() 沒成功，不執行 post_randomize()

class Beverage;
  rand bit [7:0]	beer_id;

  constraint c_beer_id { beer_id >= 10;
                        beer_id <= 50; };

  function void pre_randomize ();
  	$display ("This will be called just before randomization");
  endfunction

  function void post_randomize ();
  	$display ("This will be called just after randomization");
  endfunction

endclass

module tb;
   Beverage b;

    initial begin
      b = new ();
      $display ("Initial beerId = %0d", b.beer_id);
      if (b.randomize ())
      	$display ("Randomization successful !");
      $display ("After randomization beerId = %0d", b.beer_id);
    end
endmodule

/*
Initial beerId = 0
This will be called just before randomization
This will be called just after randomization
Randomization successful !
After randomization beerId = 25
*/