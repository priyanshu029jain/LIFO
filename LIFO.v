module LIFO(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire push,
    input wire pop,
    output reg [7:0] data_out,
    output wire [7:0] peek_data,
    output wire empty,
    output wire full
  );

  //register bank and pointers
  reg [7:0] mem_array [15:0];
  reg [4:0] ptr;

  //flag status
  assign empty = (ptr == 5'h00);
  assign full = (ptr == 5'h10);
  assign peek_data =  (!empty) ? mem_array[ptr[3:0] - 1'b1] : 8'h00;

  //lifo logic
  always @(posedge clk)
  begin
    if(reset)
    begin
      ptr <= 5'b00000;
      data_out <= 8'h00;
    end

    else
    begin
      case ({push, pop})
        2'b01 :
        begin: pop_only
          if(!empty)
          begin
            ptr <= ptr - 1'b1;
            data_out <= mem_array[ptr[3:0] - 1'b1];
          end
        end

        2'b10 :
        begin : push_only
          if(!full)
          begin
            mem_array[ptr[3:0]] <= data_in;
            ptr <= ptr + 1'b1;
          end
        end

        2'b11 :
        begin
          if(!empty && !full)
          begin
            //overwrite the top element
            mem_array[ptr[3:0] - 1'b1] <= data_in;
            //read it out simultaneously
            data_out <= mem_array[ptr[3:0] - 1'b1];
          end

          else if(empty)
          begin
            data_out <= data_in;
          end
        end

      endcase
    end
  end

`ifdef FORMAL
  // Past valid register
  reg f_past_valid = 0;
  always @(posedge clk)
    f_past_valid <= 1'b1;

  // Power-on reset assumption
  initial assume(reset);

  // Assertions
  always @(posedge clk) begin
    if (!f_past_valid) begin
      // Step 0: Initial state before first clock edge
    end else if ($past(reset)) begin
      // Post-reset state
      assert (ptr == 5'd0);
      assert (empty == 1'b1);
      assert (full == 1'b0);
      assert (data_out == 8'h00);
      assert (peek_data == 8'h00);
    end else begin
      // Invariant bounds and flag definitions
      assert (ptr <= 5'd16);
      assert (empty == (ptr == 5'd0));
      assert (full  == (ptr == 5'd16));
      assert (!(empty && full));

      if (empty)
        assert (peek_data == 8'h00);

      // Push operation
      if ($past(push) && !$past(pop) && !$past(full))
        assert (ptr == $past(ptr) + 1'b1);

      // Pop operation
      if ($past(pop) && !$past(push) && !$past(empty))
        assert (ptr == $past(ptr) - 1'b1);

      // Overflow protection
      if ($past(push) && !$past(pop) && $past(full))
        assert (ptr == 5'd16);

      // Underflow protection
      if ($past(pop) && !$past(push) && $past(empty))
        assert (ptr == 5'd0);

      // Simultaneous push & pop
      if ($past(push) && $past(pop) && !$past(empty) && !$past(full))
        assert (ptr == $past(ptr));
    end
  end

  // Cover properties
  always @(posedge clk) begin
    if (f_past_valid && !reset && !$past(reset)) begin
      cover (full);
      cover (empty && $past(!empty));
      cover (push && pop);
    end
  end
`endif

endmodule

