`ifndef AXI_MST_AGENT_SV
`define AXI_MST_AGENT_SV

class axi_mst_agent extends uvm_agent;
    `uvm_component_utils(axi_mst_agent)

    axi_mst_driver      mst_drv;
    axi_sequencer       mst_sqr;
    axi_mst_monitor     mst_mon;
    axi_reset_monitor   rst_mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mst_mon = axi_mst_monitor::type_id::create("mst_mon", this);

        if (get_is_active() == UVM_ACTIVE) begin
            mst_sqr = axi_sequencer::type_id::create("mst_sqr", this);
            mst_drv = axi_mst_driver::type_id::create("mst_drv", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        mst_mon.rst_mon = rst_mon;

        if (get_is_active() == UVM_ACTIVE) begin
            mst_drv.seq_item_port.connect(mst_sqr.seq_item_export);
            mst_drv.rst_mon = rst_mon;
        end
    endfunction

endclass : axi_mst_agent

`endif
