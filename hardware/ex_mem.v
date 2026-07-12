module ex_mem (
    input wire clk,
    input wire reset,

    // --- Control Signals IN ---
    // WB
    input wire reg_write_in, mem_to_reg_in,
    // MEM
    input wire mem_read_in, mem_write_in, branch_in,

    // --- Data IN ---
    input wire [31:0] branch_target_in, // Calculated PC+4 + (Imm<<2)
    input wire alu_zero_in,             // 1-bit flag from ALU
    input wire [31:0] alu_result_in,
    input wire [31:0] read_data2_in,    // Data to be written for 'sw'
    
    // --- Register Addresses IN ---
    input wire [4:0] dest_reg_in,       // The final chosen destination register

    // ==========================================

    // --- Control Signals OUT ---
    output reg reg_write_out, mem_to_reg_out,
    output reg mem_read_out, mem_write_out, branch_out,

    // --- Data OUT ---
    output reg [31:0] branch_target_out,
    output reg alu_zero_out,
    output reg [31:0] alu_result_out,
    output reg [31:0] read_data2_out,
    
    // --- Register Addresses OUT ---
    output reg [4:0] dest_reg_out
);

    always @(posedge clk) begin
        if (reset) begin
            reg_write_out <= 0; mem_to_reg_out <= 0;
            mem_read_out <= 0; mem_write_out <= 0; branch_out <= 0;
            branch_target_out <= 32'b0; alu_zero_out <= 0;
            alu_result_out <= 32'b0; read_data2_out <= 32'b0;
            dest_reg_out <= 5'b0;
        end else begin
            reg_write_out <= reg_write_in; mem_to_reg_out <= mem_to_reg_in;
            mem_read_out <= mem_read_in; mem_write_out <= mem_write_in; branch_out <= branch_in;
            branch_target_out <= branch_target_in; alu_zero_out <= alu_zero_in;
            alu_result_out <= alu_result_in; read_data2_out <= read_data2_in;
            dest_reg_out <= dest_reg_in;
        end
    end

endmodule