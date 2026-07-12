module forwarding_unit (
    input wire [4:0] ex_rs,         // Source register 1 in EX stage
    input wire [4:0] ex_rt,         // Source register 2 in EX stage
    
    input wire mem_reg_write,       // Is MEM stage writing to a register?
    input wire [4:0] mem_dest_reg,  // Which register is MEM writing to?
    
    input wire wb_reg_write,        // Is WB stage writing to a register?
    input wire [4:0] wb_dest_reg,   // Which register is WB writing to?

    output reg [1:0] forward_a,     // MUX control for ALU input 1
    output reg [1:0] forward_b      // MUX control for ALU input 2
);

    always @(*) begin
        // Default: No forwarding (use the standard data from the ID/EX register)
        forward_a = 2'b00;
        forward_b = 2'b00;

        // --- 1. EX Hazard (Data is right behind us in the MEM stage) ---
        // If MEM is writing to a register, and it's NOT $zero, and it matches our source register:
        if (mem_reg_write && (mem_dest_reg != 5'b0) && (mem_dest_reg == ex_rs)) begin
            forward_a = 2'b10;
        end
        if (mem_reg_write && (mem_dest_reg != 5'b0) && (mem_dest_reg == ex_rt)) begin
            forward_b = 2'b10;
        end

        // --- 2. MEM Hazard (Data is two steps behind us in the WB stage) ---
        // Note: We only forward from WB if the MEM stage isn't ALREADY forwarding a newer value!
        if (wb_reg_write && (wb_dest_reg != 5'b0) && (wb_dest_reg == ex_rs) && 
            !(mem_reg_write && (mem_dest_reg != 5'b0) && (mem_dest_reg == ex_rs))) begin
            forward_a = 2'b01;
        end
        if (wb_reg_write && (wb_dest_reg != 5'b0) && (wb_dest_reg == ex_rt) && 
            !(mem_reg_write && (mem_dest_reg != 5'b0) && (mem_dest_reg == ex_rt))) begin
            forward_b = 2'b01;
        end
    end

endmodule