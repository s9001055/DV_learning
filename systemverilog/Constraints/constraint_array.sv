// ================== static array ================== 
class Packet;
  rand bit [3:0] 	s_array [7]; 	// Declare a static array with "rand"
endclass

module tb;
  Packet pkt;

  // Create a new packet, randomize it and display contents
  initial begin
    pkt = new();
    pkt.randomize();
    $display("queue = %p", pkt.s_array);
  end
endmodule




// ================== dynamic array ================== 
class Packet;
  rand bit [3:0] 	d_array []; 	// Declare a dynamic array with "rand"

  // 限制 5 < array size < 10
  constraint c_array { d_array.size() > 5; 
                       d_array.size() < 10; 
                     }

  // 限制 d_array[i] == i
  constraint c_val   { foreach (d_array[i])
    					d_array[i] == i;
                     }

  // Utility function to display dynamic array contents
  function void display();
    foreach (d_array[i])
      $display ("d_array[%0d] = 0x%0h", i, d_array[i]);
  endfunction
endclass

module tb;
  Packet pkt;

  // Create a new packet, randomize it and display contents
  initial begin
    pkt = new();
    pkt.randomize();
    pkt.display();
  end
endmodule



// ================== queue ================== 
class Packet;
  rand bit [3:0] 	queue [$]; 	// Declare a queue with "rand"

  // 限制 queue.size() == 4
  constraint c_array { queue.size() == 4; }
endclass

module tb;
  Packet pkt;

  // Create a new packet, randomize it and display contents
  initial begin
    pkt = new();
    pkt.randomize();

    // Tip : Use %p to display arrays
    $display("queue = %p", pkt.queue);
  end
endmodule