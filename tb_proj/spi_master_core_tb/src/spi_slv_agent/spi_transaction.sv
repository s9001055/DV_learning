`ifndef SPI_TRANSACTION_SV
`define SPI_TRANSACTION_SV

class spi_transaction extends uvm_sequence_item;
    `uvm_object_utils(spi_transaction)

    // Data to shift out on MISO (slave → master)
    rand bit [SPI_MAX_CHAR-1:0] miso_data;

    // Data captured from MOSI (master → slave), filled by monitor
    bit [SPI_MAX_CHAR-1:0] mosi_data;

    // Transfer attributes (set by env/test for reference)
    int unsigned char_len;     // number of bits in this transfer
    bit          lsb_first;
    spi_mode_e   spi_mode;
    int unsigned  slave_id;    // which SS was active

    constraint c_default {
        char_len inside {[1:SPI_MAX_CHAR]};
    }

    function new(string name = "spi_transaction");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("SPI: mosi=0x%032h miso=0x%032h len=%0d mode=%s lsb=%0b ss=%0d",
                         mosi_data, miso_data, char_len,
                         spi_mode.name(), lsb_first, slave_id);
    endfunction

endclass : spi_transaction

`endif
