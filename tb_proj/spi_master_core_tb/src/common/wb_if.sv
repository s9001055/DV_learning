`ifndef WB_IF_SV
`define WB_IF_SV

interface wb_if (input logic clk, input logic rst);

    logic [4:0]  adr;
    logic [31:0] dat_i;   // master → slave (write data)
    logic [31:0] dat_o;   // slave → master (read data)
    logic [3:0]  sel;
    logic        we;
    logic        stb;
    logic        cyc;
    logic        ack;
    logic        err;
    logic        int_o;

    // Master driver clocking block
    clocking mst_cb @(posedge clk);
        default input #1 output #1;
        output adr, dat_i, sel, we, stb, cyc;
        input  dat_o, ack, err, int_o;
    endclocking

    // Monitor clocking block
    clocking mon_cb @(posedge clk);
        default input #1;
        input adr, dat_i, dat_o, sel, we, stb, cyc, ack, err, int_o;
    endclocking

    // Modports
    modport master  (clocking mst_cb);
    modport monitor (clocking mon_cb);

endinterface : wb_if

`endif
