#ifndef OPTIMIZER_H
#define OPTIMIZER_H

#include<bits/stdc++.h>
#include<fstream>

using namespace std;

vector<string> split(string str, char delimiter){
    vector<string> internal;
    string tok="";
    for(int i=0;i<str.length();i++){
        if(str[i]==delimiter || str[i]=='\t'){
            if(tok!=""){
                internal.push_back(tok);
                tok="";
            }
        }
        else{
            tok += str[i];
        }
    }
    if(tok!=""){
        internal.push_back(tok);
    }
    return internal;
}

bool isJump(string str){
    if(str=="JMP" || str=="JE" || str=="JL" || str=="JLE" || str=="JG" || str=="JGE" || str=="JNE"
    || str == "JNL" || str == "JNLE" || str == "JNG" || str == "JNGE"){
        return true;
    }
    return false;
}

bool optimizeCode(string srcfile, string dstfile){
    bool isOptimized = false;
    ifstream fin(srcfile);
    ofstream fout(dstfile);
    string prevLine="";
    string currLine;
    vector<string> prevInstruction;
    while(getline(fin,currLine)){
        vector<string> currInstruction = split(currLine, ' ');
        if(currInstruction.size() == 0){
            continue;
        }
        else if(currInstruction[0][0] == ';'){
            fout << currLine << endl;
            continue;
        }
        if(prevInstruction.size() == 0){
            prevInstruction = currInstruction;
            prevLine = currLine;
            continue;
        }
        if(currInstruction[0] == "POP" && prevInstruction[0] == "PUSH"){
            fout << ";" << prevLine << endl;
            fout << ";" << currLine << endl;
            if(currInstruction[1] != prevInstruction[1]){
                fout << "\tMOV " << currInstruction[1] << ", " << prevInstruction[1] << endl;
            }
            isOptimized = true;
            prevInstruction.clear();
            prevLine = "";
        }
        else if(currInstruction[0] == "MOV" && currInstruction[1].substr(0,currInstruction[1].length()-1)==currInstruction[2]){
            isOptimized = true;
        }
        else if(currInstruction[0] == "MOV" && prevInstruction[0] == "MOV"){
            currInstruction[1] = split(currInstruction[1], ',')[0];
            prevInstruction[1] = split(prevInstruction[1], ',')[0];
            if(currInstruction[1] == prevInstruction[1]){
                fout << ";" << prevLine << endl;
                prevInstruction = currInstruction;
                prevLine = currLine;
                isOptimized = true;
            }
            else if( currInstruction[1] == prevInstruction[2] && prevInstruction[1] == currInstruction[2]){
                fout  << prevLine << endl;
                fout << ";" << currLine << endl;
                prevInstruction.clear();
                prevLine = "";
                isOptimized = true;
            }
            else{
                fout << prevLine << endl;
                prevInstruction = currInstruction;
                prevLine = currLine;
            }
        }
        else if(isJump(prevInstruction[0]) && currInstruction[0][currInstruction[0].length()-1] == ':' && currInstruction[0].substr(0,currInstruction[0].length()-1) == prevInstruction[1]){
            fout << ";" << prevLine << endl;
            fout <<  currLine << endl;
            prevInstruction.clear();
            prevLine = "";
            isOptimized = true;
        }
        else if(prevInstruction[0] == "CMP" && !isJump(currInstruction[0])){
            fout << ";" <<prevLine << endl;
            prevInstruction.clear();
            prevLine = "";
            isOptimized = true;
        }
        else{
            fout << prevLine << endl;
            prevInstruction = currInstruction;
            prevLine = currLine;
        }
    }

    if(prevInstruction.size() != 0 && prevInstruction[0] == "CMP"){
        fout << ";" << prevLine << endl;
    }
    else{
        fout << prevLine << endl;
    }
    fin.close();
    fout.close();
    return isOptimized;
}

#endif