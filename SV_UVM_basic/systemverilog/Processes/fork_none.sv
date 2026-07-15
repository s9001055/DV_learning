// fork none 不理會 thread 有沒有完成，會直接執行 fork 之後的程式

module tb_top;
   initial begin

   	  #1 $display ("[%0t ns] Start fork ...", $time);

   	  // Main Process: Fork these processes in parallel and exits immediately
      fork
      	 // Thread1 : Print this statement after 5ns from start of fork
         #5 $display ("[%0t ns] Thread1: Orange is named after orange", $time);

         // Thread2 : Print these two statements after the given delay from start of fork
         begin
            #2 $display ("[%0t ns] Thread2: Apple keeps the doctor away", $time);
            #4 $display ("[%0t ns] Thread2: But not anymore", $time);
         end

         // Thread3 : Print this statement after 10ns from start of fork
         #10 $display ("[%0t ns] Thread3: Banana is a good fruit", $time);
      join_none

      // Main Process: Continue with rest of statements once fork-join is exited
      $display ("[%0t ns] After Fork-Join", $time);
   end
endmodule


/*
[1 ns] Start fork ...                           // 進入 fork
[1 ns] After Fork-Join                          // create 完 Thread，就離開fork
[3 ns] Thread2: Apple keeps the doctor away
[6 ns] Thread1: Orange is named after orange
[7 ns] Thread2: But not anymore
[11 ns] Thread3: Banana is a good fruit
*/