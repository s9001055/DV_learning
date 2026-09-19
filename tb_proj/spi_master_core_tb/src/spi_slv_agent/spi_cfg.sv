`ifndef SPI_CFG_SV
`define SPI_CFG_SV

class spi_cfg extends uvm_object;
    `uvm_object_utils(spi_cfg)

    int unsigned cpol = 0;      // clk idle in low or high
    int unsigned cpha = 0;      // miso or mosi trigger in posedge or negedge      

    function new(string name = "spi_cfg");
        super.new(name);
    endfunction

    // 一次設定所有 channel 相同 delay range
    function void set_cpol_cpha(int unsigned cpol_val, int unsigned cpha_val);
        cpol = cpol_val;  
        cpha = cpha_val;
    endfunction

endclass : spi_cfg

`endif