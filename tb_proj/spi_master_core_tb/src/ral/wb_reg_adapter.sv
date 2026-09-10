`ifndef WB_REG_ADAPTER_SV
`define WB_REG_ADAPTER_SV

class wb_reg_adapter extends uvm_reg_adapter;
    `uvm_object_utils(wb_reg_adapter)

    function new(string name = "wb_reg_adapter");
        super.new(name);

        // Wishbone returns data in the same cycle as ACK
        supports_byte_enable = 1;  // bus 支援 byte-level 存取
        provides_responses   = 1;  // Driver 會把 response（read data / error status）填回同一個 transaction 物件
    endfunction

    // 介紹 uvm_reg_bus_op
    // typedef struct {
    //     uvm_access_e   kind;       // UVM_READ 或 UVM_WRITE
    //     uvm_reg_addr_t addr;       // register 的位址
    //     uvm_reg_data_t data;       // 寫入的值（write）或讀回的值（read）
    //     int unsigned   n_bits;     // 有效 bit 數
    //     uvm_reg_byte_en_t byte_en; // byte enable（哪些 byte 有效）
    //     uvm_status_e   status;     // UVM_IS_OK / UVM_NOT_OK / UVM_HAS_X
    // } uvm_reg_bus_op;

    // RAL → Wishbone transaction (reg2bus)
    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        wb_transaction tr = wb_transaction::type_id::create("wb_reg_tr");

        tr.addr      = rw.addr[4:0];
        tr.sel       = rw.byte_en;
        tr.direction = (rw.kind == UVM_WRITE) ? WB_WRITE : WB_READ;
        tr.data      = rw.data;

        return tr;
    endfunction

    // Wishbone transaction → RAL (bus2reg)
    virtual function void bus2reg(uvm_sequence_item bus_item,
                                  ref uvm_reg_bus_op rw);
        wb_transaction tr;

        if (!$cast(tr, bus_item))
            `uvm_fatal("WB_ADAPTER", "Failed to cast bus_item to wb_transaction")

        rw.addr   = tr.addr;
        rw.kind   = (tr.direction == WB_WRITE) ? UVM_WRITE : UVM_READ;
        rw.data   = (tr.direction == WB_WRITE) ? tr.data : tr.rdata;
        rw.status = tr.error ? UVM_NOT_OK : UVM_IS_OK;
    endfunction

endclass : wb_reg_adapter

`endif
