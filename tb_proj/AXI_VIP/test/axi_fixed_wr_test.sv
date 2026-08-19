`ifndef AXI_FIXED_RW_TEST_SV
`define AXI_FIXED_RW_TEST_SV

class axi_fixed_rw_test extends axi_base_test;
    `uvm_component_utils(axi_fixed_rw_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_test_body();
        axi_fixed_wr_seq seq = axi_fixed_wr_seq::type_id::create("seq");
        if(!seq.randomize()) begin
            `uvm_error("MST_DRV", "axi_fixed_rw_test randomize fail")
        end
        seq.start(env.mst_agent.mst_sqr);
    endtask

endclass : axi_fixed_rw_test

`endif
