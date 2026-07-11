#include <iostream>
#include <string>
#include <vector>
#include <sstream>
#include <algorithm>

using namespace std;

// This function cleans a line of text and extracts the core words
vector<string> tokenize(string line)
{
    vector<string> tokens;

    // 1. Remove comments: Find the '#' and cut everything after it
    size_t commentPos = line.find('#');
    if (commentPos != string::npos)
    {
        line = line.substr(0, commentPos);
    }

    // 2. Remove commas: Replace them with spaces
    replace(line.begin(), line.end(), ',', ' ');

    // 3. Extract the words using a stringstream
    stringstream ss(line);
    string token;
    while (ss >> token)
    {
        tokens.push_back(token);
    }

    return tokens;
}

int main()
{
    // A messy test line of MIPS assembly code
    string testLine = "  add $t0, $t1, $t2 # adding registers together ";

    // Send it to our lexer function
    vector<string> result = tokenize(testLine);

    // Print out the results to verify it worked
    cout << "Extracted Tokens:\n";
    for (int i = 0; i < result.size(); i++)
    {
        cout << "[" << result[i] << "]\n";
    }

    return 0;
}