import uvm_pkg::*;
`include "uvm_macros.svh"

`include "ahb_defines.svh"

// =============================================================================
// ahb_env.sv - UVM Environment
// =============================================================================
class ahb_env extends uvm_env;
    `uvm_component_utils(ahb_env)

    ahb_agent      agent;
    ahb_scoreboard scoreboard;
    // ahb_coverage   coverage;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(string name = "ahb_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // -------------------------------------------------------------------------
    // Build Phase
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = ahb_agent::type_id::create("agent", this);
        scoreboard = ahb_scoreboard::type_id::create("scoreboard", this);
        // coverage   = ahb_coverage::type_id::create("coverage", this);
    endfunction

    // -------------------------------------------------------------------------
    // Connect Phase
    // -------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        // Agent analysis port -> Scoreboard
        agent.ap.connect(scoreboard.analysis_export);
        // Agent analysis port -> Coverage
        // agent.ap.connect(coverage.analysis_export);
    endfunction

endclass : ahb_env
