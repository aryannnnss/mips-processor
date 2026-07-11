#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>
#include <algorithm>
#include <unordered_map>
#include <iomanip> // NEW: For printing hex values easily
#include <cstdint>

using namespace std;

// --- DICTIONARIES (Translation Maps) ---
unordered_map<string, int> registers = {
    {"$zero", 0}, {"$t0", 8}, {"$t1", 9}, {"$t2", 10}, {"$s0", 16}
    // We will add the rest of the 32 registers later
};

unordered_map<string, int> rTypeFunct = {
    {"add", 32}, {"sub", 34}, {"and", 36}, {"or", 37}, {"slt", 42}};

// Your Lexer function stays exactly the same
vector<string> tokenize(string line)
{
    vector<string> tokens;
    size_t commentPos = line.find('#');
    if (commentPos != string::npos)
        line = line.substr(0, commentPos);
    replace(line.begin(), line.end(), ',', ' ');
    stringstream ss(line);
    string token;
    while (ss >> token)
        tokens.push_back(token);
    return tokens;
}

// --- NEW: R-Type Encoder Function ---
// This uses bitwise math to construct the 32-bit instruction
uint32_t encodeRType(string instr, string rd, string rs, string rt)
{
    uint32_t opcode = 0; // R-type opcodes are always 0
    uint32_t rs_val = registers[rs];
    uint32_t rt_val = registers[rt];
    uint32_t rd_val = registers[rd];
    uint32_t shamt = 0; // 0 for standard arithmetic
    uint32_t funct = rTypeFunct[instr];

    // Shift everything into the correct bit positions and combine with OR (|)
    uint32_t machineCode = (opcode << 26) | (rs_val << 21) | (rt_val << 16) | (rd_val << 11) | (shamt << 6) | funct;
    return machineCode;
}
int main()
{
    // --- PASS 1: The Symbol Table ---
    ifstream file("test.asm");
    if (!file.is_open())
        return 1;

    string line;
    unordered_map<string, int> symbolTable;
    int PC = 0;

    while (getline(file, line))
    {
        vector<string> tokens = tokenize(line);
        if (tokens.empty())
            continue;

        if (tokens[0].back() == ':')
        {
            string labelName = tokens[0].substr(0, tokens[0].size() - 1);
            symbolTable[labelName] = PC;
            tokens.erase(tokens.begin());
        }
        if (!tokens.empty())
            PC += 4;
    }

    // Reset the file back to the beginning for Pass 2
    file.clear();
    file.seekg(0, ios::beg);

    // --- PASS 2: Encode and Write to File ---
    ofstream outFile("machine_code.hex"); // This creates our output file for Verilog

    while (getline(file, line))
    {
        vector<string> tokens = tokenize(line);

        // Remove labels from tokens in Pass 2 so they don't break our encoder
        if (!tokens.empty() && tokens[0].back() == ':')
        {
            tokens.erase(tokens.begin());
        }

        if (tokens.empty())
            continue; // Skip empty lines

        string instr = tokens[0];

        // Check if it is an R-Type instruction (like 'add')
        if (rTypeFunct.find(instr) != rTypeFunct.end())
        {
            // tokens: [add] [$t0] [$t1] [$t2]
            string rd = tokens[1];
            string rs = tokens[2];
            string rt = tokens[3];

            uint32_t machineCode = encodeRType(instr, rd, rs, rt);

            // Write the exact hex value to our new file
            outFile << setfill('0') << setw(8) << hex << machineCode << "\n";
        }
        // (Later, you can add 'else if' statements here for I-Type and J-Type instructions)
    }

    file.close();
    outFile.close();

    cout << "Success! Machine code written to machine_code.hex\n";
    return 0;
}