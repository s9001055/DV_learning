// =============================================================================
// AHB DUT - AHB-Lite Slave (Verilog)
// Features:
//   1. No wait state transfer (HREADY always high)
//   2. Burst support: SINGLE, INCR (undefined length incremental)
// =============================================================================

module ahb_dut #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter MEM_DEPTH  = 256          // word-addressable depth
)(
    // AHB Global Signals
    input  wire                  HCLK,
    input  wire                  HRESETn,

    // AHB Transfer Signals (Slave Interface)
    input  wire                  HSEL,
    input  wire [ADDR_WIDTH-1:0] HADDR,
    input  wire                  HWRITE,
    input  wire [2:0]            HSIZE,
    input  wire [2:0]            HBURST,  // 3'b000=SINGLE, 3'b001=INCR
    input  wire [1:0]            HTRANS,  // 2'b00=IDLE, 2'b10=NONSEQ, 2'b11=SEQ
    input  wire [DATA_WIDTH-1:0] HWDATA,

    output reg  [DATA_WIDTH-1:0] HRDATA,
    output wire                  HREADYOUT,
    output wire                  HRESP
);

    // -------------------------------------------------------------------------
    // AHB Transfer Type Encoding
    // -------------------------------------------------------------------------
    localparam HTRANS_IDLE   = 2'b00;
    localparam HTRANS_NONSEQ = 2'b10;
    localparam HTRANS_SEQ    = 2'b11;

    // AHB Burst Type Encoding
    localparam HBURST_SINGLE = 3'b000;
    localparam HBURST_INCR   = 3'b001;

    // -------------------------------------------------------------------------
    // Internal Memory
    // -------------------------------------------------------------------------
    reg [DATA_WIDTH-1:0] mem [0:MEM_DEPTH-1];

    // -------------------------------------------------------------------------
    // Pipeline registers (address phase -> data phase)
    // -------------------------------------------------------------------------
    reg                  dph_sel;
    reg                  dph_write;
    reg [ADDR_WIDTH-1:0] dph_addr;
    reg [2:0]            dph_size;

    // -------------------------------------------------------------------------
    // Address Phase Active
    // -------------------------------------------------------------------------
    wire addr_phase_active = HSEL &&
                             (HTRANS == HTRANS_NONSEQ || HTRANS == HTRANS_SEQ);

    // -------------------------------------------------------------------------
    // Address Phase Capture
    // -------------------------------------------------------------------------
    always @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            dph_sel   <= 1'b0;
            dph_write <= 1'b0;
            dph_addr  <= {ADDR_WIDTH{1'b0}};
            dph_size  <= 3'b000;
        end else begin
            dph_sel   <= addr_phase_active;
            dph_write <= HWRITE;
            dph_addr  <= HADDR;
            dph_size  <= HSIZE;
        end
    end

    // -------------------------------------------------------------------------
    // Word Address (byte addr >> 2 for 32-bit bus)
    // -------------------------------------------------------------------------
    wire [7:0] word_addr = dph_addr[9:2];   // MEM_DEPTH=256, so 8-bit index

    // -------------------------------------------------------------------------
    // Write Operation (Data Phase)
    // -------------------------------------------------------------------------
    always @(posedge HCLK) begin
        if (dph_sel && dph_write) begin
            case (dph_size)
                3'b000: begin   // Byte
                    case (dph_addr[1:0])
                        2'b00: mem[word_addr][ 7: 0] <= HWDATA[ 7: 0];
                        2'b01: mem[word_addr][15: 8] <= HWDATA[15: 8];
                        2'b10: mem[word_addr][23:16] <= HWDATA[23:16];
                        2'b11: mem[word_addr][31:24] <= HWDATA[31:24];
                    endcase
                end
                3'b001: begin   // Halfword
                    if (!dph_addr[1]) begin
                        mem[word_addr][15: 0] <= HWDATA[15: 0];
                    end else begin
                        mem[word_addr][31:16] <= HWDATA[31:16];
                    end
                end
                default: begin  // Word (3'b010)
                    mem[word_addr] <= HWDATA;
                end
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // Read Operation (Data Phase, combinational for zero-wait-state)
    // -------------------------------------------------------------------------
    always @(*) begin
        HRDATA = {DATA_WIDTH{1'b0}};
        if (dph_sel && !dph_write) begin
            case (dph_size)
                3'b000: begin   // Byte
                    case (dph_addr[1:0])
                        2'b00: HRDATA = {24'b0, mem[word_addr][ 7: 0]};
                        2'b01: HRDATA = {24'b0, mem[word_addr][15: 8]};
                        2'b10: HRDATA = {24'b0, mem[word_addr][23:16]};
                        2'b11: HRDATA = {24'b0, mem[word_addr][31:24]};
                    endcase
                end
                3'b001: begin   // Halfword
                    if (!dph_addr[1])
                        HRDATA = {16'b0, mem[word_addr][15: 0]};
                    else
                        HRDATA = {16'b0, mem[word_addr][31:16]};
                end
                default: begin  // Word
                    HRDATA = mem[word_addr];
                end
            endcase
        end
    end

    // -------------------------------------------------------------------------
    // No wait state: HREADYOUT always asserted
    // HRESP always OKAY (0)
    // -------------------------------------------------------------------------
    assign HREADYOUT = 1'b1;
    assign HRESP     = 1'b0;

endmodule
