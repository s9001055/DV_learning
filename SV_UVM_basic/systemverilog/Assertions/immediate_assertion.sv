// Immediate Assertion
// 立即執行
// 驗證組合邏輯、立刻檢查結果
// assert(expr)

// Immediate assertions 最常用於 initial, always, task, function 等語法區塊中。
// 配合 $error, $warning, $fatal 可以控制模擬行為：
// $error：印錯誤，但不終止模擬
// $fatal：印錯誤並停止模擬

module test;
  int a = 3, b = 4, sum = 8;

  initial begin
    // 如果 sum != a + b，就印出錯誤訊息。
    assert (sum == a + b)  
      else $error("Sum is incorrect: %0d != %0d + %0d", sum, a, b);
  end
endmodule

/*
Error: testbench.sv (7): Sum is incorrect: 8 != 3 + 4
*/



