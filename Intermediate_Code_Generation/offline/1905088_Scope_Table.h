#ifndef SCOPE_TABLE_H
#define SCOPE_TABLE_H

#include "1905088_Function.h"
#include "1905088_SymbolID.h"

using namespace std;

class ScopeTable
{
    int  num_buckets;
    int Scope_ID;
    SymbolInfo** hashTable;
    ScopeTable* parent_scope;

    static unsigned long long int SDBMHash(string name)
    {
        unsigned long long int hash = 0;

        for (unsigned int i = 0; i < name.length(); i++)
        {
            hash = (name[i]) + (hash << 6) + (hash << 16) - hash;
        }

        return hash;
    }

public:
    ScopeTable(int TbSize)
    {
        this->num_buckets = TbSize;
        this->Scope_ID = 1;
        this->parent_scope = NULL;

        hashTable = new SymbolInfo*[num_buckets];
        for(int i=0; i<num_buckets; i++)
            hashTable[i] = NULL;
        //cout<<"created."<<endl;
    }

    void setParent(ScopeTable* parent)
    {
        this->parent_scope = parent;
    }
    ScopeTable* getParent()
    {
        return this->parent_scope;
    }

    void setID(int num)
    {
        this->Scope_ID = num;
    }
    int getID()
    {
        return this->Scope_ID;
    }

 SymbolInfo* LookUp(string name, bool flag)
{
    //cout<<"here"<<endl;
    int index = SDBMHash(name) % num_buckets;
    int linkIndex =1;
    //cout<<index<<endl;
    if(hashTable[index]!=NULL)
    {
        SymbolInfo* temp = hashTable[index];
        //cout<<temp<<endl;
        while(temp!=NULL)
        {
            if(temp->getName()==name)
            {
                if(flag);
                    //out<<"\t\'"<<name<<"\' found in ScopeTable# "<<Scope_ID<<" at position "<<index+1<<", "<<linkIndex<<endl;
                return temp;
            }
            temp = temp->getNext();
            linkIndex++;
            //cout<<"haven't got it"<<endl;
        }
    }
    //cout<<"haven't got it"<<endl;
    return NULL;
}

bool Insert(string name, string type, bool isFunc = false)
{
    // cout<<"here"<<endl;
    SymbolInfo *curr = LookUp(name, false);
    // cout<<curr<<endl;
    if (curr == NULL)
    {
        int index = SDBMHash(name) % num_buckets;
        // cout<<index<<endl;
        int linkIndex = 1;
        curr = hashTable[index];
        if (curr == NULL)
        {
            if(isFunc){  //if it is a function
                hashTable[index] = new Function(name, type);
        }
            else{ //if it is a variable
            hashTable[index] = new SymbolInfo(name, type);
            }
        }
        else
        {
            while (curr->getNext() != NULL)
            {
                curr = curr->getNext();
                linkIndex++;
            }
            if(isFunc) {
                curr->setNext(new Function(name, type));
            }
            else{ 
                curr->setNext(new SymbolInfo(name, type));
            }
            linkIndex++;
        }
        // out<<"\tInserted in ScopeTable# "<<Scope_ID<<" at position "<<index+1<<", "<<linkIndex<<endl;
        return true;
    }
    else
    {
        //logout << "\t" << name << " already exists in the current ScopeTable" << endl;
        return false;
    }
    return false;
}


bool Insert(string name, string type, string dataType, int arrsize, int totalID, bool isParam = false)
{
    // cout<<"here"<<endl;
    SymbolInfo *curr = LookUp(name, false);
    // cout<<curr<<endl;
    if (curr == NULL)
    {
        int index = SDBMHash(name) % num_buckets;
        // cout<<index<<endl;
        int linkIndex = 1;
        curr = hashTable[index];
        int offset = -(totalID + 1) *2;
        if(Scope_ID == 1) {
            offset = -1;
        }
        if (curr == NULL)
        {
            hashTable[index] = new SymbolID(name, dataType, offset, arrsize);
        }
        else
        {
            while (curr->getNext() != NULL)
            {
                curr = curr->getNext();
                linkIndex++;
            }
                curr->setNext(new SymbolID(name, dataType, offset, arrsize));
            linkIndex++;
        }
        // out<<"\tInserted in ScopeTable# "<<Scope_ID<<" at position "<<index+1<<", "<<linkIndex<<endl;
        return true;
    }
    else
    {
        //logout << "\t" << name << " already exists in the current ScopeTable" << endl;
        return false;
    }
    return false;
}

bool Delete(string name)
{
    SymbolInfo* curr = LookUp(name, false);
    if(curr == NULL)
    {
       // out<<"\t\'"<<name<<"\' not found"<<endl;
        return false;
    }
    int index = SDBMHash(name) % num_buckets;
    int linkIndex = 1;
    curr = hashTable[index];

    if(curr->getName() == name)
    {
        //out << "\tDeleted \'" << name << "\' from ScopeTable# " << Scope_ID << " at position " << index + 1 << ", " << linkIndex << endl;
        hashTable[index] = curr->getNext();
        delete curr;
        return true;
    }

    else
    {
        while (curr->getNext() != NULL)
        {
            linkIndex++;
            if (curr->getNext()->getName() == name)
            {
                //out << "\tDeleted \'" << name << "\' from ScopeTable# " << Scope_ID << " at position " << index + 1 << ", " << linkIndex << endl;
                SymbolInfo* temp = curr->getNext();
                curr->setNext(curr->getNext()->getNext());
                delete temp;
                return true;
            }
            curr = curr->getNext();
        }
    }
    return false;
}

void Print()
{
   // logout << "\tScopeTable# " << Scope_ID << endl;
    for (int i = 0; i < num_buckets; i++)
    {
        if (hashTable[i] != NULL)
        {
            //logout << "\t" << i + 1 << "--> ";
            SymbolInfo *temp = hashTable[i];
            while (temp != NULL)
            {
                //logout << "<" << temp->getName() << "," << temp->getType() << "> ";
                temp = temp->getNext();
            }
            //logout << endl;
        }
    }
}

    ~ScopeTable()
    {
        for (int i=0; i<num_buckets; i++)
        {
            if(hashTable[i]!= NULL){
            while(hashTable[i]!=NULL)
            {
                SymbolInfo* temp=hashTable[i]->getNext();
                if(hashTable[i]->getFunc()){
                    delete (Function*)hashTable[i];
                }
                else if(hashTable[i]->getType() == "ID"){
                    delete (SymbolID*)hashTable[i];
                }
                else{
                    delete hashTable[i];
                }
                hashTable[i] = temp;
            }
            }
        }
        delete[] hashTable;
    }
};


#endif // SCOPE_TABLE_H


