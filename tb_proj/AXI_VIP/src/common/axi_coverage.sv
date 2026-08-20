`ifndef AXI_COVERAGE_SV
`define AXI_COVERAGE_SV

class axi_coverage extends uvm_subscriber #(axi_transaction);
    `uvm_component_utils(axi_coverage)

    axi_transaction m_tr;

    covergroup cg_axi_txn;
        cp_dir  : coverpoint m_tr.direction {
            bins rd = {AXI_READ};
            bins wr = {AXI_WRITE};
        }

        cp_len  : coverpoint m_tr.len {
            bins len1      = {0};
            bins len2_4    = {[1:3]};
            bins len8_16   = {[7:15]};
            bins len17_64  = {[16:63]};
            bins len_max   = {[64:255]};
        }

        cp_size : coverpoint m_tr.size { bins s[] = {[0:$clog2(AXI_STRB_W)]}; }

        cp_burst: coverpoint m_tr.burst {
            bins fixed = {AXI_FIXED};
            bins incr  = {AXI_INCR};
            bins wrap  = {AXI_WRAP};
        }

        cp_id   : coverpoint m_tr.id;
        
        cp_4kb_edge: coverpoint
            ((14'h0 + m_tr.addr[11:0] + ((m_tr.len + 1) << m_tr.size)) == 14'h1000) {
            bins hit  = {1'b1};
            bins miss = {1'b0};
        }

        cx_burst_x_len  : cross cp_burst, cp_len;
        cx_dir_x_size   : cross cp_dir,   cp_size;
        cx_burst_x_resp : cross cp_burst, cp_resp;
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_axi_txn = new();
    endfunction

    virtual function void write(axi_transaction t);
        m_tr = t;
        cg_axi_txn.sample();
    endfunction

endclass : axi_coverage

`endif
