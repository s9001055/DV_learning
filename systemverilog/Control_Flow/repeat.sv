module tb;

  	// This initial block will execute a repeat statement that will run 5 times and exit
	initial begin

        // 重複執行五次
		repeat(5) begin
			$display ("Hello World !");
		end
	end
endmodule

/*
Hello World !
Hello World !
Hello World !
Hello World !
Hello World !
*/