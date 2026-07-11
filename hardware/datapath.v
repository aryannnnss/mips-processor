module datapath (
    input wire clk,
    input wire reset
);

    // --- 1. Wires (Physical copper traces between chips) ---
    wire [31:0] pc_current, pc_next, pc_plus_4;
    wire [31:0] instruction;
    
    // Control Signals
    wire reg_dst, alusrc, mem_to_reg, reg_write, mem_read, mem_write, branch;
    wire [1:0] alu_op;
    wire alu_zero;
    
    // Register File Wires
    wire [4:0] write_reg_addr;
    wire [31:0] write_data, read_data1, read_data2;
    
    // ALU and Memory Wires
    wire [31:0] sign_ext_imm;
    wire [31:0] alu_input2;
    wire [31:0] alu_result;
    wire [31:0] mem_read_data;
    
    // Branching Wires
    wire [31:0] branch_target;
    wire branch_taken;

    // --- 2. Instruction Fetch (IF) ---
    pc my_pc (
        .clk(clk),
        .reset(reset),
        .next_pc(pc_next),
        .current_pc(pc_current)
    );

    instruction_memory my_imem (
        .pc_address(pc_current),
        .instruction(instruction)
    );

    assign pc_plus_4 = pc_current + 4; // PC always increments by 4 bytes

    // --- 3. Instruction Decode (ID) & Control ---
    control_unit my_control (
        .opcode(instruction[31:26]),
        .reg_dst(reg_dst),
        .alusrc(alusrc),
        .mem_to_reg(mem_to_reg),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .branch(branch),
        .alu_op(alu_op)
    );

    // MUX: Destination Register (RD for R-type, RT for lw)
    assign write_reg_addr = (reg_dst) ? instruction[15:11] : instruction[20:16];

    register_file my_regfile (
        .clk(clk),
        .reg_write_en(reg_write),
        .read_reg1(instruction[25:21]),
        .read_reg2(instruction[20:16]),
        .write_reg(write_reg_addr),
        .write_data(write_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    sign_extend my_sign_ext (
        .in(instruction[15:0]),
        .out(sign_ext_imm)
    );

    // --- 4. Execute (EX) ---
    // MUX: ALU Input 2 (Register data vs Immediate value)
    assign alu_input2 = (alusrc) ? sign_ext_imm : read_data2;

    // ALU Control Decoder: Translates 2-bit control + funct code into 3-bit ALU operation
    wire [2:0] alu_ctrl_final;
    assign alu_ctrl_final = (alu_op == 2'b00) ? 3'b010 :                       // lw/sw -> ADD
                            (alu_op == 2'b01) ? 3'b110 :                       // beq -> SUB
                            (instruction[5:0] == 6'b100000) ? 3'b010 :         // add
                            (instruction[5:0] == 6'b100010) ? 3'b110 :         // sub
                            (instruction[5:0] == 6'b100100) ? 3'b000 :         // and
                            (instruction[5:0] == 6'b100101) ? 3'b001 :         // or
                            (instruction[5:0] == 6'b101010) ? 3'b111 : 3'b000; // slt

    alu my_alu (
        .a(read_data1),
        .b(alu_input2),
        .alu_control(alu_ctrl_final),
        .result(alu_result),
        .zero(alu_zero)
    );

    // Branch Logic: Shift offset left by 2 (multiply by 4) and add to PC+4
    assign branch_target = pc_plus_4 + (sign_ext_imm << 2);
    assign branch_taken = branch & alu_zero;

    // MUX: Next PC Address (Branch Target vs PC+4)
    assign pc_next = (branch_taken) ? branch_target : pc_plus_4;

    // --- 5. Memory (MEM) ---
    data_memory my_dmem (
        .clk(clk),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .address(alu_result),
        .write_data(read_data2),
        .read_data(mem_read_data)
    );

    // --- 6. Write Back (WB) ---
    // MUX: Data going back to Register File (Memory Data vs ALU Math Result)
    assign write_data = (mem_to_reg) ? mem_read_data : alu_result;

endmodule