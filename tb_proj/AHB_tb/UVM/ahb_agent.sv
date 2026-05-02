import uvm_pkg::*;
`include "uvm_macros.svh"

`include "ahb_defines.svh"

// =============================================================================
// ahb_agent.sv - AHB Agent (Active)
// =============================================================================
class ahb_agent extends uvm_agent;
    `uvm_component_utils(ahb_agent)

    // Sub-components
    ahb_driver    driver;
    ahb_monitor   monitor;
    ahb_sequencer #(ahb_seq_item) sequencer;

    // Export analysis port upward to environment
    uvm_analysis_port #(ahb_seq_item) ap;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(string name = "ahb_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // -------------------------------------------------------------------------
    // Build Phase
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap        = new("ap", this);
        monitor   = ahb_monitor::type_id::create("monitor", this);
        if (get_is_active() == UVM_ACTIVE) begin
            driver    = ahb_driver::type_id::create("driver", this);
            sequencer = uvm_sequencer #(ahb_seq_item)::type_id::create("sequencer", this);
        end
    endfunction

    // -------------------------------------------------------------------------
    // Connect Phase
    // -------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        // Monitor analysis port -> Agent analysis port
        monitor.ap.connect(ap);
        // Driver -> Sequencer
        if (get_is_active() == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

endclass : ahb_agent
