`ifndef WB_TRANSACTION_SV
`define WB_TRANSACTION_SV

class wb_transaction extends uvm_sequence_item;
    `uvm_object_utils(wb_transaction)

    rand bit [4:0]  addr;
    rand bit [31:0] data;
    rand bit [3:0]  sel;
    rand wb_direction_e direction;

    // Response (filled by driver/monitor)
    bit [31:0] rdata;
    bit        error;

    constraint c_default_sel {
        sel == 4'hF;
    }

    function new(string name = "wb_transaction");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("%s addr=0x%02h data=0x%08h sel=0x%01h rdata=0x%08h",
                         direction.name(), addr, data, sel, rdata);
    endfunction

endclass : wb_transaction

`endif
