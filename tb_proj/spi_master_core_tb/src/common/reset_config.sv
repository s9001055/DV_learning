`ifndef AXI_RESET_CONFIG_SV
`define AXI_RESET_CONFIG_SV

class axi_reset_config extends uvm_object;
  `uvm_object_utils(axi_reset_config)

  reset_exit_mode_e exit_mode   = WAIT_CYCLES;
  int unsigned      exit_cycles = 5;

  function new(string name = "axi_reset_config");
    super.new(name);
  endfunction
endclass : axi_reset_config

`endif