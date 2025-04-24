module tb;

  initial begin
    int a, res;

    a = $urandom_range(1, 10);
    $display ("Before calling fn: a=%0d res=%0d", a, res);

    res = fn(a);
    $display ("After calling fn: a=%0d res=%0d", a, res);

    res = fn_ref(a);
    $display ("After calling fn_ref: a=%0d res=%0d", a, res);
  end

  function int fn(int a);
    a = a + 5;
    return a * 10;
  endfunction

  function automatic int fn_ref(ref int a);
    a = a + 3;
    return a * 10;
  endfunction
endmodule

/*
//if a = 8
Before calling fn: a=8 res=0
After calling fn: a=8 res=130
After calling fn_ref: a=11 res=110
*/