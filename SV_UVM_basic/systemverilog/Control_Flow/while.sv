module tb;
  bit clk;

  always #10 clk = ~clk;
  initial begin
  	bit [3:0] counter;

    $display ("Counter = %0d", counter);          // Counter = 0
  	while (counter < 10) begin
    	@(posedge clk);
    	counter++;
        $display ("Counter = %0d", counter);      // print Counter
  	end
  	$display ("Counter = %0d", counter);          // Counter = 10
    $finish;
end
endmodule

/*
Counter = 0
Counter = 1
Counter = 2
Counter = 3
Counter = 4
Counter = 5
Counter = 6
Counter = 7
Counter = 8
Counter = 9
Counter = 10
Counter = 10
*/