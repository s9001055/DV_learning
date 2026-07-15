class my_monitor extends uvm_monitor;

    virtual my_if vif;

    uvm_analysis_port #(my_transaction)  ap;

    `uvm_component_utils(my_monitor)
    function new(string name = "my_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction 

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual my_if)::get(this, "", "vif", vif))
            `uvm_fatal("my_monitor", "virtual interface must be set for vif!!!")

        // 實例化 uvm_analysis_port
        ap = new("ap", this);
    endfunction

    extern task main_phase(uvm_phase phase);
    extern task collect_one_pkt(my_transaction tr);
endclass

task my_monitor::main_phase(uvm_phase phase);
    my_transaction tr;
    while(1) begin
        tr = new("tr");
        collect_one_pkt(tr);
        // 當收集完一個 transaction 後，需要將其寫入 ap 中
        // .write() 為 uvm_analysis_port 的內建函數
        ap.write(tr);
    end
endtask

task my_monitor::collect_one_pkt(my_transaction tr);
    bit[7:0] data_q[$];
    int psize;
    while(1) begin
        @(posedge vif.clk);
        if(vif.valid) break;
    end

    `uvm_info("my_monitor", "begin to collect one pkt", UVM_LOW);
    while(vif.valid) begin
        data_q.push_back(vif.data);
        @(posedge vif.clk);
    end
    //pop dmac
    for(int i = 0; i < 6; i++) begin
        tr.dmac = {tr.dmac[39:0], data_q.pop_front()};
    end
    //pop smac
    //pop ether_type
    …
    //pop payload 
    …
    //pop crc
    for(int i = 0; i < 4; i++) begin
        tr.crc = {tr.crc[23:0], data_q.pop_front()};
    end
    `uvm_info("my_monitor", "end collect one pkt, print it:", UVM_LOW);
    tr.my_print();
endtask