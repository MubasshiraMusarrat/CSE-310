%option noyywrap

%x STRING_STATE
%x SINGLE_COMMENT_STATE
%x MULTI_COMMENT_STATE

%{
#include<bits/stdc++.h>
#include<iostream>
#include<fstream>
#include<string>
#include "1905088_Symbol_Table.h"
#include "parser.tab.h"

using namespace std;

extern YYSTYPE yylval;
extern SymbolTable *st;
extern ofstream textlog;
extern ofstream errorlog;
extern ofstream parselog;


int line_count=1;
int error_count=0;
int store_line_count=0;

string str; //for storing string
string str_token; //for storing type of string 

string Log; //for printing log


//functions for error handling
void addError(string error, string lexeme){
    //errorlog<<"Error at line# "<<line_count<<": "<<error<<" "<<lexeme<<endl;
    //error_count++;
}

//functions for Uppercase letter
string toUpper(const string &s){
    string res="";
    for(int i=0;i<s.size();i++){
        res+=toupper(s[i]);
    }
    return res;
}

//functions for adding keywords
void addKeyword(const string &lexeme){
    string upperLexeme=toUpper(lexeme);
    //tokenout<<"<"<<upperLexeme<<", "<<lexeme<<">"<<endl;
    textlog<<"Line# "<<line_count<<": Token <" <<upperLexeme<<"> Lexeme "<<lexeme<<" found"<<endl;
    yylval.symbol = new SymbolInfo(lexeme,upperLexeme); 
}

//functions for adding numbers
void addNumber(string token,string lexeme){
    //tokenout<<"<"<<token<<", "<<lexeme<<">"<<endl;
    textlog<<"Line# "<<line_count<<": Token <"<<token<<"> Lexeme "<<lexeme<<" found"<<endl;
}

//functions for escape character token
string escapeChar(char c){
    switch(c){
        case '\'': return "\'";
        case '\"': return "\"";
        case 'n': return "\n";
        case 't': return "\t";
        case '\\': return "\\";
        case 'a': return "\a";
        case 'f': return "\f";
        case 'r': return "\r";
        case 'b': return "\b";
        case 'v': return "\v";
        case '0': return "\0";
        default: return "";
    }
}

//functions for adding character
void addCharacter(string lexeme){
    string s="";
        if (lexeme[1] == '\\'){
            s+=escapeChar(lexeme[2]);
        }
        else{
            s+= lexeme[1];
        }

       // tokenout<<"<CONST_CHAR, "<<s<<">"<<endl;
        textlog<<"Line# "<<line_count<<": Token <CONST_CHAR> Lexeme "<<s<<" found"<<endl;
}

//functions for adding operators and punctuators
void addOp_Punc(string token, string lexeme){
    //tokenout<<"<"<<token<<", "<<lexeme<<">"<<endl;
    textlog<<"Line# "<<line_count<<": Token <"<<token<<"> Lexeme "<<lexeme<<" found"<<endl;
    yylval.symbol = new SymbolInfo(lexeme,token); 
}

//functions for adding identifiers
void addID(string lexeme){
    //tokenout<<"<ID, "<<lexeme<<">"<<endl;
    textlog<<"Line# "<<line_count<<": Token <ID> Lexeme "<<lexeme<<" found"<<endl;
}

//functions for adding string
void addString(string lexeme, string str_log){
    string s = "";
    for(int i=0;i<lexeme.length(); i++){
        if(lexeme[i]=='\\'){
            s+=escapeChar(lexeme[i+1]);
            i++;
        }
        else{
            s+= lexeme[i];
        }
    }
    //tokenout<<"<"<<str_token<<", "<<s<<">"<<endl;
    textlog<<"Line# "<<(line_count-store_line_count)<<": Token <"<<str_token<<"> Lexeme "<<str_log<<" found"<<endl;
    yylval.symbol = new SymbolInfo(lexeme,"STRING");
}

//functions for adding comment
void addComment(string token, string lexeme){
    string s="";
    for(int i=0; i<lexeme.length();i++){
        if(lexeme[i] == '\\'){
            s+="\\";
        }
        else if(lexeme[i] == '\n'){
            s += "\n";
        }
        else{
            s+=lexeme[i];
        }
    }
    textlog<<"Line# "<<(line_count-store_line_count)<<": Token <"<<token<<"> Lexeme "<<s<<" found"<<endl;
}

%}

/* Definitions */
WHITESPACE [ \t\f\r\v]+ 
NEWLINE (\r)?\n
CHAR \'[^\\\n\r]\' 
ESCAPE_CHAR \'\\[\'\"nt\\afrbv0]\'
LETTER [a-zA-Z_]
ID {LETTER}({LETTER}|{DIGIT})*
DIGIT [0-9]
INT {DIGIT}+
FLOAT {DIGIT}*(\.{DIGIT}+)?([eE][+-]?{DIGIT}+)?

/* Errors */
TOO_MANY_DECIMAL_POINT {DIGIT}*(\.{DIGIT}*)+(\.{DIGIT}*)+([eE][+-]?{DIGIT}+)?
ILL_FORMAT_NUMBER {DIGIT}*(\.{DIGIT}+)?[Ee][+-]?{DIGIT}*(\.{DIGIT}*)+
INVALID_SUFFIX_OR_PREFIX  {FLOAT}+{ID}+
MULTI_CHAR \'.[^\'\r\n]+\'
EMPTY_CHAR \'\'
UNFINISHED_CHAR \'(.|\\\')?[^\'\r\n]*

%%

{WHITESPACE} { /* ignore */ }
{NEWLINE} {line_count++;}


if  { addKeyword("if");
    return IF;}
else    { addKeyword("else");
    return ELSE;}
for { addKeyword("for");
    return FOR;}
do  { addKeyword("do");
    return DO;}
int { addKeyword("int");
    return INT;}
float   { addKeyword("float");
    return FLOAT;}
void    { addKeyword("void");
    return VOID;}
switch  { addKeyword("switch");
    return SWITCH;}
default { addKeyword("default");
    return DEFAULT;}
while   { addKeyword("while");
    return WHILE;}
break   { addKeyword("break");
    return BREAK;}
char    { addKeyword("char");
    return CHAR;}
double  { addKeyword("double");
    return DOUBLE;}
return  { addKeyword("return");
    return RETURN;}
case    { addKeyword("case");
    return CASE;}
continue   { addKeyword("continue");
    return CONTINUE;}
printf  { textlog<<"Line# "<<line_count<<": Token <" <<PRINTLN<<"> Lexeme "<<printf<<" found"<<endl;
        yylval.symbol = new SymbolInfo(yytext,"PRINTLN"); 
    return PRINTLN;}

{INT} { addNumber("CONST_INT",yytext);
    yylval.symbol = new SymbolInfo(yytext,"CONST_INT"); 
        return CONST_INT;}

{FLOAT} { addNumber("CONST_FLOAT",yytext);
    yylval.symbol = new SymbolInfo(yytext,"CONST_FLOAT"); 
        return CONST_FLOAT;}

{TOO_MANY_DECIMAL_POINT} {addError("TOO_MANY_DECIMAL_POINTS",yytext);}
{ILL_FORMAT_NUMBER} {addError("ILLFORMED_NUMBER",yytext);}
{EMPTY_CHAR} {addError("EMPTY_CONST_CHAR",yytext);}

{CHAR} { addCharacter(yytext);
    yylval.symbol = new SymbolInfo(yytext,"CONST_CHAR"); 
        return CONST_CHAR;}

{ESCAPE_CHAR} { addCharacter(yytext);
    yylval.symbol = new SymbolInfo(yytext,"CONST_CHAR"); 
        return CONST_CHAR;}

{MULTI_CHAR} {addError("MULTICHAR_CONST_CHAR",yytext);}
{UNFINISHED_CHAR} {addError("UNFINISHED_CONST_CHAR",yytext);}

[+-]	{ addOp_Punc("ADDOP",yytext);
        return ADDOP; }
[*/%]   { addOp_Punc("MULOP",yytext);
    //yylval.symbol = new SymbolInfo(yytext, "MULOP");
        return MULOP; }
"--"	{ addOp_Punc("DECOP",yytext);
    //yylval.symbol = new SymbolInfo(yytext,"DECOP");
        return DECOP;}
"++"	{ addOp_Punc("INCOP",yytext);
    //yylval.symbol = new SymbolInfo(yytext,"INCOP");
        return INCOP;}
"<"|">"|"<="|">="|"=="|"!=" { addOp_Punc("RELOP",yytext);
     //yylval.symbol = new SymbolInfo(yytext,"RELOP"); 
        return RELOP; }
=	{ addOp_Punc("ASSIGNOP",yytext);
    return ASSIGNOP; }
"&&"|"||"	{ addOp_Punc("LOGICOP",yytext);
    //yylval.symbol = new SymbolInfo(yytext,"LOGICOP"); 
        return LOGICOP; }
!	{ addOp_Punc("NOT",yytext);
    return NOT;}
"("	{ addOp_Punc("LPAREN",yytext);
    return LPAREN; }
")"	{ addOp_Punc("RPAREN",yytext);
    return RPAREN; }
"{"	{ addOp_Punc("LCURL",yytext);
    return LCURL; }
"}"	{ addOp_Punc("RCURL",yytext);
    return RCURL;}
"["	{ addOp_Punc("LSQUARE",yytext);
    return LSQUARE; }
"]"	{ addOp_Punc("RSQUARE",yytext);
    return RSQUARE; }
\,	{ addOp_Punc("COMMA",yytext);
    return COMMA; }
\;	{ addOp_Punc("SEMICOLON",yytext);
    return SEMICOLON; }


{ID} { addID(yytext);
    yylval.symbol = new SymbolInfo(yytext,"ID"); 
        return ID; }

{INVALID_SUFFIX_OR_PREFIX} {addError("INVALID_ID_SUFFIX_NUM_PREFIX",yytext);}


"\"" { //beginning of string
    str.clear();
    str += "";
    str_token.clear();
    str_token += "SINGLE LINE STRING";
    store_line_count=0;
    Log.clear();
    Log+="\"";
    BEGIN STRING_STATE;
    }

<STRING_STATE>"\"" {  //end of string
    Log+="\"";
    if(str[str.length()-1] == '\\'){
        str += yytext;
    }
    else{
        addString(str,Log);
        str.clear();
        Log.clear();
        BEGIN INITIAL;
        return STRING;
    }
}

<STRING_STATE>\\{NEWLINE} { //handeling multiline string
    str_token.clear();
    str_token+="MULTI LINE STRING";
    line_count++;
    store_line_count++;
    Log += yytext;
    }

<STRING_STATE>[^\r\n] { //any character except newline
    str += yytext;
    Log += yytext;
    }

<STRING_STATE>{NEWLINE} { //newline encountered in string
    addError("UNFINISHED_STRING",Log);
    line_count++;
    str.clear();
    Log.clear();
    BEGIN INITIAL;
    }

<STRING_STATE><<EOF>> { //end of file encountered in string
    addError("UNFINISHED_STRING",Log);
    str.clear();
    Log.clear();
    //BEGIN INITIAL;
    return 0;
    }


"//" { //beginning of single line comment
    store_line_count = 0;
    Log.clear();
    Log+="//";
    BEGIN SINGLE_COMMENT_STATE;
    }

<SINGLE_COMMENT_STATE>{NEWLINE} { //end of single line comment
    addComment("SINGLE LINE COMMENT",Log);
    line_count++;
    Log.clear();
    BEGIN INITIAL;
}

<SINGLE_COMMENT_STATE>\\{NEWLINE} { //handeling multiline comment
    line_count++;
    store_line_count++;
    Log += yytext;
}

<SINGLE_COMMENT_STATE>[^\r\n] { //any character except newline
    Log += yytext;
}


"/*" { //beginning of multi line comment
    store_line_count = 0;
    Log.clear();
    Log+="/*";
    BEGIN MULTI_COMMENT_STATE;
    }

<MULTI_COMMENT_STATE>"*/" { //end of multi line comment
    Log+="*/";
    addComment("MULTI LINE COMMENT",Log);
    Log.clear();
    BEGIN INITIAL;
}

<MULTI_COMMENT_STATE>{NEWLINE}[^<<EOF>>] { //newline encountered in comment
    line_count++;
    store_line_count++;
    Log += yytext;
}

<MULTI_COMMENT_STATE>({NEWLINE}*)[<<EOF>>] {
    line_count++;
    store_line_count++;
    addError("UNFINISHED_COMMENT",Log);
    Log.clear();
    //BEGIN INITIAL;
    return 0;
}

<MULTI_COMMENT_STATE>[^\r\n] { //any character except newline
    Log += yytext;
}




.    { //any other character
    addError("UNRECOGNIZED_CHAR",yytext); }

%%