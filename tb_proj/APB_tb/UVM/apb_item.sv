import uvm_pkg::*;
`include "uvm_macros.svh"

`include "apb_defines.svh"

// transation class
class apb_item extends uvm_sequence_item;
    `uvm_object_utils(apb_item)

    rand logic [`APB_DATA_WIDTH-1:0]         paddr;
    rand logic                              pwrite;
    rand logic [`APB_DATA_WIDTH-1:0]         pwdata;
    rand logic [(`APB_DATA_WIDTH/8)-1:0]     pstrb;
         logic [`APB_DATA_WIDTH-1:0]         prdata;   // 由 Monitor 填入，不需 rand
         logic                              pslverr;


    function new(string name = "apb_item");
        super.new(name);
    endfunction

    // 格式化列印，方便 Debug
    function string convert2string();
        return $sformatf("[%s] ADDR=0x%08h DATA=0x%08h STRB=0x%h PRDATA=0x%08h ERR=%0b",
            pwrite ? "WR" : "RD", paddr, pwdata, pstrb, prdata, pslverr);
    endfunction
endclass