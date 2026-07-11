module register_file (
    input wire clk,
    input wire reg_write_en,        // Control signal: Are we allowed to write?
    
    input wire [4:0] read_reg1,     // 5-bit address for RS (Registers 0-31)
    input wire [4:0] read_reg2,     // 5-bit address for RT
    input wire [4:0] write_reg,     // 5-bit address for RD (where to save data)
    input wire [31:0] write_data,   // The actual 32-bit data to save
    
    output wire [31:0] read_data1,  // The data coming out of RS
    output wire [31:0] read_data2   // The data coming out of RT
);

    // Create 32 registers, each 32 bits wide
    reg [31:0] registers [0:31];

    // Initialize all registers to 0 (useful for simulation)
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] = 32'b0;
        end
    end

    // --- READING (Combinational: Instant) ---
    // If the requested register is 0, always output 0. Otherwise, output the register data.
    assign read_data1 = (read_reg1 == 5'b0) ? 32'b0 : registers[read_reg1];
    assign read_data2 = (read_reg2 == 5'b0) ? 32'b0 : registers[read_reg2];

    // --- WRITING (Sequential: Needs Clock) ---
    always @(posedge clk) begin
        // Only write if the enable signal is high AND we aren't trying to overwrite $zero
        if (reg_write_en && write_reg != 5'b0) begin
            registers[write_reg] <= write_data;
        end
    end

endmodule