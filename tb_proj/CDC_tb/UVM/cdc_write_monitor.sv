`include "uvm_macros.svh"
`include "cdc_defines.svh"
import uvm_pkg::*;

// ─────────────────────────────────────────────────────────────────────────────
// Write Monitor
// ─────────────────────────────────────────────────────────────────────────────
class fifo_write_monitor extends uvm_monitor;
    `uvm_component_utils(fifo_write_monitor)

    virtual cdc_fifo_if vif;
    uvm_analysis_port #(fifo_write_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual cdc_fifo_if)::get(
                this, "", "vif", vif))
            `uvm_fatal("MON_W", "Cannot get vif from config_db")
    endfunction

    task run_phase(uvm_phase phase);
        fifo_write_item tr;

        // 等待 reset 釋放
        @(posedge vif.WCLK iff vif.WRST_N);

        forever begin
            // 等 WINC=1 且 WFULL=0（有效寫入）
            @(posedge vif.WCLK iff
                (vif.WINC && !vif.WFULL));

            tr = fifo_write_item::type_id::create("wr_tr");
            tr.data = vif.WDATA;

            `uvm_info("MON_W", tr.convert2string(), UVM_MEDIUM)
            ap.write(tr);
        end
    endtask
endclass