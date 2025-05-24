`ifndef MY_DRIVER__SV
`define MY_DRIVER__SV

// 由於是從 sequencer 那邊接收 transaction 所以需要改成接收 my_transaction
class my_driver extends uvm_driver#(my_transaction);

   virtual my_if vif;

   `uvm_component_utils(my_driver)
   function new(string name = "my_driver", uvm_component parent = null);
      // 這個new函數有兩個參數，
      // 第一個參數是實例的名字，
      // 第二個則是parent。
      // 由於my_driver在uvm_env中產生實體，
      // 所以my_driver 的父結點（parent）就是my_env
      super.new(name, parent);
   endfunction

   virtual function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      // 與 top_tb 的 interface 對接
      if(!uvm_config_db#(virtual my_if)::get(this, "", "vif", vif))
         `uvm_fatal("my_driver", "virtual interface must be set for vif!!!")
   endfunction

   extern task main_phase(uvm_phase phase);
   extern task drive_one_pkt(my_transaction tr);
endclass

task my_driver::main_phase(uvm_phase phase);
   vif.data <= 8'b0;
   vif.valid <= 1'b0;
   while(!vif.rst_n)
      @(posedge vif.clk);

   // driver 使用 seq_item_port.get_next_item 向 sequencer 申請 transaction
   // seq_item_port 為 uvm_driver 成員變數

   // driver 只負責驅動 transaction，不負責產生
   // 只要有 transaction 就驅動，所以必須做成一個無限迴圈的形式

   // sequencer 如何知道 driver 是否已經成功得到 transaction
   // 如果在下次調用 get_next_item 前，item_done 被調用
   // 那麼 sequencer 就認為 driver 已經得到了這個 transaction
   while(1) begin
      seq_item_port.get_next_item(req);
      drive_one_pkt(req);
      seq_item_port.item_done();
   end
endtask

task my_driver::drive_one_pkt(my_transaction tr);
   byte unsigned     data_q[];
   int  data_size;
   
   data_size = tr.pack_bytes(data_q) / 8; 
   `uvm_info("my_driver", "begin to drive one pkt", UVM_LOW);
   repeat(3) @(posedge vif.clk);
   for ( int i = 0; i < data_size; i++ ) begin
      @(posedge vif.clk);
      vif.valid <= 1'b1;
      vif.data <= data_q[i]; 
   end

   @(posedge vif.clk);
   vif.valid <= 1'b0;
   `uvm_info("my_driver", "end drive one pkt", UVM_LOW);
endtask


`endif
