`ifndef AXI_ENV_SV
`define AXI_ENV_SV

// forward-declare RAL types(實際 include 在 top testbench file 上層)
typedef class axi_reg_block;
typedef class axi_reg_adapter;

class axi_env extends uvm_env;
    `uvm_component_utils(axi_env)

    axi_mst_agent           mst_agent;
    axi_slv_agent           slv_agent;
    axi_scoreboard          sb;
    axi_coverage            cov;
    axi_reset_monitor       rst_mon;
    axi_reset_config        rst_cfg;

    // axi_mst_cfg             mst_cfg; // move to test case
    // axi_virtual_sequencer   v_sqr;

    // // RAL
    // axi_reg_block                              reg_model;
    // axi_reg_adapter                            reg_adapter;
    // uvm_reg_predictor #(axi_transaction)       reg_predictor;

    // bit has_ral = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // void'(uvm_config_db#(bit)::get(this, "", "has_ral", has_ral));

        // Reset Config and Reset Monitor 
        rst_cfg = axi_reset_config::type_id::create("rst_cfg", this);
        rst_cfg.exit_mode = axi_reset_config::WAIT_CYCLES;
        rst_cfg.exit_cycles = 10;

        rst_mon = axi_reset_monitor::type_id::create("rst_mon", this);

        // Master agent: active
        mst_agent = axi_mst_agent::type_id::create("mst_agent", this);
        uvm_config_db#(uvm_active_passive_enum)::set(this, "mst_agent", "is_active", UVM_ACTIVE);
        // mst_cfg   = axi_mst_cfg::type_id::create("mst_cfg", this); // move to test case
        // uvm_config_db#(axi_mst_cfg)::set(this, "mst_agent*", "mst_cfg", mst_cfg); // move to test case

        // Slave agent: default passive(可透過 test override)
        uvm_config_db#(uvm_active_passive_enum)::set(this, "slv_agent", "is_active", UVM_ACTIVE);
        slv_agent = axi_slv_agent::type_id::create("slv_agent", this);

        sb    = axi_scoreboard::type_id::create("sb",    this);
        cov   = axi_coverage  ::type_id::create("cov",   this);




        // v_sqr = axi_virtual_sequencer::type_id::create("v_sqr", this);

        // if (has_ral) begin
        //     if (reg_model == null) begin
        //         reg_model = axi_reg_block::type_id::create("reg_model", , get_full_name());
        //         reg_model.build();
        //         reg_model.lock_model();
        //     end
        //     reg_adapter   = axi_reg_adapter::type_id::create("reg_adapter", , get_full_name());
        //     reg_predictor = uvm_reg_predictor#(axi_transaction)::type_id::create("reg_predictor", this);
        // end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Reset Monitor rst_cfg connect
        rst_mon.rst_cfg = rst_cfg;

        // Passing reset_monitor to agent
        mst_agent.rst_mon = rst_mon;
        slv_agent.rst_mon = rst_mon;

        // Monitor → scoreboard + coverage
        mst_agent.mon.ap.connect(sb.ap_imp);
        mst_agent.mon.ap.connect(cov.analysis_export);





        // // Virtual sequencer 綁 sub-sequencer
        // v_sqr.mst_sqr = mst_agent.sqr;
        // if (slv_agent.get_is_active() == UVM_ACTIVE)
        //     v_sqr.slv_sqr = slv_agent.sqr;

        // // RAL 連接
        // if (has_ral) begin
        //     reg_model.default_map.set_sequencer(mst_agent.sqr, reg_adapter);
        //     reg_model.default_map.set_auto_predict(0);   // 用 passive predictor

        //     reg_predictor.map     = reg_model.default_map;
        //     reg_predictor.adapter = reg_adapter;
        //     mst_agent.mon.ap.connect(reg_predictor.bus_in);
        // end
    endfunction

endclass : axi_env

`endif
