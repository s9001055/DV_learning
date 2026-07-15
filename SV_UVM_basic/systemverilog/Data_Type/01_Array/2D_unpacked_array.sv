module tb;
  byte 	stack [2][4]; 		// 2 rows, 4 cols

	initial begin
		// Assign random values to each slot of the stack
		foreach (stack[i])
          foreach (stack[i][j]) begin
            stack[i][j] = $random;
            $display ("stack[%0d][%0d] = 0x%0h", i, j, stack[i][j]);
			end

		// Print contents of the stack
		$display ("stack = %p", stack);
	end
endmodule

/*
stack[0][0] = 0x24
stack[0][1] = 0x81
stack[0][2] = 0x9
stack[0][3] = 0x63
stack[1][0] = 0xd
stack[1][1] = 0x8d
stack[1][2] = 0x65
stack[1][3] = 0x12
stack = '{'{36, -127, 9, 99}, '{13, -115, 101, 18}}
*/