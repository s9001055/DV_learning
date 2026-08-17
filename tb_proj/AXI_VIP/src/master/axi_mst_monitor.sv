`ifndef AXI_MST_MONITOR_SV
`define AXI_MST_MONITOR_SV

class axi_mst_monitor extends uvm_monitor;
    `uvm_component_utils(axi_mst_monitor)

    virtual axi_if vif;

    axi_reset_monitor   rst_mon;

    uvm_analysis_port #(axi_transaction) ap;

    // ---- Write path ----
    protected mailbox #(axi_transaction) aw_mbx;

    // W data mailbox (獨立於 AW,靠 WLAST 切 burst)
    typedef struct {
        bit [AXI_DWIDTH-1:0] data [$];
        bit [AXI_STRB_W-1:0] strb [$];
    } w_burst_t;
    protected mailbox #(w_burst_t) w_data_mbx;

    // AW + W 配對完成,等 B response
    protected axi_transaction w_done_q [$];

    // ---- Read path ----
    protected axi_transaction ar_q [$];

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap         = new("ap", this);
        aw_mbx     = new();
        w_data_mbx = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Cannot get axi_if from config_db")

        if (!uvm_config_db#(axi_reset_monitor)::get(this, "", "rst_mon", rst_mon)) begin
            `uvm_fatal(get_type_name(), "Cannot get rst_mon from config_db")
        end
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            if (rst_mon.in_reset) begin
                reset_signals();
                rst_mon.ev_reset_done.wait_trigger();
            end

            fork
                mon_aw();
                mon_w();
                mon_pair_aw_w();
                mon_b();
                mon_ar();
                mon_r();

                begin : reset_thread
                    rst_mon.ev_reset_start.wait_trigger();
                end
            join_any

            disable fork;

            // 進入 reset，執行 reset
            reset_signals();
        end
    endtask

    virtual task reset_signals();
        // 清 mailbox
        begin
            axi_transaction t;
            while (aw_mbx.try_get(t));
        end
        begin
            w_burst_t w;
            while (w_data_mbx.try_get(w));
        end
        // 清 queue
        w_done_q.delete();
        ar_q.delete();
    endtask

    // -------------------------------------------------------------------------
    // AW — 純收 header
    // -------------------------------------------------------------------------
    virtual task mon_aw();
        forever begin
            @(vif.mon_cb);
            if (vif.mon_cb.awvalid && vif.mon_cb.awready) begin
                axi_transaction tr = axi_transaction::type_id::create("aw_tr");
                tr.direction = AXI_WRITE;
                tr.id        = vif.mon_cb.awid;
                tr.addr      = vif.mon_cb.awaddr;
                tr.len       = vif.mon_cb.awlen;
                tr.size      = vif.mon_cb.awsize;
                tr.burst     = axi_burst_e'(vif.mon_cb.awburst);
                tr.lock      = axi_lock_e'(vif.mon_cb.awlock);
                tr.cache     = vif.mon_cb.awcache;
                tr.prot      = vif.mon_cb.awprot;
                tr.resp      = new[1];
                aw_mbx.put(tr);
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // W — 獨立收集,靠 WLAST 分 burst。不看 aw_q。
    // -------------------------------------------------------------------------
    virtual task mon_w();
        forever begin
            w_burst_t cur;
            forever begin
                @(vif.mon_cb);
                if (vif.mon_cb.wvalid && vif.mon_cb.wready) begin
                    cur.data.push_back(vif.mon_cb.wdata);
                    cur.strb.push_back(vif.mon_cb.wstrb);
                    if (vif.mon_cb.wlast) begin
                        w_data_mbx.put(cur);
                        break;
                    end
                end
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // AW + W FIFO 配對 → 填好 data/strb 到 transaction → 推進 w_done_q
    // -------------------------------------------------------------------------
    virtual task mon_pair_aw_w();
        axi_transaction tr;
        w_burst_t       wd;
        forever begin
            // 兩邊都到才會往下走
            aw_mbx.get(tr);
            w_data_mbx.get(wd);

            if (wd.data.size() != tr.len + 1)
                `uvm_warning(get_type_name(),
                    $sformatf("W burst length mismatch: AW len=%0d, W beats=%0d",
                              tr.len + 1, wd.data.size()))

            tr.data = new[wd.data.size()];
            tr.strb = new[wd.strb.size()];
            foreach (wd.data[i]) begin
                tr.data[i] = wd.data[i];
                tr.strb[i] = wd.strb[i];
            end

            w_done_q.push_back(tr);
        end
    endtask

    // -------------------------------------------------------------------------
    // B — 依 BID 配對 w_done_q 中第一筆同 ID 的 transaction
    // -------------------------------------------------------------------------
    virtual task mon_b();
        forever begin
            @(vif.mon_cb);
            if (vif.mon_cb.bvalid && vif.mon_cb.bready) begin
                bit found = 0;
                foreach (w_done_q[i]) begin
                    if (w_done_q[i].id == vif.mon_cb.bid) begin
                        axi_transaction tr = w_done_q[i];
                        w_done_q.delete(i);
                        tr.resp[0] = axi_resp_e'(vif.mon_cb.bresp);
                        ap.write(tr);
                        `uvm_info(get_type_name(),
                                  $sformatf("WRITE observed: addr=0x%0h id=%0h len=%0d resp=%s",
                                            tr.addr, tr.id, tr.len, tr.resp[0].name()),
                                  UVM_HIGH)
                        found = 1;
                        break;
                    end
                end
                if (!found)
                    `uvm_warning(get_type_name(),
                        $sformatf("B response BID=0x%0h has no matching write", vif.mon_cb.bid))
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // AR 
    // -------------------------------------------------------------------------
    virtual task mon_ar();
        forever begin
            @(vif.mon_cb);
            if (vif.mon_cb.arvalid && vif.mon_cb.arready) begin
                axi_transaction tr = axi_transaction::type_id::create("ar_tr");
                tr.direction = AXI_READ;
                tr.id        = vif.mon_cb.arid;
                tr.addr      = vif.mon_cb.araddr;
                tr.len       = vif.mon_cb.arlen;
                tr.size      = vif.mon_cb.arsize;
                tr.burst     = axi_burst_e'(vif.mon_cb.arburst);
                tr.lock      = axi_lock_e'(vif.mon_cb.arlock);
                tr.cache     = vif.mon_cb.arcache;
                tr.prot      = vif.mon_cb.arprot;
                tr.data      = new[tr.len + 1];
                tr.strb      = new[tr.len + 1];
                tr.resp      = new[tr.len + 1];
                ar_q.push_back(tr);
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // R (支援 interleaving 的 per-ID beat counter)
    // -------------------------------------------------------------------------
    virtual task mon_r();
        int beats [bit [AXI_IDWIDTH-1:0]];
        forever begin
            @(vif.mon_cb);
            if (vif.mon_cb.rvalid && vif.mon_cb.rready) begin
                bit [AXI_IDWIDTH-1:0] rid = vif.mon_cb.rid;
                int idx = -1;
                foreach (ar_q[i]) if (ar_q[i].id == rid) begin idx = i; break; end
                if (idx == -1) begin
                    `uvm_warning(get_type_name(),
                                 $sformatf("R beat with unknown RID=%0h", rid))
                    continue;
                end
                if (!beats.exists(rid)) beats[rid] = 0;
                ar_q[idx].data[beats[rid]] = vif.mon_cb.rdata;
                ar_q[idx].resp[beats[rid]] = axi_resp_e'(vif.mon_cb.rresp);
                beats[rid]++;
                if (vif.mon_cb.rlast) begin
                    axi_transaction tr = ar_q[idx];
                    ar_q.delete(idx);
                    beats[rid] = 0;
                    ap.write(tr);
                    `uvm_info(get_type_name(),
                              $sformatf("READ observed: addr=0x%0h id=%0h len=%0d",
                                        tr.addr, tr.id, tr.len),
                              UVM_HIGH)
                end
            end
        end
    endtask

endclass : axi_mst_monitor

`endif