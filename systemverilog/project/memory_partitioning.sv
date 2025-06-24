class MemoryBlock;

  bit [31:0] 		m_ram_start; 			// Start address of RAM
  bit [31:0] 		m_ram_end; 				// End address of RAM

  rand bit [31:0] 	m_start_addr; 			// Pointer to start address of block
  rand bit [31:0]   m_end_addr; 			// Pointer to last addr of block
  rand int 			m_block_size; 			// Block size in KB

  constraint c_addr { m_start_addr >= m_ram_start; 	// Block addr should be more than RAM start
                      m_start_addr < m_ram_end; 	// Block addr should be less than RAM end
                      m_start_addr % 4 == 0;  		// Block addr should be aligned to 4-byte boundary
                      m_end_addr == m_start_addr + m_block_size - 1; };

  // 限制 m_block_size 大小為 64, 128, 512 
  constraint c_blk_size { m_block_size inside {64, 128, 512 }; }; 	// Block's size should be either 64/128/512 bytes

  function void display();
    $display ("------ Memory Block --------");
    $display ("RAM StartAddr   = 0x%0h", m_ram_start);
    $display ("RAM EndAddr     = 0x%0h", m_ram_end);
	$display ("Block StartAddr = 0x%0h", m_start_addr);
    $display ("Block EndAddr   = 0x%0h", m_end_addr);
    $display ("Block Size      = %0d bytes", m_block_size);
  endfunction
endclass

module tb;
  initial begin
    MemoryBlock mb = new;

    // 設定 m_ram_start 跟 m_ram_end 大小
    mb.m_ram_start = 32'h0;
    mb.m_ram_end   = 32'h7FF; 		// 2KB RAM

    // 對 mb 做 randomize()
    mb.randomize();
    mb.display();
  end
endmodule