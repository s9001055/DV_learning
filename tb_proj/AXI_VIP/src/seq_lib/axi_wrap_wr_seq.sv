`ifndef AXI_WRAP_WR_SEQ_SV
`define AXI_WRAP_WR_SEQ_SV

class axi_wrap_wr_seq extends axi_base_seq;
    `uvm_object_utils(axi_wrap_wr_seq)

    rand logic [AXI_AWIDTH-1:0] addr;

    function new(string name = "axi_wrap_wr_seq");
        super.new(name);
    endfunction

    task body();
        write(addr, AXI_WRAP);

        #1000; // wait write done

        read(addr, AXI_WRAP);
    endtask
endclass : axi_wrap_wr_seq

`endif
