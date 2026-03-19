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