#ifndef SYMBOL_INFO_H
#define SYMBOL_INFO_H

#include<bits/stdc++.h>
#include<string>
using namespace std;



class SymbolInfo
{
    string Sym_name;
    string  Sym_type;
    SymbolInfo *next_Sym;
    bool isFunc;
    bool isArr;
    string arrSize;
    int startLine;
    int endLine;
    bool isLeaf;
    vector<SymbolInfo*> children;

public:
    //constructors
    SymbolInfo()
    {
        this->next_Sym = NULL;
        isFunc = false;
        isLeaf = false;

    }

    SymbolInfo(const string &name, string type)
    {
        this->Sym_name = name;
        this->Sym_type = type;
        this->next_Sym = NULL;
        this->isFunc = false;
        this->isLeaf = false;
    }

    SymbolInfo(SymbolInfo* a){
        this->Sym_name = a->Sym_name;
        this->Sym_type = a->Sym_type;
        this->next_Sym = a->next_Sym;
        this->isFunc = a->isFunc;
        //this->isArr = a->isArr;
        //this->arrSize = a->arrSize;
        this->startLine = a->startLine;
        this->endLine = a->endLine;
        this->isLeaf = a->isLeaf;
        this->children = a->children;
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

    void setFunc(bool isFunc)
    {
        this->isFunc = isFunc;
    }
    bool getFunc() const
    {
        return this->isFunc;
    }

    void setArr(bool isArr)
    {
        this->isArr = isArr;
    }
    bool getArr() const
    {
        return this->isArr;
    }

    void setArrSize(string arrSize)
    {
        this->arrSize = arrSize;
    }
    string getArrSize() const
    {
        return this->arrSize;
    }

    void setStartLine(int startLine)
    {
        this->startLine = startLine;
    }
    int getStartLine() const
    {
        return this->startLine;
    }

    void setEndLine(int endLine)
    {
        this->endLine = endLine;
    }
    int getEndLine() const
    {
        return this->endLine;
    }

    void setisLeaf(bool isLeaf)
    {
        this->isLeaf = isLeaf;
    }
    bool getisLeaf() const
    {
        return this->isLeaf;
    }


    void setChildren(vector<SymbolInfo*> children)
    {
        this->children = children;
    }
    vector<SymbolInfo*> getChildren() const
    {
        return this->children;
    }
    
    void addChild(SymbolInfo* child)
    {
        this->children.push_back(child);
    }
    //destructor
    ~SymbolInfo() {}
};

#endif // SYMBOL_INFO_H




