`ifndef ALU_COVERAGE_SV
`define ALU_COVERAGE_SV

class alu_coverage #(parameter WIDTH = 8);
    // 內部的採樣變數
    logic [WIDTH-1:0] a, b;
    logic             op;
    logic             overflow;

    // 定義 Covergroup
    covergroup alu_cg;
        // 檢查操作碼是否都有測到
        cp_op: coverpoint op {
            bins add = {0};
            bins sub = {1};
        }

        // 檢查輸入 A 的邊界值 (有號數 127, -128, 0)
        cp_a: coverpoint a {
            bins zeros   = {0};
            bins max_pos = {8'h7F};  // 127
            bins max_neg = {8'h80};  // -128
            bins others  = default;
        }

        // 檢查是否真的發生過溢位
        cp_ov: coverpoint overflow {
            bins happened = {1};
            bins none     = {0};
        }

        // Cross Coverage
        // 確認「加法溢位」跟「減法溢位」都分別發生過
        cross_op_ov: cross cp_op, cp_ov {
            // 我們只關心發生溢位的情況
            ignore_bins no_overflow = binsof(cp_ov) intersect {0}; // 排除掉 cp_ov 為 0 的所有組合
        }
    endgroup

    function new();
        alu_cg = new();
    endfunction

    // 提供一個方法讓 Monitor 呼叫並採樣
    function void sample(alu_transaction #(.WIDTH(WIDTH)) tr);
        this.a        = tr.a;
        this.b        = tr.b;
        this.op       = tr.op;
        this.overflow = tr.overflow;
        alu_cg.sample();
    endfunction
endclass

`endif // ALU_COVERAGE_SV