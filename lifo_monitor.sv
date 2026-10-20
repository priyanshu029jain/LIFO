// SystemVerilog Monitor Class for LIFO Verification Environment
// Passively monitors DUT interface pins and sends sampled transactions to Scoreboard

`ifndef LIFO_MONITOR_SV
`define LIFO_MONITOR_SV

`include "lifo_transaction.sv"
`include "lifo_if.sv"

class lifo_monitor;

  // -------------------------------------------------------------
  // Class Members
  // -------------------------------------------------------------
  // Count of monitored transactions
  int no_transactions;

  // Virtual interface to passively observe DUT pin activity
  virtual lifo_if vif;

  // Mailbox to forward sampled transactions to the Scoreboard
  mailbox #(lifo_transaction) mon2scb;

  // -------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------
  function new(virtual lifo_if vif, mailbox #(lifo_transaction) mon2scb);
    this.vif             = vif;
    this.mon2scb         = mon2scb;
    this.no_transactions = 0;
  endfunction

  // -------------------------------------------------------------
  // Main Monitor Task
  // -------------------------------------------------------------
  task main();
    lifo_transaction tr;

    forever begin
      // Sample synchronous activity at clock edge
      @(posedge vif.clk);

      // Only capture when reset is inactive and an operation is driven
      if (!vif.reset && (vif.push || vif.pop)) begin
        tr = new();

        // Sample input stimulus
        tr.push    = vif.push;
        tr.pop     = vif.pop;
        tr.data_in = vif.data_in;

        // Small delay to allow synchronous outputs and combinational flags to settle
        #1;

        // Sample DUT response
        tr.data_out  = vif.data_out;
        tr.peek_data = vif.peek_data;
        tr.empty     = vif.empty;
        tr.full      = vif.full;

        // Send a deep copy to Scoreboard via mailbox
        begin
          lifo_transaction tr_copy;
          tr_copy = new();
          tr.copy_to(tr_copy);
          mon2scb.put(tr_copy);
        end

        tr.display("MON");
        no_transactions++;
      end
    end
  endtask

endclass : lifo_monitor

`endif
