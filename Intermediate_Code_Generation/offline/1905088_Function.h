#ifndef FUNCTION_H
#define FUNCTION_H

#include "1905088_Symbol_Info.h"

using namespace std;

class Function : public SymbolInfo
{
    vector<string> paramList;
    string returnType;
    bool isDefined;

public:
    Function(string name, string type) : SymbolInfo(name, type)
    {
        setFunc(true);
        this->isDefined = false;
    }

void setReturnType(string type)
{
    this->returnType = type;
}
string getReturnType() const
{
    return this->returnType;
}

void setDefined(bool isDefined)
{
    this->isDefined = isDefined;
}
bool getDefined() const
{
    return this->isDefined;
}

void addParam( string type)
{
    paramList.push_back(type);
}

void setParamList(vector<string> paramList)
{
    this->paramList = paramList;
}
vector<string> getParamList() const
{
    return this->paramList;
}
~Function()
{
    paramList.clear();
}
};



#endif