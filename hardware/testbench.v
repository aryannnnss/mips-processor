// Set the simulation time scale: 1 nanosecond per tick, 1 picosecond precision
`timescale 1ns / 1ps

module testbench;

    // Inputs to the CPU are declared as 'reg' so we can manipulate them in the testbench
    reg clk;
    reg reset;

    // Instantiate your processor (Unit Under Test - UUT)
    datapath uut (
        .clk(clk),
        .reset(reset)
    );

    // --- Clock Generation ---
    // Toggle the clock every 5 nanoseconds (10ns total period = 100 MHz clock)
    always #5 clk = ~clk;

    // --- Simulation Logic ---
    initial begin
        // 1. Initialize the system
        clk = 0;
        reset = 1; // Hold the reset button down

        // 2. Wait 10 nanoseconds, then release the reset button
        #10;
        reset = 0;

        // 3. Let the CPU run for 100 nanoseconds
        #100;

        // 4. Stop the simulation
        $display("Simulation complete.");
        $finish;
    end

    // --- Data Monitoring ---
    // $monitor acts like a live print statement. 
    // It prints to the terminal anytime one of these variables changes.
    // Notice how we use 'uut.pc_current' to look INSIDE the datapath module!
    initial begin
        $monitor("Time: %0t ns | PC: %0d | Instruction (Hex): %h", $time, uut.pc_current, uut.instruction);
    end

endmodule