`include "apb_defines.svh"

class apb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(apb_scoreboard)

    uvm_analysis_imp #(apb_seq_item, apb_scoreboard) analysis_export;

    // Shadow Memory（對應 DUT 內部 mem[]）
    // Key = word address（PADDR[11:2]）
    logic [`APB_DATA_WIDTH-1:0] shadow_mem [int];

    int unsigned pass_cnt, fail_cnt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
    endfunction

    // -------------------------------------------------------------------------
    // 每筆 transaction 進來時呼叫
    // -------------------------------------------------------------------------
    function void write(apb_seq_item tr);
        int waddr = tr.paddr[11:2];  // word address

        if (tr.pwrite) begin
            // 寫入：更新 shadow memory（考慮 PSTRB）
            if (!shadow_mem.exists(waddr))
                shadow_mem[waddr] = 32'h0;

            for (int i = 0; i < 4; i++) begin
                if (tr.pstrb[i])
                    shadow_mem[waddr][(i*8) +: 8] = tr.pwdata[(i*8) +: 8];
            end
            `uvm_info("SB", $sformatf("WR  ADDR=0x%08h DATA=0x%08h STRB=0x%h -> shadow=0x%08h",
                tr.paddr, tr.pwdata, tr.pstrb, shadow_mem[waddr]), UVM_HIGH)

        end else begin
            // 讀取：比對 DUT PRDATA 與 shadow
            logic [`APB_DATA_WIDTH-1:0] expected;

            if (shadow_mem.exists(waddr))
                expected = shadow_mem[waddr];
            else
                expected = 32'h0;  // DUT 內部 mem 初始值為 0

            if (tr.prdata === expected) begin
                pass_cnt++;
                `uvm_info("SB", $sformatf("PASS RD ADDR=0x%08h EXP=0x%08h GOT=0x%08h",
                    tr.paddr, expected, tr.prdata), UVM_HIGH)
            end else begin
                fail_cnt++;
                `uvm_error("SB", $sformatf("FAIL RD ADDR=0x%08h EXP=0x%08h GOT=0x%08h",
                    tr.paddr, expected, tr.prdata))
            end
        end

        // PSLVERR 不應出現（DUT 固定為 0）
        if (tr.pslverr)
            `uvm_error("SB", $sformatf("Unexpected PSLVERR at ADDR=0x%08h", tr.paddr))
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SB", $sformatf("=== Scoreboard Report: PASS=%0d FAIL=%0d ===",
            pass_cnt, fail_cnt), UVM_LOW)
        if (fail_cnt > 0)
            `uvm_error("SB", "TEST FAILED - see above mismatches")
    endfunction

endclass
