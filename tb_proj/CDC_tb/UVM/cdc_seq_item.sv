    // =========================================================================
    // Write Transaction Item
    // =========================================================================
    class fifo_write_item extends uvm_sequence_item;
        `uvm_object_utils(fifo_write_item)

        rand logic [DATA_WIDTH-1:0] data;
        rand int unsigned            gap_cycles; // 寫入之間的空閒週期數

        constraint c_gap { gap_cycles inside {[0:3]}; }

        function new(string name = "fifo_write_item");
            super.new(name);
        endfunction

        function string convert2string();
            return $sformatf("WRITE data=0x%02h gap=%0d", data, gap_cycles);
        endfunction
    endclass

    // =========================================================================
    // Read Transaction Item
    // =========================================================================
    class fifo_read_item extends uvm_sequence_item;
        `uvm_object_utils(fifo_read_item)

        logic [DATA_WIDTH-1:0] data;      // 由 monitor 填入
        rand int unsigned       gap_cycles;

        constraint c_gap { gap_cycles inside {[0:3]}; }

        function new(string name = "fifo_read_item");
            super.new(name);
        endfunction

        function string convert2string();
            return $sformatf("READ  data=0x%02h gap=%0d", data, gap_cycles);
        endfunction
    endclass