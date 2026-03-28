class alu_env #(parameter WIDTH = 8);
    virtual alu_if #(WIDTH) v_if;

  	int repeat_count = 10;

    // 宣告各 component
  	alu_in_monitor  #(.WIDTH(WIDTH)) alu_in_mon;
    alu_out_monitor #(.WIDTH(WIDTH)) alu_out_mon;
  	alu_ref_model   #(.WIDTH(WIDTH)) alu_ref_model;
    alu_scoreboard  #(.WIDTH(WIDTH)) alu_scb;
    alu_generator   #(.WIDTH(WIDTH)) alu_gen;
    alu_driver 		#(.WIDTH(WIDTH)) alu_drv;
  
  	// 宣告各 component 需要用到的 mailbox
  	mailbox #(alu_transaction) drv_mbx;
  	mailbox #(alu_transaction) in_mon_ref_mbx;
  	mailbox #(alu_transaction) out_mon_scb_mbx;
  	mailbox #(alu_transaction) ref_scb_mbx;
  
  	function new(virtual alu_if if_in, int count);
      	v_if = if_in;
      	
      	repeat_count = count;
        // 實例化各 mailbox
        drv_mbx 		= new();
        in_mon_ref_mbx 	= new();
        out_mon_scb_mbx = new();
        ref_scb_mbx 	= new();
        
        // 實例化各 component
        alu_in_mon 		= new(v_if, in_mon_ref_mbx);
        alu_out_mon 	= new(v_if, out_mon_scb_mbx);
      	alu_drv 		= new(v_if, drv_mbx); 
        alu_gen 		= new(drv_mbx, repeat_count);
        alu_ref_model 	= new(in_mon_ref_mbx, ref_scb_mbx);
        alu_scb 		= new(ref_scb_mbx, out_mon_scb_mbx);
    endfunction

    task run();
        // 各 component 開始運作
        fork
          alu_in_mon.run();
          alu_out_mon.run();
          alu_drv.run();
          alu_ref_model.run();
          alu_scb.run();
          alu_gen.run();
        join_none
    endtask
  
  	function void report();
      	alu_scb.report();
    endfunction
  
endclass