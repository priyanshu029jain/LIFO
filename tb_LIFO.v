`include "LIFO.v"
`timescale 1ns/1ps

module tb_LIFO;

  // Testbench signals
  reg clk, reset;
  reg [7:0] data_in;
  reg push, pop;
  wire [7:0] data_out;
  wire empty, full;

  // Instantiate DUT
  LIFO uut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .push(push),
    .pop(pop),
    .data_out(data_out),
    .empty(empty),
    .full(full)
  );

  // Clock generation
  always #5 clk = ~clk;

  integer i;

  initial begin
    // VCD dump
    $dumpfile("testbench.vcd");
    $dumpvars(0, tb_LIFO);

    // Monitor signals
    $monitor("T=%0t | push=%b pop=%b data_in=%h | data_out=%h | empty=%b full=%b ptr=%0d",
              $time, push, pop, data_in, data_out, empty, full, uut.ptr);

    // Initialize
    clk = 0;
    reset = 1;
    push = 0;
    pop = 0;
    data_in = 0;

    // Reset
    #12 reset = 0;

    // --- Test Case 1: Push a few values ---
    for (i = 0; i < 4; i = i + 1) begin
      #10 push = 1; data_in = i + 8'hA0;
      #10 push = 0;
    end

    // --- Test Case 2: Pop values back ---
    for (i = 0; i < 4; i = i + 1) begin
      #10 pop = 1;
      #10 pop = 0;
    end

    // --- Test Case 3: Underflow check ---
    #10 pop = 1; // should not pop because empty=1
    #10 pop = 0;

    // --- Test Case 4: Fill stack completely ---
    for (i = 0; i < 16; i = i + 1) begin
      #10 push = 1; data_in = i + 8'h10;
      #10 push = 0;
    end
    #10; // expect full=1

    // --- Test Case 5: Overflow check ---
    #10 push = 1; data_in = 8'hFF; // should not push because full=1
    #10 push = 0;

    // --- Test Case 6: Pop all values back ---
    for (i = 0; i < 16; i = i + 1) begin
      #10 pop = 1;
      #10 pop = 0;
    end
    #10; // expect empty=1

    // Finish
    #50 $finish;
  end

endmodule
