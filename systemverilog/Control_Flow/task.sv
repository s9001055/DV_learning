module task_example;
    logic clk;
    logic [7:0] data, result;

    // 定義 task
    task send_data(input logic [7:0] in_data, output logic [7:0] out_data);
        @(posedge clk); // 等待時鐘邊沿
        #2; // 模擬延遲
        out_data = in_data;
        $display("Data sent: %h", out_data);
    endtask

    // 模擬時鐘
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 測試 task
    initial begin
        data = 8'hA5;
      	$display("before call send_data result: %h", result);
        send_data(data, result); // 調用 task
      	$display("after call send_data result: %h", result);
    end
  
  	initial begin
      #50 $finish;
    end
endmodule

/*
before call send_data result: xx
Data sent: a5
after call send_data result: a5
*/