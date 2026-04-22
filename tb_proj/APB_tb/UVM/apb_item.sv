`include "apb_defines.svh"

// transation class
class apb_item extends uvm_sequence_item;
    `uvm_object_utils(apb_item)

    rand logic [APB_DATA_WIDTH-1:0] addr;
    rand logic [APB_DATA_WIDTH-1:0] data;
    rand logic                  is_write;

    function new(string name = "apb_item");
        super.new(name);
    endfunction

    // 格式化列印，方便 Debug
    function string convert2string();
        return $sformatf("Addr=%0h, Data=%0h, Write=%0b", addr, data, is_write);
    endfunction
endclass