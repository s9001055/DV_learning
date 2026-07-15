// =============================================================
//  DUT：簡單的暫存器組（3 個暫存器）— 純 Verilog 版本
//
//  地址映射（APB-like，32-bit 資料匯流排）：
//    0x00  REG_CTRL   [2] ENABLE, [1:0] MODE
//    0x04  REG_DATA   [7:0] DATA（可讀寫）
//    0x08  REG_STATUS [0]   BUSY（唯讀，由 DUT 邏輯設定）
// =============================================================
module dut_reg_example (
    input  wire        clk,
    input  wire        rst_n,
    // APB-like 介面
    input  wire        psel,
    input  wire        penable,
    input  wire        pwrite,
    input  wire [7:0]  paddr,
    input  wire [31:0] pwdata,
    output reg  [31:0] prdata,
    output wire        pready
);

    // -------------------------
    // 內部暫存器
    // -------------------------
    reg [1:0] reg_mode;    // REG_CTRL[1:0]
    reg       reg_enable;  // REG_CTRL[2]
    reg [7:0] reg_data;    // REG_DATA[7:0]
    reg       reg_busy;    // REG_STATUS[0]（唯讀）

    // BUSY 計數器：ENABLE 拉起後倒數 4 clk 才清除
    reg [2:0] busy_cnt;

    // APB 傳輸完成條件（zero-wait state）
    wire apb_write_en = psel & penable & pwrite & pready;

    // -------------------------
    // 寫入邏輯（同步 reset，負緣）
    // -------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_mode   <= 2'b00;
            reg_enable <= 1'b0;
            reg_data   <= 8'h00;
        end else if (apb_write_en) begin
            case (paddr)
                8'h00: {reg_enable, reg_mode} <= pwdata[2:0];
                8'h04: reg_data               <= pwdata[7:0];
            endcase
        end
    end

    // -------------------------
    // BUSY 計數器（模擬硬體忙碌狀態）
    // -------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy_cnt <= 3'd0;
            reg_busy <= 1'b0;
        end else if (reg_enable && !reg_busy) begin
            // ENABLE 剛被拉起 → 進入忙碌狀態
            reg_busy <= 1'b1;
            busy_cnt <= 3'd4;
        end else if (reg_busy && busy_cnt > 3'd0) begin
            busy_cnt <= busy_cnt - 3'd1;
        end else if (reg_busy && busy_cnt == 3'd0) begin
            reg_busy <= 1'b0;
        end
    end

    // -------------------------
    // 讀取邏輯（組合邏輯）
    // -------------------------
    always @(*) begin
        case (paddr)
            8'h00:   prdata = {29'b0, reg_enable, reg_mode};
            8'h04:   prdata = {24'b0, reg_data};
            8'h08:   prdata = {31'b0, reg_busy};
            default: prdata = 32'hDEAD_BEEF;
        endcase
    end

    // APB pready：setup → access 各一拍，恆為 zero-wait
    assign pready = psel & penable;

endmodule
