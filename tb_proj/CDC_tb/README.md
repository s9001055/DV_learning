# CDC Asymc_fifo

## TestBench for CDC Asymc_fifo

[CDC Verification Spec](./CDC_Verification_Spec.md)

[CDC Test Plan](./CDC_Test_Plan.md)

## Asymc_fifo Interface

| Signal      | Direction (Master) | Width                  | Description                              |
| ----------- | ------------------ | ---------------------- | ---------------------------------------- |
| `WCLK`      | Input              | 1                      | Write domain clock (200 MHz)             |
| `RCLK`      | Input              | 1                      | Read domain clock (133 MHz)              |
| `WRST_N`    | Input              | 1                      | Write domain active-low async reset      |
| `RRST_N`    | Input              | 1                      | Read domain active-low async reset       |
| `WINC`      | Output             | 1                      | Write increment (write enable)           |
| `WDATA`     | Output             | `CDC_DATA_WIDTH` (8)   | Write data bus                           |
| `WFULL`     | Input              | 1                      | FIFO full flag (write domain)            |
| `RINC`      | Output             | 1                      | Read increment (read enable)             |
| `RDATA`     | Input              | `CDC_DATA_WIDTH` (8)   | Read data bus                            |
| `REMPTY`    | Input              | 1                      | FIFO empty flag (read domain)            |
| `wptr_gray` | Probe              | `CDC_ADDR_WIDTH+1` (5) | Write pointer Gray Code (internal probe) |
| `rptr_gray` | Probe              | `CDC_ADDR_WIDTH+1` (5) | Read pointer Gray Code (internal probe)  |

---

## CDC Asymc_fifo Protocol Behavior

- **Write Phase**:
  - Master asserts `WINC` with valid `WDATA` on the rising edge of `WCLK`.
  - Write is only effective when `WFULL = 0`; DUT ignores `WINC` when full.

- **Read Phase**:
  - Master asserts `RINC` on the rising edge of `RCLK`.
  - `RDATA` is combinational output, valid when `REMPTY = 0`.
  - DUT ignores `RINC` when `REMPTY = 1`.

- **CDC Synchronization**:
  - Write pointer (`wptr_gray`) synchronizes to RCLK domain via Two-FF synchronizer.
  - Read pointer (`rptr_gray`) synchronizes to WCLK domain via Two-FF synchronizer.
  - Synchronization latency is 2 cycles of the destination clock domain.
  - Gray Code encoding ensures only 1 bit changes per pointer increment — CDC safe.

- **Full / Empty Flags**:
  - `WFULL`: asserted the cycle after the 16th entry is written; de-asserts 2 WCLK after a read.
  - `REMPTY`: asserted after reset and after the last entry is read; de-asserts 2 RCLK after a write.
  - `WFULL` and `REMPTY` must never be high simultaneously.

- **Reset**:
  - `WRST_N` and `RRST_N` are independent async resets; they may be de-asserted at different times.
  - Both pointers must clear to 0 within one cycle of their respective reset de-assertion.

---

## 檔案階層目錄樹

```
├── rtl/
│   └── async_fifo.v              # 待測設計 (DUT)：深度 16、32-bit 非同步 FIFO
│                                 #   Gray Code pointer 跨域同步，Two-FF Synchronizer
│
└── tb/
    ├── cdc_defines.svh           # 全域巨集：CDC_DATA_WIDTH / CDC_DEPTH / CDC_ADDR_WIDTH
    │
    ├── cdc_fifo_if.sv            # Virtual Interface
    │                             #   - write_cb / read_cb（Driver 用 Clocking Block）
    │                             #   - write_mon_cb / read_mon_cb（Monitor 用 Clocking Block）
    │                             #   - wptr_gray / rptr_gray probe 訊號
    │                             #   - 7 個 SVA assertions
    │
    ├── cdc_seq_item.sv           # Transaction Items
    │                             #   - fifo_write_item：rand data + rand gap_cycles
    │                             #   - fifo_read_item：data（monitor 填入）+ rand gap_cycles
    │
    ├── cdc_sequence.sv           # Sequence 庫
    │                             #   - fifo_base_write_seq / fifo_base_read_seq（基底）
    │                             #   - seq_basic_write / seq_basic_read（4~8 筆固定序列）
    │                             #   - seq_fill_fifo（寫滿 CDC_DEPTH 筆，觸發 WFULL）
    │                             #   - seq_drain_fifo（讀空 CDC_DEPTH 筆，觸發 REMPTY）
    │
    ├── cdc_write_agent/
    │   ├── cdc_write_agent.sv    # Write Agent 容器（WCLK domain）
    │   ├── cdc_write_driver.sv   # Write Driver：等 WFULL=0 後驅動 WINC + WDATA
    │   └── cdc_write_monitor.sv  # Write Monitor：偵測 WINC=1 且 WFULL=0，抓 WDATA
    │
    ├── cdc_read_agent/
    │   ├── cdc_read_agent.sv     # Read Agent 容器（RCLK domain）
    │   ├── cdc_read_driver.sv    # Read Driver：等 REMPTY=0 後驅動 RINC
    │   └── cdc_read_monitor.sv   # Read Monitor：偵測 RINC=1 且 REMPTY=0，抓 RDATA
    │
    ├── cdc_scoreboard.sv         # Scoreboard：雙 domain 資料比對
    │                             #   - write_export / read_export（各接一個 analysis_fifo）
    │                             #   - run_phase blocking get，FIFO 語意先進先出比對
    │                             #   - report_phase 輸出 PASS/FAIL 統計
    │
    ├── cdc_env.sv                # Environment：連接 Write Agent、Read Agent、Scoreboard
    │
    ├── cdc_base_test.sv          # Test 層
    │                             #   - cdc_base_test：共用 apply_reset task
    │                             #   - test_basic_rw：先寫 8 筆再讀 8 筆
    │                             #   - test_full_boundary：填滿後確認 WFULL，排空後確認 REMPTY
    │
    └── top_tb.sv                 # Top-level Testbench
                                  #   - WCLK 200 MHz (2.5 ns)、RCLK 133 MHz (3.76 ns)
                                  #   - RCLK 故意延遲 1 ns，相位不對齊
                                  #   - DUT 參數由 cdc_defines.svh 巨集帶入
                                  #   - wptr_gray / rptr_gray probe 連至 interface
                                  #   - 波形輸出：top_tb.shm（$shm_open / $shm_probe）
                                  #   - Timeout 保護 500 us
```

## 執行方式

```bash
# 指定 test 名稱執行
xrun -f cdc.f +UVM_TESTNAME=test_basic_rw

# 開啟 UVM message verbosity
xrun -f cdc.f +UVM_TESTNAME=test_full_boundary +UVM_VERBOSITY=UVM_HIGH

# 查看波形（Cadence SimVision）
simvision top_tb.shm &
```
