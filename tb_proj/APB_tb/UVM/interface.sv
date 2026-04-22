`include "apb_defines.svh"

interface apb_if (
    input bit   clk,
    input logic rst_n
);
    // 1. 定義信號
    // APB 介面
    logic [31:0]                    PADDR,
    logic                           PSEL,
    logic                           PENABLE,
    logic                           PWRITE,
    logic [APB_DATA_WIDTH-1:0]      PWDATA,
    logic [(APB_DATA_WIDTH/8)-1:0]  PSTRB, // APB4 寫入選通
    logic [APB_DATA_WIDTH-1:0]      PRDATA,
    logic                           PREADY,
    logic                           PSLVERR
  
    // clocking out_mon_cb @(posedge clk);
    //     // default input #1ns 代表在時鐘上升緣之後 1ns 才採樣 (避開競爭)
    //     // default output #1ns 代表在時鐘上升緣之後 1ns 才把資料送出 (模擬 Hold time)
    //      default input #1step;

    //     // 從 mon 角度看：a, b, op 是「輸入」
    //   	input  result, overflow;
    // endclocking  
  
     // 2. 定義 Modport (規範方向)
    modport dut_port (
        input  PADDR, PSEL, PENABLE, PWRITE, PWDATA, PSTRB
        output PRDATA, PREADY, PSLVERR
    );

    // 對 Testbench 來說，方向剛好相反
    modport tb_port (
        input  PRDATA, PREADY, PSLVERR 
        output PADDR, PSEL, PENABLE, PWRITE, PWDATA, PSTRB
    );
endinterface