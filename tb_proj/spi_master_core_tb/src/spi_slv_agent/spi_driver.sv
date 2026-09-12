`ifndef SPI_DRIVER_SV
`define SPI_DRIVER_SV

class spi_driver extends uvm_driver #(spi_transaction);
    `uvm_component_utils(spi_driver)

    virtual spi_if vif;

    reset_monitor rst_mon;

    // SPI mode configuration (set by test via config_db or field)
    bit cpol = 0;
    bit cpha = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", vif))
            `uvm_fatal("SPI_DRV", "Failed to get spi_vif from config_db")

        if (!uvm_config_db#(reset_monitor)::get(this, "", "rst_mon", rst_mon)) begin
            `uvm_fatal(get_type_name(), "Cannot get rst_mon from config_db")
        end

        if (!uvm_config_db#(bit)::get(this, "", "cpol", cpol)) begin
            `uvm_info(get_type_name(), "No cpol found, using default (cpol = 0)", UVM_MEDIUM)
        end

        if (!uvm_config_db#(bit)::get(this, "", "cpha", cpha)) begin
            `uvm_info(get_type_name(), "No cpha found, using default (cpha = 0)", UVM_MEDIUM)
        end

        `uvm_info(get_type_name(), $sformatf("cpol = %d cpha = %d", cpol, cpha), UVM_MEDIUM)
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            if (rst_mon.in_reset) begin
                reset_signals();
                rst_mon.ev_reset_done.wait_trigger();
            end

            fork
                drive_slave_response();

                begin : reset_thread
                    rst_mon.ev_reset_start.wait_trigger();
                end
            join_any

            disable fork;

            // 進入 reset，執行 reset
            reset_signals();
        end
    endtask

    virtual task reset_signals();
        vif.slv_cb.miso <= 1'b0;
    endtask

    // Shift out miso_data bit by bit, synchronized to sclk edges
    virtual task drive_slave_response();
        spi_transaction tr;

        forever begin
            seq_item_port.get_next_item(tr);
            int bit_idx;

            // Wait for SS_n to go low (transfer start)
            wait (vif.ss_n != {`SPI_SS_NB{1'b1}});

            for (int i = 0; i < tr.char_len; i++) begin
                bit_idx = tr.lsb_first ? i : (tr.char_len - 1 - i);

                // Drive MISO on the appropriate edge
                if (cpha == 0) begin
                    // Mode 0/2: data setup before first clock edge
                    vif.slv_cb.miso <= tr.miso_data[bit_idx];
                    if (cpol == 0) @(posedge vif.sclk);
                    else           @(negedge vif.sclk);
                end else begin
                    // Mode 1/3: data changes on first edge, sampled on second
                    if (cpol == 0) @(posedge vif.sclk);
                    else           @(negedge vif.sclk);
                    vif.slv_cb.miso <= tr.miso_data[bit_idx];
                end
            end

            // Wait for SS_n to go high (transfer end)
            wait (vif.ss_n == {`SPI_SS_NB{1'b1}});

            seq_item_port.item_done();
            `uvm_info("SPI_DRV", $sformatf("Slave shifted out %0d bits", tr.char_len), UVM_HIGH)
        end
    endtask

endclass : spi_driver

`endif
