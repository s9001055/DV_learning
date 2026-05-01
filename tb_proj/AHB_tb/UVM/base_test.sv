import uvm_pkg::*;
`include "uvm_macros.svh"

`include "ahb_defines.svh"

// -----------------------------------------------------------------------------
// Base Test
// -----------------------------------------------------------------------------
class ahb_base_test extends uvm_test;
    `uvm_component_utils(ahb_base_test)

    ahb_env env;

    function new(string name = "ahb_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = ahb_env::type_id::create("env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction

endclass : ahb_base_test


// =============================================================================
// Test 1: Random Single Transfers
// =============================================================================
class ahb_rand_single_test extends ahb_base_test;
    `uvm_component_utils(ahb_rand_single_test)

    function new(string name = "ahb_rand_single_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        ahb_rand_single_seq seq;
        phase.raise_objection(this);
        seq = ahb_rand_single_seq::type_id::create("seq");
        seq.num_transfers = 100;
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass : ahb_rand_single_test


// =============================================================================
// Test 2: INCR Burst Test
// =============================================================================
class ahb_incr_burst_test extends ahb_base_test;
    `uvm_component_utils(ahb_incr_burst_test)

    function new(string name = "ahb_incr_burst_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        ahb_incr_burst_seq seq;
        phase.raise_objection(this);
        seq = ahb_incr_burst_seq::type_id::create("seq");
        seq.burst_length = 8;
        seq.start(env.agent.sequencer);
        phase.drop_objection(this);
    endtask

endclass : ahb_incr_burst_test