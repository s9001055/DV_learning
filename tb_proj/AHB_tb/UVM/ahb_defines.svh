// apb_defines.svh
`ifndef AHB_DEFINES_SVH
`define AHB_DEFINES_SVH

// 定義資料與位址位寬
`define AHB_DATA_WIDTH  32
`define AHB_ADDR_WIDTH  32
`define AHB_WAIT_CYCLES 8

// 你也可以順便定義一些常用的狀態
`define AHB_IDLE   2'b00
`define AHB_SETUP  2'b01
`define AHB_ACCESS 2'b10

`endif