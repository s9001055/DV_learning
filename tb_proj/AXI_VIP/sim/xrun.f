// -----------------------------------------------------------------------------
// xrun.f — file list for Cadence Xcelium
// -----------------------------------------------------------------------------

// Include search paths
+incdir+../src/common
+incdir+../src/master
+incdir+../src/slave
+incdir+../src/seq_lib
+incdir+../test
+incdir+../tb

// Package + interface (order matters)
../src/common/axi_if.sv
../src/common/axi_pkg.sv

// Tests package
../tests/tests_pkg.sv

// Top
../tb/tb_top.sv
