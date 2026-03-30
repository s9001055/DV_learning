class alu_out_monitor #(parameter WIDTH = 8);
    // 宣告虛擬介面 (指向實體 interface)
    virtual alu_if v_if;
  
    mailbox #(alu_transaction) mbx; // 要傳給 scoreboard 的 mailbox
    
    int count = 0;
  	
    // 建構子：把實體介面傳進來
    function new(virtual alu_if if_in, mailbox #(alu_transaction) mbx_out);
        this.v_if = if_in;
        this.mbx = mbx_out;
    endfunction

    // 啟動監控的任務
    task run();
        $display("[%0t] [OUT_Monitor] Class-based monitor started.", $time);
        forever begin
            // 1. 等待時鐘正緣
            @(v_if.out_mon_cb);//@(posedge v_if.clk);
            // 2. 只有在重置釋放時才採樣
            if (v_if.rst_n) begin
                // 建立一個新的 Transaction 物件來存放這一拍的資料
                alu_transaction #(.WIDTH(WIDTH)) tr;
                tr = new();
                        
                if (count < 2) begin
                  count += 1;
                  continue;
                end
                // 採樣訊號
                tr.result   = v_if.out_mon_cb.result;
                tr.overflow = v_if.out_mon_cb.overflow;

                // 3. 印出結果或傳給 Scoreboard
                mbx.put(tr); // 傳給 ref model
                //tr.display("OUT_MONITOR_CAPTURE");
            end
        end
    endtask
endclass