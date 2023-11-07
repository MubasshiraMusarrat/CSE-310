#ifndef SymbolID_H
#define SymbolID_H

#include<bits/stdc++.h>
#include <string>
#include "1905088_Symbol_Info.h"

using namespace std;

class SymbolID : public SymbolInfo{
    string dataType;

public:
    SymbolID(string name) : SymbolInfo(name, "ID")
    {
        this->dataType = dataType;
    }
    SymbolID(string name, string type) : SymbolID(name){
        this->dataType = type;
    }

    ~SymbolID()
    {
        //dtor
    }

    void setDataType(string type) { this->dataType = type; }
    string getDataType() const { return this->dataType; }

};

#endif