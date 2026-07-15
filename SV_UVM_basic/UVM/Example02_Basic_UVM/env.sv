class my_env extends uvm_env;
    //// 還沒封裝成 agent
    // my_driver drv;
    // my_monitor i_mon;   // 宣告 input monitor
    // my_monitor o_mon;   // 宣告 output monitor

    // 封裝成 agent
    my_agent i_agt;
    my_agent o_agt;
    my_model  mdl;

    uvm_tlm_analysis_fifo #(my_transaction) agt_mdl_fifo;

    my_scoreboard scb;
   
    uvm_tlm_analysis_fifo #(my_transaction) agt_scb_fifo;
    uvm_tlm_analysis_fifo #(my_transaction) agt_mdl_fifo;
    uvm_tlm_analysis_fifo #(my_transaction) mdl_scb_fifo;

    function new(string name = "my_env", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        //// 還沒封裝成 agent
        //// 使用 factory 的實例化方法 my_driver::type_id::create
        //// 才能使用factory機制中的重載功能
        // drv = my_driver::type_id::create("drv", this); 
        // i_mon = my_monitor::type_id::create("i_mon", this);
        // o_mon = my_monitor::type_id::create("o_mon", this);

        // 封裝成 agent
        i_agt = my_agent::type_id::create("i_agt", this);
        o_agt = my_agent::type_id::create("o_agt", this);
        i_agt.is_active = UVM_ACTIVE;
        o_agt.is_active = UVM_PASSIVE;

        // 實例化 model
        mdl = my_model::type_id::create("mdl", this);

        // 在 my_monitor 和 my_model 中定義並實現了各自的埠之後
        // 使用 fifo 將兩個接口連在一起


        // 為什麼這裡需要一個fifo呢？
        // 不能直接把my_monitor中的analysis_port和my_model中的blocking_get_port相連嗎？
        // 由於analysis_port是非阻塞性質的，ap.write函式呼叫完成後馬上返回，不會等待資料被接收。
        // 假如當write函式呼叫時，blocking_get_port正在忙於其他事情，而沒有準備好接收新的資料時，
        // 此時被write函數寫入的my_transaction就需要一個暫存的位置，這就是fifo。
        agt_mdl_fifo = new("agt_mdl_fifo", this);

        // 實例化 my_scoreboard
        scb = my_scoreboard::type_id::create("scb", this);

        // 建立 agent 跟 scoreboard 之間的 FIFO
        agt_scb_fifo = new("agt_scb_fifo", this);

        // 建立 model 跟 scoreboard 之間的 FIFO
        mdl_scb_fifo = new("mdl_scb_fifo", this);
    endfunction

    extern virtual function void connect_phase(uvm_phase phase);

    `uvm_component_utils(my_env)
endclass


// connect_phase 在build_phase執行完成之後馬上執行。
// 但是與build_phase不同的是，它的執行順序並不是從樹根到樹葉，
// 而是從樹葉到樹根——先執行driver和monitor的connect_phase，
// 再執行agent的connect_phase，最後執行env的connect_phase。
function void my_env::connect_phase(uvm_phase phase);
   super.connect_phase(phase);
   i_agt.ap.connect(agt_mdl_fifo.analysis_export);
   mdl.port.connect(agt_mdl_fifo.blocking_get_export);

   // 將 model.ap 跟 mdl_scb_fifo 串接
   mdl.ap.connect(mdl_scb_fifo.analysis_export);
   // 將 scb.exp_port 跟 mdl_scb_fifo 串接
   scb.exp_port.connect(mdl_scb_fifo.blocking_get_export);

   // 將 o_agt.ap 跟 agt_scb_fifo 串接
   o_agt.ap.connect(agt_scb_fifo.analysis_export);
   // 將 scb.act_port 跟 agt_scb_fifo 串接
   scb.act_port.connect(agt_scb_fifo.blocking_get_export); 
endfunction