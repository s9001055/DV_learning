// ==================== inside operator ==================== 
constraint my_range { typ > 32;
                      typ < 256; }


// typ >= 32 and typ <= 256
constraint new_range { typ inside {[32:256]}; }

// 選擇 32 or 64 or 128
constraint spec_range { type inside {32, 64, 128}; }




// ==================== weighted distributions ==================== 
class myClass;
	rand bit [2:0] typ;

    // 權重分配，使用 :=
    // 0 有 20
    // 1~5 各有 50
    // 6 有 40
    // 7 有 10
    // 總共 320
    // 產生 0 的機率為 20/320
	constraint dist1 	{  typ dist { 0:=20, [1:5]:=50, 6:=40, 7:=10}; }
endclass

module tb;
	initial begin
		for (int i = 0; i < 10; i++) begin
			myClass cls = new ();
			cls.randomize();
			$display ("itr=%0d typ=%0d", i, cls.typ);
		end
	end
endmodule



// ==================== 在 constriant block 常見的用法 ==================== 
// ==================== 1. ->  ==================== 

// Implication operator "->" tells that len should be
// 當 mode == 2 時，len > 10
constraint c_mode {  mode == 2 -> len > 10; }

// 意思跟上面一樣
constraint c_mode { if (mode == 2)
						len > 10;
				  }

// ==================== 2. 可在 constriant block 內寫 if else ==================== 
class ABC;
  rand bit [3:0] mode;
  rand bit 		 mod_en;

  constraint c_mode {
    					// If 5 <= mode <= 11, then constrain mod_en to 1
    					// This part only has 1 statement and hence do not
    					// require curly braces {}
    					if (mode inside {[4'h5:4'hB]})
  							mod_en == 1;

    					// If the above condition is false, then do the following
   						else {
                          // If mode is constrained to be 1, then mod_en should be 1
                          if ( mode == 4'h1) {
      							mod_en == 1;
                            // If mode is any other value than 1 and not within
                            // 5:11, then mod_en should be constrained to 0
    						} else {
      							mod_en == 0;
    						}
  						}
                    }

endclass

module tb;
  initial begin
    ABC abc = new;
    for (int i = 0; i < 10; i++) begin
    	abc.randomize();
      $display ("mode=0x%0h mod_en=0x%0h", abc.mode, abc.mod_en);
    end
  end

endmodule

// ==================== 3. 可在 constriant block 內寫 foreach ==================== 
class ABC;
  rand bit[3:0] array [5];

  // 每個 array[i] 的值都是他的 index
  constraint c_array { foreach (array[i]) {
    					array[i] == i;
  						}
                     }
endclass

module tb;

  initial begin
    ABC abc = new;
    abc.randomize();
    $display ("array = %p", abc.array);
  end
endmodule

// ==================== 4. solve before ==================== 
// 由於 constraint 每個事件都是平行發生
// 如果使用 solve "a" before "b" 就可以先對 a 做 rand 在對 b 的剩餘條件做 rand

// 沒有使用 solve before
class ABC;
  rand  bit			a;
  rand  bit [1:0] 	b;

  // 此時所有可能性的機率都是 1/5
  constraint c_ab { a -> b == 3'h3; }
endclass

module tb;
  initial begin
    ABC abc = new;
    for (int i = 0; i < 8; i++) begin
      abc.randomize();
      $display ("a=%0d b=%0d", abc.a, abc.b);
    end
  end
endmodule

// 使用 solve before
class ABC;
  rand  bit			a;
  rand  bit [1:0] 	b;
  
  // a == 0 時，b 的可能值為 0 ~ 3   這個部分的機率為 1/2 * 1/4
  // a == 1 時，b 的可能值為 3       這個部分的機率為 1/2
  constraint c_ab { a -> b == 3'h3;

  				  // 告訴 solver 
				  // 先 決定 a，在依照 constraint 去決定 b
                  	solve a before b;
                  }
endclass

module tb;
  initial begin
    ABC abc = new;
    for (int i = 0; i < 8; i++) begin
      abc.randomize();
      $display ("a=%0d b=%0d", abc.a, abc.b);
    end
  end
endmodule
