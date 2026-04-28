import uvm_pkg::*;
`include "uvm_macros.svh"

`include "apb_defines.svh"

class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)

    // Sub-components
    apb_driver    driver;
    apb_monitor   monitor;
    uvm_sequencer #(apb_item) sequencer;

    // 轉發 Monitor 的 analysis port
    uvm_analysis_port #(apb_item) ap;

    // ACTIVE = 有 Driver；PASSIVE = 只有 Monitor
    uvm_active_passive_enum is_active = UVM_ACTIVE;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap      = new("ap", this);
        monitor = apb_monitor::type_id::create("monitor", this);
        if (is_active == UVM_ACTIVE) begin
            sequencer = uvm_sequencer #(apb_item)::type_id::create("sequencer", this);
            driver    = apb_driver::type_id::create("driver", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        if (is_active == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);
        monitor.ap.connect(ap);
    endfunction

endclass
