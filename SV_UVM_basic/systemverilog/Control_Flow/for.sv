module tb;
 bit clk;

  always #10 clk = ~clk;
  initial begin
  	bit [3:0] counter;

    $display ("Counter = %0d", counter);        // Counter = 0
  	for (counter = 2; counter < 14; counter = counter + 2) begin
    	@(posedge clk);
    	$display ("Counter = %0d", counter);      // print Counter
  	end
    $display ("Counter = %0d", counter);        // Counter = 14
    $finish;
  end
endmodule

/*
Counter = 0
Counter = 2
Counter = 4
Counter = 6
Counter = 8
Counter = 10
Counter = 12
Counter = 14
*/