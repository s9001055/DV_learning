// rand -> 會隨機產生數值
class Packet;
	rand bit [2:0] data;   // 宣告 rand 參數 bit [2:0] data
endclass

module tb;
	initial begin
		Packet pkt = new ();
		for (int i = 0 ; i < 10; i++) begin
			pkt.randomize ();  // 使用 .randomize() 來產生隨機數
			$display ("itr=%0d data=0x%0h", i, pkt.data);
		end
	end
endmodule

/*
itr=0 data=0x7
itr=1 data=0x2
itr=2 data=0x2
itr=3 data=0x1
itr=4 data=0x2
itr=5 data=0x4
itr=6 data=0x0
itr=7 data=0x1
itr=8 data=0x5
itr=9 data=0x0
*/


// randc -> 會隨機產生數值，且在一週期內數值不重複，等所有可能都出現過後，才會結束週期
class Packet;
	randc bit [2:0] data;
endclass

module tb;
	initial begin
		Packet pkt = new ();
		for (int i = 0 ; i < 10; i++) begin
			pkt.randomize ();
			$display ("itr=%0d data=0x%0h", i, pkt.data);
		end
	end
endmodule

/*
itr=0 data=0x6
itr=1 data=0x3
itr=2 data=0x4
itr=3 data=0x7
itr=4 data=0x0
itr=5 data=0x1
itr=6 data=0x5
itr=7 data=0x2  // 一個週期結束，以上數字不重複
itr=8 data=0x5
itr=9 data=0x0
*/