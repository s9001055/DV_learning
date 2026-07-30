`ifndef AXI_TRANSACTION_SV
`define AXI_TRANSACTION_SV

class axi_transaction extends uvm_sequence_item;

    // ---- Attributes ----
    rand axi_dir_e                     direction;
    rand bit [AXI_IDWIDTH-1:0]         id;
    rand bit [AXI_AWIDTH-1:0]          addr;
    rand bit [7:0]                     len;      // burst length - 1
    rand bit [2:0]                     size;     // log2(bytes per beat)
    rand axi_burst_e                   burst;
    rand axi_lock_e                    lock;
    rand bit [3:0]                     cache;
    rand bit [2:0]                     prot;

    rand bit [AXI_DWIDTH-1:0]          data [];  // beat data
    rand bit [AXI_STRB_W-1:0]          strb [];  // per-beat strobe
         axi_resp_e                    resp [];  // response per beat (read) or single (write)

    // For error injection
    rand bit                           inject_err;
    rand int unsigned                  err_type;

    // ---- Constraints ----
    constraint c_size_bus   { size inside {[0:$clog2(AXI_STRB_W)]}; }

    constraint c_burst_type { burst inside {AXI_FIXED, AXI_INCR, AXI_WRAP}; }

    constraint c_wrap_len {
        (burst == AXI_WRAP) -> len inside {1, 3, 7, 15};   // 2,4,8,16 beats
    }

    constraint c_fixed_len {
        (burst == AXI_FIXED) -> len inside {[0:15]};
    }

    constraint c_wrap_align {
        (burst == AXI_WRAP) -> ((addr & ((1 << size) - 1)) == 0);
    }

    // 4KB boundary — INCR burst 不得跨界
    constraint c_4kb_boundary {
        (burst == AXI_INCR) ->
            ( (addr[11:0] + ((len + 1) << size)) <= 12'h1000 );
    }

    // 陣列長度依 len 決定
    constraint c_data_size {
        data.size() == len + 1;
        strb.size() == len + 1;
    }

    constraint c_default_lock { soft lock == AXI_NORMAL; }
    constraint c_default_prot { soft prot == 3'b000; }
    constraint c_no_err       { soft inject_err == 1'b0; }

    // ---- UVM ----
    `uvm_object_utils_begin(axi_transaction)
        `uvm_field_enum   (axi_dir_e,   direction, UVM_ALL_ON)
        `uvm_field_int    (id,                     UVM_ALL_ON)
        `uvm_field_int    (addr,                   UVM_ALL_ON)
        `uvm_field_int    (len,                    UVM_ALL_ON)
        `uvm_field_int    (size,                   UVM_ALL_ON)
        `uvm_field_enum   (axi_burst_e, burst,     UVM_ALL_ON)
        `uvm_field_enum   (axi_lock_e,  lock,      UVM_ALL_ON)
        `uvm_field_int    (cache,                  UVM_ALL_ON)
        `uvm_field_int    (prot,                   UVM_ALL_ON)
        `uvm_field_array_int(data,                 UVM_ALL_ON)
        `uvm_field_array_int(strb,                 UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi_transaction");
        super.new(name);
    endfunction

    // 便利函式:計算第 i 個 beat 的位址
    function bit [AXI_AWIDTH-1:0] beat_addr(input int i);
        bit [AXI_AWIDTH-1:0] a;
        case (burst)
            AXI_FIXED: a = addr;
            AXI_INCR : a = addr + (i << size);
            AXI_WRAP : begin
                int unsigned wrap_bytes = (len + 1) << size;
                bit [AXI_AWIDTH-1:0] base = addr & ~(wrap_bytes - 1);
                a = base + ((addr + (i << size) - base) & (wrap_bytes - 1));
            end
            default: a = addr;
        endcase
        return a;
    endfunction

endclass : axi_transaction

`endif
