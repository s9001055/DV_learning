`ifndef AXI_FIXED_WR_SEQ_SV
`define AXI_FIXED_WR_SEQ_SV

class axi_fixed_wr_seq extends axi_base_seq;
    `uvm_object_utils(axi_fixed_wr_seq)

    rand logic [AXI_AWIDTH-1:0] addr;

    function new(string name = "axi_fixed_wr_seq");
        super.new(name);
    endfunction

    task body();
        write(addr, AXI_FIXED);

        #1000; // wait write done

        read(addr, AXI_FIXED);
    endtask
endclass : axi_fixed_wr_seq

`endif
