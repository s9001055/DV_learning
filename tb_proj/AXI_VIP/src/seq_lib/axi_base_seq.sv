`ifndef AXI_BASE_SEQ_SV
`define AXI_BASE_SEQ_SV

class axi_base_seq extends uvm_sequence #(axi_transaction);
    `uvm_object_utils(axi_base_seq)

    function new(string name = "axi_base_seq");
        super.new(name);
    endfunction

    task write(logic [AXI_AWIDTH-1:0] aw_addr, axi_burst_e w_burst);
        axi_transaction write_item;
        write_item           = axi_transaction::type_id::create("write_item");
        if (!write_item.randomize() with {
            direction   == AXI_WRITE;
            channel     == AXI_CH_AUTO;
            addr        == aw_addr;
            burst       == w_burst;
        }) `uvm_fatal("RAND", "write_item randomize failed")
        start_item(write_item);
        finish_item(write_item);
    endtask

    task read(logic [AXI_AWIDTH-1:0] ar_addr, axi_burst_e r_burst);
        axi_transaction read_item;
        read_item           = axi_transaction::type_id::create("v");
        if (!read_item.randomize() with {
            direction   == AXI_READ;
            channel     == AXI_CH_AUTO;
            addr        == ar_addr;
            burst       == r_burst;
        }) `uvm_fatal("RAND", "read_item randomize failed")
        start_item(read_item);
        finish_item(read_item);
    endtask
endclass : axi_base_seq

`endif
