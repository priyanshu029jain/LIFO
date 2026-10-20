// SystemVerilog Environment Class for LIFO Verification
// Encapsulates Agent and Scoreboard, routing verification mailboxes and managing execution phases

`ifndef LIFO_ENVIRONMENT_SV
`define LIFO_ENVIRONMENT_SV

`include "lifo_agent.sv"
`include "lifo_scoreboard.sv"

class lifo_environment;

  // -------------------------------------------------------------
  // Class Members
  // -------------------------------------------------------------
  // Verification Agent (Generator + Driver + Monitor)
  lifo_agent      agt;

  // Scoreboard (Golden model + Result verification)
  lifo_scoreboard scb;

  // Mailbox routing transactions from Monitor to Scoreboard
  mailbox mon2scb;

  // Virtual interface handle
  virtual lifo_if vif;

  // -------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------
  function new(virtual lifo_if vif);
    this.vif     = vif;
    this.mon2scb = new();

    // Instantiate Agent and Scoreboard
    agt = new(vif, mon2scb);
    scb = new(mon2scb);
  endfunction

  // -------------------------------------------------------------
  // Pre-Test Phase: Apply reset and initialize signals
  // -------------------------------------------------------------
  task pre_test();
    $display("\n==============================================");
    $display("       PHASE: PRE-TEST (APPLYING RESET)       ");
    $display("==============================================");
    agt.pre_test();
  endtask

  // -------------------------------------------------------------
  // Test Phase: Run Agent and Scoreboard concurrently
  // -------------------------------------------------------------
  task test();
    $display("\n==============================================");
    $display("         PHASE: TEST (DRIVING TRAFFIC)        ");
    $display("==============================================");
    fork
      agt.test();
      scb.main();
    join_any
  endtask

  // -------------------------------------------------------------
  // Post-Test Phase: Drain in-flight traffic and generate report
  // -------------------------------------------------------------
  task post_test();
    $display("\n==============================================");
    $display("         PHASE: POST-TEST (DRAIN & CHECK)     ");
    $display("==============================================");

    // Wait until driver has driven all generated transactions
    wait(agt.drv.no_transactions >= agt.gen.repeat_count);

    // Drain time to allow monitor and scoreboard to finish processing
    #100;

    // Display final scoreboard pass/fail summary
    scb.report();
  endtask

  // -------------------------------------------------------------
  // Run Task: Master execution flow across all phases
  // -------------------------------------------------------------
  task run();
    pre_test();
    test();
    post_test();
    $finish;
  endtask

endclass : lifo_environment

`endif
