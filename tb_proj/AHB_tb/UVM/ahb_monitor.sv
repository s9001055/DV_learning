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
    virtual ahb_if vif;

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
        if (!uvm_config_db #(virtual ahb_if)::get(
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
            @(posedge vif.HCLK);
            if (vif.HSEL &&
                (vif.HTRANS == 2'b10 ||   // NONSEQ
                 vif.HTRANS == 2'b11)) begin  // SEQ

                trans            = ahb_seq_item::type_id::create("mon_trans");
                trans.addr       = vif.HADDR;
                trans.write      = vif.HWRITE;
                trans.size       = ahb_seq_item::hsize_e'(vif.HSIZE);
                trans.burst      = ahb_seq_item::hburst_e'(vif.HBURST);
                trans.trans      = ahb_seq_item::htrans_e'(vif.HTRANS);

                // --------------------------------------------------------------
                // Data phase (next cycle, respect HREADYOUT)
                // --------------------------------------------------------------
                do @(posedge vif.HCLK); while (!vif.HREADYOUT);

                trans.hresp  = vif.HRESP;
                trans.hready = vif.HREADYOUT;

                if (trans.write) begin
                    trans.data  = vif.HWDATA;
                    trans.rdata = '0;
                end else begin
                    trans.data  = '0;
                    trans.rdata = vif.HRDATA;
                end

                `uvm_info("MON", trans.convert2string(), UVM_HIGH)
                ap.write(trans);
            end
        end
    endtask

endclass : ahb_monitor
