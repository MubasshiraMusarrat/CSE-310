#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include<bits/stdc++.h>
#include "1905088_Scope_Table.h"
using namespace std;

class SymbolTable
{
    int ScopeSize;
    int totalScopes;
    ScopeTable* currentScopeTable;
    vector<Function*> funcList;

public:
    SymbolTable(int num)
    {
        this->ScopeSize=num;
        currentScopeTable = new ScopeTable(ScopeSize);
        this->totalScopes=1;
        currentScopeTable->setID(totalScopes);
        //out<<"\tScopeTable# "<<currentScopeTable->getID()<<" created"<<endl;
    }

    ScopeTable* getCurrentScope()
    {
        return this->currentScopeTable;
    }



    void EnterScope()
{
    ScopeTable* temp=currentScopeTable;
    currentScopeTable = new ScopeTable(ScopeSize);
    totalScopes++;
    currentScopeTable->setParent(temp);
    currentScopeTable->setID(totalScopes);
    //cout<<"works"<<endl;
    //out<<"\tScopeTable# "<<currentScopeTable->getID()<<" created"<<endl;
}

void ExitScope()
{
    if(currentScopeTable->getID()==1){
       // out<<"\tScopeTable# 1 cannot be removed"<<endl;
    }
    else
    {
        ScopeTable* temp = currentScopeTable;
        currentScopeTable = currentScopeTable->getParent();
        //out<<"\tScopeTable# "<<temp->getID()<<" removed"<<endl;
        delete temp;
    }
}

bool Insert(string name, string type, bool isFunc)
{
    //cout<<"enters"<<endl;
    bool flag = currentScopeTable->Insert(name, type, isFunc);
    if(isFunc && flag){
        funcList.push_back(new Function(name, type));
    }
    return flag;
}

bool Insert(string name, string type, string dataType)
{
    //cout<<"enters"<<endl;
    if(type != "ID"){
        cout<<"Error: "<<name<<" is not an ID"<<endl;
        return false;
    }

    return currentScopeTable->Insert(name, type, dataType);
}

bool Remove(string name)
{
    return currentScopeTable->Delete(name);
}

SymbolInfo* LookUp(string name)
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

void PrintCurrentScope()
{
    currentScopeTable->Print();
}

void PrintAllScope()
{
    ScopeTable* temp = currentScopeTable;
    while (temp != NULL)
    {
        temp->Print();
        temp = temp->getParent();
    }
}


    ~SymbolTable()
    {
        ScopeTable* temp = currentScopeTable;
        while(temp != NULL)
        {
            currentScopeTable = temp->getParent();
            //out<<"\tScopeTable# "<<temp->getID()<<" removed"<<endl;
            delete temp;
            temp = currentScopeTable;
        }
    }

};


#endif // SYMBOL_TABLE_H


