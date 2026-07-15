module tb_top;
   bit [7:0] array [8];   // Create a fixed size array

   initial begin

      // 設定 0 ~ 8 到對應 index 內
      foreach (array [index]) begin
         array[index] = index;
      end

      // 印出所有 index 內的值
      foreach (array [index]) begin
         $display ("array[%0d] = 0x%0d", index, array[index]);
      end
   end
endmodule

/*
array[0] = 0x0
array[1] = 0x1
array[2] = 0x2
array[3] = 0x3
array[4] = 0x4
array[5] = 0x5
array[6] = 0x6
array[7] = 0x7
*/