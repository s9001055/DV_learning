// 可以自己創造自己想要的 case，並給予他們權重

module tb;
	initial begin
      for (int i = 0; i < 10; i++)
        // 此 case 分母為 1+5+3 = 9
        // 出現 0 的機率為 1/9
        // 出現 5 的機率為 5/9
        // 出現 3 的機率為 3/9        
      	randcase
        	0 	: 	$display ("Wt 1");
      		5 	: 	$display ("Wt 5");
      		3 	: 	$display ("Wt 3");
      	endcase
    end
endmodule

/*
Wt 3
Wt 5
Wt 3
Wt 5
Wt 3
Wt 5
Wt 5
Wt 5
Wt 5
Wt 5
*/