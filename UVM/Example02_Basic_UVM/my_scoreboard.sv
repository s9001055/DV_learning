
// my_scoreboard要比較的資料 一是來源於reference model，二是來源於o_agt的monitor。
// 前者通過exp_port獲取，而後者通過act_port獲取。
class my_scoreboard extends uvm_scoreboard;
   my_transaction  expect_queue[$];

   // 與 reference model 串接
   uvm_blocking_get_port #(my_transaction)  exp_port;

   // 與 o_agt 的 monitor 串接
   uvm_blocking_get_port #(my_transaction)  act_port;
   `uvm_component_utils(my_scoreboard)

   extern function new(string name, uvm_component parent = null);
   extern virtual function void build_phase(uvm_phase phase);
   extern virtual task main_phase(uvm_phase phase);
endclass 

function my_scoreboard::new(string name, uvm_component parent = null);
   super.new(name, parent);
endfunction 

function void my_scoreboard::build_phase(uvm_phase phase);
   super.build_phase(phase);
   exp_port = new("exp_port", this);
   act_port = new("act_port", this);
endfunction 

task my_scoreboard::main_phase(uvm_phase phase);
   my_transaction  get_expect,  get_actual, tmp_tran;
   bit result;
 
   super.main_phase(phase);

   // 在main_phase中通過fork建立起了兩個進程
   fork 
      // thread 0
      // exp_port的資料，當收到資料後，把資料放入expect_queue中
      while (1) begin
         exp_port.get(get_expect);
         expect_queue.push_back(get_expect);
      end

      // thread 1
      // 處理act_port的資料，這是DUT的輸出資料
      // 當收集到這些資料後，從expect_queue中彈出之前從exp_port收到的資料，並調用my_transaction的my_compare函數
      while (1) begin
         act_port.get(get_actual);
         if(expect_queue.size() > 0) begin
            tmp_tran = expect_queue.pop_front();
            result = get_actual.my_compare(tmp_tran);
            if(result) begin 
               `uvm_info("my_scoreboard", "Compare SUCCESSFULLY", UVM_LOW);
            end
            else begin
               `uvm_error("my_scoreboard", "Compare FAILED");
               $display("the expect pkt is");
               tmp_tran.my_print();
               $display("the actual pkt is");
               get_actual.my_print();
            end
         end
         else begin
            `uvm_error("my_scoreboard", "Received from DUT, while Expect Queue is empty");
            $display("the unexpected pkt is");
            get_actual.my_print();
         end 
      end
   join
endtask

