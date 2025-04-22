// string       name_list [$];        // A queue of string elements
// bit [3:0]    data [$];             // A queue of 4-bit elements

// logic [7:0]  elements [$:127];     // A bounded queue of 8-bits with maximum size of 128 slots

// int  q1 [$] =  { 1, 2, 3, 4, 5 };  // Integer queue, initialize elements
// int  q2 [$];                       // Integer queue, empty
// int  tmp;                          // Temporary variable to store values

module tb;
	string fruits[$] = {"apple", "pear", "mango", "banana"};

	initial begin
		// size() - Gets size of the given queue
		$display ("Number of fruits=%0d   fruits=%p", fruits.size(), fruits);

		// insert() - Insert an element to the given index
		fruits.insert (1, "peach");
		$display ("Insert peach, size=%0d fruits=%p", fruits.size(), fruits);

		// delete() - Delete element at given index
		fruits.delete (3);
		$display ("Delete mango, size=%0d fruits=%p", fruits.size(), fruits);

		// pop_front() - Pop out element at the front
		$display ("Pop %s,    size=%0d fruits=%p", fruits.pop_front(), fruits.size(), fruits);

		// push_front() - Push a new element to front of the queue
		fruits.push_front("apricot");
		$display ("Push apricot, size=%0d fruits=%p", fruits.size(), fruits);

		// pop_back() - Pop out element from the back
		$display ("Pop %s,   size=%0d fruits=%p", fruits.pop_back(), fruits.size(), fruits);

		// push_back() - Push element to the back
		fruits.push_back("plum");
		$display ("Push plum,    size=%0d fruits=%p", fruits.size(), fruits);
	end
endmodule

/*
Number of fruits=4   fruits='{"apple", "pear", "mango", "banana"}
Insert peach, size=5 fruits='{"apple", "peach", "pear", "mango", "banana"}
Delete mango, size=4 fruits='{"apple", "peach", "pear", "banana"}
Pop apple,    size=3 fruits='{"peach", "pear", "banana"}
Push apricot, size=4 fruits='{"apricot", "peach", "pear", "banana"}
Pop banana,   size=3 fruits='{"apricot", "peach", "pear"}
Push plum,    size=4 fruits='{"apricot", "peach", "pear", "plum"}
*/