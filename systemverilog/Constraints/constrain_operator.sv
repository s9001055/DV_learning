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