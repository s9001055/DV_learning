import uvm_pkg::*;
`include "uvm_macros.svh"

`include "apb_defines.svh"

interface apb_if (
    input logic PCLK,
    input logic PRESETn
);

    logic [`APB_DATA_WIDTH-1:0]      PADDR;
    logic                           PSEL;
    logic                           PENABLE;
    logic                           PWRITE;
    logic [`APB_DATA_WIDTH-1:0]      PWDATA;
    logic [(`APB_DATA_WIDTH/8)-1:0]  PSTRB;
    logic [`APB_DATA_WIDTH-1:0]      PRDATA;
    logic                           PREADY;
    logic                           PSLVERR;

    // -------------------------------------------------------------------------
    // Clocking Block for Driver (Master 驅動端)
    // -------------------------------------------------------------------------
    clocking master_cb @(posedge PCLK);
        default input  #1step
                output #1;
        output PADDR;
        output PSEL;
        output PENABLE;
        output PWRITE;
        output PWDATA;
        output PSTRB;
        input  PRDATA;
        input  PREADY;
        input  PSLVERR;
    endclocking

    // -------------------------------------------------------------------------
    // Clocking Block for Monitor (觀測端)
    // -------------------------------------------------------------------------
    clocking monitor_cb @(posedge PCLK);
        default input #1step;
        input PADDR;
        input PSEL;
        input PENABLE;
        input PWRITE;
        input PWDATA;
        input PSTRB;
        input PRDATA;
        input PREADY;
        input PSLVERR;
    endclocking

    // -------------------------------------------------------------------------
    // Modport
    // -------------------------------------------------------------------------
    modport master_mp  (clocking master_cb,  input PCLK, PRESETn);
    modport monitor_mp (clocking monitor_cb, input PCLK, PRESETn);

    // -------------------------------------------------------------------------
    // Assertion：PENABLE 只能在 PSEL 拉高後才能拉高
    // -------------------------------------------------------------------------
    property p_penable_after_psel;
        @(posedge PCLK) disable iff (!PRESETn)
        PENABLE |-> $past(PSEL);
    endproperty
    assert property (p_penable_after_psel)
        else `uvm_error("APB_IF", "PENABLE asserted without prior PSEL")

    // -------------------------------------------------------------------------
    // Assertion：PADDR/PWRITE 在 ACCESS 階段不可改變
    // -------------------------------------------------------------------------
    property p_stable_in_access;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && PENABLE && !PREADY) |=>
            ($stable(PADDR) && $stable(PWRITE) && $stable(PWDATA) && $stable(PSTRB));
    endproperty
    assert property (p_stable_in_access)
        else `uvm_error("APB_IF", "PADDR/PWRITE/PWDATA/PSTRB changed during ACCESS with PREADY=0")

    // -------------------------------------------------------------------------
    // Assertion：PRDATA 在 PSEL/PENABLE/PREADY/!PWRITE 時, 不能為Z 或 X
    // -------------------------------------------------------------------------
    property p_prdata_valid;
        @(posedge PCLK) disable iff (!PRESETn)
        (PSEL && PENABLE && !PWRITE && PREADY) |-> !$isunknown(PRDATA);
    endproperty
    assert property (p_prdata_valid)
        else `uvm_error("APB_IF", "PRDATA unknown during PSEL && PENABLE && !PWRITE && PREADY")    

    // -------------------------------------------------------------------------
    // Assertion：PSLVERR 在 !(PSEL && PENABLE && PREADY) 時, 必須為 0
    // -------------------------------------------------------------------------
    property p_pslverr_only_access;
        @(posedge PCLK) disable iff (!PRESETn)
        !(PSEL && PENABLE && PREADY) |-> (PSLVERR == 1'b0);
    endproperty
    assert property (p_pslverr_only_access)
        else `uvm_error("APB_IF", "PSLVERR must be 0 outside access phase")  

    // -------------------------------------------------------------------------
    // Assertion：PRESETn 為0時 master 的 output port 必須為 0
    // -------------------------------------------------------------------------
    property p_reset_idle;
        @(posedge PCLK)
        (!PRESETn) |->
            (PSEL   == 1'b0) &&
            (PENABLE == 1'b0) &&
            (PWRITE  == 1'b0) &&
            (PADDR   == '0  ) &&
            (PWDATA  == '0  ) &&
            (PSTRB   == '0  );
    endproperty
    assert property (p_reset_idle)
        else `uvm_error("APB_IF", "All master outputs must be 0 within one cycle of PRESETn deassertion") 
endinterface
