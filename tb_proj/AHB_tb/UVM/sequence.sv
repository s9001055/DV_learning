import uvm_pkg::*;
`include "uvm_macros.svh"

`include "ahb_defines.svh"

// -----------------------------------------------------------------------------
// Base Sequence
// -----------------------------------------------------------------------------
class ahb_base_seq extends uvm_sequence #(ahb_seq_item);
    `uvm_object_utils(ahb_base_seq)

    function new(string name = "ahb_base_seq");
        super.new(name);
    endfunction

    // Helper: single write
    task write_word(logic [`AHB_ADDR_WIDTH-1:0] addr, logic [`AHB_DATA_WIDTH-1:0] data);
        ahb_seq_item item;
        item           = ahb_seq_item::type_id::create("wr_item");
        if (!item.randomize() with {
            addr      == local::addr;
            data      == local::data;
            write     == 1'b1;
            size      == HSIZE_WORD;
            burst     == HBURST_SINGLE;
            burst_len == 1;
        }) `uvm_fatal("RAND", "write_word randomize failed")
        start_item(item);
        finish_item(item);
    endtask

    // Helper: single read
    task read_word(logic [`AHB_ADDR_WIDTH-1:0] addr, output logic [`AHB_DATA_WIDTH-1:0] rdata);
        ahb_seq_item item;
        item = ahb_seq_item::type_id::create("rd_item");
        if (!item.randomize() with {
            addr      == local::addr;
            write     == 1'b0;
            size      == HSIZE_WORD;
            burst     == HBURST_SINGLE;
            burst_len == 1;
        }) `uvm_fatal("RAND", "read_word randomize failed")
        start_item(item);
        finish_item(item);
        rdata = item.rdata;
    endtask

endclass : ahb_base_seq

// =============================================================================
// Sequence 1: Random Single Transfers
// =============================================================================
class ahb_rand_single_seq extends ahb_base_seq;
    `uvm_object_utils(ahb_rand_single_seq)

    int unsigned num_transfers = 50;

    function new(string name = "ahb_rand_single_seq");
        super.new(name);
    endfunction

    task body();
        ahb_seq_item item;
        repeat (num_transfers) begin
            item = ahb_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with {
                data      == addr;
                burst     == HBURST_SINGLE;
                burst_len == 1;
            }) `uvm_fatal("RAND", "Randomize failed")
            finish_item(item);
        end
    endtask

endclass : ahb_rand_single_seq

// =============================================================================
// Sequence 2: INCR Burst Write then Read-back
// =============================================================================
class ahb_incr_burst_seq extends ahb_base_seq;
    `uvm_object_utils(ahb_incr_burst_seq)

    int unsigned burst_length = 4;

    function new(string name = "ahb_incr_burst_seq");
        super.new(name);
    endfunction

    task body();
        ahb_seq_item wr, rd;

        // INCR WRITE burst
        wr = ahb_seq_item::type_id::create("wr_burst");
        if (!wr.randomize() with {
            addr[1:0] == 2'b00;
            write     == 1'b1;
            size      == HSIZE_WORD;
            burst     == HBURST_INCR;
            burst_len == local::burst_length;
            // ensure no address overflow
            addr + burst_len * 4 <= 32'h0000_0400;
        }) `uvm_fatal("RAND", "Randomize failed")
        start_item(wr); finish_item(wr);

        // INCR READ burst from same start address
        rd = ahb_seq_item::type_id::create("rd_burst");
        if (!rd.randomize() with {
            addr      == wr.addr;
            write     == 1'b0;
            size      == HSIZE_WORD;
            burst     == HBURST_INCR;
            burst_len == local::burst_length;
        }) `uvm_fatal("RAND", "Randomize failed")
        start_item(rd); finish_item(rd);
    endtask

endclass : ahb_incr_burst_seq