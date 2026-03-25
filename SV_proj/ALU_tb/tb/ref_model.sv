class alu_ref_model #(parameter WIDTH = 8);
  mailbox #(alu_transaction) mbx_mon; // 收 in monitor tr 的 mailbox
  mailbox #(alu_transaction) mbx_scb; // 收 in monitor tr 的 mailbox
  
  	logic [WIDTH-1:0] result;
  	logic overflow;
    
    // 建構子：把實體介面傳進來
  function new(mailbox #(alu_transaction) mbx_in, mailbox #(alu_transaction) mbx_out);
    	this.mbx_mon = mbx_in;
    	this.mbx_scb = mbx_out;
  endfunction
  
  task run();
     forever begin
         alu_transaction tr;
			
         alu_transaction #(.WIDTH(WIDTH)) out_tr;
         out_tr = new();
       
         // 1. 從信箱拿資料 (如果信箱是空的，這行會擋住直到有資料進來)
         mbx_mon.get(tr);
         if (tr.op == 0) begin
           result = tr.a + tr.b;
           overflow = (~(tr.a ^ tr.b) & (tr.a ^ result)) & (1 << (WIDTH - 1));
         end
       	 else if (tr.op == 1) begin
           result = tr.a - tr.b;
           overflow = ((tr.a ^ tr.b) & (tr.a ^ result)) & (1 << (WIDTH - 1));
         end
       	 

       	 
       	 out_tr.result = result;
         out_tr.overflow = overflow;

       $display("[REF_MODEL] MODEL A:%d B:%d Op:%b | result:%d overflow:%d ", $signed(tr.a), $signed(tr.b), tr.op, $signed(out_tr.result), out_tr.overflow);
     end
  endtask
  
endclass