`ifndef WB_MONITOR_SV
`define WB_MONITOR_SV

class wb_monitor extends uvm_monitor;
    `uvm_component_utils(wb_monitor)

    virtual wb_if vif;
    reset_monitor rst_mon;

    uvm_analysis_port #(wb_transaction) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual wb_if)::get(this, "", "wb_vif", vif))
            `uvm_fatal("WB_MON", "Failed to get wb_vif from config_db")

        if (!uvm_config_db#(reset_monitor)::get(this, "", "rst_mon", rst_mon)) begin
            `uvm_fatal(get_type_name(), "Cannot get rst_mon from config_db")
        end
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            if (rst_mon.in_reset) begin
                rst_mon.ev_reset_done.wait_trigger();
            end

            fork
                collect_transfer();

                begin : reset_thread
                    rst_mon.ev_reset_start.wait_trigger();
                end
            join_any

            disable fork;
        end
    endtask

    virtual task collect_transfer();
        wb_transaction tr;

        forever begin
            // Wait for valid bus cycle
            @(vif.mon_cb);
            while (!(vif.mon_cb.cyc && vif.mon_cb.stb)) @(vif.mon_cb);

            // Capture request
            tr.addr      = vif.mon_cb.adr;
            tr.data      = vif.mon_cb.dat_i;
            tr.sel       = vif.mon_cb.sel;
            tr.direction = vif.mon_cb.we ? WB_WRITE : WB_READ;

            // Wait for ACK
            while (!vif.mon_cb.ack && !vif.mon_cb.err) @(vif.mon_cb);

            // Capture response
            tr.rdata = vif.mon_cb.dat_o;
            tr.error = vif.mon_cb.err;

            ap.write(tr);

            `uvm_info("WB_MON", tr.convert2string(), UVM_HIGH)
        end
    endtask

endclass : wb_monitor

`endif
