module control_unit (
    input wire [5:0] opcode,      // The top 6 bits of the instruction

    output reg reg_dst,           // 1: RD is destination (R-type), 0: RT is destination (lw)
    output reg alusrc,            // 1: ALU reads immediate, 0: ALU reads register
    output reg mem_to_reg,        // 1: Register gets Memory data, 0: Register gets ALU data
    output reg reg_write,         // 1: Write to register file
    output reg mem_read,          // 1: Read from data memory
    output reg mem_write,         // 1: Write to data memory
    output reg branch,            // 1: This is a branch instruction
    output reg [1:0] alu_op       // 2-bit signal to the ALU Control
);

    always @(*) begin
        // THE LATCH PREVENTER: Set all signals to 0 by default.
        // This ensures every wire has a defined state before the case statement runs.
        reg_dst = 0; alusrc = 0; mem_to_reg = 0; reg_write = 0;
        mem_read = 0; mem_write = 0; branch = 0; alu_op = 2'b00;

        case (opcode)
            6'b000000: begin // R-Type instructions (add, sub, and, or, slt)
                reg_dst = 1;
                reg_write = 1;
                alu_op = 2'b10;
            end
            6'b100011: begin // lw (Load Word)
                alusrc = 1;
                mem_to_reg = 1;
                reg_write = 1;
                mem_read = 1;
                alu_op = 2'b00;
            end
            6'b101011: begin // sw (Store Word)
                alusrc = 1;
                mem_write = 1;
                alu_op = 2'b00;
            end
            6'b000100: begin // beq (Branch on Equal)
                branch = 1;
                alu_op = 2'b01;
            end
        endcase
    end

endmodule