#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include "1905088_Scope_Table.h"
using namespace std;

class SymbolTable
{
    int ScopeSize;
    int totalScopes;
    int totalIDofCurrFunc;
    ScopeTable* currentScopeTable;
    vector<Function*> funcList;

public:
    SymbolTable(int num)
    {
        this->ScopeSize=num;
        currentScopeTable = new ScopeTable(ScopeSize);
        this->totalScopes=1;
        currentScopeTable->setID(totalScopes);
        this->totalIDofCurrFunc = 0;
        //out<<"\tScopeTable# "<<currentScopeTable->getID()<<" created"<<endl;
    }

    ScopeTable* getCurrentScope()
    {
        return this->currentScopeTable;
    }

    int getCurrentScopeID()
    {
        return this->currentScopeTable->getID();
    }

    int getTotalIDofCurrFunc()
    {
        return this->totalIDofCurrFunc;
    }

    void reset(){
        totalIDofCurrFunc = 0;
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

bool Insert(string name, string type, string dataType, int arrsize, bool isParam = false)
{
    //cout<<"enters"<<endl;
    if(type != "ID"){
        cout<<"Error: "<<name<<" is not an ID"<<endl;
        return false;
    }

    bool flag = currentScopeTable->Insert(name, type, dataType,arrsize,totalIDofCurrFunc, isParam);
    if(flag && !isParam){
        if(arrsize>0){
            totalIDofCurrFunc += arrsize;
        }
        else{
            totalIDofCurrFunc += 1;
        }
    }
    return flag;
}

bool Remove(string name)
{
    return currentScopeTable->Delete(name);
}

SymbolInfo* LookUpCurrentScope(string name){
    return currentScopeTable->LookUp(name,true);
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


