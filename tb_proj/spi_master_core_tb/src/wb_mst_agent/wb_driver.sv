`ifndef WB_DRIVER_SV
`define WB_DRIVER_SV

class wb_driver extends uvm_driver #(wb_transaction);
    `uvm_component_utils(wb_driver)

    virtual wb_if vif;
    reset_monitor rst_mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual wb_if)::get(this, "", "wb_vif", vif))
            `uvm_fatal("WB_DRV", "Failed to get wb_vif from config_db")

        if (!uvm_config_db#(reset_monitor)::get(this, "", "rst_mon", rst_mon)) begin
            `uvm_fatal(get_type_name(), "Cannot get rst_mon from config_db")
        end
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            if (rst_mon.in_reset) begin
                reset_signals();
                rst_mon.ev_reset_done.wait_trigger();
            end

            fork
                drive_transfer();

                begin : reset_thread
                    rst_mon.ev_reset_start.wait_trigger();
                end
            join_any

            disable fork;

            // 進入 reset，執行 reset
            reset_signals();
        end
    endtask

    virtual task reset_signals();
        vif.mst_cb.cyc   <= 1'b0;
        vif.mst_cb.stb   <= 1'b0;
        vif.mst_cb.we    <= 1'b0;
        vif.mst_cb.adr   <= '0;
        vif.mst_cb.dat_i <= '0;
        vif.mst_cb.sel   <= '0;
    endtask

    virtual task drive_transfer();
        wb_transaction tr;
        forever begin
            seq_item_port.get_next_item(tr);

            // Setup phase
            @(vif.mst_cb);
            vif.mst_cb.cyc   <= 1'b1;
            vif.mst_cb.stb   <= 1'b1;
            vif.mst_cb.we    <= (tr.direction == WB_WRITE);
            vif.mst_cb.adr   <= tr.addr;
            vif.mst_cb.dat_i <= tr.data;
            vif.mst_cb.sel   <= tr.sel;

            // Wait for ACK
            do @(vif.mst_cb);
            while (!vif.mst_cb.ack && !vif.mst_cb.err);

            // Capture response
            tr.rdata = vif.mst_cb.dat_o;
            tr.error = vif.mst_cb.err;

            // Deassert
            vif.mst_cb.cyc <= 1'b0;
            vif.mst_cb.stb <= 1'b0;
            vif.mst_cb.we  <= 1'b0;

            `uvm_info("WB_DRV", tr.convert2string(), UVM_HIGH)
            seq_item_port.item_done();
        end
    endtask

endclass : wb_driver

`endif
