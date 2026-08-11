`ifndef AXI_SLV_DRIVER_SV
`define AXI_SLV_DRIVER_SV

class axi_slv_driver extends uvm_driver #(axi_transaction);
    `uvm_component_utils(axi_slv_driver)

    virtual axi_if vif;

    axi_slv_cfg         slv_cfg;
    axi_reset_monitor   rst_mon;

    // inside Memory (persistent across reset,除非 clear_mem_on_reset = 1)
    protected bit [7:0] mem [bit [AXI_AWIDTH-1:0]];
    bit clear_mem_on_reset = 0;

    // Write address queue
    typedef struct { 
        bit [AXI_IDWIDTH-1:0]   id; 
        bit [AXI_AWIDTH-1:0]    addr;
        bit [7:0]               len; 
        bit [2:0]               size; 
        axi_burst_e burst; 
    } aw_hdr_t;
    protected aw_hdr_t wr_addr_q [$];

    // Write data queue (一個完整 burst 的所有 beats)
    typedef struct { 
        bit [AXI_DWIDTH-1:0]    data [$];
        bit [AXI_STRB_W-1:0]    strb [$]; 
    } w_burst_t;
    protected w_burst_t wr_data_q [$];

    // Read side
    typedef struct { 
        bit [AXI_IDWIDTH-1:0]   id; 
        bit [AXI_AWIDTH-1:0]    addr;
        bit [7:0]               len; 
        bit [2:0]               size;
        axi_burst_e             burst; 
        int                     beat_idx; 
    } ar_hdr_t;
    protected ar_hdr_t rd_q [$];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Cannot get axi_if from config_db")
        
        if (!uvm_config_db#(axi_slv_cfg)::get(this, "", "slv_cfg", slv_cfg)) begin
            `uvm_info(get_type_name(), "No axi_slv_cfg found, using default (zero delay)", UVM_MEDIUM)
            slv_cfg = axi_slv_cfg::type_id::create("slv_cfg");
        end

        void'(uvm_config_db#(bit)::get(this, "", "clear_mem_on_reset", clear_mem_on_reset));
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            if (rst_mon.in_reset) begin
                reset_signals();
                rst_mon.ev_reset_done.wait_trigger();
            end

            fork
                handle_aw();
                collect_w();
                pair_and_respond();
                handle_ar_and_r();
                reset_watcher();

                begin : reset_thread
                    rst_mon.ev_reset_start.wait_trigger();
                end
            join_any

            disable fork;

            // 進入 reset，執行 reset
            reset_signals();

            // 停掉所有 sequence
            if (m_sequencer != null)
                m_sequencer.stop_sequences();
        end
    endtask

    virtual task reset_signals();
        vif.awready <= 1'b0;
        vif.wready  <= 1'b0;
        vif.arready <= 1'b0;
        vif.bvalid  <= 1'b0;
        vif.rvalid  <= 1'b0;
        vif.bid     <= '0;
        vif.bresp   <= '0;
        vif.rid     <= '0;
        vif.rdata   <= '0;
        vif.rresp   <= '0;
        vif.rlast   <= 1'b0;

        // 清 in-flight queues (memory 由 clear_mem_on_reset 決定)
        wr_addr_q.delete();
        wr_data_q.delete();
        rd_q.delete();
        if (clear_mem_on_reset) mem.delete();
    endtask

    // -------------------------------------------------------------------------
    // AW channel
    // -------------------------------------------------------------------------
    virtual task handle_aw();
        aw_hdr_t h;
        forever begin
            // delay drive
            repeat ($urandom_range(slv_cfg.aw_ready_delay_max, slv_cfg.aw_ready_delay_min)) @(vif.slv_drv_cb);
            @(vif.slv_drv_cb);
            vif.slv_drv_cb.awready <= 1'b1;

            @(vif.slv_drv_cb);
            if (vif.slv_drv_cb.awvalid && vif.slv_drv_cb.awready) begin
                h.id    = vif.slv_drv_cb.awid;
                h.addr  = vif.slv_drv_cb.awaddr;
                h.len   = vif.slv_drv_cb.awlen;
                h.size  = vif.slv_drv_cb.awsize;
                h.burst = axi_burst_e'(vif.slv_drv_cb.awburst);
                wr_addr_q.push_back(h);
                `uvm_info(get_type_name(),
                          $sformatf("AW captured: id=%0h addr=0x%0h len=%0d",
                                    h.id, h.addr, h.len), UVM_HIGH)
            end

            // awready low
            vif.slv_drv_cb.awready <= 1'b0;
        end
    endtask

    // -------------------------------------------------------------------------
    // W channel
    // -------------------------------------------------------------------------
    virtual task collect_w();
        w_burst_t cur;
        
        forever begin
            // delay drive
            repeat ($urandom_range(slv_cfg.w_ready_delay_max, slv_cfg.w_ready_delay_min)) @(vif.slv_drv_cb);
            @(vif.slv_drv_cb);
            vif.slv_drv_cb.wready <= 1'b1;

            @(vif.slv_drv_cb);
            if (vif.slv_drv_cb.wvalid && vif.slv_drv_cb.wready) begin
                cur.data.push_back(vif.slv_drv_cb.wdata);
                cur.strb.push_back(vif.slv_drv_cb.wstrb);
                if (vif.slv_drv_cb.wlast) begin
                    wr_data_q.push_back(cur);
                    `uvm_info(get_type_name(),
                              $sformatf("W burst complete: %0d beats (AW %s arrived yet)",
                                        cur.data.size(),
                                        (wr_addr_q.size() > wr_data_q.size() - 1) ?
                                          "already" : "not yet"), UVM_HIGH)
                    // Reset temp burst 給下一筆
                    cur.data.delete();
                    cur.strb.delete();
                end
            end

            // wready low
            vif.slv_drv_cb.wready <= 1'b0;
        end
    endtask

    // -------------------------------------------------------------------------
    // Pair address + data,寫 memory,發 B response
    // FIFO 順序
    // -------------------------------------------------------------------------
    virtual task pair_and_respond();
        aw_hdr_t  h;
        w_burst_t b;
        forever begin
            // 等到兩隊都有東西
            wait ((wr_addr_q.size() > 0 && wr_data_q.size() > 0));

            h = wr_addr_q.pop_front();
            b = wr_data_q.pop_front();

            // check burst length 是否吻合
            if (b.data.size() != h.len + 1) begin
                `uvm_error(get_type_name(),
                    $sformatf("W burst length mismatch: AW says %0d beats, W had %0d",
                              h.len + 1, b.data.size()))
            end

            // 寫入 shadow memory
            for (int i = 0; i < b.data.size(); i++) begin
                bit [AXI_AWIDTH-1:0] a = calc_beat_addr(h, i);
                for (int j = 0; j < AXI_STRB_W; j++) begin
                    if (b.strb[i][j])
                        mem[a + j] = b.data[i][8*j +: 8];
                end
            end

            // delay drive
            repeat ($urandom_range(slv_cfg.bvalid_delay_max, slv_cfg.bvalid_delay_min)) @(vif.slv_drv_cb);
            @(vif.slv_drv_cb);
            // 發 B response
            vif.slv_drv_cb.bvalid <= 1'b1;
            vif.slv_drv_cb.bid    <= h.id;
            vif.slv_drv_cb.bresp  <= AXI_OKAY;
            do begin
                @(vif.slv_drv_cb);
            end while (!vif.slv_drv_cb.bready);

            // bvalid low
            vif.slv_drv_cb.bvalid <= 1'b0;
        end
    endtask

    // -------------------------------------------------------------------------
    // AR channel
    // -------------------------------------------------------------------------
    virtual task handle_ar();
        ar_hdr_t p;
        
        forever begin
            // delay drive
            repeat ($urandom_range(slv_cfg.ar_ready_delay_max, slv_cfg.ar_ready_delay_min)) @(vif.slv_drv_cb);
            vif.slv_drv_cb.arready <= 1'b1;

            @(vif.slv_drv_cb);
            if (vif.slv_drv_cb.arvalid && vif.slv_drv_cb.arready) begin
                p.id        = vif.slv_drv_cb.arid;
                p.addr      = vif.slv_drv_cb.araddr;
                p.len       = vif.slv_drv_cb.arlen;
                p.size      = vif.slv_drv_cb.arsize;
                p.burst     = axi_burst_e'(vif.slv_drv_cb.arburst);
                p.beat_idx  = 0;
                rd_q.push_back(p);
            end

            // arready low
            vif.slv_drv_cb.arready <= 1'b0;
        end
    endtask

    // -------------------------------------------------------------------------
    // R channel 3 mode
    // FIFO         : aw queue first in first out
    // OoO          : out of order
    // r_interleave : beat interleaving
    // -------------------------------------------------------------------------
    virtual task handle_r();
        case (slv_cfg.read_resp_mode)
            AXI_R_FIFO:        r_fifo();
            AXI_R_OOO:         r_ooo();
            AXI_R_INTERLEAVE:  r_interleave();
        endcase
    endtask

    // ----- FIFO: 先到先回, 全部 beat 送完 -----
    virtual task r_fifo();
        forever begin
            wait (rd_q.size() > 0);
            send_full_burst(0);  // index 0 = 最早那筆
        end
    endtask

    // ----- OoO: 從 rd_q 隨機挑一筆, 全部 beat 送完 -----
    virtual task r_ooo();
        forever begin
            wait (rd_q.size() > 0);
            begin
                int pick = $urandom_range(rd_q.size() - 1, 0);
                `uvm_info(get_type_name(),
                          $sformatf("R Channel Send (OoO): id=%0h",
                                    rd_q.id), UVM_HIGH)
                send_full_burst(pick);
            end
        end
    endtask

    // ----- Interleave: 每次從 rd_q 挑一筆,送 N beats 就切換 -----
    virtual task r_interleave();
        forever begin
            wait (rd_q.size() > 0);
            begin
                int pick = $urandom_range(rd_q.size() - 1, 0);
                int beats_to_send = $urandom_range(rd_q[pick].len + 1, 1);
                `uvm_info(get_type_name(),
                          $sformatf("R Channel Send (interleave): id=%0h beats_to_send=%0d",
                                    rd_q.id, beats_to_send), UVM_HIGH)
                send_partial_burst(pick, beats_to_send);
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // R r_fifo() 與 r_ooo() 使用: 送完整個 burst
    // -------------------------------------------------------------------------
    virtual task send_full_burst(int idx);
        ar_hdr_t p = rd_q[idx];
        rd_q.delete(idx);
        for (int i = 0; i <= p.len; i++) begin
            send_one_r_beat(p, i, (i == p.len));
        end
        vif.slv_drv_cb.rvalid <= 1'b0;
        vif.slv_drv_cb.rlast  <= 1'b0;
    endtask

    // -------------------------------------------------------------------------
    // R r_interleave() 使用: 送 partial burst (interleave 用)
    // -------------------------------------------------------------------------
    virtual task send_partial_burst(int idx, int max_beats);
        ar_hdr_t p = rd_q[idx];
        int sent = 0;
        while (sent < max_beats && p.beat_idx <= p.len) begin
            bit is_last = (p.beat_idx == p.len);
            send_one_r_beat(p, p.beat_idx, is_last);
            p.beat_idx++;
            sent++;
            if (is_last) begin
                // Burst 完成,從 queue 移除
                rd_q.delete(idx);
                vif.slv_drv_cb.rvalid <= 1'b0;
                vif.slv_drv_cb.rlast  <= 1'b0;
                return;
            end
        end
        // Burst 未完成, 還有beat 還沒送, 更新 beat_idx 回 queue
        rd_q[idx] = p;
        vif.slv_drv_cb.rvalid <= 1'b0;
        vif.slv_drv_cb.rlast  <= 1'b0;
    endtask

    // -------------------------------------------------------------------------
    // R 送一筆 beat
    // -------------------------------------------------------------------------
    virtual task send_one_r_beat(ar_hdr_t p, int beat, bit is_last);
        bit [AXI_AWIDTH-1:0] a = calc_beat_addr_ar(p, i);
        bit [AXI_DWIDTH-1:0] d = '0;
        for (int j = 0; j < AXI_STRB_W; j++)
            d[8*j +: 8] = mem.exists(a+j) ? mem[a+j] : 8'h00;   

        // delay drive
        repeat ($urandom_range(slv_cfg.r_beat_gap_max, slv_cfg.r_beat_gap_min)) @(vif.slv_drv_cb);
        vif.slv_drv_cb.rvalid <= 1'b1;
        vif.slv_drv_cb.rid    <= p.id;
        vif.slv_drv_cb.rdata  <= d;
        vif.slv_drv_cb.rresp  <= AXI_OKAY;
        vif.slv_drv_cb.rlast  <= is_last;
        do begin
            @(vif.slv_drv_cb);
        end while (!vif.slv_drv_cb.rready);

        // rvalid low
        vif.slv_drv_cb.rvalid <= 1'b0;
    endtask
    
    // -------------------------------------------------------------------------
    // 位址計算
    // -------------------------------------------------------------------------
    function bit [AXI_AWIDTH-1:0] calc_beat_addr(aw_hdr_t h, int i);
        case (h.burst)
            AXI_FIXED: return h.addr;
            AXI_INCR : return h.addr + (i << h.size);
            AXI_WRAP : begin
                int unsigned wb = (h.len + 1) << h.size;
                bit [AXI_AWIDTH-1:0] base = h.addr & ~(wb - 1);
                return base + ((h.addr + (i << h.size) - base) & (wb - 1));
            end
            default: return h.addr;
        endcase
    endfunction

    function bit [AXI_AWIDTH-1:0] calc_beat_addr_ar(ar_hdr_t h, int i);
        case (h.burst)
            AXI_FIXED: return h.addr;
            AXI_INCR : return h.addr + (i << h.size);
            AXI_WRAP : begin
                int unsigned wb = (h.len + 1) << h.size;
                bit [AXI_AWIDTH-1:0] base = h.addr & ~(wb - 1);
                return base + ((h.addr + (i << h.size) - base) & (wb - 1));
            end
            default: return h.addr;
        endcase
    endfunction

endclass : axi_slv_driver

`endif