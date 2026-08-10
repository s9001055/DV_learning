`ifndef AXI_MST_CFG_SV
`define AXI_MST_CFG_SV

class axi_mst_cfg extends uvm_object;
    `uvm_object_utils(axi_mst_cfg)

    // ---- AW channel ----
    int unsigned aw_valid_delay_min = 0;   // item 拿到後延幾拍才 assert AWVALID
    int unsigned aw_valid_delay_max = 0;

    // ---- W channel ----
    int unsigned w_valid_delay_min  = 0;   // item 拿到後延幾拍才開始第一個 W beat
    int unsigned w_valid_delay_max  = 0;
    int unsigned w_beat_gap_min     = 0;   // beat 之間插入的 idle cycle 數
    int unsigned w_beat_gap_max     = 0;

    // ---- B channel (master 端 BREADY delay) ----
    int unsigned bready_delay_min   = 0;   // BVALID 出現後延幾拍才拉 BREADY
    int unsigned bready_delay_max   = 0;

    // ---- AR channel ----
    int unsigned ar_valid_delay_min = 0;
    int unsigned ar_valid_delay_max = 0;

    // ---- R channel (master 端 RREADY delay) ----
    int unsigned rready_delay_min   = 0;   // RVALID 出現後延幾拍才拉 RREADY (per beat)
    int unsigned rready_delay_max   = 0;

    function new(string name = "axi_mst_cfg");
        super.new(name);
    endfunction

    // 一次設定所有 channel 相同 delay range
    function void set_all_delay(int unsigned min_d, int unsigned max_d);
        aw_valid_delay_min = min_d;  
        aw_valid_delay_max = max_d;

        w_valid_delay_min  = min_d;  
        w_valid_delay_max  = max_d;

        w_beat_gap_min     = min_d;  
        w_beat_gap_max     = max_d;

        ar_valid_delay_min = min_d;  
        ar_valid_delay_max = max_d;

        bready_delay_min   = min_d;  
        bready_delay_max   = max_d;

        rready_delay_min   = min_d;  
        rready_delay_max   = max_d;
    endfunction

    // 設定 write 側
    function void set_write_delay(int unsigned aw_min, int unsigned aw_max,
                                  int unsigned w_min,  int unsigned w_max,
                                  int unsigned b_min,  int unsigned b_max);
        aw_valid_delay_min = aw_min;  
        aw_valid_delay_max = aw_max;

        w_valid_delay_min  = w_min;   
        w_valid_delay_max  = w_max;

        bready_delay_min   = b_min;   
        bready_delay_max   = b_max;
    endfunction

    // 設定 read 側
    function void set_read_delay(int unsigned ar_min, int unsigned ar_max,
                                 int unsigned r_min,  int unsigned r_max);
        ar_valid_delay_min = ar_min;  
        ar_valid_delay_max = ar_max;

        rready_delay_min   = r_min;   
        rready_delay_max   = r_max;
    endfunction

endclass : axi_mst_cfg

`endif