`ifndef AXI_RESET_MONITOR_SV
`define AXI_RESET_MONITOR_SV

class axi_reset_monitor extends uvm_component;
    `uvm_component_utils(axi_reset_monitor)

    virtual axi_if vif;
    axi_reset_config rst_cfg;

    // event 用來給全部 component 監聽是否 reset or 離開 reset
    uvm_event ev_reset_start;    // reset 拉低的瞬間
    uvm_event ev_reset_done;     // reset 完全結束、DUT 穩定可以工作

    // 讓 component 可以隨時查詢
    bit in_reset = 1;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ev_reset_start = new("ev_reset_start");
        ev_reset_done  = new("ev_reset_done");
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_if)::get(this, "", "vif", vif))
            `uvm_fatal(get_type_name(), "Cannot get axi_if from config_db")
    endfunction

    task run_phase(uvm_phase phase);
        // 上電時先等第一次 reset 結束
        wait(vif.aresetn === 1'b0);
        in_reset = 1;
        wait(vif.aresetn === 1'b1);
        wait_dut_stable();
        in_reset = 0;
        ev_reset_done.trigger();

        // 之後持續監控
        forever begin
        @(negedge vif.aresetn);
        in_reset = 1;
        ev_reset_start.trigger();
        `uvm_info(get_type_name(), "Reset asserted", UVM_MEDIUM)

        @(posedge vif.aresetn);
        wait_dut_stable();
        in_reset = 0;
        ev_reset_done.trigger();
        `uvm_info(get_type_name(), "Reset done, DUT stable", UVM_MEDIUM)
        end
    endtask

    // 根據 config 決定怎麼等 reset 後的穩定
    task wait_dut_stable();
        case (rst_cfg.exit_mode)
            WAIT_CYCLES: begin
            repeat(rst_cfg.exit_cycles) @(posedge vif.aclk);
            end

            WAIT_SIGNAL: begin
            // 等 DUT 自己的 ready 信號
            // wait(vif.init_done === 1'b1);
            @(posedge vif.aclk);
            end

            WAIT_BUS_IDLE: begin
            // wait(vif.psel === 1'b0 && vif.penable === 1'b0);
            @(posedge vif.aclk);
            end
        endcase
    endtask
endclass : axi_reset_monitor

`endif
