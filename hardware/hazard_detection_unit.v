module hazard_detection_unit (
    input wire id_ex_mem_read,      // Is the instruction in EX a 'lw'?
    input wire [4:0] id_ex_rt,      // What register is 'lw' writing to?
    input wire [4:0] if_id_rs,      // Source register 1 of the instruction in ID
    input wire [4:0] if_id_rt,      // Source register 2 of the instruction in ID
    
    output reg stall                // 1 = STALL THE PIPELINE, 0 = RUN NORMAL
);

    always @(*) begin
        // If the instruction ahead of us is reading memory AND it's writing to a register we need right now:
        if (id_ex_mem_read && ((id_ex_rt == if_id_rs) || (id_ex_rt == if_id_rt))) begin
            stall = 1'b1; // Trigger the stall
        end else begin
            stall = 1'b0; // Safe to proceed
        end
    end

endmodule