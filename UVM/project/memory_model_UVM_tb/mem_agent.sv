// 將 driver 跟 monitor 封裝成 agent

`include "mem_seq_item.sv"
`include "mem_sequencer.sv"
`include "mem_sequence.sv"
`include "mem_driver.sv"
`include "mem_monitor.sv"

class mem_agent extends uvm_agent;

  // component instances
  mem_driver    driver;
  mem_sequencer sequencer;
  mem_monitor   monitor;

  `uvm_component_utils(mem_agent)
  
  // constructor
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction : new

  // build_phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // 實例化 monitor
    monitor = mem_monitor::type_id::create("monitor", this);

    // 根據 get_is_active() 來判斷是否 實例化 driver 跟 sequencer
    if(get_is_active() == UVM_ACTIVE) begin
      driver    = mem_driver::type_id::create("driver", this);
      sequencer = mem_sequencer::type_id::create("sequencer", this);
    end
  endfunction : build_phase
    
  // connect_phase
  // 連接 driver sequencer 的 port
  function void connect_phase(uvm_phase phase);
    if(get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction : connect_phase

endclass : mem_agent