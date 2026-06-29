module LIFO(
input clk,reset,
input [7:0] data_in,
input push, pop,
output reg [7:0] data_out,
output empty, full
    );
    
    //register bank and pointers
    reg [7:0] mem_array [15:0];
    reg [4:0] ptr;
    
    //flag status
    assign empty = (ptr == 5'd0);
    assign full = (ptr == 5'd16);
    
    //lifo logic
    always @(posedge clk) begin
        if(reset) begin
            ptr <= 5'b00000;
            data_out <= 8'h00;
        end 
        else begin
            if (push && !full) begin
                mem_array[ptr[3:0]] <= data_in;
                ptr <= ptr +1;
            end 
            if(pop && !empty) begin
                ptr <= ptr - 1;
                data_out <= mem_array[ptr[3:0] -1];
            end
        end        
    end 
       
endmodule