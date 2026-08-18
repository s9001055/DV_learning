SystemVerilog simulation 每個 timestep 內部有嚴格的執行順序，叫 **simulation scheduling regions**。IEEE 1800-2017 §4 定義了這些 region。

## 一個 posedge aclk 內部的執行順序

```
    posedge aclk
        │
        ▼
┌─────────────────┐
│   Preponed      │  SVA 在這裡 sample signal（看到的是上一個 timestep 的 settled value）
├─────────────────┤
│   Active        │  blocking assignment (=)、continuous assignment 在這裡執行
├─────────────────┤
│   Inactive      │  #0 delay 的 assignment
├─────────────────┤
│   NBA           │  non-blocking assignment (<=) 在這裡更新值
├─────────────────┤
│   Observed      │  SVA assertion evaluation（用 Preponed sample 的值來判斷 pass/fail）
├─────────────────┤
│   Reactive      │  program block / clocking block output drive
├─────────────────┤
│   Re-NBA        │  program block 的 non-blocking assignment
├─────────────────┤
│   Postponed     │  $monitor / $strobe 在這裡讀值（看到的是這個 timestep 最終 settled value）
└─────────────────┘
        │
        ▼
    下一個 event
```

## 你遇到的問題對照

```
posedge aclk @ T=1055ns:

Preponed:   SVA sample wvalid → 還是 1 (上一拍 drive_w 設的值)
            SVA 記錄: wvalid = 1, aresetn = 0

Active:     (沒有 blocking assign)

NBA:        handle_reset 的 vif.wvalid <= 0 → 排程更新為 0

Observed:   SVA 用 Preponed 的值判斷:
            !aresetn = 1 (antecedent 成立)
            !wvalid = !1 = 0 (consequent 失敗)
            → ASSERTION FAIL ✗

Reactive:   CB persistent drive → wvalid 被蓋回 1 或保持 0 (看誰贏)

Postponed:  waveform viewer 讀到最終值 = 0
```

所以你看到的現象是：**waveform 顯示 0（Postponed 的值），但 SVA 看到 1（Preponed 的值）**。兩個是不同 region 的 snapshot。

## 簡單記法

| Region | 誰在這裡 | 看到的值 |
|--------|---------|---------|
| **Preponed** | SVA sampling、`$past()` | 上一拍的 final value（最舊）|
| **Active** | `=` assignment | 當拍 |
| **NBA** | `<=` assignment | 當拍但晚一點 |
| **Observed** | SVA pass/fail 判定 | 用 Preponed 的值 |
| **Reactive** | Clocking block output | 當拍但更晚 |
| **Postponed** | `$monitor`、waveform | 當拍最終值（最新）|

這就是為什麼 clocking block 和直接 assign 混用會出事 — CB output 在 **Reactive**（最晚），`<=` 在 **NBA**（較早），SVA 在 **Preponed**（最早）。三者看到的值可能完全不同。
