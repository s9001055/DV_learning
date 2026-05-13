import uvm_pkg::*;
`include "uvm_macros.svh"

`include "ahb_defines.svh"

// =============================================================================
// ahb_driver.sv - AHB-Lite Master Driver
//
// Implements the AHB-Lite two-phase (address phase / data phase) protocol:
//   - Supports SINGLE and INCR (undefined length) bursts
//   - Waits for HREADYOUT before advancing (handles wait states)
//   - Drives IDLE between transactions
// =============================================================================
class ahb_driver extends uvm_driver #(ahb_seq_item);
    `uvm_component_utils(ahb_driver)

    // Virtual interface handle
    virtual ahb_if.driver_mp vif;

    mailbox #(ahb_seq_item) addr_phase_item_q;
    mailbox #(ahb_seq_item) data_phase_item_q;

    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    function new(string name = "ahb_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // -------------------------------------------------------------------------
    // Build Phase - get virtual interface from config_db
    // -------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        addr_phase_item_q = new(1);
        data_phase_item_q = new(1);

        if (!uvm_config_db #(virtual ahb_if.driver_mp)::get(
                this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "ahb_driver: virtual interface not found in config_db")
    endfunction

    // -------------------------------------------------------------------------
    // Run Phase
    // -------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        // 初始化匯流排為 IDLE
        drive_idle();
        
        fork
            get_item_thread();
            addr_phase_drive_thread();
            data_phase_drive_thread();
        join
    endtask

    // -------------------------------------------------------------------------
    // Drive IDLE state on the bus
    // -------------------------------------------------------------------------
    task drive_idle();
        vif.driver_cb.HSEL    <= 1'b0;
        vif.driver_cb.HTRANS  <= 2'b00;  // IDLE
        vif.driver_cb.HADDR   <= '0;
        vif.driver_cb.HWRITE  <= 1'b0;
        vif.driver_cb.HSIZE   <= 3'b010;
        vif.driver_cb.HBURST  <= 3'b000;
        vif.driver_cb.HWDATA  <= '0;
    endtask

    // -------------------------------------------------------------------------
    // Get seq_item from sequencer
    // -------------------------------------------------------------------------
    task get_item_thread;
        ahb_seq_item item;
        int unsigned num_beats;
        logic [`AHB_ADDR_WIDTH-1:0] cur_addr;
        int          byte_inc;

        forever begin
            seq_item_port.get_next_item(item);

            num_beats = (item.burst == ahb_seq_item::HBURST_INCR) ?
                        item.burst_len : 1;
            cur_addr  = item.addr;
            byte_inc  = (1 << int'(item.size));

            `uvm_info("DRV", item.convert2string(), UVM_HIGH)

            // ------------------------------------------------------------------
            // ADDRESS PHASE ITEM
            // ------------------------------------------------------------------
            for (int beat = 0; beat < num_beats; beat++) begin
                ahb_seq_item addr_item;
                $cast(addr_item, item.clone());
                // cur_addr        = cur_addr + (1 << int'(item.size));
                addr_item.addr   = cur_addr + ((1 << int'(item.size)) * beat);
                addr_item.trans  = item.trans;

                // put item into addr_phase_item_q
                addr_phase_item_q.put(addr_item);
            end
            seq_item_port.item_done();
        end
    endtask


    // -------------------------------------------------------------------------
    // Drive ADDR_PHASE item
    // -------------------------------------------------------------------------
    task addr_phase_drive_thread;
        ahb_seq_item item;
        forever begin
            addr_phase_item_q.get(item);
            @(vif.driver_cb);
            if ( !vif.HRESETn ) begin
                drive_idle();
            end else begin
                if (vif.driver_cb.HREADYOUT) begin
                    // Drive Master Signals
                    vif.driver_cb.HSEL        <= 1'b1;
                    vif.driver_cb.HADDR       <= item.addr;
                    vif.driver_cb.HWRITE      <= item.write;
                    vif.driver_cb.HSIZE       <= item.size;
                    vif.driver_cb.HBURST      <= item.burst;
                    vif.driver_cb.HTRANS      <= item.trans;
                    if ( item.write ) begin
                        data_phase_item_q.put(item);
                    end
                end
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Drive DATA_PHASE item
    // -------------------------------------------------------------------------
    task data_phase_drive_thread;
        ahb_seq_item item;
        forever begin
            data_phase_item_q.get(item);
            @(vif.driver_cb);
            if ( !vif.HRESETn ) begin
                drive_idle();
            end else begin
                if (vif.driver_cb.HREADYOUT) begin

                    if (item.write) begin
                        vif.driver_cb.HWDATA <= item.data;
                    end else begin
                        // Latch read data
                        item.rdata = vif.driver_cb.HRDATA;
                        `uvm_info("DRV", $sformatf("READ  addr=0x%08h rdata=0x%08h",
                                item.addr, item.rdata), UVM_HIGH)
                    end
                    item.hresp  = vif.driver_cb.HRESP;
                    item.hready = vif.driver_cb.HREADYOUT;
                end
            end
        end
    endtask

endclass : ahb_driver
