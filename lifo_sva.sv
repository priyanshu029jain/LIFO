// SystemVerilog Assertions (SVA) Module for LIFO
// Used by Formal Verification (SymbiYosys) and Dynamic SVA checkers

module lifo_sva (
  input wire        clk,
  input wire        reset,
  input wire [7:0]  data_in,
  input wire        push,
  input wire        pop,
  input wire [7:0]  data_out,
  input wire [7:0]  peek_data,
  input wire        empty,
  input wire        full,
  input wire [4:0]  ptr
);

`ifdef FORMAL

  // Assume reset on power-up
  initial assume (reset == 1'b1);

  // Disallow operations while in reset
  always @(posedge clk) begin
    if (reset) begin
      assume (push == 1'b0);
      assume (pop  == 1'b0);
    end
  end

  // -------------------------------------------------------------
  // SystemVerilog Assertions (SVA)
  // -------------------------------------------------------------

  // 1. Pointer bounds: pointer must never exceed maximum depth 16
  assert_ptr_range: assert property (
    @(posedge clk) disable iff (reset)
    ptr <= 5'd16
  );

  // 2. Empty flag definition: empty iff pointer is 0
  assert_empty_flag: assert property (
    @(posedge clk) disable iff (reset)
    empty == (ptr == 5'd0)
  );

  // 3. Full flag definition: full iff pointer is 16
  assert_full_flag: assert property (
    @(posedge clk) disable iff (reset)
    full == (ptr == 5'd16)
  );

  // 4. Mutual exclusion: cannot be simultaneously empty and full
  assert_mutex_flags: assert property (
    @(posedge clk) disable iff (reset)
    !(empty && full)
  );

  // 5. Peek data is zero when empty
  assert_peek_empty: assert property (
    @(posedge clk) disable iff (reset)
    empty |-> (peek_data == 8'h00)
  );

  // 6. Push operation: increments pointer by 1 when not full
  assert_push_increments: assert property (
    @(posedge clk) disable iff (reset)
    (push && !pop && !full) |=> (ptr == $past(ptr) + 1'b1)
  );

  // 7. Pop operation: decrements pointer by 1 when not empty
  assert_pop_decrements: assert property (
    @(posedge clk) disable iff (reset)
    (pop && !push && !empty) |=> (ptr == $past(ptr) - 1'b1)
  );

  // 8. Overflow protection: push when full leaves pointer at 16
  assert_overflow_safe: assert property (
    @(posedge clk) disable iff (reset)
    (push && !pop && full) |=> (ptr == 5'd16 && full)
  );

  // 9. Underflow protection: pop when empty leaves pointer at 0
  assert_underflow_safe: assert property (
    @(posedge clk) disable iff (reset)
    (pop && !push && empty) |=> (ptr == 5'd0 && empty)
  );

  // 10. Simultaneous push & pop: leaves depth unchanged
  assert_push_pop_invariant: assert property (
    @(posedge clk) disable iff (reset)
    (push && pop && !empty && !full) |=> (ptr == $past(ptr))
  );

  // -------------------------------------------------------------
  // Cover Properties: Prove reachability of key states
  // -------------------------------------------------------------

  // Cover 1: Stack reaches full capacity
  cover_full_stack: cover property (
    @(posedge clk) disable iff (reset)
    full
  );

  // Cover 2: Stack becomes empty after being non-empty
  cover_empty_after_data: cover property (
    @(posedge clk) disable iff (reset)
    empty && $past(!empty)
  );

  // Cover 3: Simultaneous push and pop execution
  cover_simultaneous_op: cover property (
    @(posedge clk) disable iff (reset)
    push && pop && !empty
  );

`endif

endmodule
