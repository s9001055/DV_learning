`ifndef AXI_SLV_CFG_SV
`define AXI_SLV_CFG_SV

class axi_slv_cfg extends uvm_object;
    `uvm_object_utils(axi_slv_cfg)

    // ---- AW channel ----
    int unsigned aw_ready_delay_min = 0;   // item 拿到後延幾拍才 assert AWVALID
    int unsigned aw_ready_delay_max = 0;

    // ---- W channel ----
    int unsigned w_ready_delay_min  = 0;   // item 拿到後延幾拍才開始第一個 W beat
    int unsigned w_ready_delay_max  = 0;

    // ---- B channel (SLAVE 端 BVALID delay) ----
    int unsigned bvalid_delay_min   = 0;   // BREADY 出現後延幾拍才拉 BVALID
    int unsigned bvalid_delay_max   = 0;

    // ---- AR channel ----
    int unsigned ar_ready_delay_min = 0;
    int unsigned ar_ready_delay_max = 0;

    // ---- R channel (SLAVE 端 RVALID delay) ----
    int unsigned rvalid_delay_min   = 0;   // RREADY 出現後延幾拍才拉 RVALID (per beat)
    int unsigned rvalid_delay_max   = 0;
    int unsigned r_beat_gap_min     = 0;   // beat 之間插入的 idle cycle 數
    int unsigned r_beat_gap_max     = 0;

    // ---- R channel response mode    FIFO, OoO, Interleaving
    axi_read_resp_mode_e read_resp_mode = AXI_R_FIFO;

    function new(string name = "axi_mst_cfg");
        super.new(name);
    endfunction

    // 一次設定所有 channel 相同 delay range
    function void set_all_delay(int unsigned min_d, int unsigned max_d);
        aw_ready_delay_min = min_d;  
        aw_ready_delay_max = max_d;

        w_ready_delay_min  = min_d;  
        w_ready_delay_max  = max_d;

        bvalid_delay_min   = min_d;  
        bvalid_delay_max   = max_d;

        ar_ready_delay_min = min_d;  
        ar_ready_delay_max = max_d;

        rvalid_delay_min   = min_d;  
        rvalid_delay_max   = max_d;

        r_beat_gap_min     = min_d;  
        r_beat_gap_max     = max_d;
    endfunction

    // 設定 write 側
    function void set_write_delay(int unsigned aw_min, int unsigned aw_max,
                                  int unsigned w_min,  int unsigned w_max,
                                  int unsigned b_min,  int unsigned b_max);
        aw_ready_delay_min = aw_min;  
        aw_ready_delay_max = aw_max;

        w_ready_delay_min  = w_min;   
        w_ready_delay_max  = w_max;

        bvalid_delay_min   = b_min;   
        bvalid_delay_max   = b_max;
    endfunction

    // 設定 read 側
    function void set_read_delay(int unsigned ar_min, int unsigned ar_max,
                                 int unsigned r_min,  int unsigned r_max);
        ar_ready_delay_min = ar_min;  
        ar_ready_delay_max = ar_max;

        rvalid_delay_min   = r_min;   
        rvalid_delay_max   = r_max;
    endfunction

endclass : axi_slv_cfg

`endif