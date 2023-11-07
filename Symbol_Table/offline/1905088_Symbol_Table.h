#ifndef SYMBOL_TABLE_H
#define SYMBBOL_TABLE_H

#include "1905088_Scope_Table.h"
using namespace std;

class SymbolTable
{
    int ScopeSize;
    int totalScopes;
    ScopeTable* currentScopeTable;

public:
    SymbolTable(int num)
    {
        this->ScopeSize=num;
        currentScopeTable = new ScopeTable(ScopeSize);
        this->totalScopes=1;
        currentScopeTable->setID(totalScopes);
        out<<"\tScopeTable# "<<currentScopeTable->getID()<<" created"<<endl;
        //EnterScope();
        //if(currentScopeTable==NULL)
        //cout<<"created"<<endl;
    }

    ScopeTable* getCurrentScope()
    {
        return this->currentScopeTable;
    }

    void EnterScope();
    void ExitScope();
    bool Insert(string name, string type);
    bool Remove(string name);
    SymbolInfo* LookUp(string name);
    void PrintCurrentScope();
    void PrintAllScope();

    ~SymbolTable()
    {
        ScopeTable* temp = currentScopeTable;
        while(temp != NULL)
        {
            currentScopeTable = temp->getParent();
            out<<"\tScopeTable# "<<temp->getID()<<" removed"<<endl;
            delete temp;
            temp = currentScopeTable;
        }
    }

};

void SymbolTable:: EnterScope()
{
    ScopeTable* temp=currentScopeTable;
    currentScopeTable = new ScopeTable(ScopeSize);
    totalScopes++;
    currentScopeTable->setParent(temp);
    currentScopeTable->setID(totalScopes);
    //cout<<"works"<<endl;
    out<<"\tScopeTable# "<<currentScopeTable->getID()<<" created"<<endl;
}

void SymbolTable:: ExitScope()
{
    if(currentScopeTable->getID()==1)
        out<<"\tScopeTable# 1 cannot be removed"<<endl;
    else
    {
        ScopeTable* temp = currentScopeTable;
        currentScopeTable = currentScopeTable->getParent();
        out<<"\tScopeTable# "<<temp->getID()<<" removed"<<endl;
        delete temp;
    }
}

bool SymbolTable:: Insert(string name, string type)
{
    //cout<<"enters"<<endl;
    return currentScopeTable->Insert(name, type);
}

bool SymbolTable:: Remove(string name)
{
    return currentScopeTable->Delete(name);
}

SymbolInfo* SymbolTable:: LookUp(string name)
{
    ScopeTable* temp =currentScopeTable;

    while( temp != NULL)
    {
        SymbolInfo* symbol = temp->LookUp(name,true);
        if(symbol != NULL)
            return symbol;
        else
            temp = temp->getParent();
    }

    return NULL;
}

void SymbolTable:: PrintCurrentScope()
{
    currentScopeTable->Print();
}

void SymbolTable:: PrintAllScope()
{
    ScopeTable* temp = currentScopeTable;
    while (temp != NULL)
    {
        temp->Print();
        temp = temp->getParent();
    }
}

#endif // SYMBOL_TABLE_H


