`include "apb_defines.svh"

class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    virtual apb_if.monitor_mp vif;

    // Analysis port：連到 Scoreboard / Coverage
    uvm_analysis_port #(apb_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual apb_if.monitor_mp)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "apb_monitor: cannot get virtual interface from config_db")
    endfunction

    task run_phase(uvm_phase phase);
        apb_item tr;

        // 等待 Reset 釋放
        @(posedge vif.PCLK iff vif.PRESETn === 1'b1);
        `uvm_info("APB_MON", "Reset released, monitoring started", UVM_LOW)

        forever begin
            // 等待 SETUP 相位（PSEL=1, PENABLE=0）
            @(vif.monitor_cb iff (vif.monitor_cb.PSEL && !vif.monitor_cb.PENABLE));

            tr = apb_item::type_id::create("mon_tr");
            tr.paddr  = vif.monitor_cb.PADDR;
            tr.pwrite = vif.monitor_cb.PWRITE;
            tr.pwdata = vif.monitor_cb.PWDATA;
            tr.pstrb  = vif.monitor_cb.PSTRB;

            // 等待 ACCESS 完成（PSEL=1, PENABLE=1, PREADY=1）
            @(vif.monitor_cb iff (vif.monitor_cb.PSEL   &&
                                   vif.monitor_cb.PENABLE &&
                                   vif.monitor_cb.PREADY));

            tr.prdata  = vif.monitor_cb.PRDATA;
            tr.pslverr = vif.monitor_cb.PSLVERR;

            `uvm_info("APB_MON", tr.convert2string(), UVM_MEDIUM)
            ap.write(tr);
        end
    endtask

endclass
