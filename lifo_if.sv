// SystemVerilog Interface for LIFO Verification Environment
// Follows standard layered testbench architecture (Driver, Monitor, DUT modports)

`ifndef LIFO_IF_SV
`define LIFO_IF_SV

interface lifo_if #(parameter int DATA_WIDTH = 8) (
  input logic clk,
  input logic reset
);

  // Data and control signals
  logic [DATA_WIDTH-1:0] data_in;
  logic                  push;
  logic                  pop;
  logic [DATA_WIDTH-1:0] data_out;
  logic [DATA_WIDTH-1:0] peek_data;
  logic                  empty;
  logic                  full;

  // -------------------------------------------------------------
  // Driver Modport: Drives stimulus (push, pop, data_in) into DUT
  // -------------------------------------------------------------
  modport DRIVER (
    input  clk,
    input  reset,
    output data_in,
    output push,
    output pop,
    input  data_out,
    input  peek_data,
    input  empty,
    input  full
  );

  // -------------------------------------------------------------
  // Monitor Modport: Passively samples all interface activity
  // -------------------------------------------------------------
  modport MONITOR (
    input clk,
    input reset,
    input data_in,
    input push,
    input pop,
    input data_out,
    input peek_data,
    input empty,
    input full
  );

  // -------------------------------------------------------------
  // DUT Modport: Direct pin-level mapping to LIFO RTL module
  // -------------------------------------------------------------
  modport DUT (
    input  clk,
    input  reset,
    input  data_in,
    input  push,
    input  pop,
    output data_out,
    output peek_data,
    output empty,
    output full
  );

endinterface : lifo_if

`endif
