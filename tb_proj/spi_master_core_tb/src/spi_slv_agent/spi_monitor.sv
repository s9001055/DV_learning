`ifndef SPI_MONITOR_SV
`define SPI_MONITOR_SV

class spi_monitor extends uvm_monitor;
    `uvm_component_utils(spi_monitor)

    virtual spi_if vif;
    uvm_analysis_port #(spi_transaction) ap;

    // SPI mode (must match DUT's CTRL settings)
    bit cpol = 0;
    bit cpha = 0;
    bit lsb_first = 0;
    int unsigned char_len = 8;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", vif))
            `uvm_fatal("SPI_MON", "Failed to get spi_vif from config_db")
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            spi_transaction tr;
            collect_transfer(tr);
            ap.write(tr);
        end
    endtask

    virtual task collect_transfer(output spi_transaction tr);
        int bit_idx;
        tr = spi_transaction::type_id::create("spi_mon_tr");
        tr.char_len  = char_len;
        tr.lsb_first = lsb_first;
        tr.mosi_data = '0;
        tr.miso_data = '0;

        // Wait for any SS_n to go low
        wait (vif.ss_n != {`SPI_SS_NB{1'b1}});

        // Identify which slave is selected
        for (int s = 0; s < `SPI_SS_NB; s++)
            if (!vif.ss_n[s]) tr.slave_id = s;

        // Sample data on each sclk edge
        for (int i = 0; i < char_len; i++) begin
            bit_idx = lsb_first ? i : (char_len - 1 - i);

            // Sample on the appropriate edge based on CPOL/CPHA
            if (cpha == 0) begin
                if (cpol == 0) @(posedge vif.sclk);  // sample on rising
                else           @(negedge vif.sclk);   // sample on falling
            end else begin
                if (cpol == 0) @(negedge vif.sclk);   // sample on falling
                else           @(posedge vif.sclk);   // sample on rising
            end

            tr.mosi_data[bit_idx] = vif.mosi;
            tr.miso_data[bit_idx] = vif.miso;
        end

        // Wait for SS_n to go high
        wait (vif.ss_n == {`SPI_SS_NB{1'b1}});

        tr.spi_mode = spi_mode_e'({cpol, cpha});
        `uvm_info("SPI_MON", tr.convert2string(), UVM_MEDIUM)
    endtask

endclass : spi_monitor

`endif
