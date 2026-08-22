# AXI4 UVM VIP — Verification Specification & Test Plan

> **Protocol**: AMBA AXI4 (IHI0022E) | **Tool**: Cadence Xcelium (xrun)
> **Bus Parameters**: AWIDTH=32, DWIDTH=64, IDWIDTH=4, STRB_W=8
> **Mode**: Loopback (Master + Slave self-check)

---

## 目錄

1. [簡介](#1-簡介-introduction)
2. [VIP 架構分析](#2-vip-架構分析-architecture-analysis)
3. [介面訊號](#3-介面訊號-interface-signals)
4. [SVA Protocol Checker 分析](#4-sva-protocol-checker-分析)
5. [Checker 分析](#5-checker-分析)
6. [功能覆蓋率分析](#6-功能覆蓋率分析-functional-coverage)
7. [測試計畫](#7-測試計畫-test-plan)

---

## 1. 簡介 (Introduction)

### 1.1 目的

- 實作具有 Master Agent 與 Slave Agent 的 AXI VIP
- SPEC版本: AMBA AXI4 (IHI0022E)

### 1.2 範圍

- AXI4 五個 channel（AW / W / B / AR / R）之協定行為驗證
- 三種 burst 類型（FIXED / INCR / WRAP）之資料傳輸正確性
- Loopback 模式下的 Master + Slave 自我驗證
- SVA Protocol Checker 之協定合規性檢查
- Functional Coverage 規劃與缺口分析

---

## 2. VIP 架構分析 (Architecture Analysis)

### 2.1 檔案結構

| 目錄 | 檔案 | 職責 |
|---|---|---|
| `src/common/` | `axi_pkg.sv` | 全域參數、enum 定義、include 順序管理 |
| | `axi_transaction.sv` | Sequence item：burst constraint、`beat_addr()` 位址計算 |
| | `axi_if.sv` | Interface：3 組 clocking block (`mst_drv_cb` / `slv_drv_cb` / `mon_cb`) |
| | `axi_env.sv` | Environment：組裝所有 agent、scoreboard、coverage |
| | `axi_scoreboard.sv` | Shadow memory byte-level write/read 比對 |
| | `axi_coverage.sv` | Functional coverage：burst/len/size/id/4KB edge + cross |
| | `axi_reset_monitor.sv` | Event-based reset 協調（`ev_reset_start` / `ev_reset_done`） |
| | `axi_sequencer.sv` | `typedef uvm_sequencer #(axi_transaction)` |
| `src/master/` | `axi_mst_driver.sv` | Mailbox-based AW/W/AR dispatch，支援 `AXI_CH_AUTO` |
| | `axi_mst_monitor.sv` | AW+W FIFO 配對、B response ID matching、R interleaving |
| | `axi_mst_cfg.sv` | Per-channel delay 設定（valid delay / beat gap / ready delay） |
| | `axi_mst_agent.sv` | Agent wrapper（driver + monitor + sequencer） |
| `src/slave/` | `axi_slv_driver.sv` | 內建 byte-addressed `mem[]`、3 種 R response mode |
| | `axi_slv_monitor.sv` | 與 mst_monitor 相同架構 |
| | `axi_slv_cfg.sv` | Per-channel delay 設定 + `read_resp_mode` 選擇 |
| | `axi_slv_agent.sv` | Agent wrapper |
| `src/seq_lib/` | `axi_base_seq.sv` | 提供 `write()` / `read()` task-level 介面 |
| | `axi_fixed/incr/wrap_wr_seq.sv` | 各 burst type 之 write-then-read sequence |
| `sva/` | `axi_protocol_checker.sv` | SVA module：7 組 property（stable/reset/WRAP/4KB） |
| | `axi_bind.sv` | Bind module（`ifdef HAS_DUT` 條件編譯） |
| `test/` | `axi_base_test.sv` | Base test：build env、raise/drop objection |
| | `axi_fixed/incr/wrap_wr_test.sv` | 對應 3 種 burst type 之 directed test |
| `tb/` | `tb_top.sv` | Top module：clock/reset、interface、SVA instantiation |

### 2.2 環境拓撲（Loopback 模式）

目前 VIP 運作於 Loopback 模式：Master agent 與 Slave agent 接在同一組 `axi_if` 上，Master 送出之 transaction 由 Slave driver 接收並回應。沒有外部 DUT，用於 VIP 自身正確性驗證。

| 元件 | 實作特點 |
|---|---|
| `axi_mst_driver` | Mailbox 架構，AW/W/AR 各自獨立 thread 驅動，支援 channel 欄位（`AXI_CH_AUTO` / `AXI_CH_AW` / `AXI_CH_W`）分離控制，可模擬 W-before-AW |
| `axi_slv_driver` | `handle_aw()` + `collect_w()` + `pair_and_respond()` 三段式 FIFO 配對，正確處理 AW/W 到達順序不確定性，寫入 byte-addressed `mem[]` |
| `axi_slv_driver` R channel | 3 種 response mode：`AXI_R_FIFO`（先到先回）、`AXI_R_OOO`（隨機挑 burst）、`AXI_R_INTERLEAVE`（beat 層級交錯） |
| `axi_mst_monitor` | AW+W 獨立收集再 FIFO 配對，B response 用 ID matching，R channel 支援 per-ID beat counter（interleaving 安全） |
| `axi_scoreboard` | 單一 `analysis_imp`，依 direction 分流 `handle_write` / `handle_read`，用 shadow memory byte-level 比對 |
| `axi_coverage` | `uvm_subscriber`，接 `mst_monitor.ap`，covergroup 含 burst/len/size/id/4KB edge 與 2 組 cross |
| `axi_reset_monitor` | 集中式 reset 管理：`ev_reset_start` / `ev_reset_done` event，所有 driver/monitor 統一監聽 |
| `axi_protocol_checker` | 獨立 SVA module，涵蓋 VALID stable、payload stable、reset low、WRAP len/align、4KB boundary 共 15 條 assertion |

### 2.3 功能

- Master driver 的 **channel 分離機制**（`AXI_CH_AUTO` / `AXI_CH_AW` / `AXI_CH_W`）讓使用者可以獨立控制 AW 跟 W 的發送時機，支援 W-before-AW 測試情境
- Slave driver 的**三種 R response mode** 讓同一套 VIP 可以驗證 FIFO、Out-of-Order、Interleaving 三種回應行為
- Reset monitor 採**集中式 event 架構**，所有 component 共用同一份 reset 狀態，避免各 component 自行偵測 reset 造成的時序不一致

---

## 3. 介面訊號 (Interface Signals)

AXI VIP 介面定義於 `axi_if.sv`，參數化支援 AWIDTH / DWIDTH / IDWIDTH。三組 clocking block 分別服務 master driver、slave driver、monitor，確保驅動與取樣時序正確。

| Channel | 訊號 | 方向 (Master) | 說明 |
|---|---|---|---|
| Global | `aclk` / `aresetn` | In | 系統時脈（100MHz）與低態非同步 reset |
| AW | `awid`/`awaddr`/`awlen`/`awsize`/`awburst` | Out | 寫入位址與 burst 屬性 |
| AW | `awlock`/`awcache`/`awprot` | Out | Lock / Cache / Protection（目前 default constraint） |
| AW | `awvalid` / `awready` | Out / In | 位址通道 handshake |
| W | `wdata` / `wstrb` / `wlast` | Out | 寫入資料、byte strobe、burst 結尾標記 |
| W | `wvalid` / `wready` | Out / In | 資料通道 handshake |
| B | `bid` / `bresp` | In | 寫入回應 ID 與回應碼 |
| B | `bvalid` / `bready` | In / Out | 回應通道 handshake |
| AR | `arid`/`araddr`/`arlen`/`arsize`/`arburst` | Out | 讀取位址與 burst 屬性 |
| AR | `arvalid` / `arready` | Out / In | 讀取位址 handshake |
| R | `rid` / `rdata` / `rresp` / `rlast` | In | 讀取資料與回應 |
| R | `rvalid` / `rready` | In / Out | 讀取資料 handshake |

---

## 4. SVA Protocol Checker 分析

`axi_protocol_checker.sv` 定義了assertion，涵蓋協定核心規則：

| SVA 編號 | Assertion 名稱 | 對應規格 | 說明 |
|---|---|---|---|
| 001a | `A_AR_VALID_STABLE` | A3.2.2 | ARVALID stable until ARREADY |
| 001b | `A_W_VALID_STABLE` | A3.2.2 | WVALID stable until WREADY |
| 001c | `A_R_VALID_STABLE` | A3.2.2 | RVALID stable until RREADY |
| 001d | `A_B_VALID_STABLE` | A3.2.2 | BVALID stable until BREADY |
| 001e | `A_AW_VALID_STABLE` | A3.2.2 | AWVALID 拉高後不可在 AWREADY 前撤回 |
| 002a | `A_AW_PAYLOAD_STABLE` | A3.2.2 | AWVALID && !AWREADY 期間 payload 不可變 |
| 002b | `A_AR_PAYLOAD_STABLE` | A3.2.2 | AR payload stable |
| 002c | `A_W_PAYLOAD_STABLE` | A3.2.2 | W channel payload stable until handshake |
| 003a-e | `A_RESET_LOW_*VALID` | A3.1.2 | Reset 期間所有 VALID 必須為 0 |
| 004a-b | `A_AW/AR_WRAP_LEN` | A3.4.1 | WRAP burst len 必須為 1/3/7/15 |
| 005a-b | `A_AW/AR_WRAP_ALIGN` | A3.4.1 | WRAP burst 起始位址必須 size-aligned |
| 006a-b | `A_AW/AR_4KB` | A3.4.1 | INCR burst 不可跨越 4KB boundary |

---

## 5. Checker 分析

### 5.1 Checking 分層

| 層級 | 元件 | 檢查內容 |
|---|---|---|
| Protocol (SVA) | `axi_protocol_checker` | VALID stable / payload stable / reset / WRAP / 4KB |
| Protocol (Monitor) | `axi_mst_monitor` | AW+W burst length mismatch、B response 無匹配之 AW、R beat 無匹配之 AR |
| Data (Scoreboard) | `axi_scoreboard` | Write data vs Read-back data byte-level 比對 |

---

## 6. 功能覆蓋率分析 (Functional Coverage)

### 6.1 現有 Covergroup（`cg_axi_txn`）

| Coverpoint / Cross | Bins | 說明 |
|---|---|---|
| `cp_dir` | rd / wr | Read 與 Write 方向 |
| `cp_len` | len1(0) / len2_4(1~3) / len8_16(7~15) / len17_64(16~63) / len_max(64~255) | Burst 長度分bin |
| `cp_size` | s[0:$clog2(STRB_W)] | 自動分bin（0~3 for 64-bit bus） |
| `cp_burst` | fixed / incr / wrap | 三種 burst 類型 |
| `cp_id` | 自動分bin（16 bins for 4-bit ID） | Transaction ID 分佈 |
| `cp_4kb_edge` | hit / miss | 是否剛好碰到 4KB 邊界 |
| `cx_burst_x_len` | cross cp_burst × cp_len | 各 burst 類型的長度分佈 |
| `cx_dir_x_size` | cross cp_dir × cp_size | 讀寫方向 × burst size |

---

## 7. 測試計畫 (Test Plan)

### 7.1 測試案例

| 編號 | 測試名稱 | 狀態 | 說明 |
|---|---|---|---|
| T01 | `axi_fixed_wr_test` | 已實作 | FIXED burst write-then-read，單筆，`#1000` 等待後讀回 |
| T02 | `axi_incr_wr_test` | 已實作 | INCR burst write-then-read，隨機 len/size/addr |
| T03 | `axi_wrap_wr_test` | 已實作 | WRAP burst write-then-read，constraint 限制 len=1/3/7/15 |
| T04 | `axi_random_rw_test` | None | 全隨機 burst/len/size/addr/id，連續多筆 write-then-read |
| T05 | `axi_outstanding_wr_test` | None | 多筆 write 同時 outstanding（不等 B response 就發下一筆），驗證 mailbox 與 ID ordering |
| T06 | `axi_outstanding_rd_test` | None | 多筆 read 同時 outstanding，搭配不同 ID |
| T07 | `axi_concurrent_rw_test` | None | Read 與 Write 同時進行（parallel fork），驗證 driver 的多通道並行 |
| T08 | `axi_backpressure_test` | None | 透過 `mst_cfg` / `slv_cfg` 設定大範圍延遲，驗證無死結 |
| T09 | `axi_w_before_aw_test` | None | 強制 W channel 先發（透過 `mst_cfg` 對 AW 做delay drive），驗證 slave pairing |
| T10 | `axi_wrap_boundary_test` | None | WRAP burst 位址回繞，起始位址於邊界附近 |
| T11 | `axi_r_ooo_test` | None | Slave 設定 `read_resp_mode = AXI_R_OOO`，驗證 monitor 的 per-ID tracking |
| T12 | `axi_r_interleave_test` | None | Slave 設定 `AXI_R_INTERLEAVE`，驗證 beat 層級交錯 |
| T13 | `axi_max_outstanding_stress` | None | 逼近 outstanding 上限之壓力測試 |
| T14 | `axi_reset_mid_txn_test` | None | Transaction 進行中觸發 reset，驗證 `reset_monitor` 協調所有 component 正確復原 |
| T15 | `axi_4kb_boundary_edge_test` | None | INCR burst 接近 4KB 邊界，驗證 SVA `A_AW/AR_4KB` |
| T16 | `axi_raw_hazard_test` | None | 同一位址的 write 未完成就發 read，觀察 scoreboard 行為 |

---

## 8. Simulation

進入 sim 資料夾執行makefile

`make`
