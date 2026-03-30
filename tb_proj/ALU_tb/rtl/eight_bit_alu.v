// support OP
// add, sub
// or, and, xor, not

module eight_bit_alu #(
    parameter WIDTH = 8
)(
  	input  					clk,
  	input  					rst_n,
    input  		[WIDTH-1:0] a,      // 輸入 A
    input  		[WIDTH-1:0] b,      // 輸入 B
    input               	op,     // 操作碼: 0 為 ADD, 1 為 SUB
    output reg	[WIDTH-1:0] result, // 運算結果
    output reg              overflow // 溢位旗標
);

    // 內部的中間變數仍可用組合邏輯
    wire [WIDTH-1:0] b_mux;
    wire [WIDTH-1:0] next_result;
    wire             next_overflow;

  	assign b_mux = (op) ? ~b : b;
    assign next_result = a + b_mux + op;
  	assign next_overflow = (a[WIDTH-1] == b_mux[WIDTH-1]) && (next_result[WIDTH-1] != a[WIDTH-1]);

    // 正緣觸發邏輯
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        result   <= 0;
        overflow <= 0;
      end else begin
        result   <= next_result;
        overflow <= next_overflow;
      end
    end

endmodule
