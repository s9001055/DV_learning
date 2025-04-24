module tb;

  // 一直執行直到 module finish
  initial begin
    forever begin
      #5 $display ("Hello World !");
    end
  end

  // 50 ns 後，finish
  initial
    #50 $finish;
endmodule

/*
Hello World !
Hello World !
Hello World !
Hello World !
Hello World !
Hello World !
Hello World !
Hello World !
Hello World !
*/