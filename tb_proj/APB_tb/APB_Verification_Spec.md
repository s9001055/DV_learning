# APB Memory Slave — Verification Specification

Version 1.0 | Project: APB VIP Practice

| Field          | Value                                                      |
| -------------- | ---------------------------------------------------------- |
| Document Owner | DV Engineer                                                |
| DUT            | apb_memory_slave (APB4 Slave, 32-bit data, 10-bit address) |
| Protocol       | AMBA APB4 (PREADY / PSLVERR / PSTRB support)               |
| Simulator      | Cadence Xcelium 23.03 + UVM 1.1d                           |
| Created        | 2026-05                                                    |

---

## 1. Overview

This document defines the verification strategy for the APB memory slave DUT (`apb_memory_slave`). The DUT implements an AMBA APB4-compliant slave interface with configurable wait states (`WAIT_CYCLES`), byte-enable write support (`PSTRB`), and PSLVERR error signalling. The verification environment is built with SystemVerilog UVM 1.1d.

---

## 2. DUT Architecture

### 2.1 Parameters

| Parameter   | Default | Description                                              |
| ----------- | ------- | -------------------------------------------------------- |
| ADDR_WIDTH  | 10      | Address bits; memory depth = 2^ADDR_WIDTH words          |
| DATA_WIDTH  | 32      | Data bus width in bits                                   |
| WAIT_CYCLES | 0       | Number of wait states inserted before PREADY is asserted |

### 2.2 Interface Signals

| Signal  | Width | Dir | Description                                       |
| ------- | ----- | --- | ------------------------------------------------- |
| PCLK    | 1     | IN  | Clock                                             |
| PRESETn | 1     | IN  | Active-low synchronous reset                      |
| PADDR   | 32    | IN  | Address bus                                       |
| PSEL    | 1     | IN  | Slave select                                      |
| PENABLE | 1     | IN  | Enable / access phase indicator                   |
| PWRITE  | 1     | IN  | 1 = Write, 0 = Read                               |
| PWDATA  | 32    | IN  | Write data bus                                    |
| PSTRB   | 4     | IN  | Byte-enable strobes (APB4)                        |
| PRDATA  | 32    | OUT | Read data bus; combinational; valid when PREADY=1 |
| PREADY  | 1     | OUT | Slave ready; combinational from wait_cnt          |
| PSLVERR | 1     | OUT | Slave error; tied low in this DUT                 |

---

## 3. Verification Environment Architecture

### 3.1 Component Hierarchy

| Component          | Role                                                                            |
| ------------------ | ------------------------------------------------------------------------------- |
| top_tb             | Top-level module; instantiates DUT and apb_if; starts UVM                       |
| apb_if             | SystemVerilog interface; master_cb / monitor_cb clocking blocks; SVA assertions |
| apb_test           | Test class; creates env; starts sequences                                       |
| apb_env            | Environment; instantiates agent and scoreboard                                  |
| apb_agent (active) | Contains sequencer, driver, monitor                                             |
| apb_driver         | Drives APB master signals via master_cb clocking block                          |
| apb_monitor        | Passive observation of all APB signals; publishes apb_item via analysis port    |
| apb_scoreboard     | Shadow memory comparison; checks PRDATA == expected on every read               |
| apb_sequence       | Generates write / read-back transaction pairs                                   |
| apb_item           | UVM sequence item: paddr, pwrite, pwdata, pstrb, prdata, pslverr                |

---

## 4. Assertion Strategy (SVA)

| Assertion             | Description                                                                  |
| --------------------- | ---------------------------------------------------------------------------- |
| p_penable_after_psel  | PENABLE may only assert one cycle after PSEL rises                           |
| p_stable_in_access    | PADDR, PWRITE, PWDATA, PSTRB must remain stable while PENABLE=1 and PREADY=0 |
| p_prdata_valid        | PRDATA must not be X/Z when PSEL && PENABLE && !PWRITE && PREADY             |
| p_pslverr_only_access | PSLVERR must be 0 outside the access phase                                   |
| p_reset_idle          | All master outputs must be 0 within one cycle of PRESETn deassertion         |

---
