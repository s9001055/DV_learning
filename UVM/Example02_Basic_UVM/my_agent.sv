class my_agent extends uvm_agent ;
    my_driver drv;
    my_monitor mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    extern virtual function void build_phase(uvm_phase phase);
    extern virtual function void connect_phase(uvm_phase phase);

    `uvm_component_utils(my_agent)
endclass


function void my_agent::build_phase(uvm_phase phase);
    super.build_phase(phase);

    // UVM_PASSIVE和UVM_ACTIVE。
    // 1. 在uvm_agent中，is_active的值默認為UVM_ACTIVE，在這種模式下，是需要產生實體driver
    // 2. UVM_PASSIVE使用在輸出埠上不需要驅動任何信號，只需要監測信號
    //    在這種情況下，埠上是只需要monitor的，所以driver可以不用產生實體
    if (is_active == UVM_ACTIVE) begin                      // 根據 is_active 來決定是否創建 driver 的實例
        drv = my_driver::type_id::create("drv", this);
    end
    mon = my_monitor::type_id::create("mon", this);
endfunction

function void my_agent::connect_phase(uvm_phase phase);
    super.connect_phase(phase);
endfunction