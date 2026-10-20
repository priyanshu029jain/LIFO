// SystemVerilog Scoreboard Class for LIFO Verification Environment
// Implements a golden reference model to verify DUT functional correctness

`ifndef LIFO_SCOREBOARD_SV
`define LIFO_SCOREBOARD_SV

`include "lifo_transaction.sv"

class lifo_scoreboard;

  // -------------------------------------------------------------
  // Class Members
  // -------------------------------------------------------------
  // Mailbox to receive transactions from Monitor
  mailbox #(lifo_transaction) mon2scb;

  // Golden reference model storage (Depth = 16)
  bit [7:0] ref_stack [15:0];
  int       ref_ptr;

  // Verification statistics counters
  int pass_count;
  int fail_count;
  int total_transactions;

  // -------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------
  function new(mailbox #(lifo_transaction) mon2scb);
    this.mon2scb            = mon2scb;
    this.ref_ptr            = 0;
    this.pass_count         = 0;
    this.fail_count         = 0;
    this.total_transactions = 0;
  endfunction

  // -------------------------------------------------------------
  // Main Scoreboard Task
  // -------------------------------------------------------------
  task main();
    lifo_transaction tr;
    bit [7:0] expected_data_out;
    bit [7:0] expected_peek;
    bit       expected_empty;
    bit       expected_full;

    forever begin
      mon2scb.get(tr);
      total_transactions++;

      // Compute golden model expectations based on current state & stimulus
      case ({tr.push, tr.pop})

        // ---------------------------------------------------------
        // Case 1: POP ONLY
        // ---------------------------------------------------------
        2'b01: begin
          if (ref_ptr > 0) begin
            ref_ptr--;
            expected_data_out = ref_stack[ref_ptr];

            // Verify data_out
            if (tr.data_out === expected_data_out) begin
              $display("[SCB] [PASS] @%0t | POP Match: data_out=0x%02h", $time, tr.data_out);
              pass_count++;
            end else begin
              $error("[SCB] [FAIL] @%0t | POP Mismatch! Exp=0x%02h, Got=0x%02h",
                     $time, expected_data_out, tr.data_out);
              fail_count++;
            end
          end else begin
            // Underflow attempt
            $display("[SCB] [INFO] @%0t | POP attempted on EMPTY stack (Ignored as expected)", $time);
          end
        end

        // ---------------------------------------------------------
        // Case 2: PUSH ONLY
        // ---------------------------------------------------------
        2'b10: begin
          if (ref_ptr < 16) begin
            ref_stack[ref_ptr] = tr.data_in;
            ref_ptr++;
            $display("[SCB] [INFO] @%0t | PUSH: data_in=0x%02h | Stack Depth=%0d",
                     $time, tr.data_in, ref_ptr);
            pass_count++;
          end else begin
            // Overflow attempt
            $display("[SCB] [INFO] @%0t | PUSH attempted on FULL stack (Ignored as expected)", $time);
          end
        end

        // ---------------------------------------------------------
        // Case 3: SIMULTANEOUS PUSH & POP
        // ---------------------------------------------------------
        2'b11: begin
          if (ref_ptr > 0) begin
            // Overwrites the top element; depth remains unchanged
            ref_stack[ref_ptr - 1] = tr.data_in;
            $display("[SCB] [INFO] @%0t | PUSH+POP Overwrite Top: data_in=0x%02h", $time, tr.data_in);
            pass_count++;
          end else begin
            $display("[SCB] [INFO] @%0t | PUSH+POP on empty stack: Pass-through", $time);
          end
        end

        default: begin
          // IDLE (no-op)
        end

      endcase

      // -----------------------------------------------------------
      // Verify Status Flags and Peek Output
      // -----------------------------------------------------------
      expected_empty = (ref_ptr == 0);
      expected_full  = (ref_ptr == 16);
      expected_peek  = (ref_ptr > 0) ? ref_stack[ref_ptr - 1] : 8'h00;

      // Check Empty Flag
      if (tr.empty === expected_empty) begin
        pass_count++;
      end else begin
        $error("[SCB] [FAIL] @%0t | EMPTY flag mismatch! Exp=%b, Got=%b",
               $time, expected_empty, tr.empty);
        fail_count++;
      end

      // Check Full Flag
      if (tr.full === expected_full) begin
        pass_count++;
      end else begin
        $error("[SCB] [FAIL] @%0t | FULL flag mismatch! Exp=%b, Got=%b",
               $time, expected_full, tr.full);
        fail_count++;
      end

      // Check Peek Data
      if (tr.peek_data === expected_peek) begin
        pass_count++;
      end else begin
        $error("[SCB] [FAIL] @%0t | PEEK_DATA mismatch! Exp=0x%02h, Got=0x%02h",
               $time, expected_peek, tr.peek_data);
        fail_count++;
      end

    end
  endtask

  // -------------------------------------------------------------
  // Summary Report Method
  // -------------------------------------------------------------
  function void report();
    $display("\n==============================================");
    $display("           SCOREBOARD FINAL REPORT            ");
    $display("==============================================");
    $display(" Total Transactions Checked: %0d", total_transactions);
    $display(" Checks Passed             : %0d", pass_count);
    $display(" Checks Failed             : %0d", fail_count);
    if (fail_count == 0) begin
      $display(" STATUS                    : ALL CHECKS PASSED!");
    end else begin
      $display(" STATUS                    : TEST FAILED WITH %0d ERRORS!", fail_count);
    end
    $display("==============================================\n");
  endfunction

endclass : lifo_scoreboard

`endif
