1. my UVM notes link: https://1drv.ms/f/c/2ff01a406384200f/Ej9-9NIpAI9FgTBTe9QT_fgB-5tqRh5oHzDrBM22K5Vn3Q

你的 sequence
regmodel.CTRL.write(status, value, UVM_FRONTDOOR)
│
▼
┌─────────────────────────────┐
│ uvm_reg layer │ ← RAL 內部
│ uvm_reg::write() │
│ uvm_reg::do_write() │
│ uvm_reg_map::do_write() │
│ uvm_reg_map::do_bus_write() │
└─────────┬───────────────────┘
│ adapter.reg2bus(rw)
▼
┌─────────────────────────────┐
│ uvm_reg_adapter layer │ ← 你寫的 apb_reg_adapter
│ reg2bus() → apb_seq_item │
└─────────┬───────────────────┘
│ sequencer.start_item()
│ sequencer.finish_item()
▼
┌─────────────────────────────┐
│ uvm_sequencer layer │ ← agent.seqr
│ TLM FIFO 傳遞 item │
└─────────┬───────────────────┘
│ seq_item_port.get_next_item()
▼
┌─────────────────────────────┐
│ uvm_driver layer │ ← apb_driver
│ drive_transfer() │
│ APB Setup + Access phase │
└─────────┬───────────────────┘
│ 真實 bus signal 切換
▼
┌─────────────────────────────┐
│ DUT │
│ register 被真實 bus 寫入 │
└─────────┬───────────────────┘
│
▼
┌─────────────────────────────┐
│ apb_monitor │ ← 觀察 bus
│ ap.write(observed) │
└─────────┬───────────────────┘
│
▼
┌─────────────────────────────┐
│ uvm_reg_predictor │ ← explicit predict 模式
│ adapter.bus2reg() │
│ reg.predict() 更新 mirror │
└─────────────────────────────┘
