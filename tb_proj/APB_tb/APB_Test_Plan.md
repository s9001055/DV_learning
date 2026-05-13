# APB Memory Slave — Test Plan

Version 1.0 | Project: APB VIP Practice

---

## 1. Priority Legend

| Priority | Meaning                                       |
| -------- | --------------------------------------------- |
| P1       | Must pass — blocks tape-out                   |
| P2       | Should pass — important feature               |
| P3       | Nice to have — corner case / coverage closure |

---

## 2. Basic Write / Read-Back Tests

Verify fundamental APB write and read transactions against the shadow memory scoreboard.

| Test Name              | Purpose                                               | Type     | Priority | Pass Condition                    |
| ---------------------- | ----------------------------------------------------- | -------- | -------- | --------------------------------- |
| test_wr_rd_single      | Write one word, read back, compare                    | Directed | P1       | PRDATA == PWDATA, 0 SB errors     |
| test_wr_rd_random_addr | 20 random aligned addresses write then read           | C-Random | P1       | All read-back values match shadow |
| test_wr_rd_all_zero    | Write 0x00000000 to 16 addresses, read back           | Directed | P1       | PRDATA == 0x00000000              |
| test_wr_rd_all_ones    | Write 0xFFFFFFFF to 16 addresses, read back           | Directed | P1       | PRDATA == 0xFFFFFFFF              |
| test_wr_rd_alternating | Write 0xAAAA5555 / 0x5555AAAA alternating pattern     | Directed | P2       | Data integrity, no bit flip       |
| test_wr_rd_walking_bit | Walking-1 and walking-0 patterns across all data bits | Directed | P2       | Each bit toggled correctly        |

---

## 3. PSTRB Byte-Enable Tests

Verify that PSTRB correctly enables individual byte lanes during writes.

| Test Name               | Purpose                                                  | Type     | Priority | Pass Condition                   |
| ----------------------- | -------------------------------------------------------- | -------- | -------- | -------------------------------- |
| test_pstrb_byte0_only   | Write only byte 0 (PSTRB=0x1), read back                 | Directed | P1       | Only byte 0 updated in shadow    |
| test_pstrb_byte3_only   | Write only byte 3 (PSTRB=0x8), read back                 | Directed | P1       | Only byte 3 updated in shadow    |
| test_pstrb_half_word_lo | Write lower 2 bytes (PSTRB=0x3)                          | Directed | P1       | Bytes 0-1 updated, 2-3 unchanged |
| test_pstrb_half_word_hi | Write upper 2 bytes (PSTRB=0xC)                          | Directed | P1       | Bytes 2-3 updated, 0-1 unchanged |
| test_pstrb_random       | Random PSTRB for 30 transactions                         | C-Random | P2       | Byte-level scoreboard passes     |
| test_pstrb_overlap      | Write partial bytes then overwrite with different strobe | Directed | P2       | Merged result matches shadow     |

---

## 4. PREADY / Wait State Tests

Verify master correctly waits for PREADY and that data is stable when PREADY asserts.

| Test Name          | Purpose                                         | Type     | Priority | Pass Condition                          |
| ------------------ | ----------------------------------------------- | -------- | -------- | --------------------------------------- |
| test_wait_0_cycles | WAIT_CYCLES=0: immediate PREADY                 | Directed | P1       | Transaction completes in 2 cycles       |
| test_wait_1_cycle  | WAIT_CYCLES=1: one wait state                   | Directed | P1       | PREADY held low for 1 extra cycle       |
| test_wait_3_cycles | WAIT_CYCLES=3 (default config)                  | Directed | P1       | PREADY low for 3 cycles, data correct   |
| test_wait_random   | Random WAIT_CYCLES 0-7, 20 transactions         | C-Random | P2       | No timeout, data always correct         |
| test_prdata_stable | Confirm PRDATA stable for entire PREADY=1 cycle | Directed | P2       | No glitch on PRDATA during valid window |

---

## 5. Protocol Compliance Tests

Verify the DUT and master both comply with the APB4 protocol state machine.

| Test Name               | Purpose                                       | Type     | Priority | Pass Condition                         |
| ----------------------- | --------------------------------------------- | -------- | -------- | -------------------------------------- |
| test_penable_timing     | PENABLE asserts exactly one cycle after PSEL  | Directed | P1       | SVA p_penable_after_psel passes        |
| test_addr_stable_access | PADDR/PWRITE stable throughout access phase   | Directed | P1       | SVA p_stable_in_access passes          |
| test_back_to_back       | 10 consecutive transactions with no IDLE gap  | Directed | P2       | All transactions captured by monitor   |
| test_idle_between       | Random IDLE cycles (1-5) between transactions | C-Random | P2       | No data corruption across transactions |
| test_read_before_write  | Read from uninitialised address, expect 0     | Directed | P2       | PRDATA == 0x00000000, no SB error      |

---

## 6. Reset Tests

Verify correct behaviour when PRESETn is asserted during normal operation.

| Test Name              | Purpose                                           | Type     | Priority | Pass Condition                           |
| ---------------------- | ------------------------------------------------- | -------- | -------- | ---------------------------------------- |
| test_reset_at_startup  | Assert reset before first transaction             | Directed | P1       | wait_cnt=0, no spurious PREADY           |
| test_reset_mid_setup   | Assert reset during SETUP phase                   | Directed | P1       | Transaction aborted, bus returns to IDLE |
| test_reset_mid_access  | Assert reset during ACCESS phase (PREADY=0)       | Directed | P1       | Transaction aborted cleanly              |
| test_reset_then_resume | Reset, then run 10 normal write/read transactions | Directed | P2       | All post-reset transactions pass SB      |

---

## 7. Address Boundary Tests

Verify correct behaviour at the extremes of the supported address space.

| Test Name              | Purpose                                          | Type     | Priority | Pass Condition                   |
| ---------------------- | ------------------------------------------------ | -------- | -------- | -------------------------------- |
| test_addr_min          | Write/read at address 0x000                      | Directed | P1       | Data correct                     |
| test_addr_max          | Write/read at address 0xFFC (top of 1K space)    | Directed | P1       | Data correct                     |
| test_addr_full_sweep   | Sequential write then read across all 1024 words | Directed | P2       | 0 SB errors across entire memory |
| test_addr_random_dense | 100 random writes then matching reads            | C-Random | P3       | Coverage closure on address bins |

---

## 8. PSLVERR Tests

Verify PSLVERR is never incorrectly asserted (DUT hardwires it to 0).

| Test Name              | Purpose                                            | Type     | Priority | Pass Condition                                |
| ---------------------- | -------------------------------------------------- | -------- | -------- | --------------------------------------------- |
| test_pslverr_never_set | Run 50 random transactions, check PSLVERR=0 always | C-Random | P1       | SVA p_pslverr_only_access passes; SB 0 errors |
| test_pslverr_on_read   | Confirm PSLVERR=0 on all read transactions         | Directed | P2       | No unexpected PSLVERR captured                |
| test_pslverr_on_write  | Confirm PSLVERR=0 on all write transactions        | Directed | P2       | No unexpected PSLVERR captured                |

---

## 9. Regression Summary

| Category            | Total Tests | P1     | Automation                        |
| ------------------- | ----------- | ------ | --------------------------------- |
| Basic Write/Read    | 6           | 4      | UVM regression                    |
| PSTRB Byte-Enable   | 6           | 4      | UVM regression                    |
| PREADY / Wait State | 5           | 3      | UVM regression                    |
| Protocol Compliance | 5           | 3      | UVM regression + SVA              |
| Reset               | 4           | 2      | UVM regression                    |
| Address Boundary    | 4           | 2      | UVM regression                    |
| PSLVERR             | 3           | 1      | UVM regression + SVA              |
| **TOTAL**           | **33**      | **19** | `xrun -f apb.f +UVM_TESTNAME=...` |
