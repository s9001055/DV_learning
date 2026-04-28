`include "apb_defines.svh"

class apb_driver extends uvm_driver #(apb_seq_item);
    `uvm_component_utils(apb_driver)

    virtual apb_if.master_mp vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual apb_if.master_mp)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "apb_driver: cannot get virtual interface from config_db")
    endfunction

    task run_phase(uvm_phase phase);
        apb_seq_item req;

        // 初始化匯流排為 IDLE
        drive_idle();

        forever begin
            @(vif.master_cb);
            if ( !vif.PRESETn ) begin
                drive_idle();
            end else begin
                seq_item_port.get_next_item(req);
                drive_transfer(req);
                seq_item_port.item_done();
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // IDLE 狀態：所有輸出拉低
    // -------------------------------------------------------------------------
    task drive_idle();
        vif.master_cb.PSEL    <= 1'b0;
        vif.master_cb.PENABLE <= 1'b0;
        vif.master_cb.PWRITE  <= 1'b0;
        vif.master_cb.PADDR   <= '0;
        vif.master_cb.PWDATA  <= '0;
        vif.master_cb.PSTRB   <= '0;
    endtask

    // -------------------------------------------------------------------------
    // 完整 APB 傳輸：SETUP → ACCESS (含 PREADY stall)
    // -------------------------------------------------------------------------
    task drive_transfer(apb_seq_item req);
        // --- SETUP Phase ---
        // 第一個 clk: 設定 PADDR, PWRITE, PWDATA, PSTRB, PSEL
        // @(vif.master_cb);
        vif.master_cb.PADDR   <= req.paddr;
        vif.master_cb.PWRITE  <= req.pwrite;
        vif.master_cb.PWDATA  <= req.pwrite ? req.pwdata : '0;
        vif.master_cb.PSTRB   <= req.pwrite ? req.pstrb  : '0;
        vif.master_cb.PSEL    <= 1'b1;
        vif.master_cb.PENABLE <= 1'b0;

        // --- ACCESS Phase ---
        // 第二個 clk: 舉起 PENABLE
        @(vif.master_cb);
        vif.master_cb.PENABLE <= 1'b1;

        // 等待 PREADY（Slave 可插入 wait states）
        @(vif.master_cb iff vif.master_cb.PREADY === 1'b1);

        // 捕捉讀取結果
        req.prdata  = vif.master_cb.PRDATA;
        req.pslverr = vif.master_cb.PSLVERR;

        // 回到 IDLE
        @(vif.master_cb);
        drive_idle();

        `uvm_info("APB_DRV", req.convert2string(), UVM_HIGH)
    endtask

endclass
