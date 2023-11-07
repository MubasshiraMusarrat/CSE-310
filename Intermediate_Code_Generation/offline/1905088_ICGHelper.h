#ifndef ICG_HELPER_H
#define ICG_HELPER_H

#include<bits/stdc++.h>
#include<fstream>

using namespace std;

void write(string filename, string s){
    ofstream file;
    file.open(filename,ios::out);
    file << s << endl;
    file.close();
}

void append(string filename, string s){
    ofstream file;
    file.open(filename,ios::app);
    file << s << endl;
    file.close();
}

void append(string filename, string s, int line){
    ofstream temp;
    ifstream file;
    string s1;
    temp.open("temp.asm",ios::out);
    file.open(filename,ios::in);
    int i=0;
    bool written = false;

    while(getline(file,s1)){
        if(i==line){
            temp << s << endl;
            written = true;
        }
        temp << s1 << endl;
        i++;
    }
    if(!written){
       temp << s << endl;
        written = true; 
    }

    file.close();
    temp.close();
    remove(filename.c_str());
    rename("temp.asm",filename.c_str());
}

#endif