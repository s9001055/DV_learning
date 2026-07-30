`ifndef AXI_AGENT_SV
`define AXI_AGENT_SV

typedef enum { 
    AXI_MASTER, 
    AXI_SLAVE 
} axi_agent_role_e;

class axi_agent extends uvm_agent;
    `uvm_component_utils(axi_agent)

    axi_agent_role_e role = AXI_MASTER;

    axi_mst_driver mst_drv;
    axi_sequencer  sqr;
    axi_monitor    mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'(uvm_config_db#(axi_agent_role_e)::get(this, "", "role", role));

        mon = axi_monitor::type_id::create("mon", this);

        if (get_is_active() == UVM_ACTIVE) begin
            sqr = axi_sequencer::type_id::create("sqr", this);
            if (role == AXI_MASTER)
                mst_drv = axi_mst_driver::type_id::create("mst_drv", this);
            else
                slv_drv = axi_slv_driver::type_id::create("slv_drv", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (get_is_active() == UVM_ACTIVE) begin
            if (role == AXI_MASTER)
                mst_drv.seq_item_port.connect(sqr.seq_item_export);
            // Slave driver 不用 sequencer(靠 handle_* task 自主回應)
        end
    endfunction

endclass : axi_agent

`endif
