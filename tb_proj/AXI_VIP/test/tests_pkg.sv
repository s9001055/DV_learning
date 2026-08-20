//==============================================================================
// Purpose: 所有 test class 集中在同一個 package 方便 xrun 編譯順序管理。
//==============================================================================
`ifndef TESTS_PKG_SV
`define TESTS_PKG_SV

package tests_pkg;
    import uvm_pkg::*;
    import axi_pkg::*;
    `include "uvm_macros.svh"

    `include "axi_base_test.sv"
    `include "axi_fixed_wr_test.sv"
    `include "axi_incr_wr_test.sv"
    `include "axi_wrap_wr_test.sv"
endpackage

`endif
