# 用 uvm_reg_frontdoor 完全自訂存取流程

如果存取行為跟標準的「一筆 read / 一筆 write」差太多（例如需要多筆 bus transaction、特殊的 handshake 序列），就不用 adapter 了，改用 frontdoor sequence：

```
class spi_ctrl_frontdoor extends uvm_reg_frontdoor;`uvm_object_utils(spi_ctrl_frontdoor)

    function new(string name = "spi_ctrl_frontdoor");
        super.new(name);
    endfunction

    virtual task body();
        wb_transaction tr;

        // 可以做任何你想做的事，不受 uvm_reg_bus_op 限制
        if (rw_info.kind == UVM_WRITE) begin
            // 第一筆：寫設定，GO=0
            `uvm_do_with(tr, {
                addr      == rw_info.addr[4:0];
                data      == (rw_info.data & ~(1 << SPI_CTRL_GO));
                direction == WB_WRITE;
            })

            // 第二筆：寫 GO=1
            `uvm_do_with(tr, {
                addr      == rw_info.addr[4:0];
                data      == rw_info.data;
                direction == WB_WRITE;
            })
        end else begin
            `uvm_do_with(tr, {
                addr      == rw_info.addr[4:0];
                direction == WB_READ;
            })
            rw_info.data   = tr.rdata;
            rw_info.status = UVM_IS_OK;
        end
    endtask

endclass

// 註冊到特定 register：
spi_ctrl_frontdoor fd = spi_ctrl_frontdoor::type_id::create("fd");
env.reg_model.ctrl.set_frontdoor(fd);

// 之後 ctrl.write() 就會自動走你的 frontdoor，而不是 adapter
env.reg_model.ctrl.write(status, 32'h0101); // 自動變成兩筆 bus write
`
```
