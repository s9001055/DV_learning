module tb;
	event eventA; 		// Declare an event handle called  "eventA"

	initial begin
		fork
            // create 2 個 thread
			waitForTrigger (eventA);    // Task waits for eventA to happen
			#5 ->eventA;                // #5後 Triggers eventA
		join
	end

	// The event is passed as an argument to this task. It simply waits for the event
	// to be triggered
	task waitForTrigger (event eventA);
		$display ("[%0t] Waiting for EventA to be triggered", $time);
		wait (eventA.triggered);    // 等待 eventA 被 triggered
		$display ("[%0t] EventA has triggered", $time);
	endtask
endmodule


/*
[0] Waiting for EventA to be triggered
[5] EventA has triggered
*/