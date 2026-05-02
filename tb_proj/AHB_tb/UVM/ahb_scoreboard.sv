import uvm_pkg::*;
`include "uvm_macros.svh"

`include "ahb_defines.svh"

// =============================================================================
// ahb_scoreboard.sv - Self-Checking Scoreboard (Reference Model)
//
// Maintains a software model of DUT memory.
// On every write: updates the model.
// On every read:  compares HRDATA against model prediction.
// =============================================================================
class ahb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ahb_scoreboard)

    // Analysis import - receives transactions from monitor
    uvm_analysis_imp #(ahb_seq_item, ahb_scoreboard) analysis_export;

    // -------------------------------------------------------------------------
    // Reference Memory Model
    // -------------------------------------------------------------------------
    // Byte-addressed; we store 1 byte per entry and word-stitch as needed
    logic [7:0] ref_mem [int unsigned];  // sparse associative array

    // Statistics
    int unsigned checks_passed;
    int unsigned checks_failed;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(string name = "ahb_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        checks_passed = 0;
        checks_failed = 0;
    endfunction

    // -------------------------------------------------------------------------
    // Build Phase
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
    endfunction

    // -------------------------------------------------------------------------
    // write() - called by analysis port on every completed transaction
    // -------------------------------------------------------------------------
    function void write(ahb_seq_item t);
        if (t.write)
            do_write(t);
        else
            do_read(t);
    endfunction

    // -------------------------------------------------------------------------
    // Reference Model - Write
    // -------------------------------------------------------------------------
    function void do_write(ahb_seq_item t);
        case (t.size)
            ahb_seq_item::HSIZE_BYTE: begin
                ref_mem[t.addr] = t.data[7:0];
            end
            ahb_seq_item::HSIZE_HALFWORD: begin
                ref_mem[t.addr]   = t.data[7:0];
                ref_mem[t.addr+1] = t.data[15:8];
            end
            default: begin  // WORD
                ref_mem[t.addr]   = t.data[7:0];
                ref_mem[t.addr+1] = t.data[15:8];
                ref_mem[t.addr+2] = t.data[23:16];
                ref_mem[t.addr+3] = t.data[31:24];
            end
        endcase
        `uvm_info("SB", $sformatf("REF_WRITE addr=0x%08h data=0x%08h size=%s",
                  t.addr, t.data, t.size.name()), UVM_HIGH)
    endfunction

    // -------------------------------------------------------------------------
    // Reference Model - Read & Check
    // -------------------------------------------------------------------------
    function void do_read(ahb_seq_item t);
        logic [31:0] expected;
        logic [7:0]  b0, b1, b2, b3;

        case (t.size)
            ahb_seq_item::HSIZE_BYTE: begin
                b0 = ref_mem.exists(t.addr) ? ref_mem[t.addr] : 8'h00;
                expected = {24'h0, b0};
            end
            ahb_seq_item::HSIZE_HALFWORD: begin
                b0 = ref_mem.exists(t.addr)   ? ref_mem[t.addr]   : 8'h00;
                b1 = ref_mem.exists(t.addr+1) ? ref_mem[t.addr+1] : 8'h00;
                expected = {16'h0, b1, b0};
            end
            default: begin  // WORD
                b0 = ref_mem.exists(t.addr)   ? ref_mem[t.addr]   : 8'h00;
                b1 = ref_mem.exists(t.addr+1) ? ref_mem[t.addr+1] : 8'h00;
                b2 = ref_mem.exists(t.addr+2) ? ref_mem[t.addr+2] : 8'h00;
                b3 = ref_mem.exists(t.addr+3) ? ref_mem[t.addr+3] : 8'h00;
                expected = {b3, b2, b1, b0};
            end
        endcase

        if (t.rdata === expected) begin
            checks_passed++;
            `uvm_info("SB", $sformatf("PASS addr=0x%08h exp=0x%08h got=0x%08h",
                      t.addr, expected, t.rdata), UVM_HIGH)
        end else begin
            checks_failed++;
            `uvm_error("SB", $sformatf("FAIL addr=0x%08h exp=0x%08h got=0x%08h",
                       t.addr, expected, t.rdata))
        end
    endfunction

    // -------------------------------------------------------------------------
    // Report Phase - print summary
    // -------------------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        `uvm_info("SB", $sformatf(
            "=== SCOREBOARD SUMMARY: PASSED=%0d  FAILED=%0d ===",
            checks_passed, checks_failed), UVM_NONE)
        if (checks_failed > 0)
            `uvm_error("SB", "TEST FAILED - scoreboard detected errors")
        else if (checks_passed == 0)
            `uvm_warning("SB", "No read checks were performed!")
    endfunction

endclass : ahb_scoreboard
