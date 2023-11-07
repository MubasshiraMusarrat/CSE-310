#ifndef SYMBOL_INFO_H
#define SYMBOL_INFO_H

#include<bits/stdc++.h>
#include<string>
using namespace std;

ofstream out("output.txt", ios_base::out );

class SymbolInfo
{
    string Sym_name;
    string  Sym_type;
    SymbolInfo *next_Sym;

public:
    //constructors
    SymbolInfo()
    {
        this->next_Sym = NULL;
    }

    SymbolInfo(string name, string type)
    {
        this->Sym_name = name;
        this->Sym_type = type;
        this->next_Sym = NULL;
    }

    //setter & getters
    void setName(string name)
    {
        this->Sym_name=name;
    }
    string getName() const
    {
        return this->Sym_name;
    }

    void setType(string type)
    {
        this->Sym_type=type;
    }
    string getType() const
    {
        return this->Sym_type;
    }

    void setNext(SymbolInfo* next)
    {
        this->next_Sym=next;
    }
    SymbolInfo* getNext() const
    {
        return this->next_Sym;
    }

    //destructor
    ~SymbolInfo() {}
};

#endif // SYMBOL_INFO_H




