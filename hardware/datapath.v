module datapath (
    input wire clk,
    input wire reset
);

    // ========================================================================
    // 1. INSTRUCTION FETCH (IF) STAGE
    // ========================================================================
    wire [31:0] if_pc_current, if_pc_next, if_pc_plus_4, if_instruction;
    wire stall; // The stall signal from our hazard unit
    
    // MUX: If stalling, hold current PC. Else, proceed normally.
    assign if_pc_next = (stall) ? if_pc_current : if_pc_plus_4; 

    pc my_pc (.clk(clk), .reset(reset), .next_pc(if_pc_next), .current_pc(if_pc_current));
    instruction_memory my_imem (.pc_address(if_pc_current), .instruction(if_instruction));
    assign if_pc_plus_4 = if_pc_current + 4;

    // --- IF/ID PIPELINE REGISTER ---
    wire [31:0] id_pc_plus_4, id_instruction;
    
    // MUX: If stalling, feed the ID data back into itself to freeze it
    wire [31:0] stall_safe_pc = (stall) ? id_pc_plus_4 : if_pc_plus_4;
    wire [31:0] stall_safe_inst = (stall) ? id_instruction : if_instruction;

    if_id reg_if_id (
        .clk(clk), .reset(reset),
        .pc_plus_4_in(stall_safe_pc), .instruction_in(stall_safe_inst),
        .pc_plus_4_out(id_pc_plus_4), .instruction_out(id_instruction)
    );

    // ========================================================================
    // 2. INSTRUCTION DECODE (ID) STAGE
    // ========================================================================
    wire id_reg_dst, id_alusrc, id_mem_to_reg, id_reg_write, id_mem_read, id_mem_write, id_branch;
    wire [1:0] id_alu_op;
    wire [31:0] id_read_data1, id_read_data2, id_sign_ext_imm;

    control_unit my_control (
        .opcode(id_instruction[31:26]),
        .reg_dst(id_reg_dst), .alusrc(id_alusrc), .mem_to_reg(id_mem_to_reg),
        .reg_write(id_reg_write), .mem_read(id_mem_read), .mem_write(id_mem_write),
        .branch(id_branch), .alu_op(id_alu_op)
    );

    // Wires coming BACK from the WB stage
    wire wb_reg_write;
    wire [4:0] wb_dest_reg;
    wire [31:0] wb_write_data;

    register_file my_regfile (
        .clk(clk),
        .reg_write_en(wb_reg_write),    
        .read_reg1(id_instruction[25:21]),
        .read_reg2(id_instruction[20:16]),
        .write_reg(wb_dest_reg),        
        .write_data(wb_write_data),     
        .read_data1(id_read_data1),
        .read_data2(id_read_data2)
    );

    sign_extend my_sign_ext (.in(id_instruction[15:0]), .out(id_sign_ext_imm));

    // --- HAZARD DETECTION UNIT ---
    wire ex_mem_read;
    wire [4:0] ex_rt;
    
    hazard_detection_unit my_hazard (
        .id_ex_mem_read(ex_mem_read), 
        .id_ex_rt(ex_rt), 
        .if_id_rs(id_instruction[25:21]), 
        .if_id_rt(id_instruction[20:16]),
        .stall(stall)
    );

    // MUX: If stalling, force all control signals to 0 (creating a NOP Bubble)
    wire safe_reg_write = (stall) ? 1'b0 : id_reg_write;
    wire safe_mem_to_reg = (stall) ? 1'b0 : id_mem_to_reg;
    wire safe_mem_read = (stall) ? 1'b0 : id_mem_read;
    wire safe_mem_write = (stall) ? 1'b0 : id_mem_write;
    wire safe_branch = (stall) ? 1'b0 : id_branch;
    wire safe_alusrc = (stall) ? 1'b0 : id_alusrc;
    wire safe_reg_dst = (stall) ? 1'b0 : id_reg_dst;
    wire [1:0] safe_alu_op = (stall) ? 2'b00 : id_alu_op;

    // --- ID/EX PIPELINE REGISTER ---
    wire ex_reg_write, ex_mem_to_reg, ex_mem_write, ex_branch, ex_alusrc, ex_reg_dst;
    wire [1:0] ex_alu_op;
    wire [31:0] ex_pc_plus_4, ex_read_data1, ex_read_data2, ex_sign_ext_imm;
    wire [4:0] ex_rs, ex_rd;

    id_ex reg_id_ex (
        .clk(clk), .reset(reset),
        // Control IN (Using the Hazard-Safe wires!)
        .reg_write_in(safe_reg_write), .mem_to_reg_in(safe_mem_to_reg),
        .mem_read_in(safe_mem_read), .mem_write_in(safe_mem_write), .branch_in(safe_branch),
        .alusrc_in(safe_alusrc), .reg_dst_in(safe_reg_dst), .alu_op_in(safe_alu_op),
        // Data IN
        .pc_plus_4_in(id_pc_plus_4), .read_data1_in(id_read_data1),
        .read_data2_in(id_read_data2), .sign_ext_imm_in(id_sign_ext_imm),
        // Reg IN
        .rs_in(id_instruction[25:21]), .rt_in(id_instruction[20:16]), .rd_in(id_instruction[15:11]),
        
        // Control OUT
        .reg_write_out(ex_reg_write), .mem_to_reg_out(ex_mem_to_reg),
        .mem_read_out(ex_mem_read), .mem_write_out(ex_mem_write), .branch_out(ex_branch),
        .alusrc_out(ex_alusrc), .reg_dst_out(ex_reg_dst), .alu_op_out(ex_alu_op),
        // Data OUT
        .pc_plus_4_out(ex_pc_plus_4), .read_data1_out(ex_read_data1),
        .read_data2_out(ex_read_data2), .sign_ext_imm_out(ex_sign_ext_imm),
        // Reg OUT
        .rs_out(ex_rs), .rt_out(ex_rt), .rd_out(ex_rd)
    );

    // ========================================================================
    // 3. EXECUTE (EX) STAGE
    // ========================================================================
    wire [1:0] forward_a, forward_b;
    wire [31:0] forwarded_alu_input1, forwarded_alu_input2, ex_alu_input2;
    wire [31:0] ex_alu_result, ex_branch_target;
    wire ex_alu_zero;
    wire [4:0] ex_dest_reg;
    wire [2:0] ex_alu_ctrl_final;
    
    wire mem_reg_write;
    wire [4:0] mem_dest_reg;

    // --- FORWARDING UNIT ---
    forwarding_unit my_forwarding (
        .ex_rs(ex_rs), .ex_rt(ex_rt),
        .mem_reg_write(mem_reg_write), .mem_dest_reg(mem_dest_reg),
        .wb_reg_write(wb_reg_write), .wb_dest_reg(wb_dest_reg),
        .forward_a(forward_a), .forward_b(forward_b)
    );

    // --- 3-to-1 INTERCEPT MUXES ---
    wire [31:0] mem_alu_result;
    assign forwarded_alu_input1 = (forward_a == 2'b10) ? mem_alu_result :
                                  (forward_a == 2'b01) ? wb_write_data :
                                  ex_read_data1;

    assign forwarded_alu_input2 = (forward_b == 2'b10) ? mem_alu_result :
                                  (forward_b == 2'b01) ? wb_write_data :
                                  ex_read_data2;

    assign ex_alu_input2 = (ex_alusrc) ? ex_sign_ext_imm : forwarded_alu_input2;
    assign ex_dest_reg = (ex_reg_dst) ? ex_rd : ex_rt;
    assign ex_branch_target = ex_pc_plus_4 + (ex_sign_ext_imm << 2);

    assign ex_alu_ctrl_final = (ex_alu_op == 2'b00) ? 3'b010 :                       
                               (ex_alu_op == 2'b01) ? 3'b110 :                       
                               (ex_sign_ext_imm[5:0] == 6'b100000) ? 3'b010 :         
                               (ex_sign_ext_imm[5:0] == 6'b100010) ? 3'b110 :         
                               (ex_sign_ext_imm[5:0] == 6'b100100) ? 3'b000 :         
                               (ex_sign_ext_imm[5:0] == 6'b100101) ? 3'b001 :         
                               (ex_sign_ext_imm[5:0] == 6'b101010) ? 3'b111 : 3'b000; 

    alu my_alu (
        .a(forwarded_alu_input1), .b(ex_alu_input2), .alu_control(ex_alu_ctrl_final),
        .result(ex_alu_result), .zero(ex_alu_zero)
    );

    // --- EX/MEM PIPELINE REGISTER ---
    wire mem_mem_to_reg, mem_mem_read, mem_mem_write, mem_branch, mem_alu_zero;
    wire [31:0] mem_branch_target, mem_read_data2;

    ex_mem reg_ex_mem (
        .clk(clk), .reset(reset),
        .reg_write_in(ex_reg_write), .mem_to_reg_in(ex_mem_to_reg),
        .mem_read_in(ex_mem_read), .mem_write_in(ex_mem_write), .branch_in(ex_branch),
        .branch_target_in(ex_branch_target), .alu_zero_in(ex_alu_zero),
        .alu_result_in(ex_alu_result), .read_data2_in(forwarded_alu_input2), 
        .dest_reg_in(ex_dest_reg),
        
        .reg_write_out(mem_reg_write), .mem_to_reg_out(mem_mem_to_reg),
        .mem_read_out(mem_mem_read), .mem_write_out(mem_mem_write), .branch_out(mem_branch),
        .branch_target_out(mem_branch_target), .alu_zero_out(mem_alu_zero),
        .alu_result_out(mem_alu_result), .read_data2_out(mem_read_data2),
        .dest_reg_out(mem_dest_reg)
    );

    // ========================================================================
    // 4. MEMORY (MEM) STAGE
    // ========================================================================
    wire [31:0] mem_read_data;

    data_memory my_dmem (
        .clk(clk),
        .mem_write(mem_mem_write), .mem_read(mem_mem_read),
        .address(mem_alu_result), .write_data(mem_read_data2),
        .read_data(mem_read_data)
    );

    // --- MEM/WB PIPELINE REGISTER ---
    wire wb_mem_to_reg;
    wire [31:0] wb_mem_read_data, wb_alu_result;

    mem_wb reg_mem_wb (
        .clk(clk), .reset(reset),
        .reg_write_in(mem_reg_write), .mem_to_reg_in(mem_mem_to_reg),
        .mem_read_data_in(mem_read_data), .alu_result_in(mem_alu_result),
        .dest_reg_in(mem_dest_reg),
        
        .reg_write_out(wb_reg_write), .mem_to_reg_out(wb_mem_to_reg),
        .mem_read_data_out(wb_mem_read_data), .alu_result_out(wb_alu_result),
        .dest_reg_out(wb_dest_reg)
    );

    // ========================================================================
    // 5. WRITE-BACK (WB) STAGE
    // ========================================================================
    assign wb_write_data = (wb_mem_to_reg) ? wb_mem_read_data : wb_alu_result;

endmodule