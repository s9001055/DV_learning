// constraint 可以用來限制參數在 random 時，產生出固定範圍的值

class Pkt;
	rand bit [7:0] addr;
	rand bit [7:0] data;

	constraint addr_limit { addr <= 8'hB; }   // 限制 addr 數值要小於 < 0xB
endclass