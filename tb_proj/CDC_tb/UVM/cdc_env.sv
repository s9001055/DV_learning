`include "uvm_macros.svh"
`include "cdc_defines.svh"
import uvm_pkg::*;

// ─────────────────────────────────────────────────────────────────────────────
// CDC Env
// ─────────────────────────────────────────────────────────────────────────────
class cdc_fifo_env extends uvm_env;
    `uvm_component_utils(cdc_fifo_env)

    cdc_write_agent  write_agent;
    cdc_read_agent   read_agent;
    cdc_scoreboard   scoreboard;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        write_agent = cdc_write_agent::type_id::create("write_agent", this);
        read_agent  = cdc_read_agent::type_id::create("read_agent",  this);
        scoreboard  = cdc_scoreboard::type_id::create("scoreboard",  this);
    endfunction

    function void connect_phase(uvm_phase phase);
        // Write Monitor → Scoreboard write_export
        write_agent.ap.connect(scoreboard.write_export);
        // Read Monitor  → Scoreboard read_export
        read_agent.ap.connect(scoreboard.read_export);
    endfunction
endclass