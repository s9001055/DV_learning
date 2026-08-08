`ifndef AXI_SLV_AGENT_SV
`define AXI_SLV_AGENT_SV

class axi_slv_agent extends uvm_agent;
    `uvm_component_utils(axi_slv_agent)

    axi_slv_driver      slv_drv;
    axi_sequencer       slv_sqr;
    axi_slv_monitor     slv_mon;
    axi_reset_monitor   rst_mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        slv_mon = axi_slv_monitor::type_id::create("slv_mon", this);

        if (get_is_active() == UVM_ACTIVE) begin
            slv_sqr = axi_sequencer::type_id::create("slv_sqr", this);
            slv_drv = axi_slv_driver::type_id::create("slv_drv", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        slv_mon.rst_mon = rst_mon;

        if (get_is_active() == UVM_ACTIVE) begin
            slv_drv.seq_item_port.connect(slv_sqr.seq_item_export);
            slv_drv.rst_mon = rst_mon;
        end
    endfunction

endclass : axi_slv_agent

`endif
