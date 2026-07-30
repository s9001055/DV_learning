# SVA 序列（Sequence）運算子

---

## 1. 延遲運算子 `##` — 序列的時間骨架

`##` 連接兩個布林表達式，決定了前後事件之間要隔幾個 clock cycle

### 1.1 固定延遲

```systemverilog
a ##0 b      // 同一 cycle，a 和 b 同時成立
a ##1 b      // a 成立的下一 cycle b 成立
a ##5 b      // a 成立後恰好 5 cycle b 成立
```

`##0` 的語意是「同一取樣點」。它最常出現在把兩個條件合在一個時間點檢查：

```systemverilog
// 等價於 (psel && !penable)
psel ##0 !penable
```

### 1.2 範圍延遲

```systemverilog
a ##[1:3] b     // a 成立後 1~3 cycle 之間 b 成立
a ##[0:5] b     // a 的同一 cycle 或之後 0~5 cycle
a ##[1:$] b     // a 之後，1 cycle 到「模擬結束」之間
```

範圍延遲產生多個可能的 match。例如 `a ##[1:3] b`，如果 b 在 cycle 2 和 cycle 3 都是 high，則有兩個 match（長度不同）。這在搭配 implication 時很重要 — 每個 match 都會獨立觸發後件的評估。

```systemverilog
// 如果只想取「第一個」match（最短的），用 first_match
first_match(a ##[1:5] b)

// 這在後件有固定 timing 時特別重要
property p_strict;
  @(posedge clk)
  first_match(req ##[1:3] ack) |-> ##2 done;
endproperty
// 不加 first_match：req 之後每個 ack match 都啟動獨立的 ##2 done 檢查
// 加了 first_match：只有第一個 ack 啟動
```

### 1.3 `##[1:$]` — 開放式延遲的陷阱

```systemverilog
// 「req 之後總有一天 ack 會來」
req |-> ##[1:$] ack

// 問題：如果模擬在 ack 來之前就結束了呢？
// 預設行為（weak）：模擬結束前沒 match → inconclusive → 不報 fail
// 如果你真的要求 ack 一定要來，用 strong：
req |-> strong(##[1:$] ack)   // ack 沒來 → fail
```

---

## 2. 連續重複 `[*N]` — Consecutive Repetition

`[*N]` 表示某個布林表達式必須「連續 N 個 cycle 都成立」。

```systemverilog
b[*3]         // b 連續 3 cycles high
              // 等價於 b ##1 b ##1 b

b[*0]         // ⚠ 特殊：不佔任何 cycle（空匹配）
b[*2:5]       // b 連續 high 2~5 cycles
b[*0:3]       // b 連續 high 0~3 cycles（包含「完全不出現」的情況）
```

### 2.1 `[*0]` 的特殊語意

`[*0]` 不是「b 等於 0」，而是「這個子序列消失了，不佔任何 cycle」：

```systemverilog
a ##1 b[*0] ##1 c
// b[*0] 消除了自己和兩邊各一個 ##1
// 等價於 a ##1 c   （不是 a ##2 c！）

// 實際用法：可選的中間狀態
a ##1 busy[*0:3] ##1 done
// busy 可以出現 0~3 cycles，然後 done
// 如果 busy 出現 0 次 → a ##1 done
// 如果 busy 出現 2 次 → a ##1 busy ##1 busy ##1 done
```

### 2.2 實戰範例：AHB Burst

```systemverilog
// AHB INCR4 burst：NONSEQ 開頭，接 3 個 SEQ
sequence s_incr4;
  (htrans == NONSEQ && hburst == INCR4)
  ##1 (htrans == SEQ)[*3];      // SEQ 連續 3 cycles
endsequence

// AHB INCR（不定長 burst）：NONSEQ 開頭，1 個以上 SEQ
sequence s_incr;
  (htrans == NONSEQ && hburst == INCR)
  ##1 (htrans == SEQ)[*1:$];    // 至少 1 個 SEQ，上限不定
endsequence

// 考慮 wait state（hready low 時 htrans 保持不變）搭配 p_htrans_stable_during_wait
sequence s_incr4_with_wait;
  (htrans == NONSEQ && hburst == INCR4 && hready)
  ##1 ((htrans == SEQ && hready)[->1])[*3];  // 3 個有效的 SEQ beat
endsequence

// 獨立的 property 檢查 wait state 期間 htrans 穩定
property p_htrans_stable_during_wait;
    @(posedge hclk) disable iff (!hresetn)
    (!hready) |-> ##1 $stable(htrans);
endproperty
```

---

## 3. 跳躍重複 `[->N]` — Goto Repetition

`[->N]` 表示「第 N 次出現布林表達式為 true 的 cycle」。中間可以有任意多個 false 的 cycle。

```systemverilog
b[->3]    // 等到 b 第 3 次為 true
          // 中間的 !b cycles 都被跳過
          // match 結束在第 3 個 b 出現的那個 cycle
```

### 3.1 `[->N]` 的 match 結束點

關鍵：`[->N]` 的 match 嚴格結束在第 N 個 true 的 cycle。這表示如果後面緊接 `##1 c`，c 必須在第 N 個 b 的下一 cycle 就成立。

```
波形：b = 0, 1, 0, 1, 0, 0, 1, 0, 0
            ↑     ↑        ↑
            1st   2nd      3rd

b[->3] 的 match 在 cycle 6（第 3 個 b=1）
b[->3] ##1 done → done 必須在 cycle 7 成立
```

### 3.2 實戰範例：等待第 N 個 handshake

```systemverilog
// 等 3 筆 valid/ready handshake 完成
sequence s_three_txns;
  (valid && ready)[->3];
endsequence

// 第 3 筆完成後，下一 cycle done 必須拉高
property p_done_after_three;
  @(posedge clk) disable iff (rst)
  $rose(start) |-> s_three_txns ##1 done;
endproperty
```

---

## 4. 非連續重複 `[=N]` — Non-consecutive Repetition

`[=N]` 和 `[->N]` 幾乎相同 — 都是「等到布林表達式累計 N 次為 true」。差別在 match 的結束點。

### 4.1 `[->N]` vs `[=N]` 核心差異

```
波形：b = 0, 1, 0, 1, 0, 0, 1, 0, 0
   cycle:  0  1  2  3  4  5  6  7  8
              ↑     ↑         ↑
              1st   2nd       3rd

b[->3]：match 嚴格結束在 cycle 6（第 3 個 b=1）
        → 只有一個 match 點：cycle 6

b[=3]： match 可以在 cycle 6 結束，也可以延伸到 cycle 7, 8...
        → 多個 match 點：cycle 6, 7, 8...（只要 b 不再出現第 4 次）
```

### 4.2 搭配後續事件的差異

```systemverilog
// [->3]：match 鎖定在第 3 個 b=1 的 cycle
// 之後如果接 ##1 c，c 必須在「第 3 個 b 的下一 cycle」成立
b[->3] ##1 c      // c 必須在 cycle 7（第 3 個 b 的下一 cycle）

// [=3]：match 可以在第 3 個 b=1 之後繼續「滑行」，吸收後面的 !b cycles
// 之後如果接 ##1 c，c 可以在更晚的 cycle 成立
b[=3] ##1 c       // c 可以在 cycle 7, 8, 9... 任何 cycle（只要 b 不再出現第 4 次）
```

### 4.3 什麼時候用 `[=N]` 而不是 `[->N]`？

當你不在乎第 N 次 match 之後到下一個事件之間有多少空閒 cycle 時。例如：

```systemverilog
// 「在一筆 burst 中，data_valid 累計出現 4 次，然後 burst 結束」
// 不確定 burst_end 在第 4 個 valid 之後多久出現
property p_burst_complete;
  @(posedge clk) disable iff (rst)
  burst_start |-> data_valid[=4] ##1 burst_end;
endproperty
// 用 [=4]：burst_end 可以在第 4 個 valid 之後任意 cycle
// 用 [->4]：burst_end 必須緊接在第 4 個 valid 的下一 cycle
```

---

## 5. 序列組合運算子

這些運算子把兩個序列合成更複雜的時序模式。

### 5.1 `and` — 兩序列皆須成功

```systemverilog
// s1 和 s2 從同一 cycle 開始，都必須 match
// match 結束時間 = 較晚結束的那個
(a ##[1:3] b) and (c ##[2:4] d)
// 兩者都從當前 cycle 開始
// 如果 a##2 b match 在 cycle 2，c##3 d match 在 cycle 3
// → and 的整體 match 在 cycle 3（取較晚者）
```

`and` vs `&&` 的差異：在 sequence 層級，`and` 是 sequence 運算子；`&&` 是布林運算子。別搞混：

```systemverilog
(a && b)           // 布林：a 和 b 在同一 cycle 同時為 true
(seq1 and seq2)    // 序列：兩個時序序列都要 match
```

### 5.2 `or` — 至少一個成功

```systemverilog
// s1 或 s2 至少一個 match
(a ##1 b) or (a ##2 c)
// 如果 b 在 cycle 1 成立 → match（不管 c）
// 如果 c 在 cycle 2 成立 → match（不管 b）
// 如果兩個都 match → 也 match（取較短 or 較長視上下文）
```

實戰：APB transfer 可以是 immediate 或 with wait states：

```systemverilog
sequence s_apb_transfer;
  // immediate：SETUP → ACCESS → done
  // with wait：SETUP → ACCESS → wait → ... → done
  (psel && !penable)                    // SETUP phase
  ##1
  (
    (penable && pready)                 // immediate: ACCESS + ready 同 cycle
    or
    (penable && !pready)[*1:$] ##1      // wait states
    (penable && pready)                 // 最終 ready
  );
endsequence
```

### 5.3 `intersect` — 同時開始且同時結束

```systemverilog
// 像 and，但額外要求兩個序列在「同一 cycle 結束」
(a ##[2:5] b) intersect (c ##3 d)
// 兩者都從同一 cycle 開始
// 都必須 match
// 且兩者的 match 長度必須相同
// 這裡 c##3 d 固定長度 3，所以 a##[2:5]b 也必須在 3 cycles 後 match
// → 等價於 (a ##3 b) and (c ##3 d)
```

典型用法 — 限制開放範圍序列的長度：

```systemverilog
// 要求整個 burst 恰好在 N 個 cycle 完成
(req ##1 data[*1:$] ##1 done) intersect (##5 1'b1)
// 整個序列必須恰好 5 cycles 長
// ##5 1'b1 是一個「佔 5 cycle 的固定長度序列」trick
```

### 5.4 `within` — 包含關係

```systemverilog
// s1 的完整 match 必須「在 s2 的時間範圍內」
s1 within s2

// s2 先開始，s1 在 s2 進行的過程中完成，s2 之後也結束
// 等價於：(##[0:$] s1 ##[0:$]) intersect s2
```

實戰：在一個 frame 期間，某個 check 必須通過：

```systemverilog
sequence s_frame;
  sof ##1 payload[*1:$] ##1 eof;    // frame = SOF + payload + EOF
endsequence

property p_crc_within_frame;
  @(posedge clk) disable iff (rst)
  // CRC check 必須在 frame 期間完成
  (crc_start ##[1:5] crc_done) within s_frame;
endproperty
```

### 5.5 `throughout` — 條件持續成立

```systemverilog
// 布林表達式在整個序列期間都必須為 true
(expr) throughout seq

// 注意：左邊是布林表達式，不是序列
// 右邊是序列
```

這是 AHB/AXI 驗證的常用模式：

```systemverilog
// AHB burst 期間 hbusreq 不可拉低
property p_busreq_hold;
  @(posedge clk) disable iff (!hresetn)
  (htrans == NONSEQ && hburst != SINGLE)
  |=>
  (hbusreq) throughout (
    (htrans == SEQ && hready)[->3]    // 等 3 個有效 SEQ beat
  );
endproperty

// AXI write：wvalid 拉高期間 wdata 和 wstrb 必須穩定
property p_wdata_stable_during_valid;
  @(posedge aclk) disable iff (!aresetn)
  (wvalid && !wready)
  |=>
  ($stable(wdata) && $stable(wstrb)) throughout (
    (!wready)[*0:$] ##1 wready       // 等到 wready
  );
endproperty
```

### 5.6 `first_match` — 只取最早的 match

```systemverilog
// 對有多種可能 match 長度的序列，只取第一個（最短的）
first_match(req ##[1:5] ack)
// 如果 ack 在 cycle 2 和 cycle 4 都成立
// 不加 first_match → 兩個 match（長度 2 和長度 4）
// 加了 first_match → 只有長度 2 的那個
```

什麼時候必須用 `first_match`？當你把範圍延遲序列用在 implication 的前件（antecedent）時：

```systemverilog
// ✗ 問題：多個 match 各自觸發獨立的後件評估
property p_bad;
  @(posedge clk)
  (req ##[1:5] ack) |-> ##1 done;
  // 如果 ack 在 cycle 2 和 4 都成立
  // → cycle 3 的 done 被檢查（由 match@2 觸發）
  // → cycle 5 的 done 也被檢查（由 match@4 觸發）
  // 可能造成意外的 assertion fail
endproperty

// ✓ 修正：只看第一個 handshake
property p_good;
  @(posedge clk)
  first_match(req ##[1:5] ack) |-> ##1 done;
endproperty
```

---

## 6. 序列方法：`.triggered` 和 `.matched`

### 6.1 `.triggered`

在 sequence 的結束 cycle（Observed region），回傳 `true`：

```systemverilog
sequence s_setup;
  @(posedge clk) cfg_write ##[1:3] cfg_done;
endsequence

// 用在 property 的前件
property p_after_setup;
  @(posedge clk) disable iff (rst)
  s_setup.triggered |-> ##1 run_enabled;
endproperty

// 用在 procedural code
always @(posedge clk) begin
  if (s_setup.triggered)
    $display("[%0t] Setup complete", $time);
end
```

`.triggered` 的語意細節：它回傳的是「在這個 cycle 結束、在 Observed region 的值」。如果你在 Active region（例如 `always @(posedge clk)` block 內）讀取它，讀到的可能是上一次的值。通常在 concurrent assertion 內使用就不會有問題。

### 6.2 `.matched` — 跨時鐘域

```systemverilog
// 來源時鐘域的序列
sequence s_src;
  @(posedge clk_a) req_a ##[1:3] ack_a;
endsequence

// 在目標時鐘域觀察「來源序列是否完成了」
property p_cross;
  @(posedge clk_b) disable iff (rst)
  s_src.matched |-> ##[1:2] response_b;
endproperty
// s_src 在 clk_a 域完成時，.matched 在下一個 clk_b 邊沿為 true
```

---

## 7. 序列中的局部變數

序列可以宣告局部變數，在 match item 中捕捉信號值供後續 cycle 使用：

```systemverilog
sequence s_data_integrity;
  logic [31:0] saved_addr;
  logic [31:0] saved_data;
  // 在 write phase 捕捉 addr 和 data
  (wr_valid && wr_ready,
   saved_addr = wr_addr,           // match item: 逗號分隔
   saved_data = wr_data)
  ##[1:10]
  // 在 read phase 比對
  (rd_valid && rd_ready &&
   rd_addr == saved_addr &&
   rd_data == saved_data);
endsequence

cover property (@(posedge clk) disable iff (rst) s_data_integrity);
```

進階 — 累加器模式：

```systemverilog
sequence s_byte_count;
  int total;
  (frame_start, total = 0)
  ##1
  (data_valid, total = total + 1)[*1:$]
  ##1
  (frame_end && total == expected_len);
endsequence

property p_frame_length;
  @(posedge clk) disable iff (rst)
  frame_start |-> s_byte_count;
endproperty
```

規則：局部變數的 scope 是整個 sequence match attempt。每個新的 attempt 都有自己獨立的一份變數副本，不會互相干擾。

---

## 8. 運算子優先序（由高到低）

```
[*N]  [->N]  [=N]       重複（最高）
##                       延遲
throughout               布林持續
within                   時間包含
intersect                同長度交集
and                      兩者皆 match
or                       任一 match（最低）
```

建議：遇到複雜組合永遠加括號，不要依賴優先序。

```systemverilog
// ✗ 容易誤讀
a ##1 b[*3] or c ##2 d
// 實際解析為 (a ##1 (b[*3])) or (c ##2 d)

// ✓ 加括號明確意圖
(a ##1 b[*3]) or (c ##2 d)
```

---

## 9. 面試常見考題

```systemverilog
// Q1: 以下兩者等價嗎？
(a ##1 b) or (a ##1 c)     vs     a ##1 (b or c)
// A: 不完全等價！
// 左邊：兩個獨立序列從同一 cycle 各自 attempt
// 右邊：a 成立後下一 cycle 檢查 (b || c)
// 在大多數場景結果相同，但如果 a 的取樣跨 attempt 有副作用就不同

// Q2: b[*0] ##1 c  和  ##1 c  一樣嗎？
// A: 不一樣！
// b[*0] ##1 c → b[*0] 消除了 ##1 的一個 cycle → 等價於 ##0 c → c（同 cycle）
// 正確理解：[*0] 在延遲鏈中「抵消」一個 ##1

// Q3: 區分 b[->2] ##1 c  和  b[=2] ##1 c
// A: [->2]：c 在第 2 個 b 的下一 cycle
//    [=2]：c 在第 2 個 b 之後任意（可能多等幾 cycle），
//           但在 c 出現前 b 不能再出現第 3 次
```

---

## 10. 速查表

### 延遲

| 語法 | 意義 |
|------|------|
| `##N` | 恰好 N cycles 後 |
| `##[M:N]` | M 到 N cycles 內 |
| `##[0:$]` | 0 到無限 cycles |

### 重複

| 語法 | 類型 | match 結束點 |
|------|------|-------------|
| `[*N]` | 連續 | 第 N 個連續 true 的 cycle |
| `[*M:N]` | 連續範圍 | 第 M~N 個連續 true 的 cycle |
| `[->N]` | 跳躍（goto） | 嚴格鎖定第 N 個 true |
| `[=N]` | 非連續 | 第 N 個 true 及其之後的 !b cycles |

### 組合

| 語法 | 意義 |
|------|------|
| `s1 and s2` | 兩者皆 match，結束取較晚者 |
| `s1 or s2` | 至少一者 match |
| `s1 intersect s2` | 兩者皆 match 且同 cycle 結束 |
| `s1 within s2` | s1 的 match 在 s2 的時間範圍內 |
| `(expr) throughout seq` | expr 在 seq 期間持續為 true |
| `first_match(seq)` | 只取最短的第一個 match |

---
