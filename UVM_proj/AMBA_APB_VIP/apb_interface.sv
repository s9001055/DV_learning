interface apb_intf (input logic clk);
    logic PWRITE;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic [31:0] PADDR;
    logic PREADY;
    logic PRESETn;
    logic PENABLE;
    logic PSLVERR;
    logic PSEL1;

endinterface