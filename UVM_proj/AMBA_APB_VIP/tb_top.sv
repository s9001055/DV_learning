`include "package.svh"

module tb_top;
    logic clk;

    apb_apb_vif apb_vif(clk);

    apb_mem dut(._PCLK(clk), ._PRESETn(apb_vif.PRESETn), ._PSEL1(apb_vif.PSEL1), ._PWRITE(apb_vif.PWRITE), 
                ._PENABLE(apb_vif.PENABLE), ._PADDR(apb_vif.PADDR), ._PWDATA(apb_vif.PWDATA),
                ._PRDATA(apb_vif.PRDATA), ._PREADY(apb_vif.PREADY), ._PSLVERR(apb_vif.PSLVERR));

    always #5 clk = ~clk;

    initial begin
        uvm_config_db#(virtual apb_vif)::set(null, "*", "vif", apb_vif);
        run_test("base_test");
    end
endmodule