// 以下是一個 APB bus protocol 的 interface

interface apb_if (input pclk);
	logic [31:0]    paddr;   // address 變數
	logic [31:0]    pwdata;  // write data 傳輸變數
	logic [31:0]    prdata;  // read data 傳輸變數
	logic           penable;
	logic           pwrite;
	logic           psel;
endinterface