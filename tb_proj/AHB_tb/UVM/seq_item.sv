// =============================================================================
// ahb_seq_item.sv - AHB Transaction (Sequence Item)
// =============================================================================
class ahb_seq_item extends uvm_sequence_item;
    `uvm_object_utils(ahb_seq_item)

    // -------------------------------------------------------------------------
    // AHB Transfer Type Enums
    // -------------------------------------------------------------------------
    typedef enum logic [1:0] {
        HTRANS_IDLE   = 2'b00,
        HTRANS_BUSY   = 2'b01,
        HTRANS_NONSEQ = 2'b10,
        HTRANS_SEQ    = 2'b11
    } htrans_e;

    typedef enum logic [2:0] {
        HBURST_SINGLE = 3'b000,
        HBURST_INCR   = 3'b001
    } hburst_e;

    typedef enum logic [2:0] {
        HSIZE_BYTE     = 3'b000,
        HSIZE_HALFWORD = 3'b001,
        HSIZE_WORD     = 3'b010
    } hsize_e;

    // -------------------------------------------------------------------------
    // Randomizable Fields
    // -------------------------------------------------------------------------
    rand logic [31:0] addr;
    rand logic        write;
    rand logic [31:0] data;
    rand hsize_e      size;
    rand hburst_e     burst;
    rand htrans_e     trans;
    rand int unsigned burst_len;  // number of beats in an INCR burst

    // Response (captured by monitor)
    logic [31:0] rdata;
    logic        hresp;
    logic        hready;

    // -------------------------------------------------------------------------
    // Constraints
    // -------------------------------------------------------------------------
    // Address must be within DUT memory range (256 words = 1KB)
    constraint c_addr_range {
        addr inside {[32'h0000_0000 : 32'h0000_03FF]};
    }

    // Address alignment: match size
    constraint c_addr_align {
        (size == HSIZE_HALFWORD) -> (addr[0]   == 1'b0);
        (size == HSIZE_WORD)     -> (addr[1:0] == 2'b00);
    }

    // Default burst length for INCR
    constraint c_burst_len {
        (burst == HBURST_INCR) -> burst_len inside {[2:8]};
        (burst == HBURST_SINGLE) -> burst_len == 1;
    }

    // For directed tests, trans defaults to NONSEQ
    constraint c_trans_default {
        trans == HTRANS_NONSEQ;
    }

    // Keep address inside memory even when burst wraps (1K boundary)
    constraint c_burst_addr_safe {
        (burst == HBURST_INCR) ->
            (addr + burst_len * (1 << int'(size))) <= 32'h0000_0400;
    }

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(string name = "ahb_seq_item");
        super.new(name);
    endfunction

    // -------------------------------------------------------------------------
    // UVM Field Automation (for print/copy/compare)
    // -------------------------------------------------------------------------
    function void do_copy(uvm_object rhs);
        ahb_seq_item rhs_;
        super.do_copy(rhs);
        if (!$cast(rhs_, rhs))
            `uvm_fatal("CAST", "do_copy: cast failed")
        addr      = rhs_.addr;
        write     = rhs_.write;
        data      = rhs_.data;
        size      = rhs_.size;
        burst     = rhs_.burst;
        trans     = rhs_.trans;
        burst_len = rhs_.burst_len;
        rdata     = rhs_.rdata;
        hresp     = rhs_.hresp;
        hready    = rhs_.hready;
    endfunction

    function bit do_compare(uvm_object rhs, uvm_comparer comparer);
        ahb_seq_item rhs_;
        do_compare = super.do_compare(rhs, comparer);
        if (!$cast(rhs_, rhs))
            `uvm_fatal("CAST", "do_compare: cast failed")
        do_compare &= (addr  === rhs_.addr);
        do_compare &= (write === rhs_.write);
        do_compare &= (size  === rhs_.size);
        if (write)
            do_compare &= (data === rhs_.data);
    endfunction

    function string convert2string();
        return $sformatf(
            "[AHB] %s addr=0x%08h size=%s burst=%s data/rdata=0x%08h/0x%08h resp=%0b",
            write ? "WRITE" : "READ ",
            addr,
            size.name(),
            burst.name(),
            write ? data : rdata,
            rdata,
            hresp
        );
    endfunction

endclass : ahb_seq_item
