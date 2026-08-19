`ifndef AXI_INCR_WR_SEQ_SV
`define AXI_INCR_WR_SEQ_SV

class axi_incr_wr_seq extends axi_base_seq;
    `uvm_object_utils(axi_incr_wr_seq)

    rand logic [AXI_AWIDTH-1:0] addr;

    function new(string name = "axi_incr_wr_seq");
        super.new(name);
    endfunction

    task body();
        write(addr, AXI_INCR);

        #1000; // wait write done

        read(addr, AXI_INCR);
    endtask
endclass : axi_incr_wr_seq

`endif
