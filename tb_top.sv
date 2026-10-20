// Top-Level Testbench for LIFO Layered Verification Environment
// Connects Clock/Reset, Interface, DUT, and Environment together

`timescale 1ns/1ps

`include "LIFO.v"
`include "lifo_if.sv"
`include "lifo_environment.sv"

module tb_top;

  // -------------------------------------------------------------
  // Clock and Reset Signals
  // -------------------------------------------------------------
  logic clk;
  logic reset;

  // Clock generation: 100MHz (10ns period)
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    clk   = 0;
    reset = 1;
    #20 reset = 0;
  end

  // -------------------------------------------------------------
  // Interface Instantiation
  // -------------------------------------------------------------
  lifo_if intf (
    .clk   (clk),
    .reset (reset)
  );

  // -------------------------------------------------------------
  // DUT Instantiation
  // -------------------------------------------------------------
  LIFO dut (
    .clk       (intf.clk),
    .reset     (intf.reset),
    .data_in   (intf.data_in),
    .push      (intf.push),
    .pop       (intf.pop),
    .data_out  (intf.data_out),
    .peek_data (intf.peek_data),
    .empty     (intf.empty),
    .full      (intf.full)
  );

  // -------------------------------------------------------------
  // Environment Instance & Test Execution
  // -------------------------------------------------------------
  lifo_environment env;

  initial begin
    // Waveform dump for GTKWave / visual debugging
    $dumpfile("testbench.vcd");
    $dumpvars(0, tb_top);

    // Instantiate Environment and pass virtual interface handle
    env = new(intf);

    // Configure test parameters (number of transactions to verify)
    env.agt.gen.repeat_count = 40;

    // Run the full verification flow (pre_test -> test -> post_test)
    env.run();
  end

endmodule : tb_top
