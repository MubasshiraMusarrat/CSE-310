#ifndef SymbolID_H
#define SymbolID_H

#include "1905088_Symbol_Info.h"

using namespace std;

class SymbolID : public SymbolInfo{
    string dataType;
    int arrsize;
    int offset;

public:
    SymbolID(string name, int offset) : SymbolInfo(name, "ID")
    {
        this->dataType = dataType;
        this->offset = offset;
        this->arrsize = 0;
    }

    SymbolID(string name, string type, string dataType, int offset, int arrsize) : SymbolInfo(name,type){
        this->dataType = dataType;
        this->offset = offset;
        this->arrsize = arrsize;
    }

    SymbolID(string name, string dataType, int offset, int arrsize) : SymbolID(name,offset){
        this->dataType = dataType;
        this->arrsize = arrsize;
    }

    ~SymbolID()
    {
        //dtor
    }

    void setDataType(string type) { this->dataType = type; }
    string getDataType() const { return this->dataType; }

    void setOffset(int offset) { this->offset = offset; }
    int getOffset() const { return this->offset; }

    void setArrsize(int arrsize) { this->arrsize = arrsize; }
    int getArrsize() const { return this->arrsize; }

};

#endif