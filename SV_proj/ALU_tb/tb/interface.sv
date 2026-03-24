interface alu_if #(parameter WIDTH = 8) (
    input bit   clk,
    input logic rst_n
);
    // 1. 定義信號
    logic [WIDTH-1:0] a;
    logic [WIDTH-1:0] b;
    logic             op;
    logic [WIDTH-1:0] result;
    logic             overflow;
  
    clocking mon_cb @(posedge clk);
        // default input #1ns 代表在時鐘上升緣之後 1ns 才採樣 (避開競爭)
        // default output #1ns 代表在時鐘上升緣之後 1ns 才把資料送出 (模擬 Hold time)
        default input #1ns output #1ns;

        // 從 mon 角度看：a, b, op 是「輸入」
        input a, b, op;

      	output  result, overflow;
    endclocking  
  
     // 2. 定義 Modport (規範方向)
    // 對 ALU 來說，a, b, op 是輸入，其餘是輸出
    modport dut_port (
        input  a, b, op,
        output result, overflow
    );

    // 對 Testbench 來說，方向剛好相反
    modport tb_port (
        output a, b, op,
        input  result, overflow
    );
endinterface