# CDC Asymc_fifo — Test Plan

Version 1.0 | Project: CDC Asymc_fifo

---

## 1. Priority Legend

| Priority | Meaning                                       |
| -------- | --------------------------------------------- |
| P1       | Must pass — blocks tape-out                   |
| P2       | Should pass — important feature               |
| P3       | Nice to have — corner case / coverage closure |

---

## 2. Basic Write / Read-Back Tests

Verify fundamental Asymc_fifo write and read transactions against the shadow memory scoreboard.

| Test Name              | Purpose                                     | Type     | Priority | Pass Condition                    |
| ---------------------- | ------------------------------------------- | -------- | -------- | --------------------------------- |
| test_wr_rd_random_addr | 20 random aligned addresses write then read | C-Random | P1       | All read-back values match shadow |

---

## 3. Fill / Drain FIFO Tests

Verify that Asymc_fifo correctly handle fill & empty situation.

| Test Name           | Purpose              | Type     | Priority | Pass Condition |
| ------------------- | -------------------- | -------- | -------- | -------------- |
| test_seq_fill_fifo  | Filling FIFO to full | Directed | P1       | WFULL assert   |
| test_seq_drain_fifo | Draining FIFO        | Directed | P1       | REMPTY assert  |

---

## 4. Protocol Compliance Tests

---

## 5. Regression Summary
