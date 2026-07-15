module blocking_nonblocking (
    input logic clk, a, b,
    output logic c_block, d_block, c_nonblock, d_nonblock
);
    // 阻塞賦值
    always @(posedge clk) begin
        c_block = a & b;        // 立即更新 c_block
        d_block = c_block | b;  // 使用更新後的 c_block
    end

    // 非阻塞賦值
    always @(posedge clk) begin
        c_nonblock <= a & b;            // 延遲更新 c_nonblock
        d_nonblock <= c_nonblock | b;   // 使用舊的 c_nonblock
    end
endmodule