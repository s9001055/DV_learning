interface myBus (input clk);
  logic [7:0]  data;
  logic      enable;

  // 從 TestBench 來看, 'data' 是 input and 'write' 是 output
  modport TB  (input data, clk, output enable);

  // 從 DUT 來看, 'data' 是 output and 'enable' 是 input
  modport DUT (output data, input enable, clk);
endinterface