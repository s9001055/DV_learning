`ifndef AXI_RANDOM_WR_SEQ_SV
`define AXI_RANDOM_WR_SEQ_SV

class axi_random_wr_seq extends axi_base_seq;
    `uvm_object_utils(axi_random_wr_seq)

    rand int count;

    function new(string name = "axi_random_wr_seq");
        super.new(name);
    endfunction

    task body();
        axi_transaction write_item;
        axi_transaction read_item;
        `uvm_info(get_type_name(), $sformatf("Repeat count=%0d", count), UVM_LOW)

        repeat(count) begin
            write_item           = axi_transaction::type_id::create("write_item");
            if (!write_item.randomize() with {
                direction   == AXI_WRITE;
                channel     == AXI_CH_AUTO;
            }) `uvm_fatal("RAND", "write_item randomize failed")
            start_item(write_item);
            finish_item(write_item);

            #1000; // wait write done

            read_item           = axi_transaction::type_id::create("v");
            if (!read_item.randomize() with {
                direction   == AXI_READ;
                channel     == AXI_CH_AUTO;
            }) `uvm_fatal("RAND", "read_item randomize failed")
            start_item(read_item);
            finish_item(read_item);
        end
    endtask
endclass : axi_random_wr_seq

`endif
