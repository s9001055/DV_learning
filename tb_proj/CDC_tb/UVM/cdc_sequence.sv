`include "uvm_macros.svh"
`include "cdc_defines.svh"
import uvm_pkg::*;

// ─── Base sequence ───────────────────────────────────────────────────────────
class fifo_base_write_seq extends uvm_sequence #(fifo_write_item);
    `uvm_object_utils(fifo_base_write_seq)
    function new(string name="fifo_base_write_seq"); super.new(name); endfunction

    task write_data(logic [`CDC_DATA_WIDTH-1:0] d, int gap=0);
        fifo_write_item tr = fifo_write_item::type_id::create("tr");
        start_item(tr);
        tr.data       = d;
        tr.gap_cycles = gap;
        finish_item(tr);
    endtask
endclass

class fifo_base_read_seq extends uvm_sequence #(fifo_read_item);
    `uvm_object_utils(fifo_base_read_seq)
    function new(string name="fifo_base_read_seq"); super.new(name); endfunction

    task read_one(int gap=0);
        fifo_read_item tr = fifo_read_item::type_id::create("tr");
        start_item(tr);
        tr.gap_cycles = gap;
        finish_item(tr);
    endtask
endclass

// 基本寫入
class seq_basic_write extends fifo_base_write_seq;
    `uvm_object_utils(seq_basic_write)
    rand int unsigned n;
    constraint c_n { n inside {[4:8]}; }
    function new(string name="seq_basic_write"); super.new(name); endfunction

    task body();
        `uvm_info("SEQ", $sformatf("Basic write: %0d items", n), UVM_LOW)
        for (int i = 0; i < n; i++)
            write_data(8'hA0 + i, 1);  // 固定資料便於 debug
    endtask
endclass

// 基本讀出
class seq_basic_read extends fifo_base_read_seq;
    `uvm_object_utils(seq_basic_read)
    rand int unsigned n;
    constraint c_n { n inside {[4:8]}; }
    function new(string name="seq_basic_read"); super.new(name); endfunction

    task body();
        `uvm_info("SEQ", $sformatf("Basic read: %0d items", n), UVM_LOW)
        for (int i = 0; i < n; i++)
            read_one(1);
    endtask
endclass