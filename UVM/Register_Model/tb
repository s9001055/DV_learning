// =============================================================
//  UVM Register Model 學習範例 — 完整 Testbench
//
//  層次結構：
//    tb_top
//    └── test_reg_basic
//        └── env_reg
//            ├── apb_agent (active)
//            │   ├── apb_sequencer
//            │   ├── apb_driver
//            │   └── apb_monitor
//            ├── reg_block_dut   (Register Model)
//            └── uvm_reg_predictor
// =============================================================

`include "uvm_macros.svh"
import uvm_pkg::*;

// ─────────────────────────────────────────────
//  SECTION 1：APB Transaction（bus sequence item）
// ─────────────────────────────────────────────
class apb_seq_item extends uvm_sequence_item;
    `uvm_object_utils(apb_seq_item)

    rand logic        pwrite;
    rand logic [7:0]  paddr;
    rand logic [31:0] pwdata;
         logic [31:0] prdata;  // 讀取結果（由 driver 填入）

    function new(string name = "apb_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("[APB] %s addr=0x%02h data=0x%08h",
                         pwrite ? "WR" : "RD", paddr,
                         pwrite ? pwdata : prdata);
    endfunction
endclass

// ─────────────────────────────────────────────
//  SECTION 2：APB Driver
// ─────────────────────────────────────────────
class apb_driver extends uvm_driver #(apb_seq_item);
    `uvm_component_utils(apb_driver)

    // 介面（透過 config_db 取得）
    virtual interface apb_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "apb_driver: 找不到 apb_if")
    endfunction

    task run_phase(uvm_phase phase);
        apb_seq_item req;
        // 初始狀態
        vif.psel    = 0;
        vif.penable = 0;
        vif.pwrite  = 0;
        vif.paddr   = 0;
        vif.pwdata  = 0;

        forever begin
            seq_item_port.get_next_item(req);
            drive_transfer(req);
            seq_item_port.item_done();
        end
    endtask

    // APB 兩段式（Setup -> Access）
    task drive_transfer(apb_seq_item item);
        // Setup phase
        @(posedge vif.clk);
        vif.psel    <= 1;
        vif.penable <= 0;
        vif.pwrite  <= item.pwrite;
        vif.paddr   <= item.paddr;
        vif.pwdata  <= item.pwdata;

        // Access phase
        @(posedge vif.clk);
        vif.penable <= 1;
        @(posedge vif.clk iff vif.pready);
        item.prdata = vif.prdata;   // 捕捉讀取結果

        // 結束
        vif.psel    <= 0;
        vif.penable <= 0;
    endtask
endclass

// ─────────────────────────────────────────────
//  SECTION 3：APB Monitor（送給 predictor 用）
// ─────────────────────────────────────────────
class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    virtual interface apb_if vif;
    uvm_analysis_port #(apb_seq_item) ap;  // 連接 predictor

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "apb_monitor: 找不到 apb_if")
    endfunction

    task run_phase(uvm_phase phase);
        apb_seq_item observed;
        forever begin
            // 等待 APB 傳輸完成（access phase 結束）
            @(posedge vif.clk iff (vif.psel && vif.penable && vif.pready));
            observed        = apb_seq_item::type_id::create("observed");
            observed.pwrite = vif.pwrite;
            observed.paddr  = vif.paddr;
            observed.pwdata = vif.pwdata;
            observed.prdata = vif.prdata;
            `uvm_info("MON", observed.convert2string(), UVM_HIGH)
            ap.write(observed);  // 推送給 predictor
        end
    endtask
endclass

// ─────────────────────────────────────────────
//  SECTION 4：APB Agent
// ─────────────────────────────────────────────
class apb_agent extends uvm_agent;
    `uvm_component_utils(apb_agent)

    apb_driver    drv;
    apb_monitor   mon;
    uvm_sequencer #(apb_seq_item) seqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv  = apb_driver::type_id::create("drv",  this);
        mon  = apb_monitor::type_id::create("mon", this);
        seqr = uvm_sequencer #(apb_seq_item)::type_id::create("seqr", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(seqr.seq_item_export);
    endfunction
endclass

// ─────────────────────────────────────────────
//  SECTION 5：Register Model
//  每個 class 對應一個硬體暫存器
// ─────────────────────────────────────────────

// --- REG_CTRL（位址 0x00）---
class reg_ctrl extends uvm_reg;
    `uvm_object_utils(reg_ctrl)

    uvm_reg_field MODE;    // [1:0] RW
    uvm_reg_field ENABLE;  // [2]   RW

    function new(string name = "reg_ctrl");
        // 第三個參數：has_coverage（此處不使用 functional coverage）
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    function void build();
        MODE   = uvm_reg_field::type_id::create("MODE");
        ENABLE = uvm_reg_field::type_id::create("ENABLE");
        // configure(父暫存器, 位元寬度, LSB位置, 存取類型, volatile, reset值, has_reset, is_rand, individually_accessible)
        MODE.configure  (this, 2, 0, "RW", 0, 2'h0, 1, 1, 0);
        ENABLE.configure(this, 1, 2, "RW", 0, 1'h0, 1, 1, 0);
    endfunction
endclass

// --- REG_DATA（位址 0x04）---
class reg_data extends uvm_reg;
    `uvm_object_utils(reg_data)

    uvm_reg_field DATA;  // [7:0] RW

    function new(string name = "reg_data");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    function void build();
        DATA = uvm_reg_field::type_id::create("DATA");
        DATA.configure(this, 8, 0, "RW", 0, 8'h00, 1, 1, 0);
    endfunction
endclass

// --- REG_STATUS（位址 0x08）---
class reg_status extends uvm_reg;
    `uvm_object_utils(reg_status)

    uvm_reg_field BUSY;  // [0] RO

    function new(string name = "reg_status");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    function void build();
        BUSY = uvm_reg_field::type_id::create("BUSY");
        // "RO"：register model 不會驅動寫入，DUT 決定此值
        BUSY.configure(this, 1, 0, "RO", 1, 1'h0, 1, 0, 0);
        //                                ^volatile=1 表示 DUT 可自行改變
    endfunction
endclass

// --- 頂層 reg_block ---
class reg_block_dut extends uvm_reg_block;
    `uvm_object_utils(reg_block_dut)

    reg_ctrl   CTRL;
    reg_data   DATA;
    reg_status STATUS;

    uvm_reg_map apb_map;  // 位址映射

    function new(string name = "reg_block_dut");
        super.new(name, UVM_NO_COVERAGE);
    endfunction

    function void build();
        // 建立暫存器實例
        CTRL   = reg_ctrl::type_id::create("CTRL");
        DATA   = reg_data::type_id::create("DATA");
        STATUS = reg_status::type_id::create("STATUS");
        CTRL.build();   CTRL.configure(this);
        DATA.build();   DATA.configure(this);
        STATUS.build(); STATUS.configure(this);

        // 建立位址映射
        // create_map(name, base_addr, bus_width_bytes, endian)
        apb_map = create_map("apb_map", 0, 4, UVM_LITTLE_ENDIAN);
        apb_map.add_reg(CTRL,   'h00, "RW");
        apb_map.add_reg(DATA,   'h04, "RW");
        apb_map.add_reg(STATUS, 'h08, "RO");

        lock_model();  // 完成建立後鎖定（不可再加暫存器）
    endfunction
endclass

// ─────────────────────────────────────────────
//  SECTION 6：APB Adapter
//  橋接 uvm_reg_bus_op ↔ apb_seq_item
// ─────────────────────────────────────────────
class apb_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(apb_reg_adapter)

    function new(string name = "apb_reg_adapter");
        super.new(name);
        // 告知 UVM：此 adapter 是否支援 byte enable
        supports_byte_enable = 0;
        // 是否提供 bus2reg（被動預測）；這裡讓 predictor 負責
        provides_responses   = 0;
    endfunction

    // register model → bus transaction
    function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        apb_seq_item item = apb_seq_item::type_id::create("item");
        item.pwrite = (rw.kind == UVM_WRITE) ? 1 : 0;
        item.paddr  = rw.addr[7:0];
        item.pwdata = rw.data;
        return item;
    endfunction

    // bus transaction → register model（配合 predictor 使用）
    function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        apb_seq_item item;
        if (!$cast(item, bus_item))
            `uvm_fatal("CAST_FAIL", "bus2reg: 無法轉型為 apb_seq_item")
        rw.kind    = item.pwrite ? UVM_WRITE : UVM_READ;
        rw.addr    = item.paddr;
        rw.data    = item.pwrite ? item.pwdata : item.prdata;
        rw.status  = UVM_IS_OK;
    endfunction
endclass

// ─────────────────────────────────────────────
//  SECTION 7：Environment
// ─────────────────────────────────────────────
class env_reg extends uvm_env;
    `uvm_component_utils(env_reg)

    apb_agent                              agent;
    reg_block_dut                          regmodel;
    apb_reg_adapter                        adapter;
    uvm_reg_predictor #(apb_seq_item)      predictor;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent     = apb_agent::type_id::create("agent",     this);
        regmodel  = reg_block_dut::type_id::create("regmodel");
        adapter   = apb_reg_adapter::type_id::create("adapter",   this);
        predictor = uvm_reg_predictor #(apb_seq_item)::type_id::create("predictor", this);

        regmodel.build();
        // 將 regmodel 放入 config_db，讓 test 取得
        uvm_config_db #(reg_block_dut)::set(this, "*", "regmodel", regmodel);
    endfunction

    function void connect_phase(uvm_phase phase);
        // 1. 設定 reg_map 的 sequencer 與 adapter
        regmodel.apb_map.set_sequencer(agent.seqr, adapter);

        // 2. 連接 predictor：monitor → predictor → regmodel
        predictor.map     = regmodel.apb_map;
        predictor.adapter = adapter;
        agent.mon.ap.connect(predictor.bus_in);
    endfunction
endclass

// ─────────────────────────────────────────────
//  SECTION 8：Sequences（各種暫存器操作示範）
// ─────────────────────────────────────────────

// --- 基礎讀寫序列 ---
class seq_basic_rw extends uvm_reg_sequence;
    `uvm_object_utils(seq_basic_rw)

    reg_block_dut regmodel;

    function new(string name = "seq_basic_rw");
        super.new(name);
    endfunction

    task body();
        uvm_status_e  status;
        uvm_reg_data_t rdata;

        `uvm_info("SEQ", "=== 開始基礎讀寫測試 ===", UVM_MEDIUM)

        // ---- 寫入 REG_CTRL ----
        `uvm_info("SEQ", "寫入 CTRL: MODE=2, ENABLE=1", UVM_MEDIUM)
        regmodel.CTRL.write(status, 32'h0000_0006, UVM_FRONTDOOR);
        // 或使用 field 操作：
        // regmodel.CTRL.MODE.set(2'h2);
        // regmodel.CTRL.ENABLE.set(1'b1);
        // regmodel.CTRL.update(status);

        // ---- 讀回 REG_CTRL 並驗證 ----
        regmodel.CTRL.read(status, rdata, UVM_FRONTDOOR);
        `uvm_info("SEQ", $sformatf("讀回 CTRL = 0x%08h", rdata), UVM_MEDIUM)
        if (rdata[2:0] !== 3'b110)
            `uvm_error("CHK", $sformatf("CTRL 值錯誤！期望=0x6，實際=0x%0h", rdata[2:0]))

        // ---- 寫入 REG_DATA ----
        `uvm_info("SEQ", "寫入 DATA = 0xAB", UVM_MEDIUM)
        regmodel.DATA.DATA.write(status, 8'hAB, UVM_FRONTDOOR);

        regmodel.DATA.read(status, rdata, UVM_FRONTDOOR);
        `uvm_info("SEQ", $sformatf("讀回 DATA = 0x%08h", rdata), UVM_MEDIUM)

        // ---- 讀取唯讀 STATUS ----
        regmodel.STATUS.read(status, rdata, UVM_FRONTDOOR);
        `uvm_info("SEQ", $sformatf("STATUS.BUSY = %0b", rdata[0]), UVM_MEDIUM)

        `uvm_info("SEQ", "=== 基礎讀寫測試完成 ===", UVM_MEDIUM)
    endtask
endclass

// --- Desired/Mirrored 示範序列 ---
class seq_desired_mirror extends uvm_reg_sequence;
    `uvm_object_utils(seq_desired_mirror)

    reg_block_dut regmodel;

    function new(string name = "seq_desired_mirror");
        super.new(name);
    endfunction

    task body();
        uvm_status_e status;

        `uvm_info("SEQ", "=== desired vs mirrored 示範 ===", UVM_MEDIUM)

        // set() 只改 desired value，不產生 bus traffic
        regmodel.DATA.DATA.set(8'hFF);
        `uvm_info("SEQ",
            $sformatf("set 後：desired=0x%0h, mirrored=0x%0h",
                regmodel.DATA.DATA.get(),
                regmodel.DATA.DATA.get_mirrored_value()),
            UVM_MEDIUM)
        // 此時 desired != mirrored → update() 會觸發寫入
        regmodel.DATA.update(status, UVM_FRONTDOOR);
        `uvm_info("SEQ", "update() 完成，DUT 已同步", UVM_MEDIUM)

        // mirror() 從 DUT 讀回，並可選擇 UVM_CHECK 自動比對
        regmodel.DATA.mirror(status, UVM_CHECK, UVM_FRONTDOOR);
        `uvm_info("SEQ", "mirror(UVM_CHECK) 通過", UVM_MEDIUM)

        `uvm_info("SEQ", "=== desired vs mirrored 示範完成 ===", UVM_MEDIUM)
    endtask
endclass

// --- Reset 驗證序列 ---
class seq_reset_check extends uvm_reg_sequence;
    `uvm_object_utils(seq_reset_check)

    reg_block_dut regmodel;

    function new(string name = "seq_reset_check");
        super.new(name);
    endfunction

    task body();
        uvm_status_e status;

        `uvm_info("SEQ", "=== Reset 值驗證 ===", UVM_MEDIUM)
        // 通知 model reset 已發生，更新所有 mirrored = reset value
        regmodel.reset();

        // 用 mirror(UVM_CHECK) 逐一讀 DUT 並比對 reset 值
        regmodel.CTRL.mirror  (status, UVM_CHECK, UVM_FRONTDOOR);
        regmodel.DATA.mirror  (status, UVM_CHECK, UVM_FRONTDOOR);
        regmodel.STATUS.mirror(status, UVM_CHECK, UVM_FRONTDOOR);
        `uvm_info("SEQ", "所有暫存器 reset 值正確", UVM_MEDIUM)
    endtask
endclass

// ─────────────────────────────────────────────
//  SECTION 9：Test
// ─────────────────────────────────────────────
class test_reg_basic extends uvm_test;
    `uvm_component_utils(test_reg_basic)

    env_reg       env;
    reg_block_dut regmodel;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = env_reg::type_id::create("env", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        if (!uvm_config_db #(reg_block_dut)::get(this, "*", "regmodel", regmodel))
            `uvm_fatal("NO_RM", "找不到 regmodel")
    endfunction

    task run_phase(uvm_phase phase);
        seq_basic_rw      seq1;
        seq_desired_mirror seq2;
        seq_reset_check   seq3;

        phase.raise_objection(this);

        // --- 測試 1：基礎讀寫 ---
        seq1 = seq_basic_rw::type_id::create("seq1");
        seq1.regmodel = regmodel;
        seq1.start(null);  // reg_sequence 不需要掛 sequencer

        #100;

        // --- 測試 2：desired/mirrored ---
        seq2 = seq_desired_mirror::type_id::create("seq2");
        seq2.regmodel = regmodel;
        seq2.start(null);

        #50;

        // --- 測試 3：reset 驗證（需實際觸發 DUT rst_n）---
        // 注意：此處需要測試台頂層協助拉低 rst_n
        // force tb_top.rst_n = 0; #20; release tb_top.rst_n;
        seq3 = seq_reset_check::type_id::create("seq3");
        seq3.regmodel = regmodel;
        seq3.start(null);

        phase.drop_objection(this);
    endtask
endclass

// ─────────────────────────────────────────────
//  SECTION 10：Interface 與 Testbench Top
// ─────────────────────────────────────────────
interface apb_if (input logic clk);
    logic        rst_n;
    logic        psel;
    logic        penable;
    logic        pwrite;
    logic [7:0]  paddr;
    logic [31:0] pwdata;
    logic [31:0] prdata;
    logic        pready;
endinterface

module tb_top;
    logic clk;
    logic rst_n;

    // 時鐘產生
    initial clk = 0;
    always #5 clk = ~clk;  // 100 MHz

    // APB Interface
    apb_if apb_bus(.clk(clk));
    assign apb_bus.rst_n = rst_n;

    // 接入 DUT
    dut_reg_example u_dut (
        .clk     (clk),
        .rst_n   (rst_n),
        .psel    (apb_bus.psel),
        .penable (apb_bus.penable),
        .pwrite  (apb_bus.pwrite),
        .paddr   (apb_bus.paddr),
        .pwdata  (apb_bus.pwdata),
        .prdata  (apb_bus.prdata),
        .pready  (apb_bus.pready)
    );

    // 啟動 UVM，設定 interface
    initial begin
        uvm_config_db #(virtual apb_if)::set(null, "uvm_test_top.*", "vif", apb_bus);

        // Reset 序列
        rst_n = 0;
        repeat(4) @(posedge clk);
        rst_n = 1;

        // 啟動測試
        run_test("test_reg_basic");
    end

    // Timeout 保護
    initial begin
        #100_000;
        `uvm_fatal("TIMEOUT", "模擬超時，請檢查驗證環境")
    end
endmodule
