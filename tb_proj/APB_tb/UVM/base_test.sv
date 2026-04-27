`include "apb_defines.svh"

// -----------------------------------------------------------------------------
// Base Test
// -----------------------------------------------------------------------------
class base_test extends uvm_test;
    `uvm_component_utils(base_test)

    apb_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = apb_env::type_id::create("env", this);
    endfunction

    // 設定 timeout，避免卡住
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        #500ns;
        phase.drop_objection(this);
    endtask

    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction
endclass

// -----------------------------------------------------------------------------
// Test 2: Write-Then-Read（核心正確性驗證）
// -----------------------------------------------------------------------------
class apb_test_wr_rd extends base_test;
    `uvm_component_utils(apb_test_wr_rd)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        apb_wr_rd_seq seq;
        phase.raise_objection(this);
        repeat (20) begin
            // 使用 apb_wr_rd_seq  testcase 來測試
            seq = apb_wr_rd_seq::type_id::create("seq");
            seq.start(env.agent.sequencer);
        end
        #100ns;
        phase.drop_objection(this);
    endtask
endclass