// SystemVerilog Driver Class for LIFO Verification Environment
// Consumes transactions from the Generator and drives them onto the DUT interface pins

`ifndef LIFO_DRIVER_SV
`define LIFO_DRIVER_SV

`include "lifo_transaction.sv"
`include "lifo_if.sv"

class lifo_driver;

  // -------------------------------------------------------------
  // Class Members
  // -------------------------------------------------------------
  // Count of driven transactions
  int no_transactions;

  // Virtual interface connected to the DUT
  virtual lifo_if vif;

  // Mailbox to receive transactions from the Generator
  mailbox gen2drv;

  // Handshake event to signal Generator after completing a drive cycle
  event drv_done;

  // -------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------
  function new(virtual lifo_if vif, mailbox gen2drv, event drv_done);
    this.vif             = vif;
    this.gen2drv         = gen2drv;
    this.drv_done        = drv_done;
    this.no_transactions = 0;
  endfunction

  // -------------------------------------------------------------
  // Reset Task: Drives default safe values during reset
  // -------------------------------------------------------------
  task reset();
    wait(vif.reset);
    $display("[DRV] @%0t | Reset asserted. Initializing driver signals...", $time);
    vif.data_in <= 8'h00;
    vif.push    <= 1'b0;
    vif.pop     <= 1'b0;
    wait(!vif.reset);
    $display("[DRV] @%0t | Reset de-asserted. Driver ready.", $time);
  endtask

  // -------------------------------------------------------------
  // Drive Task: Translates transaction into pin-level activity
  // -------------------------------------------------------------
  task drive();
    lifo_transaction tr;

    forever begin
      // Fetch transaction from Generator mailbox
      gen2drv.get(tr);

      // Apply stimulus synchronized with the rising edge of clock
      @(posedge vif.clk);
      vif.data_in <= tr.data_in;
      vif.push    <= tr.push;
      vif.pop     <= tr.pop;

      // Hold for one clock cycle then return control signals to idle
      @(posedge vif.clk);
      vif.push    <= 1'b0;
      vif.pop     <= 1'b0;

      tr.display("DRV");
      no_transactions++;

      // Trigger handshake to let the Generator produce the next transaction
      -> drv_done;
    end
  endtask

  // -------------------------------------------------------------
  // Main Task
  // -------------------------------------------------------------
  task main();
    drive();
  endtask

endclass : lifo_driver

`endif
