module mem_wb (
    input wire clk,
    input wire reset,

    // --- Control Signals IN ---
    // WB
    input wire reg_write_in, mem_to_reg_in,

    // --- Data IN ---
    input wire [31:0] mem_read_data_in,
    input wire [31:0] alu_result_in,
    
    // --- Register Addresses IN ---
    input wire [4:0] dest_reg_in,

    // ==========================================

    // --- Control Signals OUT ---
    output reg reg_write_out, mem_to_reg_out,

    // --- Data OUT ---
    output reg [31:0] mem_read_data_out,
    output reg [31:0] alu_result_out,
    
    // --- Register Addresses OUT ---
    output reg [4:0] dest_reg_out
);

    always @(posedge clk) begin
        if (reset) begin
            reg_write_out <= 0; mem_to_reg_out <= 0;
            mem_read_data_out <= 32'b0; alu_result_out <= 32'b0;
            dest_reg_out <= 5'b0;
        end else begin
            reg_write_out <= reg_write_in; mem_to_reg_out <= mem_to_reg_in;
            mem_read_data_out <= mem_read_data_in; alu_result_out <= alu_result_in;
            dest_reg_out <= dest_reg_in;
        end
    end

endmodule