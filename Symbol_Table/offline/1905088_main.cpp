#include "1905088_Symbol_Table.h"
using namespace std;

string cmd[4];

void Split(string s)
{
    stringstream ss(s);
    int i=0;
    while(i<4)
    {
        ss>>cmd[i];
        //cout<<cmd[i]<<endl;
        i++;
    }
}
int main()
{
    string s;
    ifstream in("test_input.txt");
    getline(in,s);
    int n= stoi(s);
//cout<<n;
    {
        SymbolTable ST(n);

        int i=1;
        while(!in.eof())
        {
            for(int j=0; j<4; j++)
            {
                cmd[j].clear();
                //if(cmd[j].empty())
                //cout<<"NULL"<<endl;
            }
            getline(in,s);
            Split(s);
            /* for(int j=0;j<5;j++)
             cout<<cmd[j];
             cout<<endl; */
            out<<"Cmd "<<i<<": ";
            if(cmd[0] == "I")
            {
                out<<s<<endl;
                if(cmd[1].empty() || cmd[2].empty() || !cmd[3].empty())
                {
                    out<<"\tNumber of parameters mismatch for the command "<<cmd[0]<<endl;
                }
                else
                    ST.Insert(cmd[1],cmd[2]);
            }
            else if(cmd[0] == "L")
            {
                out<<s<<endl;
                if(cmd[1].empty() || !cmd[2].empty())
                {
                    out<<"\tNumber of parameters mismatch for the command "<<cmd[0]<<endl;
                }
                else
                {
                    if(!ST.LookUp(cmd[1]))
                        out<<"\t\'"<<cmd[1]<<"\' not found in any of the ScopeTables"<<endl;
                }

            }
            else if(cmd[0] == "D")
            {
                out<<s<<endl;
                if(cmd[1].empty() || !cmd[2].empty())
                {
                    out<<"\tNumber of parameters mismatch for the command "<<cmd[0]<<endl;
                }
                else
                {
                    if(!ST.Remove(cmd[1]))
                        out<<"\tNot found in the current ScopeTable"<<endl;
                }
            }

            else if(cmd[0] == "P")
            {
                out<<s<<endl;
                if(cmd[1].empty() || !cmd[2].empty())
                {
                    out<<"\tNumber of parameters mismatch for the command "<<cmd[0]<<endl;
                }
                else
                {
                    if(cmd[1] == "A")
                    {
                        ST.PrintAllScope();
                    }
                    else if(cmd[1] == "C")
                    {
                        ST.PrintCurrentScope();
                    }
                    else
                        out<<"\tInvalid command after P"<<endl;
                }
            }

            else if(cmd[0] == "S")
            {
                out<<s<<endl;
                if(!cmd[1].empty())
                {
                    out<<"\tNumber of parameters mismatch for the command "<<cmd[0]<<endl;
                }
                else
                    ST.EnterScope();
            }

            else if(cmd[0] == "E")
            {
                out<<s<<endl;
                if(!cmd[1].empty())
                {
                    out<<"\tNumber of parameters mismatch for the command "<<cmd[0]<<endl;
                }
                else
                    ST.ExitScope();
            }

            else if(cmd[0] == "Q")
            {
                out<<cmd[0]<<endl;
                break;
            }
            else
                out<<"\tInvalid command"<<endl;

            i++;
        }
    }

    in.close();
    out.close();

    return 0;
}
