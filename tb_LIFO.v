`include "LIFO.v"
`timescale 1ns/1ps

// Self-checking directed testbench for LIFO
// - Stimulus is applied on the falling edge, DUT outputs are checked 1ns after the rising edge
// - A reference model (model_stack / model_ptr) predicts every output after every operation
// - Prints a per-case result and a final PASS/FAIL summary
module tb_LIFO;

  // Testbench signals
  reg clk, reset;
  reg [7:0] data_in;
  reg push, pop;
  wire [7:0] data_out;
  wire [7:0] peek_data;
  wire empty, full;

  // Instantiate DUT
  LIFO uut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .push(push),
    .pop(pop),
    .data_out(data_out),
    .peek_data(peek_data),
    .empty(empty),
    .full(full)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Reference model
  reg [7:0] model_stack [0:15];
  integer   model_ptr;
  reg [7:0] model_dout;

  // Scoreboard counters
  integer checks_total, checks_failed;
  integer cases_total, cases_failed, case_fail_start;
  reg [8*48:1] case_name;

  integer i;

  // -------------------------------------------------------------
  // Case bookkeeping
  // -------------------------------------------------------------
  task begin_case(input [8*48:1] name);
    begin
      case_name       = name;
      cases_total     = cases_total + 1;
      case_fail_start = checks_failed;
    end
  endtask

  task end_case;
    begin
      if (checks_failed == case_fail_start)
        $display("[PASS] Case %0d: %0s", cases_total, case_name);
      else begin
        $display("[FAIL] Case %0d: %0s (%0d check(s) failed)",
                 cases_total, case_name, checks_failed - case_fail_start);
        cases_failed = cases_failed + 1;
      end
    end
  endtask

  // -------------------------------------------------------------
  // Compare every DUT output against the reference model
  // -------------------------------------------------------------
  task check_outputs;
    reg [7:0] exp_peek;
    begin
      exp_peek     = (model_ptr > 0) ? model_stack[model_ptr - 1] : 8'h00;
      checks_total = checks_total + 1;
      if (data_out !== model_dout || peek_data !== exp_peek ||
          empty !== (model_ptr == 0) || full !== (model_ptr == 16) || uut.ptr !== model_ptr) begin
        checks_failed = checks_failed + 1;
        $display("  MISMATCH @%0t [%0s] data_out=%h/%h peek=%h/%h empty=%b/%b full=%b/%b ptr=%0d/%0d (got/exp)",
                 $time, case_name, data_out, model_dout, peek_data, exp_peek,
                 empty, (model_ptr == 0), full, (model_ptr == 16), uut.ptr, model_ptr);
      end
    end
  endtask

  // -------------------------------------------------------------
  // Drive one clock cycle of (push, pop, data), update the model, check
  // -------------------------------------------------------------
  task do_op(input p, input q, input [7:0] d);
    begin
      @(negedge clk);
      push = p; pop = q; data_in = d;
      @(posedge clk);

      // Reference model update (spec: README "Operations")
      if (reset) begin
        model_ptr  = 0;
        model_dout = 8'h00;
      end else begin
        case ({p, q})
          2'b10: if (model_ptr < 16) begin
                   model_stack[model_ptr] = d;
                   model_ptr = model_ptr + 1;
                 end
          2'b01: if (model_ptr > 0) begin
                   model_ptr  = model_ptr - 1;
                   model_dout = model_stack[model_ptr];
                 end
          2'b11: if (model_ptr == 0)
                   model_dout = d;                          // pass-through on empty
                 else begin
                   model_dout = model_stack[model_ptr - 1]; // read old top
                   model_stack[model_ptr - 1] = d;          // overwrite top (also when full)
                 end
          default: ;                                        // idle
        endcase
      end

      #1 check_outputs;
    end
  endtask

  task do_push(input [7:0] d); do_op(1'b1, 1'b0, d);    endtask
  task do_pop;                 do_op(1'b0, 1'b1, 8'h00); endtask
  task do_pushpop(input [7:0] d); do_op(1'b1, 1'b1, d); endtask
  task do_idle;                do_op(1'b0, 1'b0, 8'h00); endtask

  task apply_reset;
    begin
      @(negedge clk);
      reset = 1; push = 0; pop = 0;
      @(posedge clk);
      model_ptr  = 0;
      model_dout = 8'h00;
      #1 check_outputs;
      @(negedge clk);
      reset = 0;
    end
  endtask

  task fill_stack(input [7:0] base);
    begin
      while (model_ptr < 16)
        do_push(base + model_ptr);
    end
  endtask

  task drain_stack;
    begin
      while (model_ptr > 0)
        do_pop;
    end
  endtask

  // -------------------------------------------------------------
  // Directed test cases
  // -------------------------------------------------------------
  initial begin
    // VCD dump
    $dumpfile("testbench.vcd");
    $dumpvars(0, tb_LIFO);

    // Initialize
    clk = 0; reset = 1; push = 0; pop = 0; data_in = 0;
    model_ptr = 0; model_dout = 8'h00;
    checks_total = 0; checks_failed = 0;
    cases_total  = 0; cases_failed  = 0;

    // --- Case 1: Reset values ---
    begin_case("Reset values");
    apply_reset;
    end_case;

    // --- Case 2: Idle cycles hold state ---
    begin_case("Idle after reset holds state");
    repeat (3) do_idle;
    end_case;

    // --- Case 3: Single push then pop ---
    begin_case("Single push / pop");
    do_push(8'h5A);
    do_pop;
    end_case;

    // --- Case 4: Push 4, pop 4 (LIFO order) ---
    begin_case("Push 4 then pop 4 in LIFO order");
    for (i = 0; i < 4; i = i + 1) do_push(8'hA0 + i);
    for (i = 0; i < 4; i = i + 1) do_pop;
    end_case;

    // --- Case 5: Underflow ---
    begin_case("Pop on empty is ignored");
    do_pop;
    end_case;

    // --- Case 6: Repeated underflow, data_out holds last value ---
    begin_case("Repeated pops on empty hold data_out");
    repeat (3) do_pop;
    end_case;

    // --- Case 7: Push+pop on empty passes data through ---
    begin_case("Push+pop on empty passes data_in through");
    do_pushpop(8'h3C);
    end_case;

    // --- Case 8: Push+pop at depth 1 ---
    begin_case("Push+pop at depth 1 overwrites top");
    do_push(8'h11);
    do_pushpop(8'h22);
    do_pop;
    end_case;

    // --- Case 9: Push+pop on partially filled stack ---
    begin_case("Push+pop at depth 5 keeps depth");
    for (i = 0; i < 5; i = i + 1) do_push(8'h40 + i);
    do_pushpop(8'hC5);
    drain_stack;
    end_case;

    // --- Case 10: Back-to-back push+pop ---
    begin_case("8 back-to-back push+pop operations");
    do_push(8'h01);
    do_push(8'h02);
    for (i = 0; i < 8; i = i + 1) do_pushpop(8'hD0 + i);
    drain_stack;
    end_case;

    // --- Case 11: Fill stack completely ---
    begin_case("Fill to 16 sets full exactly at 16");
    for (i = 0; i < 15; i = i + 1) do_push(8'h10 + i);  // full must still be 0 at 15
    do_push(8'h1F);                                     // full must be 1 at 16
    end_case;

    // --- Case 12: Overflow ---
    begin_case("Push on full is ignored (x3)");
    do_push(8'hFF);
    do_push(8'hFE);
    do_push(8'hFD);
    end_case;

    // --- Case 13: Pop from full clears full ---
    begin_case("Pop from full clears full, push refills");
    do_pop;
    do_push(8'h2F);
    end_case;

    // --- Case 14: Push+pop on full (spec: overwrite top) ---
    begin_case("Push+pop on full overwrites top");
    do_pushpop(8'hEE);
    end_case;

    // --- Case 15: Drain full stack ---
    begin_case("Drain 16 entries in LIFO order");
    drain_stack;
    do_pop;  // one extra pop on empty
    end_case;

    // --- Case 16: Boundary data values ---
    begin_case("Boundary data values 00/FF/55/AA");
    do_push(8'h00);
    do_push(8'hFF);
    do_push(8'h55);
    do_push(8'hAA);
    drain_stack;
    end_case;

    // --- Case 17: Peek is non-destructive ---
    begin_case("Peek is stable across idle cycles");
    do_push(8'h77);
    do_push(8'h88);
    repeat (4) do_idle;
    drain_stack;
    end_case;

    // --- Case 18: Interleaved push/pop pattern ---
    begin_case("Interleaved push-push-pop pattern");
    for (i = 0; i < 6; i = i + 1) begin
      do_push(8'h60 + 2*i);
      do_push(8'h61 + 2*i);
      do_pop;
    end
    drain_stack;
    end_case;

    // --- Case 19: Fill and drain twice (memory reuse) ---
    begin_case("Fill / drain twice with new data");
    fill_stack(8'h80);
    drain_stack;
    fill_stack(8'hB0);
    drain_stack;
    end_case;

    // --- Case 20: Reset with data in the stack ---
    begin_case("Reset mid-operation empties the stack");
    for (i = 0; i < 6; i = i + 1) do_push(8'h90 + i);
    do_pop;
    apply_reset;
    do_pop;  // must be ignored after reset
    end_case;

    // --- Case 21: Reset has priority over push/pop ---
    begin_case("Reset has priority over push and pop");
    do_push(8'h12);
    @(negedge clk);
    reset = 1; push = 1; pop = 0; data_in = 8'h34;
    @(posedge clk);
    model_ptr = 0; model_dout = 8'h00;
    #1 check_outputs;
    @(negedge clk);
    reset = 0; push = 0;
    do_idle;
    end_case;

    // --- Case 22: Push on full then push+pop on full, then recover ---
    begin_case("Full-boundary stress then recovery");
    fill_stack(8'hC0);
    do_push(8'h99);
    do_pushpop(8'h9A);
    do_pop;
    do_push(8'h9B);
    drain_stack;
    end_case;

    // Summary
    $display("\n==============================================");
    $display("        DIRECTED TESTBENCH SUMMARY");
    $display("==============================================");
    $display(" Cases  : %0d / %0d passed", cases_total - cases_failed, cases_total);
    $display(" Checks : %0d / %0d passed", checks_total - checks_failed, checks_total);
    if (checks_failed == 0)
      $display(" STATUS : ALL CHECKS PASSED!");
    else
      $display(" STATUS : TEST FAILED WITH %0d MISMATCH(ES)", checks_failed);
    $display("==============================================\n");

    #20 $finish;
  end

endmodule
