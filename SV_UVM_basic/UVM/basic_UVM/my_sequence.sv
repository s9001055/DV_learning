`ifndef MY_SEQUENCE__SV
`define MY_SEQUENCE__SV

class my_sequence extends uvm_sequence #(my_transaction);
   my_transaction m_trans;

   function new(string name= "my_sequence");
      super.new(name);
   endfunction

   // uvm_do() 產生了一個transaction並交給sequencer，
   // driver取走這個transaction後，uvm_do()並不會立刻返回執行下一次的uvm_do，
   // 而是等待在那裡，直到driver返回 item_done信號。
   // 此時，uvm_do()才算是執行完畢，返回後開始執行下一個uvm_do()，並產生新的transaction。
   virtual task body();
      if(starting_phase != null) 
         starting_phase.raise_objection(this);
      repeat (10) begin
         `uvm_do(m_trans)
      end
      #1000;
      if(starting_phase != null) 
         starting_phase.drop_objection(this);
   endtask

   // 為什麼使用 uvm_object_utils 而不是 uvm_component_utils
   // 因為 sequence 有生命周期，不像 Driver 在整個模擬期間都會存在
   // 所以沒有使用 factory 機制的 uvm_component_utils 
   `uvm_object_utils(my_sequence)
endclass
`endif
