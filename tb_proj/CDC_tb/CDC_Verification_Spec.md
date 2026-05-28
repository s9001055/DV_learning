# CDC Asymc_fifo — Verification Specification

Version 1.0 | Project: CDC Asymc_fifo

| Field          | Value                            |
| -------------- | -------------------------------- |
| Document Owner | DV Engineer                      |
| DUT            | CDC Asymc_fifo                   |
| Simulator      | Cadence Xcelium 23.03 + UVM 1.1d |
| Created        | 2026-05                          |

---

## 1. Overview

This document defines the verification strategy for the CDC Asymc_fifo DUT (`async_fifo`).

---

## 2. DUT Architecture

### 2.1 Parameters

| Parameter  | Default       | Description                                     |
| ---------- | ------------- | ----------------------------------------------- |
| ADDR_WIDTH | $clog2(DEPTH) | Address bits; memory depth = 2^ADDR_WIDTH words |
| DATA_WIDTH | 8             | Data bus width in bits                          |
| DEPTH      | 16            | Memory depth                                    |

### 2.2 Interface Signals

| Signal | Width | Dir | Description                  |
| ------ | ----- | --- | ---------------------------- |
| WCLK   | 1     | IN  | Write Side Clock             |
| WRST_N | 1     | IN  | Write Side Reset             |
| WINC   | 32    | IN  | Write Side Increase          |
| WDATA  | 1     | IN  | Write Side DATA              |
| WFULL  | 1     | IN  | Write Side Queue full signal |
| RCLK   | 1     | IN  | Read Side Clock              |
| RRST_N | 32    | IN  | Read Side Reset              |
| RINC   | 4     | IN  | Read Side Increase           |
| RDATA  | 32    | OUT | Read Side DATA               |
| REMPTY | 1     | OUT | Read Side Queue Empty signal |

---

## 3. Verification Environment Architecture

### 3.1 Component Hierarchy

| Component           | Role                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------ |
| top_tb              | Top-level module; instantiates DUT and cdc_fifo_if; starts UVM                       |
| cdc_fifo_if         | SystemVerilog interface; SVA assertions                                              |
| cdc_read_agent      | Read Agent: Contains sequencer, driver, monitor                                      |
| fifo_read_driver    | Drives Read signals via interface                                                    |
| fifo_read_monitor   | Passive observation of all Read signals; publishes read_item via analysis port       |
| fifo_read_item      | UVM sequence item                                                                    |
| cdc_write_agent     | Write Agent: Contains sequencer, driver, monitor                                     |
| fifo_write_driver   | Drives Write signals via interface                                                   |
| fifo_write_monitor  | Passive observation of all Write signals; publishes read_item via analysis port      |
| fifo_write_item     | UVM sequence item                                                                    |
| cdc_base_test       | Test class; creates env; starts sequences                                            |
| cdc_fifo_env        | Environment; instantiates agent and scoreboard                                       |
| cdc_scoreboard      | Compare the data written by the Write Monitor with the data read by the Read Monitor |
| fifo_base_write_seq | Generates Write transaction                                                          |
| fifo_base_read_seq  | Generates Read transaction                                                           |

---

## 4. Assertion Strategy (SVA)

| Assertion            | Description                                                                    |
| -------------------- | ------------------------------------------------------------------------------ |
| p_no_write_when_full | During WFULL, wptr_gray should not be modified                                 |
| p_no_read_when_empty | During WFULL, rptr_gray should not be modified                                 |
| p_wptr_gray_one_hot  | Gray code security: Only 1 bit differs each time the wptr_gray pointer changes |
| p_rptr_gray_one_hot  | Gray code security: Only 1 bit differs each time the rptr_gray pointer changes |
| p_no_full_and_empty  | WFULL and REMPTY cannot both be 1                                              |
| p_reset_clears_wptr  | After a reset, the wptr_gray pointer must be returned to zero                  |
| p_reset_clears_rptr  | After a reset, the rptr_gray pointer must be returned to zero                  |

---
