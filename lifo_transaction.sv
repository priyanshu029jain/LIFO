// SystemVerilog Transaction Class for LIFO Verification Environment
// Represents the transaction packet transferred between:
// - Generator -> Driver    (Stimulus: push, pop, data_in)
// - Monitor   -> Scoreboard (Response: data_out, peek_data, empty, full)

`ifndef LIFO_TRANSACTION_SV
`define LIFO_TRANSACTION_SV

class lifo_transaction;

  // -------------------------------------------------------------
  // Stimulus Fields (Inputs to DUT)
  // -------------------------------------------------------------
  rand bit [7:0] data_in;
  rand bit       push;
  rand bit       pop;

  // -------------------------------------------------------------
  // Response Fields (Sampled from DUT by Monitor)
  // -------------------------------------------------------------
  bit [7:0]      data_out;
  bit [7:0]      peek_data;
  bit            empty;
  bit            full;

  // -------------------------------------------------------------
  // Constructor
  // -------------------------------------------------------------
  function new();
    data_in   = 8'h00;
    push      = 1'b0;
    pop       = 1'b0;
    data_out  = 8'h00;
    peek_data = 8'h00;
    empty     = 1'b1;
    full      = 1'b0;
  endfunction

  // -------------------------------------------------------------
  // Randomization Method
  // Provides weighted random stimulus generation:
  // - 40% Push
  // - 40% Pop
  // - 10% Simultaneous Push & Pop
  // - 10% Idle
  // -------------------------------------------------------------
  function int randomize();
    int op;
    data_in = $urandom_range(0, 255);
    op = $urandom_range(0, 9);
    case (op)
      0, 1, 2, 3: begin // Push only
        push = 1'b1;
        pop  = 1'b0;
      end
      4, 5, 6, 7: begin // Pop only
        push = 1'b0;
        pop  = 1'b1;
      end
      8: begin          // Push & Pop simultaneous
        push = 1'b1;
        pop  = 1'b1;
      end
      default: begin    // Idle / No-op
        push = 1'b0;
        pop  = 1'b0;
      end
    endcase
    return 1;
  endfunction

  // -------------------------------------------------------------
  // Copy / Clone Method
  // Copies transaction values to a destination transaction object
  // -------------------------------------------------------------
  function void copy_to(lifo_transaction to);
    if (to != null) begin
      to.data_in   = data_in;
      to.push      = push;
      to.pop       = pop;
      to.data_out  = data_out;
      to.peek_data = peek_data;
      to.empty     = empty;
      to.full      = full;
    end
  endfunction

  // -------------------------------------------------------------
  // Display Method
  // -------------------------------------------------------------
  function void display(string tag = "TRANSACTION");
    $display("[%s] @%0t | push=%b pop=%b data_in=0x%02h | data_out=0x%02h peek=0x%02h | empty=%b full=%b",
             tag, $time, push, pop, data_in, data_out, peek_data, empty, full);
  endfunction

endclass : lifo_transaction

`endif
