`include "apb_defines.svh"

// -----------------------------------------------------------------------------
// Base Sequence
// -----------------------------------------------------------------------------
class apb_base_seq extends uvm_sequence #(apb_seq_item);
    `uvm_object_utils(apb_base_seq)
    function new(string name = "apb_base_seq"); super.new(name); endfunction

    // 便利任務：單筆寫入
    task do_write(logic [31:0] addr, logic [31:0] data, logic [3:0] strb = 4'hF);
        apb_seq_item tr = apb_seq_item::type_id::create("wr_tr");
        start_item(tr);
        if (!tr.randomize() with { paddr == addr; pwrite == 1; pwdata == data; pstrb == strb; })
            `uvm_fatal("SEQ", "Randomize failed")
        finish_item(tr);
    endtask

    // 便利任務：單筆讀取
    task do_read(logic [31:0] addr);
        apb_seq_item tr = apb_seq_item::type_id::create("rd_tr");
        start_item(tr);
        if (!tr.randomize() with { paddr == addr; pwrite == 0; })
            `uvm_fatal("SEQ", "Randomize failed")
        finish_item(tr);
    endtask
endclass

// -----------------------------------------------------------------------------
// Write-Then-Read Sequence（寫後讀回驗證）
// -----------------------------------------------------------------------------
class apb_wr_rd_seq extends apb_base_seq;
    `uvm_object_utils(apb_wr_rd_seq)
    rand logic [31:0] addr;
    rand logic [31:0] data;
    constraint c_align { addr[1:0] == 2'b00; }
    constraint c_range { addr inside {[32'h0:32'hFFC]}; }

    function new(string name = "apb_wr_rd_seq"); super.new(name); endfunction

    task body();
        do_write(addr, data, 4'hF);
        do_read(addr);
    endtask
endclass




