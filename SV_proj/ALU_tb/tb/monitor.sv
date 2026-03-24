class alu_monitor #(parameter WIDTH = 8);
    // 宣告虛擬介面 (指向實體 interface)
    virtual alu_if v_if;
  
 	logic [WIDTH-1:0] prev_a, prev_b;
    logic             prev_op;
    
    // 建構子：把實體介面傳進來
    function new(virtual alu_if if_in);
        this.v_if = if_in;
    endfunction

    // 啟動監控的任務
    task run();
        $display("[%0t] [Monitor] Class-based monitor started.", $time);
        forever begin
            // 1. 等待時鐘正緣
          @(v_if.mon_cb);//@(posedge v_if.cb);
            
            // 2. 只有在重置釋放時才採樣
            if (v_if.rst_n) begin
                // 建立一個新的 Transaction 物件來存放這一拍的資料
              	alu_transaction #(.WIDTH(WIDTH)) tr;
                tr = new();
                
                // 採樣訊號 (注意：因為是同步電路，這裡抓到的是當前輸出的結果)
                tr.a        = v_if.mon_cb.a;
                tr.b        = v_if.mon_cb.b;
                tr.op       = v_if.mon_cb.op;
                tr.result   = v_if.result;
                tr.overflow = v_if.overflow;
                
                // 3. 印出結果或傳給 Scoreboard
                tr.display("MONITOR_CAPTURE");
            end
        end
    endtask
endclass