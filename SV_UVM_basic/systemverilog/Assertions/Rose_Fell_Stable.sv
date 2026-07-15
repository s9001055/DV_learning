// $rose()	    偵測某控制訊號（如 reset、req）上升沿   (訊號從 0 -> 1，為 true)
// $fell()	    偵測某旗標或狀態（如 enable）下降沿     (訊號從 1 -> 0，為 true)
// $stable()	檢查訊號是否在特定週期中保持不變        (訊號上個週期與這個週期一樣為 true)




// 在 SystemVerilog Assertions（SVA） 中，|-> 是一個非常常見且重要的 時序操作符，
// 代表 "if...then..." 的時序邏輯。
// 這個符號在 concurrent assertions（同步/時序斷言）中被用來建立 條件成立後的時序反應。

// example 
// 如果某個週期 req 為 1
// 那麼 下個週期（##1） ack 必須為 1
// 否則會報 assertion 
assert property (@(posedge clk) req |-> ##1 ack);