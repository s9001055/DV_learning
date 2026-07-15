class mem_monitor extends uvm_monitor;

  // Virtual Interface
  virtual mem_if vif;

  // 建立對 scoreboard 的傳輸通道 uvm_analysis_port
  uvm_analysis_port #(mem_seq_item) item_collected_port;
  
  // 用來收集DUT執行完的 transations
  mem_seq_item trans_collected;

  `uvm_component_utils(mem_monitor)

  // new - constructor
  function new (string name, uvm_component parent);
    super.new(name, parent);
    trans_collected = new();

    // 實例化 item_collected_port
    item_collected_port = new("item_collected_port", this);
  endfunction : new

  // build_phase - getting the interface handle
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual mem_if)::get(this, "", "vif", vif))
       `uvm_fatal("NOVIF",{"virtual interface must be set for: ",get_full_name(),".vif"});
  endfunction: build_phase
  
  // run_phase - convert the signal level activity to transaction level.
  // i.e, sample the values on interface signal ans assigns to transaction class fields
  virtual task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.MONITOR.clk);
      wait(vif.monitor_cb.wr_en || vif.monitor_cb.rd_en);
        trans_collected.addr = vif.monitor_cb.addr;
      if(vif.monitor_cb.wr_en) begin
        trans_collected.wr_en = vif.monitor_cb.wr_en;
        trans_collected.wdata = vif.monitor_cb.wdata;
        trans_collected.rd_en = 0;
        @(posedge vif.MONITOR.clk); // 等待完成
      end
      if(vif.monitor_cb.rd_en) begin
        trans_collected.rd_en = vif.monitor_cb.rd_en;
        trans_collected.wr_en = 0;
        @(posedge vif.MONITOR.clk);
        @(posedge vif.MONITOR.clk); // 假設 read data 有延遲，所以等兩個 clk
        trans_collected.rdata = vif.monitor_cb.rdata;
      end
	  item_collected_port.write(trans_collected); // 將 trans_collected 寫入 port，送到 socreboard
      end 
  endtask : run_phase

endclass : mem_monitor
