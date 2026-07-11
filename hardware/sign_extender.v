module sign_extend (
    input wire [15:0] in,
    output wire [31:0] out
);
    // This takes the 16th bit (the sign bit) and copies it 16 times, 
    // then glues the original 16 bits to the end of it.
    assign out = {{16{in[15]}}, in};

endmodule