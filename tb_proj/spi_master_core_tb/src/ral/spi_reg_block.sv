`ifndef SPI_REG_BLOCK_SV
`define SPI_REG_BLOCK_SV

// CTRL register (offset 0x10)
// [13] ASS  [12] IE  [11] LSB  [10] TX_NEG  [9] RX_NEG
// [8]  GO   [7] reserved       [6:0] CHAR_LEN
class spi_reg_ctrl extends uvm_reg;
    `uvm_object_utils(spi_reg_ctrl)

    rand uvm_reg_field char_len;
    rand uvm_reg_field reserved;
    rand uvm_reg_field go_bsy;
    rand uvm_reg_field rx_neg;
    rand uvm_reg_field tx_neg;
    rand uvm_reg_field lsb;
    rand uvm_reg_field ie;
    rand uvm_reg_field ass;

    function new(string name = "spi_reg_ctrl");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        //                  parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible
        char_len        = uvm_reg_field::type_id::create("char_len");
        char_len.configure  (this, 7,  0,  "RW", 0, 7'h0,  1, 1, 1);

        reserved        = uvm_reg_field::type_id::create("reserved");
        reserved.configure  (this, 1,  7,  "RO", 0, 1'b0,  0, 0, 0);

        go_bsy          = uvm_reg_field::type_id::create("go_bsy");
        go_bsy.configure        (this, 1,  8,  "RW", 1, 1'b0,  1, 1, 1);
        // Note: GO is auto-cleared by HW when transfer completes

        rx_neg          = uvm_reg_field::type_id::create("rx_neg");
        rx_neg.configure(this, 1,  9,  "RW", 0, 1'b0,  1, 1, 1);

        tx_neg          = uvm_reg_field::type_id::create("tx_neg");
        tx_neg.configure(this, 1, 10,  "RW", 0, 1'b0,  1, 1, 1);

        lsb             = uvm_reg_field::type_id::create("lsb");
        lsb.configure       (this, 1, 11,  "RW", 0, 1'b0,  1, 1, 1);

        ie              = uvm_reg_field::type_id::create("ie");
        ie.configure        (this, 1, 12,  "RW", 0, 1'b0,  1, 1, 1);

        ass             = uvm_reg_field::type_id::create("ass");
        ass.configure       (this, 1, 13,  "RW", 0, 1'b0,  1, 1, 1);
    endfunction

endclass : spi_reg_ctrl


// DIVIDER register (offset 0x14)
class spi_reg_divider extends uvm_reg;
    `uvm_object_utils(spi_reg_divider)

    rand uvm_reg_field divider;

    function new(string name = "spi_reg_divider");
        //parameter: name, size, has_coverage
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        //                parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible
        divider = uvm_reg_field::type_id::create("divider");
        divider.configure(this, 16, 0, "RW", 0, 16'hFFFF, 1, 1, 1);
    endfunction
endclass : spi_reg_divider


// SS register (offset 0x18)
class spi_reg_ss extends uvm_reg;
    `uvm_object_utils(spi_reg_ss)

    rand uvm_reg_field ss;

    function new(string name = "spi_reg_ss");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        //                parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible
        ss = uvm_reg_field::type_id::create("ss");
        ss.configure(this, 8, 0, "RW", 0, 8'b0, 1, 1, 1);
    endfunction

endclass : spi_reg_ss


// TX registers (offset 0x00~0x0C, write-only from SW perspective)
// Note: reading same address returns RX data, handled by address aliasing
class spi_reg_tx extends uvm_reg;
    `uvm_object_utils(spi_reg_tx)

    rand uvm_reg_field data;

    function new(string name = "spi_reg_tx");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        //                parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible
        data = uvm_reg_field::type_id::create("data");
        data.configure(this, 32, 0, "WO", 0, 32'h0, 1, 1, 1);
    endfunction

endclass : spi_reg_tx


// RX registers (offset 0x00~0x0C, read-only)
class spi_reg_rx extends uvm_reg;
    `uvm_object_utils(spi_reg_rx)

    uvm_reg_field data;

    function new(string name = "spi_reg_rx");
        super.new(name, 32, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        //                parent, size, lsb_pos, access, volatile, reset, has_reset, is_rand, individually_accessible
        data = uvm_reg_field::type_id::create("data");
        data.configure(this, 32, 0, "RO", 1, 32'h0, 0, 0, 1);
    endfunction

endclass : spi_reg_rx


// ================================================================
//  Register Block
// ================================================================
class spi_reg_block extends uvm_reg_block;
    `uvm_object_utils(spi_reg_block)

    // Registers
    rand spi_reg_ctrl    ctrl;
    rand spi_reg_divider divider;
    rand spi_reg_ss      ss;
    rand spi_reg_tx      tx[4];
    spi_reg_rx           rx[4];

    uvm_reg_map          default_map;

    function new(string name = "spi_reg_block");
        super.new(name, UVM_NO_COVERAGE);
    endfunction

    virtual function void build();
        // Create registers
        ctrl    = spi_reg_ctrl::type_id::create("ctrl");
        //            parent, regfile(所屬的uvm_reg_file), hdl_path(給 backdoor用)
        ctrl.configure(this, null, "");
        ctrl.build();

        divider = spi_reg_divider::type_id::create("divider");
        divider.configure(this, null, "");
        divider.build();

        ss      = spi_reg_ss::type_id::create("ss");
        ss.configure(this, null, "");
        ss.build();

        foreach (tx[i]) begin
            tx[i] = spi_reg_tx::type_id::create($sformatf("tx%0d", i));
            tx[i].configure(this, null, "");
            tx[i].build();
        end

        foreach (rx[i]) begin
            rx[i] = spi_reg_rx::type_id::create($sformatf("rx%0d", i));
            rx[i].configure(this, null, "");
            rx[i].build();
        end

        // Create address map (byte-addressed, 32-bit bus)
        default_map = create_map("default_map",                 // map 名稱
                                 .base_addr(0),                 // base address offset
                                 .n_bytes(4),                   // bus 寬度（byte 為單位）
                                 .endian(UVM_LITTLE_ENDIAN));   // big or little endian


        // 加入 reg 到 default_map
        // TX registers (write path): offset 0x00, 0x04, 0x08, 0x0C
        foreach (tx[i])
            default_map.add_reg(tx[i], 'h00 + i * 4, "WO");

        // RX registers (read path): same offsets, added as shared address
        // RTL uses same address for TX(write) and RX(read)
        foreach (rx[i])
            default_map.add_reg(rx[i], 'h00 + i * 4, "RO");

        // Control/status registers
        default_map.add_reg(ctrl,    'h10, "RW");
        default_map.add_reg(divider, 'h14, "RW");
        default_map.add_reg(ss,      'h18, "RW");

        lock_model();
    endfunction

endclass : spi_reg_block

`endif
