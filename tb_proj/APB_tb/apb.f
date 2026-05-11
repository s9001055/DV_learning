// --- Inc Dir (標頭檔搜尋路徑) ---
+incdir+./rtl
+incdir+./UVM

// --- RTL Design ---
./rtl/apb_mem.v

// --- UVM Components ---
// 如果你有定義 xxx_pkg.sv，請放在這裡，並放在 top_tb 之前
./UVM/interface.sv
./UVM/apb_item.sv
./UVM/apb_driver.sv
./UVM/apb_monitor.sv
./UVM/apb_scoreboard.sv
./UVM/apb_agent.sv
./UVM/apb_env.sv
./UVM/apb_sequence.sv
./UVM/base_test.sv
./UVM/top_tb.sv