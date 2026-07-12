module if_id (
    input wire clk,
    input wire reset,
    
    // Inputs from the IF stage
    input wire [31:0] pc_plus_4_in,
    input wire [31:0] instruction_in,
    
    // Outputs to the ID stage
    output reg [31:0] pc_plus_4_out,
    output reg [31:0] instruction_out
);

    always @(posedge clk) begin
        if (reset) begin
            // Clear the pipeline register on reset (inserts a NOP - No Operation)
            pc_plus_4_out <= 32'b0;
            instruction_out <= 32'b0;
        end else begin
            // Pass the data across the boundary on the clock tick
            pc_plus_4_out <= pc_plus_4_in;
            instruction_out <= instruction_in;
        end
    end

endmodule