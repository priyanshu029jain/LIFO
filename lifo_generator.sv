// SystemVerilog Generator Class for LIFO Verification Environment
// Creates randomized transaction objects and delivers them to the Driver via Mailbox

`ifndef LIFO_GENERATOR_SV
`define LIFO_GENERATOR_SV

`include "lifo_transaction.sv"

class lifo_generator;

  // -------------------------------------------------------------
  // Class Members
  // -------------------------------------------------------------
  // Transaction handle
  lifo_transaction tr;

  // Mailbox to transmit transactions to the Driver
  mailbox #(lifo_transaction) gen2drv;

  // Handshake event: signaled by Driver when it finishes processing a transaction
  event drv_done;

  // Completion event: signaled when all transactions have been generated
  event ended;

  // Total count of transactions to generate
  int repeat_count;

  // -------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------
  function new(mailbox #(lifo_transaction) gen2drv, event drv_done);
    this.gen2drv      = gen2drv;
    this.drv_done     = drv_done;
    this.repeat_count = 10;
  endfunction

  // -------------------------------------------------------------
  // Main Task
  // Generates 'repeat_count' randomized transactions
  // -------------------------------------------------------------
  task main();
    for (int i = 0; i < repeat_count; i++) begin
      tr = new();
      if (!tr.randomize()) begin
        $fatal(1, "[GEN] @%0t | Transaction randomization failed!", $time);
      end

      // Deep copy to prevent race conditions
      begin
        lifo_transaction tr_copy;
        tr_copy = new();
        tr.copy_to(tr_copy);
        gen2drv.put(tr_copy);
      end

      tr.display("GEN");

      // Wait for driver handshake before generating the next transaction
      @(drv_done);
    end

    // Trigger completion event
    -> ended;
  endtask

endclass : lifo_generator

`endif
