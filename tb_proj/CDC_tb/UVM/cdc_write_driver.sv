`include "uvm_macros.svh"
`include "cdc_defines.svh"
import uvm_pkg::*;

// ─────────────────────────────────────────────────────────────────────────────
// Write Driver
// ─────────────────────────────────────────────────────────────────────────────
class fifo_write_driver extends uvm_driver #(fifo_write_item);
    `uvm_component_utils(fifo_write_driver)

    virtual cdc_fifo_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual cdc_fifo_if)::get(
                this, "", "vif", vif))
            `uvm_fatal("DRV", "Cannot get vif from config_db")
    endfunction

    task run_phase(uvm_phase phase);
        fifo_write_item tr;

        // 等待 reset 釋放
        @(posedge vif.WCLK iff vif.WRST_N);
        @(posedge vif.WCLK);

        forever begin
            seq_item_port.get_next_item(tr);
            drive_item(tr);
            seq_item_port.item_done();
        end
    endtask

    task drive_item(fifo_write_item tr);
        // 若 FIFO 滿，等到有空位
        while (vif.WFULL) begin
            `uvm_info("WDRV", "FIFO full, waiting...", UVM_HIGH)
            @(posedge vif.WCLK);
        end

        // 透過 clocking block 驅動（有固定 skew，無 race condition）
        vif.WINC  <= 1'b1;
        vif.WDATA <= tr.data;
        @(posedge vif.WCLK);

        vif.WINC  <= 1'b0;
        vif.WDATA <= 'x;

        // 空閒週期（模擬非連續寫入）
        repeat(tr.gap_cycles) @(posedge vif.WCLK);
    endtask
endclass