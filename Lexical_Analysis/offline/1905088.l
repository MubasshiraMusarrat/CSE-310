%option noyywrap

%x STRING_STATE
%x SINGLE_COMMENT_STATE
%x MULTI_COMMENT_STATE

%{
#include<bits/stdc++.h>
#include "1905088_Symbol_Table.h"

using namespace std;

int line_count=1;
int error_count=0;
int store_line_count=0;

ofstream tokenout;

string str; //for storing string
string str_token; //for storing type of string 

string Log; //for printing log

SymbolTable st(10);

//functions for error handling
void addError(string error, string lexeme){
    logout<<"Error at line# "<<line_count<<": "<<error<<" "<<lexeme<<endl;
    error_count++;
}

//functions for Uppercase letter
string toUpper(string s){
    string res="";
    for(int i=0;i<s.size();i++){
        res+=toupper(s[i]);
    }
    return res;
}

//functions for adding keywords
void addKeyword(string lexeme){
    string upperLexeme=toUpper(lexeme);
    tokenout<<"<"<<upperLexeme<<", "<<lexeme<<">"<<endl;
    logout<<"Line# "<<line_count<<": Token <" <<upperLexeme<<"> Lexeme "<<lexeme<<" found"<<endl;
}

//functions for adding numbers
void addNumber(string token,string lexeme){
    tokenout<<"<"<<token<<", "<<lexeme<<">"<<endl;
    logout<<"Line# "<<line_count<<": Token <"<<token<<"> Lexeme "<<lexeme<<" found"<<endl;
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

        tokenout<<"<CONST_CHAR, "<<s<<">"<<endl;
        logout<<"Line# "<<line_count<<": Token <CONST_CHAR> Lexeme "<<s<<" found"<<endl;
}

//functions for adding operators and punctuators
void addOp_Punc(string token, string lexeme){
    tokenout<<"<"<<token<<", "<<lexeme<<">"<<endl;
    logout<<"Line# "<<line_count<<": Token <"<<token<<"> Lexeme "<<lexeme<<" found"<<endl;
}

//functions for adding identifiers
void addID(string lexeme){
    tokenout<<"<ID, "<<lexeme<<">"<<endl;
    logout<<"Line# "<<line_count<<": Token <ID> Lexeme "<<lexeme<<" found"<<endl;
    bool flag=st.Insert(lexeme,"ID");
    if(flag){
        st.PrintAllScope();
    }
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
    tokenout<<"<"<<str_token<<", "<<s<<">"<<endl;
    logout<<"Line# "<<(line_count-store_line_count)<<": Token <"<<str_token<<"> Lexeme "<<str_log<<" found"<<endl;
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
    logout<<"Line# "<<(line_count-store_line_count)<<": Token <"<<token<<"> Lexeme "<<s<<" found"<<endl;
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
UNFINISHED_CHAR \'(.|\\.|\\\')?

%%

{WHITESPACE} { /* ignore */ }
{NEWLINE} {line_count++;}


if|else|for|do|int|float|void|switch|default|while|break|char|double|return|case|continue {
    addKeyword(yytext);
}


{INT} {addNumber("CONST_INT",yytext);}
{FLOAT} {addNumber("CONST_FLOAT",yytext);}
{TOO_MANY_DECIMAL_POINT} {addError("TOO_MANY_DECIMAL_POINTS",yytext);}
{ILL_FORMAT_NUMBER} {addError("ILLFORMED_NUMBER",yytext);}

{EMPTY_CHAR} {addError("EMPTY_CONST_CHAR",yytext);}
{CHAR} {addCharacter(yytext);}
{ESCAPE_CHAR} {addCharacter(yytext);}
{MULTI_CHAR} {addError("MULTICHAR_CONST_CHAR",yytext);}
{UNFINISHED_CHAR} {addError("UNFINISHED_CONST_CHAR",yytext);}

[+-]	{ addOp_Punc("ADDOP",yytext); }
[*/%]   { addOp_Punc("MULOP",yytext); }
"--"|"++"	{ addOp_Punc("INCOP",yytext); }
"<"|">"|"<="|">="|"=="|"!=" { addOp_Punc("RELOP",yytext); }
=	{ addOp_Punc("ASSIGNOP",yytext); }
"&&"|"||"	{ addOp_Punc("LOGICOP",yytext); }
&|"|"|"^"|"<<"|">>" { addOp_Punc("BITOP",yytext); }
!	{ addOp_Punc("NOT",yytext); }
"("	{ addOp_Punc("LPAREN",yytext); }
")"	{ addOp_Punc("RPAREN",yytext); }
"{"	{ 
    addOp_Punc("LCURL",yytext); 
    st.EnterScope();
    }
"}"	{ 
    addOp_Punc("RCURL",yytext); 
    st.ExitScope();
    }
"["	{ addOp_Punc("LSQUARE",yytext); }
"]"	{ addOp_Punc("RSQUARE",yytext); }
\,	{ addOp_Punc("COMMA",yytext); }
\;	{ addOp_Punc("SEMICOLON",yytext); }


{ID} {addID(yytext);}	
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

<MULTI_COMMENT_STATE>{NEWLINE} { //newline encountered in comment
    line_count++;
    store_line_count++;
    Log += yytext;
}

<MULTI_COMMENT_STATE>[<<EOF>>] {
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

int main(int argc, char** argv) {
	if(argc!=2){
		cout<<"Please provide input file name and try again\n";
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		cout<<"Cannot open specified file\n";
		return 0;
	}
	
	logout.open("1905088_log.txt");
	tokenout.open("1905088_token.txt");

	yyin= fin;
	yylex();
	fclose(yyin);

    //Outputting the rest & closing the files
    st.PrintAllScope();
    logout<<"Total lines: "<<line_count<<endl;
    logout<<"Total errors: "<<error_count<<endl;
    
    tokenout.close();
    logout.close();
	
	return 0;
}
