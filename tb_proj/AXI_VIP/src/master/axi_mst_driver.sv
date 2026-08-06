`ifndef AXI_MST_DRIVER_SV
`define AXI_MST_DRIVER_SV

class axi_mst_driver extends uvm_driver #(axi_transaction);
    `uvm_component_utils(axi_mst_driver)

    virtual axi_if      vif;

    axi_reset_monitor   rst_mon;

    // 每個 channel 的 mailbox, 收集要 drive 的 item
    mailbox #(axi_transaction) aw_mbx;
    mailbox #(axi_transaction) w_mbx;
    mailbox #(axi_transaction) ar_mbx;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        aw_mbx = new();
        w_mbx  = new();
        ar_mbx = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Cannot get axi_if from config_db")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            if (rst_mon.in_reset) begin
                reset_signals();
                rst_mon.ev_reset_done.wait_trigger();
            end

            fork
                get_req_dispatch();
                drive_aw();
                drive_w();
                drive_b();
                drive_ar();
                drive_r();

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

    // 初始 idle 值
    virtual task reset_signals();
        vif.mst_drv_cb.awvalid <= 1'b0;
        vif.mst_drv_cb.wvalid  <= 1'b0;
        vif.mst_drv_cb.bready  <= 1'b0;
        vif.mst_drv_cb.arvalid <= 1'b0;
        vif.mst_drv_cb.rready  <= 1'b0;
    endtask

    // 從 seq_item_port 取交易,依 direction 跟 channel 丟到對應 mailbox
    virtual task get_req_dispatch();
        axi_transaction req, rsp;
        forever begin
            seq_item_port.get_next_item(req);
            case (req.channel)
                AXI_CH_AW: begin
                    aw_mbx.put(req);
                end
                AXI_CH_W: begin
                    w_mbx.put(req);
                end
                AXI_CH_AR: begin
                    ar_mbx.put(req);
                end
                AXI_CH_AUTO: begin
                    if (req.direction == AXI_WRITE) begin
                        aw_mbx.put(req);
                        w_mbx.put(req);
                    end
                    else begin
                        ar_mbx.put(req);
                    end
                end
                default: begin
                    aw_mbx.put(req);
                    w_mbx.put(req);
                    ar_mbx.put(req);
                end
            endcase
            // 立刻 item_done,讓 sequence 可以繼續產生 outstanding txn
            seq_item_port.item_done();
        end
    endtask

    virtual task drive_aw();
        axi_transaction tr;
        forever begin
            aw_mbx.get(tr);
            @(vif.mst_drv_cb);
            vif.mst_drv_cb.awid    <= tr.id;
            vif.mst_drv_cb.awaddr  <= tr.addr;
            vif.mst_drv_cb.awlen   <= tr.len;
            vif.mst_drv_cb.awsize  <= tr.size;
            vif.mst_drv_cb.awburst <= tr.burst;
            vif.mst_drv_cb.awlock  <= tr.lock;
            vif.mst_drv_cb.awcache <= tr.cache;
            vif.mst_drv_cb.awprot  <= tr.prot;
            vif.mst_drv_cb.awvalid <= 1'b1;
            do @(vif.mst_drv_cb); while (!vif.mst_drv_cb.awready);
            vif.mst_drv_cb.awvalid <= 1'b0;
        end
    endtask

    virtual task drive_w();
        axi_transaction tr;
        forever begin
            w_mbx.get(tr);
            foreach (tr.data[i]) begin
                @(vif.mst_drv_cb);
                vif.mst_drv_cb.wdata  <= tr.data[i];
                vif.mst_drv_cb.wstrb  <= tr.strb[i];
                vif.mst_drv_cb.wlast  <= (i == tr.data.size()-1);
                vif.mst_drv_cb.wvalid <= 1'b1;
                do @(vif.mst_drv_cb); while (!vif.mst_drv_cb.wready);
            end
            vif.mst_drv_cb.wvalid <= 1'b0;
            vif.mst_drv_cb.wlast  <= 1'b0;
        end
    endtask

    virtual task drive_b();
        vif.mst_drv_cb.bready <= 1'b1;   // 簡化:always ready
        forever @(vif.mst_drv_cb);
    endtask

    virtual task drive_ar();
        axi_transaction tr;
        forever begin
            ar_mbx.get(tr);
            @(vif.mst_drv_cb);
            vif.mst_drv_cb.arid    <= tr.id;
            vif.mst_drv_cb.araddr  <= tr.addr;
            vif.mst_drv_cb.arlen   <= tr.len;
            vif.mst_drv_cb.arsize  <= tr.size;
            vif.mst_drv_cb.arburst <= tr.burst;
            vif.mst_drv_cb.arlock  <= tr.lock;
            vif.mst_drv_cb.arcache <= tr.cache;
            vif.mst_drv_cb.arprot  <= tr.prot;
            vif.mst_drv_cb.arvalid <= 1'b1;
            do @(vif.mst_drv_cb); while (!vif.mst_drv_cb.arready);
            vif.mst_drv_cb.arvalid <= 1'b0;
        end
    endtask

    virtual task drive_r();
        vif.mst_drv_cb.rready <= 1'b1;   // 簡化:always ready
        forever @(vif.mst_drv_cb);
    endtask

endclass : axi_mst_driver

`endif
