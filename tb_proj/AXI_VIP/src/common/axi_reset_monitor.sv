`ifndef AXI_RESET_MONITOR_SV
`define AXI_RESET_MONITOR_SV

class axi_reset_monitor extends uvm_component;
    `uvm_component_utils(axi_reset_monitor)

    virtual axi_if vif;
    axi_reset_config rst_cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Cannot get axi_if from config_db")
    endfunction

    task run_phase(uvm_phase phase);

    endtask

endclass : axi_reset_monitor

`endif
