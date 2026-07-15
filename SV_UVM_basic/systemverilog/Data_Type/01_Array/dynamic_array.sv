module tb;
	// Create a dynamic array that can hold elements of type int
	int 	array [];

	initial begin
		// Create a size for the dynamic array -> size here is 5
		// so that it can hold 5 values
		array = new [5];

		// Initialize the array with five values
		array = '{31, 67, 10, 4, 99};

		// Loop through the array and print their values
		foreach (array[i])
			$display ("array[%0d] = %0d", i, array[i]);
	end
endmodule

/*
array[0] = 31
array[1] = 67
array[2] = 10
array[3] = 4
array[4] = 99
*/


module tb1;
	// Create two dynamic arrays of type int
	int array [];
	int id [];

	initial begin
		// Allocate 5 memory locations to "array" and initialize with values
		array = new [5];
		array = '{1, 2, 3, 4, 5};

		// Point "id" to "array"
		id = array;

		// Display contents of "id"
		$display ("id = %p", id);

		// Grow size by 1 and copy existing elements to the new dyn.Array "id"
		id = new [id.size() + 1] (id);

		// Assign value 6 to the newly added location [index 5]
		id [id.size() - 1] = 6;

		// Display contents of new "id"
		$display ("New id = %p", id);

		// Display size of both arrays
		$display ("array.size() = %0d, id.size() = %0d", array.size(), id.size());
	end
endmodule

/*
id = '{1, 2, 3, 4, 5}
New id = '{1, 2, 3, 4, 5, 6}
array.size() = 5, id.size() = 6
*/