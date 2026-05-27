-uvm
-sv
-access +rwc
-timescale 1ns/1ps

// 輸入想要測的 testcase
+UVM_TESTNAME=test_basic_rw

// --- Inc Dir (標頭檔搜尋路徑) ---
+incdir+./rtl
+incdir+./UVM

// --- RTL Design ---
./rtl/async_fifo.v

// --- UVM Components ---
./UVM/cdc_fifo_if.sv
./UVM/cdc_seq_item.sv
./UVM/cdc_write_driver.sv
./UVM/cdc_write_monitor.sv
./UVM/cdc_write_agent.sv
./UVM/cdc_read_driver.sv
./UVM/cdc_read_monitor.sv
./UVM/cdc_read_agent.sv
./UVM/cdc_scoreboard.sv
./UVM/cdc_env.sv
./UVM/cdc_sequence.sv
./UVM/cdc_base_test.sv
./UVM/top_tb.sv