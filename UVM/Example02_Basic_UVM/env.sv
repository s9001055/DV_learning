class my_env extends uvm_env;
    my_driver drv;
    my_monitor i_mon;   // 宣告 input monitor

    my_monitor o_mon;   // 宣告 output monitor

    function new(string name = "my_env", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // 使用 factory 的實例化方法 my_driver::type_id::create
        // 才能使用factory機制中的重載功能
        drv = my_driver::type_id::create("drv", this); 
        i_mon = my_monitor::type_id::create("i_mon", this);
        o_mon = my_monitor::type_id::create("o_mon", this);
    endfunction

    `uvm_component_utils(my_env)
endclass