# AMBA APB

#### VIP for APB Protocol

## APB Verification Spec

./APB_Verification_Spec.md

## APB Test Plan

./APB_Test_Plan.md

## APB Interface

| Signal    | Direction (Master) | Width           | Description                         |
| --------- | ------------------ | --------------- | ----------------------------------- |
| `PCLK`    | Input              | 1               | APB clock                           |
| `PRESETn` | Input              | 1               | Active-low reset                    |
| `PADDR`   | Output             | `APB_ADDR_WIDTH | Address bus                         |
| `PWRITE`  | Output             | 1               | Write enable (1=write, 0=read)      |
| `PSEL`    | Output             | 1               | Slave select (one-hot, multi-slave) |
| `PENABLE` | Output             | 1               | Enable for access phase             |
| `PWDATA`  | Output             | `APB_DATA_WIDTH | Write data bus                      |
| `PREADY`  | Input              | 1               | Slave ready signal                  |
| `PRDATA`  | Input              | `APB_DATA_WIDTH | Read data bus                       |
| `PSLVERR` | Input              | 1               | Slave error response                |

---

## APB Protocol Behavior

- **Setup Phase**:
  - Master asserts `PSEL` with valid `PADDR`, `PWRITE`, `PWDATA` (for write) on the rising edge of `PCLK`.

- **Access Phase**:
  - After `PSEL` is set to HIGH, the next CLOCK `PENABLE` must also be set to HIGH.
  - Master asserts `PENABLE` while keeping `PSEL` high.
  - Slave responds with `PREADY` and provides `PRDATA` for read operations.

- **Timing Control**:
  - Single setup and access phase; no burst support.
  - Ready signal may insert wait states.

- **Error Response**:
  - Slave asserts `PSLVERR` high during the access phase to indicate a transfer error.
  - `PSLVERR` is only valid when `PSEL`, `PENABLE`, and `PREADY` are all high.
  - ⚠️ Status: Planned — PSLVERR detection is defined but not yet implemented.

---

## 檔案階層目錄樹

```
├── rtl/
│   └── apb_mem.v             # 待測設計 (DUT)：參數化 APB Memory Slave
│
└── tb/
    ├── apb_defines.svh       # 全域宏定義：包含資料位寬與狀態常數
    ├── apb_item.sv           # 交易層物件 (Transaction)：定義 APB 傳輸封包
    │
    ├── apb_agent/            # Agent 層組件
    │   ├── apb_agent.sv      # Agent 容器：封裝 Driver, Monitor 與 Sequencer
    │   ├── apb_driver.sv     # 驅動器：實現 APB 狀態機訊號驅動
    │   └── apb_monitor.sv    # 監測器：匯流排活動採樣並轉換為 Transaction
    │
    ├── apb_env/              # Environment 層組件
    │   ├── apb_env.sv        # 環境容器：連接 Agent 與 Scoreboard
    │   └── apb_scoreboard.sv # 計分板：內建 Shadow Memory 進行數據比對
    │
    ├── apb_sequence.sv       # Sequence 庫：定義基礎寫入/讀取測試序列
    |
    |
    └── base_test.sv          # 測試案例：包含 base_test 與具體的 apb_test_wr_rd
```
