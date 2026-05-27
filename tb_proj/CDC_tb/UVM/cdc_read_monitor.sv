`include "uvm_macros.svh"
`include "cdc_defines.svh"
import uvm_pkg::*;

// ─────────────────────────────────────────────────────────────────────────────
// Read Monitor
// ─────────────────────────────────────────────────────────────────────────────
class fifo_read_monitor extends uvm_monitor;
    `uvm_component_utils(fifo_read_monitor)

    virtual cdc_fifo_if vif;
    uvm_analysis_port #(fifo_read_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual cdc_fifo_if)::get(
                this, "", "vif", vif))
            `uvm_fatal("MON_R", "Cannot get vif from config_db")
    endfunction

    task run_phase(uvm_phase phase);
        fifo_read_item tr;

        // 等待 reset 釋放
        @(posedge vif.RCLK iff vif.RRST_N);

        forever begin
            // 有效讀取：RINC=1 且 REMPTY=0
            // RDATA 在同一拍有效（組合邏輯輸出），#1step 確保取樣穩定值
            @(posedge vif.RCLK iff
                (vif.RINC && !vif.REMPTY));

            tr = fifo_read_item::type_id::create("rd_tr");
            tr.data = vif.RDATA;

            `uvm_info("MON_R", tr.convert2string(), UVM_MEDIUM)
            ap.write(tr);
        end
    endtask
endclass