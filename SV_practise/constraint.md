# Constraint 練習

---

## Constraint 交集分析

**題目：** `randomize()` 會不會成功？如果成功，`addr` 的可能值域是什麼？

```systemverilog
class pkt extends uvm_sequence_item;
  rand bit [7:0] addr;
  rand bit [1:0] burst;

  constraint c1 { addr[1:0] == 2'b00; }
  constraint c2 { (burst == 2'b10) -> addr > 8'hF0; }
  constraint c3 { burst == 2'b10; }
endclass
```

**答案：**

會成功。

- `c3` 鎖定 `burst == 2'b10`
- `c2` 因此生效，要求 `addr > 8'hF0`，即 `addr ∈ {8'hF1 ~ 8'hFF}`
- `c1` 要求 word-aligned，`addr[1:0] == 2'b00`

兩者交集只剩三個值：**`8'hF4`、`8'hF8`、`8'hFC`**

---

## Implication 方向性（`->` vs `<->`）

**題目：** 以下兩個 constraint 的行為有什麼不同？`mode == 0` 且 `len == 8` 在 A 和 B 分別合不合法？

```systemverilog
// 版本 A
constraint ca { (mode == 1) -> (len > 4); }

// 版本 B
constraint cb { (mode == 1) <-> (len > 4); }
```

**答案：**

- 版本 A：**合法**。`->` 是單向蘊含，前件 `mode == 1` 為假時，整個 expression 自動為真（vacuous truth），不管後件是什麼。
- 版本 B：**不合法**。`<->` 是雙向蘊含，兩邊必須同真同假。`len == 8 > 4` 為真，所以 `mode` 也必須為 1，與 `mode == 0` 矛盾。

**關鍵字：** Vacuous truth — 單向 implication 前件為假時自動成立。

---

## `solve...before` 機率分佈

**題目：** 以下兩段 code 在隨機結果的機率分佈上有什麼差異？`flag == 1` 的機率在 A 和 B 分別是多少？

```systemverilog
// 版本 A：沒有 solve...before
class pkt extends uvm_sequence_item;
  rand bit       flag;
  rand bit [2:0] data;

  constraint c1 { flag -> (data inside {3'b001, 3'b010}); }
endclass

// 版本 B：有 solve...before
class pkt extends uvm_sequence_item;
  rand bit       flag;
  rand bit [2:0] data;

  constraint c1 { flag -> (data inside {3'b001, 3'b010}); }
  constraint c2 { solve flag before data; }
endclass
```

**答案：**

版本 A：列出所有合法組合：

- `flag == 0`：data = 0~7（implication 自動成立）→ **8 種**
- `flag == 1`：data 只能是 001、010 → **2 種**
- 總共 **10 種**，`P(flag == 1) = 2/10 = 20%`

版本 B：`solve flag before data` 讓 solver 先決定 `flag`，此時 0 和 1 各 **50%**。確定 `flag` 之後才去解 `data` 的值域。

**使用時機：** 當你希望某個控制變數（flag、mode、burst type）的分佈不要被另一個變數的值域大小「稀釋」掉時使用。在 coverage-driven test 中特別重要，否則某些模式因為組合數少而幾乎不被選到。

---

## Constraint 衝突判斷

**題目：** `randomize()` 會成功還是失敗？

```systemverilog
class pkt extends uvm_sequence_item;
  rand bit [3:0] addr;
  rand bit [3:0] size;

  constraint c1 { addr inside {[4:7]};  }
  constraint c2 { size inside {1, 2, 4}; }
  constraint c3 { addr + size <= 8;     }
  constraint c4 { addr >= size * 2;     }
endclass
```

**答案：**

會成功。固定值域小的變數（size 只有 3 個值），逐一代入檢查：

**size = 4：**

- `c4`：`addr >= 8`，但 `c1` 限制 addr 最大 7 → **矛盾，排除**

**size = 1：**

- `c4`：`addr >= 2` → {4,5,6,7} 全過
- `c3`：`addr + 1 <= 8` → `addr <= 7` → 全過
- 合法組合：**(4,1)、(5,1)、(6,1)、(7,1)**

**size = 2：**

- `c4`：`addr >= 4` → 全過
- `c3`：`addr + 2 <= 8` → `addr <= 6`
- 合法組合：**(4,2)、(5,2)、(6,2)**

總共 **7 種**合法組合。

---

## 動態控制與繼承

**題目：** 拿到別人寫好的 base class，不能改原始碼。如何在特定 test 中改變行為？

```systemverilog
class base_pkt extends uvm_sequence_item;
  `uvm_object_utils(base_pkt)

  rand bit [7:0]  addr;
  rand bit [15:0] data;
  rand bit [2:0]  burst;

  constraint c_addr { addr inside {[8'h00:8'h7F]}; }
  constraint c_burst { burst < 5; }
endclass
```

需求：`addr` 改成 `[8'h80:8'hFF]`、`burst` 固定為 3、`data` 維持完全隨機。

**答案：**

**重要觀念：** inline constraint 是「附加」在原有 constraint 之上，不是「取代」。直接用 `randomize() with { addr inside {[8'h80:8'hFF]}; }` 會跟原本的 `c_addr` 衝突而失敗。

**做法一：`constraint_mode()` + inline constraint（局部調整）**

```systemverilog
base_pkt tr = base_pkt::type_id::create("tr");
tr.c_addr.constraint_mode(0);
tr.c_burst.constraint_mode(0);
assert(tr.randomize() with {
  addr inside {[8'h80:8'hFF]};
  burst == 3;
});
```

**做法二：繼承 + constraint override + factory**

```systemverilog
class high_addr_pkt extends base_pkt;
  `uvm_object_utils(high_addr_pkt)

  // 同名 constraint 自動覆蓋 parent 的版本
  constraint c_addr  { addr inside {[8'h80:8'hFF]}; }
  constraint c_burst { burst == 3; }
endclass

// test 的 build_phase 中
set_type_override_by_type(
  base_pkt::get_type(),
  high_addr_pkt::get_type()
);
```

|          | constraint_mode          | 繼承 override                 |
| -------- | ------------------------ | ----------------------------- |
| 影響範圍 | 單次、局部               | 全域或特定路徑                |
| 適合場景 | sequence 裡臨時調整      | 整個 test 都要改行為          |
| 可維護性 | 散落各處，容易忘記開回來 | 集中管理，搭配 factory 很乾淨 |

---

## DMA Descriptor Constraint

**題目：** 設計一個 `dma_descriptor` class，約束需求：

1. `src_addr` 和 `dst_addr` 都必須 4-byte aligned
2. Transfer 不能跨越 4K boundary
3. `mode == FILL` 時，`transfer_len` 只能是 4 的倍數
4. `mode == SCATTER` 時，`src_addr` 和 `dst_addr` 不能在同一個 4K page
5. `mode` 的值只能是 0、1、2

**答案：**

```systemverilog
typedef enum bit [1:0] {
  NORMAL = 0, FILL = 1, SCATTER = 2
} dma_mode_e;

class dma_descriptor extends uvm_sequence_item;
  `uvm_object_utils(dma_descriptor)

  rand bit [31:0] src_addr, dst_addr;
  rand bit [7:0]  transfer_len;
  rand dma_mode_e mode;

  constraint c_align {
    src_addr[1:0] == 2'b00;
    dst_addr[1:0] == 2'b00;
  }

  constraint c_len_min { transfer_len >= 1; }

  constraint c_4k_boundary {
    src_addr[31:12] == (src_addr + transfer_len - 1)[31:12];
  }

  constraint c_mode_rule {
    (mode == FILL)    -> (transfer_len[1:0] == 2'b00);
    (mode == SCATTER) -> (src_addr[31:12] != dst_addr[31:12]);
  }
endclass
```

**常見錯誤與注意事項：**

- **Alignment**：用 `addr[1:0] == 2'b00` 比 `inside` 簡潔
- **4K boundary**：用 bit slice `[31:12]` 比較比除法/modulo 更 solver 友善
- **`transfer_len >= 1`**：`bit [7:0]` 值域包含 0，需要額外約束，容易漏掉
- **`transfer_len[1:0] == 2'b00`**：比 `transfer_len % 4 == 0` 更偏硬體思維，面試加分
- **Enum**：用 `typedef enum` 定義 mode，比直接用數字可讀性高

---
