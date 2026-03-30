class alu_generator #(parameter WIDTH = 8);
  	alu_transaction #(.WIDTH(WIDTH)) tr;
    mailbox #(alu_transaction) mbx; // 與 Driver 共用同一個郵箱
    int loop_count = 10;           // 預計測試幾筆資料

  function new(mailbox #(alu_transaction) mbx_in, int count);
        this.mbx = mbx_in;
    	this.loop_count = count;
    endfunction

    task run();
        repeat(loop_count) begin
            tr = new();
            // 隨機化資料
            if (!tr.randomize()) $error("Randomization failed!");
            
            // $display("[%0t] [Generator] Created new transaction, putting into mailbox...", $time);
            
            // 將資料丟進信箱
            mbx.put(tr); 
        end
        $display("[%0t] [Generator] Finished generating %0d transactions.", $time, loop_count);
    endtask
endclass