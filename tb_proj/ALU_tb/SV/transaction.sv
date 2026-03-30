class alu_transaction #(parameter WIDTH = 8);
    // 使用 rand 關鍵字以便後續進行隨機化測試
    rand bit [WIDTH-1:0] a;
    rand bit [WIDTH-1:0] b;
    rand bit             op;
    
    // 結果通常不由 Generator 產生，但需要空間存放 Monitor 抓到的值
    bit [WIDTH-1:0]      result;
    bit                  overflow;

    // 顯示函數也需要適應位元長度
    function void display(string name = "ALU_TX");
        $display("[%s] A:%d B:%d Op:%b | Result:%d Over:%b (Width:%0d)", name, $signed(a), $signed(b), op, $signed(result), overflow, WIDTH);
    endfunction
endclass