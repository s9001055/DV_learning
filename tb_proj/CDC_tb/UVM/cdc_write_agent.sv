// ─────────────────────────────────────────────────────────────────────────────
// Write Agent
// ─────────────────────────────────────────────────────────────────────────────
class cdc_write_agent extends uvm_agent;
    `uvm_component_utils(cdc_write_agent)

    fifo_write_driver  driver;
    fifo_write_monitor monitor;
    uvm_sequencer #(fifo_write_item) sequencer;

    uvm_analysis_port #(fifo_write_item) ap;  // 轉發給 scoreboard

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap       = new("ap", this);
        monitor  = fifo_write_monitor::type_id::create("monitor", this);

        if (get_is_active() == UVM_ACTIVE) begin
            driver    = fifo_write_driver::type_id::create("driver", this);
            sequencer = uvm_sequencer #(fifo_write_item)::type_id::create(
                            "sequencer", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        if (get_is_active() == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);
        monitor.ap.connect(ap);
    endfunction
endclass
