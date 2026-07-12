module id_ex (
    input wire clk,
    input wire reset,

    // --- Control Signals IN (From Control Unit) ---
    // Write-Back (WB) Signals
    input wire reg_write_in, mem_to_reg_in,
    // Memory (MEM) Signals
    input wire mem_read_in, mem_write_in, branch_in,
    // Execute (EX) Signals
    input wire alusrc_in, reg_dst_in,
    input wire [1:0] alu_op_in,

    // --- Data IN (From Register File & Sign Extender) ---
    input wire [31:0] pc_plus_4_in,
    input wire [31:0] read_data1_in,
    input wire [31:0] read_data2_in,
    input wire [31:0] sign_ext_imm_in,

    // --- Register Addresses IN ---
    // We pass rs and rt for Hazard Detection later!
    input wire [4:0] rs_in, rt_in, rd_in,

    // ==========================================

    // --- Control Signals OUT (To EX, MEM, WB Stages) ---
    output reg reg_write_out, mem_to_reg_out,
    output reg mem_read_out, mem_write_out, branch_out,
    output reg alusrc_out, reg_dst_out,
    output reg [1:0] alu_op_out,

    // --- Data OUT ---
    output reg [31:0] pc_plus_4_out,
    output reg [31:0] read_data1_out,
    output reg [31:0] read_data2_out,
    output reg [31:0] sign_ext_imm_out,

    // --- Register Addresses OUT ---
    output reg [4:0] rs_out, rt_out, rd_out
);

    always @(posedge clk) begin
        if (reset) begin
            // Flush the pipeline (insert a NOP)
            reg_write_out <= 0; mem_to_reg_out <= 0;
            mem_read_out <= 0; mem_write_out <= 0; branch_out <= 0;
            alusrc_out <= 0; reg_dst_out <= 0; alu_op_out <= 2'b00;

            pc_plus_4_out <= 32'b0; read_data1_out <= 32'b0;
            read_data2_out <= 32'b0; sign_ext_imm_out <= 32'b0;
            rs_out <= 5'b0; rt_out <= 5'b0; rd_out <= 5'b0;
        end else begin
            // Pass everything forward on the clock edge
            reg_write_out <= reg_write_in; mem_to_reg_out <= mem_to_reg_in;
            mem_read_out <= mem_read_in; mem_write_out <= mem_write_in; branch_out <= branch_in;
            alusrc_out <= alusrc_in; reg_dst_out <= reg_dst_in; alu_op_out <= alu_op_in;

            pc_plus_4_out <= pc_plus_4_in; read_data1_out <= read_data1_in;
            read_data2_out <= read_data2_in; sign_ext_imm_out <= sign_ext_imm_in;
            rs_out <= rs_in; rt_out <= rt_in; rd_out <= rd_in;
        end
    end

endmodule