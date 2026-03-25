class alu_driver;
    virtual alu_if v_if;
    mailbox #(alu_transaction) mbx; // 定義存放 Transaction 的信箱

    function new(virtual alu_if if_in, mailbox #(alu_transaction) mbx_in);
        this.v_if = if_in;
        this.mbx  = mbx_in;
    endfunction

    task run();
        $display("[%0t] [Driver] Class-based driver started.", $time);
        forever begin
            alu_transaction tr;
            
            // 1. 從信箱拿資料 (如果信箱是空的，這行會擋住直到有資料進來)
            mbx.get(tr);
            
            // 2. 驅動到介面上
          @(posedge v_if.clk);
            //#1; // 模擬 Hold time
            v_if.a  <= tr.a;
            v_if.b  <= tr.b;
            v_if.op <= tr.op;
            
          $display("[%0t] [Driver] Drive A:%d B:%d Op:%b", $time, $signed(tr.a), $signed(tr.b), tr.op);
        end
    endtask
endclass