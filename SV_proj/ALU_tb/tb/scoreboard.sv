class alu_scoreboard #(parameter WIDTH = 8);
    mailbox #(alu_transaction) ref_mbx; // 收 ref model 的 mailbox
    mailbox #(alu_transaction) o_mon_mbx; // 收 out monitor 的 mailbox
    
    // 統計成功與失敗的次數
    int pass_count = 0;
    int fail_count = 0;  
  
    // 建構子：把實體介面傳進來
  	function new(mailbox #(alu_transaction) ref_mbx, mailbox #(alu_transaction) o_mon_mbx);
    	this.ref_mbx = ref_mbx;
      	this.o_mon_mbx = o_mon_mbx;
    endfunction
  
    task run();
        alu_transaction #(WIDTH) tr_ref, tr_mon;
        $display("[%0t] [Scoreboard] Scoreboard started.", $time);
            
        forever begin
            ref_mbx.get(tr_ref);
            o_mon_mbx.get(tr_mon);
        
            // 開始對答案
            if (tr_ref.result === tr_mon.result && tr_ref.overflow === tr_mon.overflow) begin
                pass_count++;
                $display("[%0t] [Scoreboard] PASS! A:%d B:%d Op:%b | Result:%d (Expected:%d) overflow:%d (Expected:%d)", 
                        $time, $signed(tr_ref.a), $signed(tr_ref.b), tr_ref.op, 
                        $signed(tr_mon.result), $signed(tr_ref.result), tr_mon.overflow, tr_ref.overflow);
            end else begin
                fail_count++;
                $display("[%0t] [Scoreboard] ERROR!!! MISMATCH!", $time);
                $display("       Actual   -> Result:%d, Over:%b", $signed(tr_mon.result), tr_mon.overflow);
                $display("       Expected -> Result:%d, Over:%b", $signed(tr_ref.result), tr_ref.overflow);
                // 這裡可以選擇是否要 $stop 停止模擬
            end
        end
    endtask

    // 模擬結束後印出總結
    function void report();
        $display("\n---------------------------------------");
        $display("  Verification Report Summary");
        $display("  PASSED: %0d", pass_count);
        $display("  FAILED: %0d", fail_count);
        $display("---------------------------------------\n");
    endfunction
endclass