`ifndef AXI_RANDOM_WR_TEST_SV
`define AXI_RANDOM_WR_TEST_SV

class axi_random_wr_test extends axi_base_test;
    `uvm_component_utils(axi_random_wr_test)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual task run_test_body();
        axi_random_wr_seq seq = axi_random_wr_seq::type_id::create("seq");
        if(!seq.randomize()) begin
            `uvm_error("INCR TEST", "axi_random_wr_test randomize fail")
        end
        seq.start(env.mst_agent.mst_sqr);
    endtask

endclass : axi_random_wr_test

`endif
