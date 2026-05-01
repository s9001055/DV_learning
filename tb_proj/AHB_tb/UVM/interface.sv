import uvm_pkg::*;
`include "uvm_macros.svh"

`include "ahb_defines.svh"

interface ahb_if (
    input logic HCLK,
    input logic HRESETn
);
    // AHB Signals
    logic                  HSEL;
    logic [`AHB_ADDR_WIDTH-1:0] HADDR;
    logic                  HWRITE;
    logic [2:0]            HSIZE;
    logic [2:0]            HBURST;
    logic [1:0]            HTRANS;
    logic [`AHB_DATA_WIDTH-1:0] HWDATA;
    logic [`AHB_DATA_WIDTH-1:0] HRDATA;
    logic                  HREADYOUT;
    logic                  HRESP;

    // Clocking block for Driver (master drives)
    clocking driver_cb @(posedge HCLK);
        default input #1 output #1;
        output HSEL;
        output HADDR;
        output HWRITE;
        output HSIZE;
        output HBURST;
        output HTRANS;
        output HWDATA;
        input  HRDATA;
        input  HREADYOUT;
        input  HRESP;
    endclocking

    // Clocking block for Monitor (observe only)
    clocking monitor_cb @(posedge HCLK);
        default input #1;
        input HSEL;
        input HADDR;
        input HWRITE;
        input HSIZE;
        input HBURST;
        input HTRANS;
        input HWDATA;
        input HRDATA;
        input HREADYOUT;
        input HRESP;
    endclocking

    // Modport for Driver
    modport driver_mp  (clocking driver_cb,  input HCLK, input HRESETn);
    // Modport for Monitor
    modport monitor_mp (clocking monitor_cb, input HCLK, input HRESETn);

endinterface : ahb_if
