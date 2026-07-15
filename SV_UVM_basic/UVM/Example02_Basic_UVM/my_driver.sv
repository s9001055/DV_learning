class my_driver extends uvm_driver#(my_transaction); // 由於是從 sequencer 那邊接收 transaction 所以需要改成接收 my_transaction
    virtual my_if vif;
    virtual my_if vif2;

    `uvm_component_utils(my_driver) // factory 機制
    function new(string name = "my_driver", uvm_component parent = null);
        // 這個new函數有兩個參數，
        // 第一個參數是實例的名字，
        // 第二個則是parent。
        // 由於my_driver在uvm_env中產生實體，
        // 所以my_driver 的父結點（parent）就是my_env
        super.new(name, parent);
        `uvm_info("my_driver", "new is called", UVM_LOW);
    endfunction
    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("my_driver", "build_phase is called", UVM_LOW);
        if(!uvm_config_db#(virtual my_if)::get(this, "", "vif", vif))               // 與 top_tb 的 interface 對接
            `uvm_fatal("my_driver", "virtual interface must be set for vif!!!")
        if(!uvm_config_db#(virtual my_if)::get(this, "", "vif2", vif2))             // 與 top_tb 的 interface 對接
            `uvm_fatal("my_driver", "virtual interface must be set for vif2!!!")
    endfunction

    extern virtual task main_phase(uvm_phase phase);
    extern virtual task drive_one_pkt(my_transaction tr);
endclass


task my_driver::main_phase(uvm_phase phase);
    `uvm_info("my_driver", "main_phase is called", UVM_LOW);
    vif.data <= 8'b0;
    vif.valid <= 1'b0;
    while(!vif.rst_n)
        @(posedge vif.clk);
        for(int i = 0; i < 256; i++)begin
            @(posedge vif.clk);
            vif.data <= $urandom_range(0, 255);
            vif.valid <= 1'b1;
            `uvm_info("my_driver", "data is drived", UVM_LOW);
        end
    @(posedge vif.clk);
    vif.valid <= 1'b0;

    for(int i = 0; i < 2; i++) begin    // 實例出兩個 transaction，丟給 drive_one_pkt() 去執行
        tr = new("tr");
        assert(tr.randomize() with {pload.size == 200;});
        drive_one_pkt(tr);
    end

    phase.drop_objection(this);     // Objection drop 機制 
endtask


task my_driver::drive_one_pkt(my_transaction tr);
    bit [47:0] tmp_data;
    bit [7:0] data_q[$];
    //push dmac to data_q
    tmp_data = tr.dmac;
    for(int i = 0; i < 6; i++) begin
        data_q.push_back(tmp_data[7:0]);
        tmp_data = (tmp_data >> 8);
    end

    //push smac to data_q
    tmp_data = tr.smac;
    for(int i = 0; i < 6; i++) begin
        data_q.push_back(tmp_data[7:0]);
        tmp_data = (tmp_data >> 8);
    end

    //push ether_type to data_q
    tmp_data = tr.ether_type;
    for(int i = 0; i < 2; i++) begin
        data_q.push_back(tmp_data[7:0]);
        tmp_data = (tmp_data >> 8);
    end

    //push payload to data_q
    tmp_data = tr.payload;
    for(int i = 0; i < 1; i++) begin
        data_q.push_back(tmp_data[7:0]);
        tmp_data = (tmp_data >> 8);
    end

    //push crc to data_q
    tmp_data = tr.crc;
    for(int i = 0; i < 4; i++) begin
        data_q.push_back(tmp_data[7:0]);
        tmp_data = (tmp_data >> 8);
    end

    `uvm_info("my_driver", "begin to drive one pkt", UVM_LOW);
    repeat(3) @(posedge vif.clk);

    while(data_q.size() > 0) begin
        @(posedge vif.clk);
        vif.valid <= 1'b1;
        vif.data <= data_q.pop_front();
    end

    @(posedge vif.clk);
    vif.valid <= 1'b0;
    `uvm_info("my_driver", "end drive one pkt", UVM_LOW);
endtask