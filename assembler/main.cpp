#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>
#include <algorithm>
#include <unordered_map> // NEW: This is the data structure for our Symbol Table

using namespace std;

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

int main()
{
    ifstream file("test.asm");
    if (!file.is_open())
    {
        cout << "Error: Could not open test.asm\n";
        return 1;
    }

    string line;
    unordered_map<string, int> symbolTable; // This will hold our labels and addresses
    int PC = 0;                             // Program Counter starts at memory address 0

    // --- PASS 1: Find Labels and Calculate Memory Addresses ---
    while (getline(file, line))
    {
        vector<string> tokens = tokenize(line);
        if (tokens.empty())
            continue; // Skip empty lines

        // Check if the very first word is a label (ends with a colon ':')
        string firstToken = tokens[0];
        if (firstToken.back() == ':')
        {
            // Remove the ':' and save it to the map with the current PC address
            string labelName = firstToken.substr(0, firstToken.size() - 1);
            symbolTable[labelName] = PC;

            // Remove the label from the tokens list so it doesn't mess up Pass 2 later
            tokens.erase(tokens.begin());
        }

        // If there are still instruction tokens left on this line, advance the PC by 4 bytes
        if (!tokens.empty())
        {
            PC += 4;
        }
    }
    file.close();

    // Print the Symbol Table to prove it worked
    cout << "--- Symbol Table ---\n";
    for (auto const &pair : symbolTable)
    {
        cout << "Label: [" << pair.first << "] -> Memory Address: " << pair.second << "\n";
    }

    return 0;
}