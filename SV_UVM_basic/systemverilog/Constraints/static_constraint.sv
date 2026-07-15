// constraint 可以宣告成 static 型態
// 當 constraint 為 static，則此 constraint 為個物件共用的 constraint
// 有任一物件使用 .constraint_mode(); 去開關 constraint 時
// 其他物件也會開關此 static constraint

class ABC;
  rand bit [3:0]  a;

  // "c1" is non-static, but "c2" is static
  constraint c1 { a > 5; }
  static constraint c2 { a < 12; }
endclass

module tb;
  initial begin
    ABC obj1 = new;
    ABC obj2 = new;

    // Turn non-static constraint
    // 當 obj1 去關閉 c2 constraint，則 obj2 的 c2 也會被關閉
    obj1.c2.constraint_mode(0);

    for (int i = 0; i < 5; i++) begin
      obj1.randomize();
      obj2.randomize();
      $display ("obj1.a = %0d, obj2.a = %0d", obj1.a, obj2.a);
    end
  end
endmodule


/*
obj1.a = 7, obj2.a = 8
obj1.a = 6, obj2.a = 9
obj1.a = 14, obj2.a = 12   // 看到 obj1 跟 obj2 的 a 都超出 12
obj1.a = 10, obj2.a = 11
obj1.a = 8, obj2.a = 7
*/