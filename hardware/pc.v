module pc (
    input wire clk,
    input wire reset,
    input wire [31:0] next_pc,      // The address we WANT to go to next
    output reg [31:0] current_pc    // The address we are CURRENTLY at
);

    // This block triggers ONLY on the positive edge of the clock
    always @(posedge clk) begin
        if (reset) begin
            // Synchronous Reset: If the reset button is pushed, go to address 0
            current_pc <= 32'b0;
        end else begin
            // Normal Operation: Capture the next address and output it
            current_pc <= next_pc;
        end
    end

endmodule