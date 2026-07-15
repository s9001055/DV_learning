// assert 分成
// 1. Sequence 
//   sequence <name_of_sequence>
//      <test expression>
//   endsequence
//   // Assert the sequence
//   assert property (<name_of_sequence>);

// 2. Property
//    property <name_of_property>
//       <test expression> or
//       <sequence expressions>
//    endproperty
//    // Assert the property
//    assert property (<name_of_property>);

// 3. Immediate Assertions
//    always @ (<some_event>) begin
// 	    ...
// 	    // This is an immediate assertion executed only
// 	    // at this point in the execution flow
// 	    $assert(!fifo_empty);      // Assert that fifo is not empty at this point
// 	    ...
//    end

// 4. Concurrent Assertions
//   // Define a property to specify that an ack should be
//   // returned for every grant within 1:4 clocks
//   property p_ack;
// 	    @(posedge clk) gnt ##[1:4] ack;
//   endproperty
//   assert property(p_ack);    // Assert the given property is true always

// 創建 assertion 步驟
// Following are the steps to create assertions:
// Step 1: Create boolean expressions
// Step 2: Create sequence expressions
// Step 3: Create property
// Step 4: Assert property

module tb;
  bit a, b, c, d;
  bit clk;

  always #10 clk = ~clk;

  initial begin
    for (int i = 0; i < 20; i++) begin
      {a, b, c, d} = $random;
      $display("%0t a=%0d b=%0d c=%0d d=%0d", $time, a, b, c, d);
      @(posedge clk);
    end
    #10 $finish;
  end

  sequence s_ab;
    a ##1 b;        // 當 a 為 true 時，過 1 個週期後 b 也要為 true
  endsequence

  sequence s_cd;
    c ##2 d;        // 當 c 為 true 時，過 2 個週期後 d 也要為 true
  endsequence

  property p_expr;
    // a 為 true
    // ➜ 下一個 clock：b 為 true
    // ➜ 再下一個 clock（##1）：c 為 true
    // ➜ 再兩個 clock：d 為 true
    @(posedge clk) s_ab ##1 s_cd; 
  endproperty

  assert property (p_expr);
endmodule


