`ifndef AXI_SCOREBOARD_SV
`define AXI_SCOREBOARD_SV

class axi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_scoreboard)

    uvm_analysis_imp #(axi_transaction, axi_scoreboard) ap_imp;

    // 用 byte-addressed associative array 當 shadow memory
    protected bit [7:0] shadow [bit [AXI_AWIDTH-1:0]];

    // 統計
    int unsigned m_num_wr, m_num_rd, m_num_err;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap_imp = new("ap_imp", this);
    endfunction

    virtual function void write(axi_transaction t);
        if (t.direction == AXI_WRITE)
            handle_write(t);
        else
            handle_read(t);
    endfunction

    protected function void handle_write(axi_transaction t);
        m_num_wr++;
        // 用 monitor 收到的 wdata + wstrb 更新 shadow memory
        for (int i = 0; i <= t.len; i++) begin
            bit [AXI_AWIDTH-1:0] a = t.beat_addr(i);
            for (int b = 0; b < AXI_STRB_W; b++) begin
                if (t.strb[i][b])
                    shadow[a + b] = t.data[i][8*b +: 8];
            end
        end
    endfunction

    protected function void handle_read(axi_transaction t);
        m_num_rd++;
        for (int i = 0; i <= t.len; i++) begin
            bit [AXI_AWIDTH-1:0] a = t.beat_addr(i);
            bit [AXI_DWIDTH-1:0] exp = '0;
            for (int b = 0; b < AXI_STRB_W; b++)
                exp[8*b +: 8] = shadow.exists(a+b) ? shadow[a+b] : 8'h00;

            if (t.data[i] !== exp) begin
                m_num_err++;
                `uvm_error(get_type_name(),
                    $sformatf("READ mismatch @ addr=0x%0h beat=%0d: got=0x%0h exp=0x%0h",
                              a, i, t.data[i], exp))
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(),
            $sformatf("SB summary: writes=%0d reads=%0d errors=%0d",
                       m_num_wr, m_num_rd, m_num_err),
            UVM_LOW)
        if (m_num_err > 0)
            `uvm_error(get_type_name(),
                $sformatf("Scoreboard reported %0d data mismatches", m_num_err))
    endfunction

endclass : axi_scoreboard

`endif
