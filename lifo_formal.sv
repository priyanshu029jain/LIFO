// Top Formal Wrapper binding LIFO DUT and SVA Checkers
`include "LIFO.v"
`include "lifo_sva.sv"

module lifo_formal (
  input wire        clk,
  input wire        reset,
  input wire [7:0]  data_in,
  input wire        push,
  input wire        pop,
  output wire [7:0] data_out,
  output wire [7:0] peek_data,
  output wire       empty,
  output wire       full
);

  // DUT instance
  LIFO dut (
    .clk       (clk),
    .reset     (reset),
    .data_in   (data_in),
    .push      (push),
    .pop       (pop),
    .data_out  (data_out),
    .peek_data (peek_data),
    .empty     (empty),
    .full      (full)
  );

  // SVA formal checker instance
  lifo_sva sva_inst (
    .clk       (clk),
    .reset     (reset),
    .data_in   (data_in),
    .push      (push),
    .pop       (pop),
    .data_out  (data_out),
    .peek_data (peek_data),
    .empty     (empty),
    .full      (full),
    .ptr       (dut.ptr)
  );

endmodule
