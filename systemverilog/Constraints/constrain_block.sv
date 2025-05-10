class ABC;
	rand bit [3:0] mode;

	// 建立一個 constrain block 來限制 mode 的數值範圍， 2 < mode <= 6
	constraint c_mode { mode > 2;
	                    mode <= 6;
	                  };
endclass

class DEF;
	rand bit [3:0] mode;

    // 可以先宣告一個 constraint block 後，在外部去定義範圍
    // 可分為 implicit、explicit
	constraint c_implicit; 				
	extern constraint c_explicit;
endclass

// This is an external constraint because it is outside
// the class-endclass body of the class. The constraint
// is reference using ::
constraint ABC::c_implicit { mode > 2; };
constraint ABC::c_explicit { mode <= 6; };

module tb;
	ABC abc;

	initial begin
      	// Create a new object with this handle
		abc = new();

      	// In a for loop, lets randomize this class handle
      	// 5 times and see how the value of mode changes
        // A class can be randomized by calling its "randomize()"
		for (int i = 0; i < 5; i++) begin
			abc.randomize();
          $display ("mode = 0x%0h", abc.mode);
		end
	end
endmodule


/*
mode = 0x5
mode = 0x5
mode = 0x4
mode = 0x3
mode = 0x3
*/