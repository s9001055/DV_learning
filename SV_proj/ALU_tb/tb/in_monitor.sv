class alu_in_monitor #(parameter WIDTH = 8);
    // 宣告虛擬介面 (指向實體 interface)
    virtual alu_if v_if;
  	mailbox #(alu_transaction) mbx; // 要傳給 ref model 的 mailbox
  
	bit first = 1;
    
    // 建構子：把實體介面傳進來
  	function new(virtual alu_if if_in, mailbox #(alu_transaction) mbx_out);
        this.v_if = if_in;
    	this.mbx = mbx_out;
    endfunction

    // 啟動監控的任務
    task run();
      $display("[%0t] [IN_Monitor] Class-based monitor started.", $time);
        forever begin
            // 1. 等待時鐘正緣
          @(posedge v_if.clk);
            
            // 2. 只有在重置釋放時才採樣
            if (v_if.rst_n) begin
                // 建立一個新的 Transaction 物件來存放這一拍的資料
              	alu_transaction #(.WIDTH(WIDTH)) tr;
                tr = new();
                
                // 採樣訊號 (注意：因為是同步電路，這裡抓到的是當前輸出的結果)
                tr.a        = v_if.a;
                tr.b        = v_if.b;
                tr.op       = v_if.op;
                tr.result   = v_if.result;
                tr.overflow = v_if.overflow;
                
                if (first == 0) begin
                    // 3. 印出結果或傳給 Scoreboard
                    //tr.display("IN_MONITOR_CAPTURE");
                    mbx.put(tr); // 傳給 ref model
                end
                first = 0;
            end
        end
    endtask
endclass