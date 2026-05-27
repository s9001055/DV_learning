import uvm_pkg::*

// ─────────────────────────────────────────────────────────────────────────────
// Read Driver
// ─────────────────────────────────────────────────────────────────────────────
class fifo_read_driver extends uvm_driver #(fifo_read_item);
    `uvm_component_utils(fifo_read_driver)

    virtual cdc_fifo_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual cdc_fifo_if)::get(
                this, "", "vif", vif))
            `uvm_fatal("RDRV", "Cannot get vif from config_db")
    endfunction

    task run_phase(uvm_phase phase);
        fifo_read_item tr;

        // 等待 reset 釋放
        @(posedge vif.RCLK iff vif.RRST_N);
        @(posedge vif.RCLK);

        forever begin
            seq_item_port.get_next_item(tr);
            drive_item(tr);
            seq_item_port.item_done();
        end
    endtask

    task drive_item(fifo_read_item tr);
        // 若 FIFO 空，等到有資料
        while (vif.REMPTY) begin
            `uvm_info("RDRV", "FIFO empty, waiting...", UVM_HIGH)
            @(vif.RCLK);
        end

        // 透過 clocking block 驅動
        vif.RINC <= 1'b1;
        @(vif.RCLK);

        vif.RINC <= 1'b0;

        // 空閒週期
        repeat(tr.gap_cycles) @(vif.RCLK);
    endtask
endclass