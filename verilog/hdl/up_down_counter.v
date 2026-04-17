module up_down_counter (
    input       wire        clk,      // 時脈訊號
    input       wire        rst_n,    // 非同步低電位重置
    input       wire [31:0] min,      // 計數最小值
    input       wire [31:0] max,      // 計數最大值
    output reg  [31:0] count          // 目前計數值
);

    // 定義狀態：0 為遞增 (Up)，1 為遞減 (Down)
    reg dir; 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 32'd0;
            dir   <= 1'b0; // 預設向上計數
        end else begin
            if (dir == 1'b0) begin
                // --- 遞增模式 ---
                if (count >= max) begin
                    count <= count - 32'd1;
                    dir   <= 1'b1; // 到達最大值，轉向向下
                end else if (count < min) begin
                    count <= min;   // 若當前值小於最小值，跳回 min 開始
                end else begin
                    count <= count + 32'd1;
                end
            end else begin
                // --- 遞減模式 ---
                if (count <= min) begin
                    count <= count + 32'd1;
                    dir   <= 1'b0; // 到達最小值，轉向向上
                end else if (count > max) begin
                    count <= max;   // 若當前值大於最大值，跳回 max 開始
                end else begin
                    count <= count - 32'd1;
                end
            end
        end
    end

endmodule
