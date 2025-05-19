class my_env extends uvm_env;
    //// 還沒封裝成 agent
    // my_driver drv;
    // my_monitor i_mon;   // 宣告 input monitor
    // my_monitor o_mon;   // 宣告 output monitor

    // 封裝成 agent
    my_agent i_agt;
    my_agent o_agt;

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
    endfunction

    `uvm_component_utils(my_env)
endclass