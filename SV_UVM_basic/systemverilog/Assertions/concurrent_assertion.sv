// Concurrent Assertions（並行斷言）-> SystemVerilog Assertion (SVA)
// 跨時間檢查
// 驗證時序行為、事件序列
// assert property(...)



// 運算子            介紹                   Example
// ##N	        等待 N 個時鐘週期	        a ##2 b
// [*N]	        某事件持續 N 次	            a[*3]
// [#]	        任意非零時間延遲	
// ##[M:N]	    延遲 M 到 N 個週期	        a ##[1:3] b
// within       限制事件序列在另一事件內     s1 within s2
// disable iff	在某條件下禁用斷言	        @(posedge clk) disable iff (reset) ...




// 定義事件序列
sequence seq_name;
  ... 
endsequence

// 基於 sequence 建立驗證條件。
property prop_name;
  @(posedge clk) seq_name; // 可加條件
endproperty

// 在模擬中啟用斷言
assert property (prop_name);


// example 
sequence s_ab;
  // 在某個時刻 a 為 true
  // 下個時鐘週期（##1） b 必須為 true
  // 否則斷言失敗
  a ##1 b; 
endsequence

property p_check;
  @(posedge clk) s_ab;
endproperty

assert property (p_check);