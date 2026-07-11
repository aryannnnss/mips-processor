module data_memory (
    input wire clk,
    input wire mem_write,
    input wire mem_read,
    input wire [31:0] address,
    input wire [31:0] write_data,
    
    output wire [31:0] read_data
);

    // Create 64 slots of 32-bit RAM
    reg [31:0] ram [0:63];

    // READING: Combinational
    // Divide address by 4 to convert MIPS byte-addressing to Verilog word-addressing
    assign read_data = (mem_read) ? ram[address[31:2]] : 32'b0;

    // WRITING: Sequential
    always @(posedge clk) begin
        if (mem_write) begin
            ram[address[31:2]] <= write_data;
        end
    end

endmodule