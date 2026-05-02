import uvm_pkg::*;
`include "uvm_macros.svh"

`include "ahb_defines.svh"

// =============================================================================
// ahb_monitor.sv - AHB-Lite Protocol Monitor
//
// Observes the AHB bus passively, reconstructs completed transactions,
// and broadcasts them to subscribers (scoreboard, coverage collector).
// =============================================================================
class ahb_monitor extends uvm_monitor;
    `uvm_component_utils(ahb_monitor)

    // Virtual interface (monitor modport - read-only)
    virtual ahb_if.monitor_mp vif;

    // Analysis port - broadcasts completed transactions
    uvm_analysis_port #(ahb_seq_item) ap;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(string name = "ahb_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // -------------------------------------------------------------------------
    // Build Phase
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual ahb_if.monitor_mp)::get(
                this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "ahb_monitor: virtual interface not found in config_db")
    endfunction

    // -------------------------------------------------------------------------
    // Run Phase - continuously sample bus
    // -------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        ahb_seq_item trans;

        // Wait for reset
        @(posedge vif.HCLK iff vif.HRESETn === 1'b1);

        forever begin
            // ------------------------------------------------------------------
            // Wait for an active address phase
            // ------------------------------------------------------------------
            @(vif.monitor_cb);
            if (vif.monitor_cb.HSEL &&
                (vif.monitor_cb.HTRANS == 2'b10 ||   // NONSEQ
                 vif.monitor_cb.HTRANS == 2'b11)) begin  // SEQ

                trans            = ahb_seq_item::type_id::create("mon_trans");
                trans.addr       = vif.monitor_cb.HADDR;
                trans.write      = vif.monitor_cb.HWRITE;
                trans.size       = ahb_seq_item::hsize_e'(vif.monitor_cb.HSIZE);
                trans.burst      = ahb_seq_item::hburst_e'(vif.monitor_cb.HBURST);
                trans.trans      = ahb_seq_item::htrans_e'(vif.monitor_cb.HTRANS);

                // --------------------------------------------------------------
                // Data phase (next cycle, respect HREADYOUT)
                // --------------------------------------------------------------
                do @(vif.monitor_cb); while (!vif.monitor_cb.HREADYOUT);

                trans.hresp  = vif.monitor_cb.HRESP;
                trans.hready = vif.monitor_cb.HREADYOUT;

                if (trans.write) begin
                    trans.data  = vif.monitor_cb.HWDATA;
                    trans.rdata = '0;
                end else begin
                    trans.data  = '0;
                    trans.rdata = vif.monitor_cb.HRDATA;
                end

                `uvm_info("MON", trans.convert2string(), UVM_HIGH)
                ap.write(trans);
            end
        end
    endtask

endclass : ahb_monitor
