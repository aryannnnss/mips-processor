module alu (
    input wire [31:0] a,          // Input 1 (from read_data1)
    input wire [31:0] b,          // Input 2 (from read_data2 or immediate value)
    input wire [2:0] alu_control, // Control signal telling the ALU what to do
    
    output reg [31:0] result,     // The 32-bit answer
    output wire zero              // 1-bit flag: goes HIGH if result is 0
);

    // Combinational logic block: triggers whenever a, b, or alu_control changes
    always @(*) begin
        case (alu_control)
            3'b000: result = a & b;                 // Logical AND
            3'b001: result = a | b;                 // Logical OR
            3'b010: result = a + b;                 // Arithmetic ADD
            3'b110: result = a - b;                 // Arithmetic SUB
            3'b111: result = (a < b) ? 32'b1 : 32'b0; // Set Less Than (SLT)
            default: result = 32'b0;                // Default case to prevent latches
        endcase
    end

    // The zero flag is purely combinational based on the result.
    // If result == 0, this expression evaluates to 1 (True).
    assign zero = (result == 32'b0);

endmodule