// SystemVerilog Agent Class for LIFO Verification Environment
// Encapsulates Generator, Driver, and Monitor components into a unified verification block

`ifndef LIFO_AGENT_SV
`define LIFO_AGENT_SV

`include "lifo_generator.sv"
`include "lifo_driver.sv"
`include "lifo_monitor.sv"

class lifo_agent;

  // -------------------------------------------------------------
  // Class Members / Sub-Components
  // -------------------------------------------------------------
  lifo_generator gen;
  lifo_driver    drv;
  lifo_monitor   mon;

  // Internal mailbox between Generator and Driver
  mailbox gen2drv;

  // Internal handshake event between Driver and Generator
  event drv_done;

  // Virtual interface to DUT
  virtual lifo_if vif;

  // -------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------
  function new(virtual lifo_if vif, mailbox mon2scb);
    this.vif     = vif;
    this.gen2drv = new();

    // Instantiate sub-components
    gen = new(gen2drv, drv_done);
    drv = new(vif, gen2drv, drv_done);
    mon = new(vif, mon2scb);
  endfunction

  // -------------------------------------------------------------
  // Pre-test Task: Executes reset phase before starting stimulus
  // -------------------------------------------------------------
  task pre_test();
    drv.reset();
  endtask

  // -------------------------------------------------------------
  // Test Phase Task: Runs Generator, Driver, and Monitor concurrently
  // -------------------------------------------------------------
  task test();
    fork
      drv.main();
      mon.main();
      gen.main();
    join_any
  endtask

  // -------------------------------------------------------------
  // Main Agent Execution Task
  // -------------------------------------------------------------
  task main();
    pre_test();
    test();
  endtask

endclass : lifo_agent

`endif
