// ============================================================
// Round-Robin Arbiter v2 (fixed)
// ============================================================
module rr_arbiter #(
    parameter N = 4
)(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [N-1:0] req,
    output reg  [N-1:0] grant,
    output wire         valid
);
 
    reg  [N-1:0] priority_ptr;
    wire [N-1:0] grant_comb;
 
    wire [2*N-1:0] req_doubled;
    wire [2*N-1:0] mask;        // full 2N-bit mask
    wire [2*N-1:0] masked;
    wire [2*N-1:0] grant_2x;
 
    assign req_doubled = {req, req};
 
    // *** FIX: mask must be 2N bits wide, using full subtraction result ***
    // priority_ptr is N bits one-hot; treat as a 2N-bit number for subtraction
    assign mask   = ~({{N{1'b0}}, priority_ptr} - {{2*N-1{1'b0}}, 1'b1});
    assign masked = req_doubled & mask;   // use full 2N mask (not just lower N bits)
 
    // Isolate lowest set bit
    assign grant_2x = masked & (~masked + 1'b1);
 
    // Fold 2N -> N
    genvar gi;
    generate
        for (gi = 0; gi < N; gi = gi + 1) begin : fold
            assign grant_comb[gi] = grant_2x[gi] | grant_2x[gi + N];
        end
    endgenerate
 
    always @(posedge clk) begin
        if (!rst_n) begin
            grant        <= {N{1'b0}};
            priority_ptr <= {{N-1{1'b0}}, 1'b1};
        end else begin
            grant <= grant_comb;
            if (|grant_comb)
                priority_ptr <= {grant_comb[N-2:0], grant_comb[N-1]};
        end
    end
 
    assign valid = |grant;
 
endmodule
