`ifndef AXI_PKG_SV
`define AXI_PKG_SV

package axi_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // ---- Bus parameters ----
    parameter int AXI_AWIDTH  = 32;
    parameter int AXI_DWIDTH  = 64;
    parameter int AXI_IDWIDTH = 4;
    parameter int AXI_STRB_W  = AXI_DWIDTH / 8;

    // ---- Enums ----
    typedef enum bit { 
        AXI_READ  = 1'b0, 
        AXI_WRITE = 1'b1 
    } axi_dir_e;

    typedef enum bit [1:0] { 
        AXI_FIXED = 2'b00,
        AXI_INCR  = 2'b01,
        AXI_WRAP  = 2'b10 
    } axi_burst_e;

    typedef enum bit [1:0] { 
        AXI_OKAY   = 2'b00,
        AXI_EXOKAY = 2'b01,
        AXI_SLVERR = 2'b10,
        AXI_DECERR = 2'b11 
    } axi_resp_e;

    typedef enum bit { 
        AXI_NORMAL    = 1'b0,
        AXI_EXCLUSIVE = 1'b1 
    } axi_lock_e;

    typedef enum { 
        AXI_CH_AW, 
        AXI_CH_W, 
        AXI_CH_AR,
        AXI_CH_AUTO
    } axi_channel_e;

    typedef enum { 
        AXI_R_FIFO,         // AR 先到先回, burst beats 連續
        AXI_R_OOO,          // 不同 ID 的 burst 可亂序回, beats 連續
        AXI_R_INTERLEAVE    // 不同 ID 的 beats 可交錯 (interleaving)
    } axi_read_resp_mode_e;

    typedef enum {
        WAIT_CYCLES,       // 等固定 cycle
        WAIT_SIGNAL,       // 等 DUT 的 ready 信號
        WAIT_BUS_IDLE      // 等 bus 上沒有活動
    } reset_exit_mode_e;

    // Forward-declare / include order
    `include "axi_transaction.sv"
    `include "axi_sequencer.sv"
    `include "axi_reset_config.sv"
    `include "axi_reset_monitor.sv"
    `include "axi_mst_cfg.sv"
    `include "axi_mst_driver.sv"
    `include "axi_mst_monitor.sv"
    `include "axi_mst_agent.sv"
    `include "axi_slv_cfg.sv"
    `include "axi_slv_driver.sv"
    `include "axi_slv_monitor.sv"
    `include "axi_slv_agent.sv"
    // `include "axi_coverage.sv"
    `include "axi_scoreboard.sv"
    // `include "axi_virtual_sequencer.sv"
    `include "axi_env.sv"

    // Sequences
    `include "axi_base_seq.sv"
    `include "axi_fixed_wr_seq.sv"
    `include "axi_incr_wr_seq.sv"

endpackage : axi_pkg

`endif
