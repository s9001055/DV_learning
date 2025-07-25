// 此 module 為 擁有 2 ^ ADDR_WIDTH 大小的 memory

module memory
  #( parameter ADDR_WIDTH = 2,
     parameter DATA_WIDTH = 8 ) (
    input clk,
    input reset,
    
    //control signals
    input [ADDR_WIDTH-1:0]  addr,
    input                   wr_en,
    input                   rd_en,
    
    //data signals
    input  [DATA_WIDTH-1:0] wdata,
    output [DATA_WIDTH-1:0] rdata
  ); 
  
  reg [DATA_WIDTH-1:0] rdata;
  
  //Memory
  reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH];

  //Reset 
  always @(posedge reset) 
    for(int i=0;i<2**ADDR_WIDTH;i++) mem[i]=8'hFF;
   
  // 執行寫入操作，將 wdata 寫入指定 addr
  always @(posedge clk) 
    if (wr_en)    mem[addr] <= wdata;

  // 執行讀取操作，將指定 addr 讀出至 rdata
  always @(posedge clk)
    if (rd_en) rdata <= mem[addr];

endmodule