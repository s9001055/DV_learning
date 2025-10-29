`include "package.svh"

module tb_top;
    logic clk;

    apb_intf apb_vif(clk);

    always #5 clk = ~clk;

    initial begin
        uvm_config_db#(virtual apb_intf)::set(null, "*", "vif", apb_vif);
        run_test("base_test");
    end
endmodule