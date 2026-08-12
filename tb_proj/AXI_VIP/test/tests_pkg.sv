//==============================================================================
// Purpose: 所有 test class 集中在同一個 package 方便 xrun 編譯順序管理。
//==============================================================================
`ifndef TESTS_PKG_SV
`define TESTS_PKG_SV

package tests_pkg;
    import uvm_pkg::*;
    import axi_pkg::*;
    `include "uvm_macros.svh"

    `include "tests/axi_base_test.sv"
    `include "tests/axi_fixed_rw_test.sv"
endpackage

`endif
