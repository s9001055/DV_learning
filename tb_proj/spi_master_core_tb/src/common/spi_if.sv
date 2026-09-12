`ifndef SPI_IF_SV
`define SPI_IF_SV

interface spi_if (input logic clk);

    logic                       sclk;      // SPI clock (from DUT)
    logic                       mosi;      // master out slave in
    logic                       miso;      // master in slave out
    logic [`SPI_SS_NB-1:0]      ss_n;      // slave select (active low)

    // SPI slave driver clocking block (samples on sclk)
    // Note: actual sampling edge depends on CPOL/CPHA, handled in driver
    clocking slv_cb @(posedge clk);
        default input #1 output #1;
        input  sclk, mosi, ss_n;
        output miso;
    endclocking

    // Monitor clocking block
    clocking mon_cb @(posedge clk);
        default input #1;
        input sclk, mosi, miso, ss_n;
    endclocking

    modport slave   (clocking slv_cb);
    modport monitor (clocking mon_cb);

endinterface : spi_if

`endif
