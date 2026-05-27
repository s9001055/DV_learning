`include "uvm_macros.svh"
`include "cdc_defines.svh"
import uvm_pkg::*;

// ─────────────────────────────────────────────────────────────────────────────
// Read Agent
// ─────────────────────────────────────────────────────────────────────────────
class cdc_read_agent extends uvm_agent;
    `uvm_component_utils(cdc_read_agent)

    fifo_read_driver  driver;
    fifo_read_monitor monitor;
    uvm_sequencer #(fifo_read_item) sequencer;

    uvm_analysis_port #(fifo_read_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap      = new("ap", this);
        monitor = fifo_read_monitor::type_id::create("monitor", this);

        if (get_is_active() == UVM_ACTIVE) begin
            driver    = fifo_read_driver::type_id::create("driver", this);
            sequencer = uvm_sequencer #(fifo_read_item)::type_id::create(
                            "sequencer", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        if (get_is_active() == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);
        monitor.ap.connect(ap);
    endfunction
endclass