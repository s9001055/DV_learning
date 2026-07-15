interface my_int (input bit clk);
	// Rest of interface code

	clocking cb_clk @(posedge clk);
        // 定義 input 提前 3ns 取樣, output 延後 2 ns 取樣
		default input #3ns output #2ns;  
		input enable;
		output data;
	endclocking
endinterface