`include "uvm_macros.svh"
`include "cdc_defines.svh"
import uvm_pkg::*;

// ─── Base Test ───────────────────────────────────────────────────────────────
class cdc_base_test extends uvm_test;
    `uvm_component_utils(cdc_base_test)

    cdc_fifo_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = cdc_fifo_env::type_id::create("env", this);
    endfunction

    // 共用 reset task（在 top_tb 透過 vif 操作）
    task apply_reset(virtual cdc_fifo_if vif, int rst_cycles = 5);
        vif.WRST_N = 1'b0;
        vif.RRST_N = 1'b0;
        repeat(rst_cycles) @(posedge vif.WCLK);
        @(posedge vif.RCLK);
        vif.WRST_N = 1'b1;
        vif.RRST_N = 1'b1;
        `uvm_info("TEST", "Reset released", UVM_LOW)
    endtask
endclass


// Test 1：基本讀寫正確性 
class test_basic_rw extends cdc_base_test;
    `uvm_component_utils(test_basic_rw)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    task run_phase(uvm_phase phase);
        seq_basic_write  wseq;
        seq_basic_read   rseq;
        virtual cdc_fifo_if vif;
        phase.raise_objection(this);

        uvm_config_db #(virtual cdc_fifo_if)::get(null, "uvm_test_top", "vif", vif);
        apply_reset(vif);

        wseq = seq_basic_write::type_id::create("wseq");
        rseq = seq_basic_read::type_id::create("rseq");
        wseq.n = 8; rseq.n = 8;

        // 先寫後讀（等寫完再讀）
        fork
            wseq.start(env.write_agent.sequencer);
        join
        // 加一點延遲等同步 latency（2 RCLK）
        repeat(10) @(posedge vif.RCLK);
        fork
            rseq.start(env.read_agent.sequencer);
        join

        #500ns;
        phase.drop_objection(this);
    endtask
endclass

// Test 2：REMPTY & WFULL 邊界
class test_full_boundary extends cdc_base_test;
    `uvm_component_utils(test_basic_rw)
    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    task run_phase(uvm_phase phase);
        seq_fill_fifo  wseq;
        seq_drain_fifo   rseq;
        virtual cdc_fifo_if vif;
        phase.raise_objection(this);

        uvm_config_db #(virtual cdc_fifo_if)::get(null, "uvm_test_top", "vif", vif);
        apply_reset(vif);

        wseq = seq_fill_fifo::type_id::create("wseq");
        rseq = seq_drain_fifo::type_id::create("rseq");

        // 先寫後讀（等寫完再讀）
        wseq.start(env.write_agent.sequencer);
        // 加一點延遲等同步 latency（2 RCLK）
        repeat(10) @(posedge vif.RCLK);
        rseq.start(env.read_agent.sequencer);

        #500ns;
        phase.drop_objection(this);
    endtask
endclass

