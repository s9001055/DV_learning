`ifndef AXI_BASE_TEST_SV
`define AXI_BASE_TEST_SV

import uvm_pkg::*;
import axi_pkg::*;
`include "uvm_macros.svh"

class axi_base_test extends uvm_test;
    `uvm_component_utils(axi_base_test)

    axi_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axi_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info(get_type_name(), "Base test starting", UVM_LOW)
        #1us;   // 讓 reset 完成
        run_test_body();
        #500ns;
        phase.drop_objection(this);
    endtask

    virtual task run_test_body();
        // 子類覆寫這個
    endtask

endclass : axi_base_test

`endif
