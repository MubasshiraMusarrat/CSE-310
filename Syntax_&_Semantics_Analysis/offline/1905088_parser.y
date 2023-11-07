%{
#include<bits/stdc++.h>
#include<iostream>
#include<string>
#include<fstream>
#include "1905088_Symbol_Table.h"

using namespace std;

int yyparse(void);
int yylex(void);

//bool DEBUG = false;

extern FILE *yyin;
FILE *fp;
extern int line_count;
extern int error_count;
extern string toUpper(const string &s);

SymbolTable st = SymbolTable(11);

vector <pair<string, string>> param_list;
vector <string> decL;
vector <SymbolInfo*> arg_list;
string varType;
string funcName;
string returnType;

bool isFuncDec = false;
bool isFuncDef = false;
bool hasReturn = false;
bool isIDDec = false;
bool zeroFlag = false;

ofstream textlog;
ofstream errorlog;
ofstream parselog;

void yyerror(char *s)
{
	errorlog<<"Line#  "<<line_count<<": "<<"Syntax error"<<endl;
	error_count++;
}

void typeCheck(string ltype,string rtype){
	if(ltype == "UNDECLARED" || rtype == "UNDECLARED"){
		return;
	}
	if(ltype != rtype){
		if(ltype[ltype.size()-1] == '*'){
			errorlog<<"Line#  "<<line_count<<": "<<"Type mismatch"<<endl;
			error_count++;
		}
		else if(rtype[rtype.size()-1] == '*'){
			errorlog<<"Line#  "<<line_count<<": "<<"Type mismatch"<<endl;
			error_count++;
		}
		else{
			errorlog<<"Line# "<<line_count<<": "<<"Type mismatch"<<endl;
			error_count++;
		}
	}
}

string typeCast(string ltype,string rtype){
	if(ltype[ltype.size()-1]=='*' || rtype[rtype.size()-1]=='*'){
		typeCheck(ltype,rtype);
	}
	else if(ltype == "CONST_FLOAT"){
		return "CONST_FLOAT";
	}
	else if(ltype == "CONST_INT" && (rtype == "CONST_INT" || rtype == "CONST_CHAR")){
		return "CONST_INT";
	}
	else
		typeCheck(ltype,rtype);

	return ltype;
}

string typeCast2(string ltype,string rtype){
	if(ltype[ltype.size()-1]=='*' || rtype[rtype.size()-1]=='*'){
		typeCheck(ltype,rtype);
	}
	else if(ltype == "CONST_FLOAT" || rtype == "CONST_FLOAT"){
		return "CONST_FLOAT";
	}
	else if(ltype == "CONST_INT" && (rtype == "CONST_INT" || rtype == "CONST_CHAR")){
		return "CONST_INT";
	}
	else
		typeCheck(ltype,rtype);

	return ltype;
}

bool checkVoidFunc(SymbolInfo* si){
	if(si->getType() == "VOID"){
		errorlog<<"Line#  "<<line_count<<": "<<"Void function used in expression"<<endl;
		error_count++;
		return true;
	}
	else{
		return false;
	}
}

void insertID(SymbolInfo* si, string type) {
	string name = si->getName();
	type = "CONST_" + toUpper(type);
	bool flag = st.Insert(name, "ID" , type );
	if(!flag){
		errorlog<<"Line#  "<<line_count<<": "<<"Conflicting types for '"<<name<<"'"<<endl;
		error_count++;
		//if(si->getFunc()){
			//errorlog<<"Line#  "<<line_count<<": "<<name<<" is a function"<<endl;}
	}
	else{
		decL.push_back(name);
	}
	
}

void handleFuncDef(){
	if(isIDDec){ return; }
	if(isFuncDef){
		errorlog<<"Line#  "<<line_count<<": "<<"'"+funcName<<"' redeclared as different kind of symbol"<<endl;
		error_count++;
		return;
	}
	Function* f = (Function*)st.LookUp(funcName);
	f->setDefined(true);
	if(f->getReturnType() != returnType){
		//errorlog<<"Line#  "<<line_count<<": "<<"Return type mismatch"<<endl;
		//error_count++;
	}
	else{
		if(f->getName() != "main"){
			if(f->getReturnType() != "CONST_VOID" && !hasReturn){
				errorlog<<"Line#  "<<line_count<<": "<<"No return statement of function '"<<funcName<<"'"<<endl;
				error_count++;
			}
		}
	}
}

void handleFunDec(string name, string r){
	Function* f;
	funcName = name;
	returnType = r;
	bool flag = st.Insert(funcName,"ID", true);
 if(!flag){
	SymbolInfo* si = st.LookUp(funcName);
	if(si->getFunc()){
		isFuncDec = true;
		f = (Function*)si;
		if(f->getDefined()){
			isFuncDef = true;
		}
	}
	else{
		errorlog<<"Line#  "<<line_count<<": "<<"'"<<funcName<<"' redeclared as different kind of symbol"<<endl;
		error_count++;
		isIDDec = true;
	}
 }
 else{
	SymbolInfo* si = st.LookUp(funcName);
	f = (Function*)si;
	f->setReturnType(returnType);
	for(int i=0;i<param_list.size();i++){
		if(param_list[i].first == ""){
			errorlog<<"Line#  "<<line_count<<": "<<"Parameter "<<i+1<<" of Function: "<<funcName<<" has no name"<<endl;
			error_count++;
		}
		f->addParam("CONST_"+toUpper(param_list[i].second));
	}
 }
}

void PrintTree(SymbolInfo* a, int level){
if(a != NULL){
	for(int i=1;i<=level;i++){
		parselog<<"  ";
	}
	if(!(a->getisLeaf()))
	{
		if(a->getName()=="int" || a->getName()=="float" || a->getName()=="void" || a->getName()=="char")
			parselog<<"Type_specifier : "<<toUpper(a->getName())<<"\t<Line: "<<a->getStartLine()<<"-"<<a->getEndLine()<<">"<<endl;
		else
			parselog<<a->getName()<<"\t<Line: "<<a->getStartLine()<<"-"<<a->getEndLine()<<">"<<endl;
	}
	else
	parselog<<a->getName()<<"\t<Line: "<<a->getStartLine()<<">"<<endl;

	for(SymbolInfo* si : a->getChildren()){
		PrintTree(si,level+1);
	}
  }
}

void deleteTree(SymbolInfo* a){
	if(a != NULL){
		for(SymbolInfo* si : a->getChildren()){
			deleteTree(si);
		}
		delete a;
	}
}
%}

%union
{
	SymbolInfo *symbol;
}

%token<symbol> IF ELSE FOR DO INT FLOAT VOID SWITCH DEFAULT WHILE BREAK CHAR DOUBLE RETURN CASE CONTINUE PRINTLN 
%token<symbol> CONST_INT CONST_FLOAT 
%token<symbol> CONST_CHAR 
%token<symbol> ADDOP MULOP RELOP LOGICOP INCOP DECOP
%token<symbol> ASSIGNOP NOT LPAREN RPAREN LCURL RCURL LSQUARE RSQUARE SEMICOLON COMMA
%token<symbol> ID
%token<symbol> STRING

%type<symbol> start program unit func_prototype func_declaration func_definition parameter_list compound_statement var_declaration
%type<symbol> type_specifier declaration_list statements statement expression_statement variable expression
%type<symbol> logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments

%left POSTFIX_INCOP
%left POSTFIX_DECOP
%right PREFIX_INCOP
%right PREFIX_DECOP

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE


%%

start : program {
		textlog<<"start\t: program\n";
		
		$$ = new SymbolInfo("start : program", "VARIABLE");
		$$->setStartLine($1->getStartLine());
		$$->setEndLine($1->getEndLine());
		$$->addChild(new SymbolInfo($1));
		PrintTree($$,0);

		st.PrintAllScope();
		st.ExitScope();
		textlog<<"Total lines: "<<line_count<<endl;
		textlog<<"Total errors: "<<error_count<<endl;

		// deleteTree($$);
		delete $1;
	}
	;

program : program unit {
	textlog<<"program\t: program unit\n";
	$$ = new SymbolInfo("program : program unit", "VARIABLE");

	$$->setStartLine($1->getStartLine());
	$$->setEndLine($2->getEndLine());
	$$->addChild(new SymbolInfo($1));
	$$->addChild(new SymbolInfo($2));

	delete $1;
	delete $2;
}
	| unit {
	textlog<<"program\t: unit\n";
	$$ = new SymbolInfo("program : unit", $1->getType());

	$$->setStartLine($1->getStartLine());
	$$->setEndLine($1->getEndLine());
	$$->addChild(new SymbolInfo($1));
	}
	;
	
unit : var_declaration {
	textlog<<"unit\t: var_declaration\n";
	$$ = new SymbolInfo("unit : var_declaration", $1->getType());

	$$->setStartLine($1->getStartLine());
	$$->setEndLine($1->getEndLine());
	$$->addChild(new SymbolInfo($1));

	delete $1;
}
     | func_declaration {
	textlog<<"unit\t: func_declaration\n";
	$$ = new SymbolInfo("unit : func_declaration", $1->getType());

	$$->setStartLine($1->getStartLine());
	$$->setEndLine($1->getEndLine());
	$$->addChild(new SymbolInfo($1));

	delete $1;
	}
     | func_definition {
	textlog<<"unit\t: func_definition\n";
	$$ = new SymbolInfo("unit : func_definition", $1->getType());

	$$->setStartLine($1->getStartLine());
	$$->setEndLine($1->getEndLine());
	$$->addChild(new SymbolInfo($1));

	delete $1;
	}
;

 func_prototype: type_specifier ID LPAREN parameter_list RPAREN {
	string r = "CONST_" + toUpper($1->getName());
	handleFunDec($2->getName(),r);
	$$ = new SymbolInfo("func_definition : type_specifier ID LPAREN parameter_list RPAREN", "parameter_list");

	SymbolInfo* temp = new SymbolInfo($2);
	temp->setisLeaf(true);
	temp->setName("ID : "+$2->getName());
	temp->setStartLine(line_count);
	temp->setEndLine(line_count);
	temp->addChild(NULL);

	SymbolInfo* temp2 = new SymbolInfo($3);
	temp2->setisLeaf(true);
	temp2->setName("LPAREN : "+$3->getName());
	temp2->setStartLine(line_count);
	temp2->setEndLine(line_count);
	temp2->addChild(NULL);

	SymbolInfo* temp3 = new SymbolInfo($5);
	temp3->setisLeaf(true);
	temp3->setName("RPAREN : "+$5->getName());
	temp3->setStartLine(line_count);
	temp3->setEndLine(line_count);
	temp3->addChild(NULL);

	$$->setStartLine($1->getStartLine());
	$$->setEndLine(temp3->getEndLine());
	$$->addChild(new SymbolInfo($1));
	$$->addChild(temp);
	$$->addChild(temp2);
	$$->addChild(new SymbolInfo($4));
	$$->addChild(temp3);

	delete $1;
	delete $2;
	delete $3;
	delete $4;
	delete $5;
 }
| type_specifier ID LPAREN parameter_list error RPAREN {
	string r = "CONST_" + toUpper($1->getName());
	handleFunDec($2->getName(),r);
	$$ = new SymbolInfo("function_definition : type_specifier ID LPAREN parameter_list error RPAREN", "parameter_list");

	SymbolInfo* temp = new SymbolInfo($2);
	temp->setisLeaf(true);
	temp->setName("ID : "+$2->getName());
	temp->setStartLine(line_count);
	temp->setEndLine(line_count);
	temp->addChild(NULL);

	SymbolInfo* temp2 = new SymbolInfo($3);
	temp2->setisLeaf(true);
	temp2->setName("LPAREN : "+$3->getName());
	temp2->setStartLine(line_count);
	temp2->setEndLine(line_count);
	temp2->addChild(NULL);

	SymbolInfo* temp3 = new SymbolInfo($6);
	temp3->setisLeaf(true);
	temp3->setName("RPAREN : "+$6->getName());
	temp3->setStartLine(line_count);
	temp3->setEndLine(line_count);
	temp3->addChild(NULL);

	$$->setStartLine($1->getStartLine());
	$$->setEndLine(temp3->getEndLine());
	$$->addChild(new SymbolInfo($1));
	$$->addChild(temp);
	$$->addChild(temp2);
	$$->addChild(new SymbolInfo($4));
	$$->addChild(temp3);

	delete $1;
	delete $2;
	delete $3;
	delete $4;
	delete $6;
}
| type_specifier ID LPAREN RPAREN {
	string r = "CONST_" + toUpper($1->getName());
	handleFunDec($2->getName(),r);
	$$ = new SymbolInfo("function_definition : type_specifier ID LPAREN RPAREN", "");

	SymbolInfo* temp = new SymbolInfo($2);
	temp->setisLeaf(true);
	temp->setName("ID : "+$2->getName());
	temp->setStartLine(line_count);
	temp->setEndLine(line_count);
	temp->addChild(NULL);

	SymbolInfo* temp2 = new SymbolInfo($3);
	temp2->setisLeaf(true);
	temp2->setName("LPAREN : "+$3->getName());
	temp2->setStartLine(line_count);
	temp2->setEndLine(line_count);
	temp2->addChild(NULL);

	SymbolInfo* temp3 = new SymbolInfo($4);
	temp3->setisLeaf(true);
	temp3->setName("RPAREN : "+$4->getName());
	temp3->setStartLine(line_count);
	temp3->setEndLine(line_count);
	temp3->addChild(NULL);

	$$->setStartLine($1->getStartLine());
	$$->setEndLine(temp3->getEndLine());
	$$->addChild(new SymbolInfo($1));
	$$->addChild(temp);
	$$->addChild(temp2);
	$$->addChild(temp3);
	
	delete $1;
	delete $2;
	delete $3;
	delete $4;
}
;  

func_declaration : func_prototype SEMICOLON {
	textlog<<"func_declaration\t: type_specifier ID LPAREN" +$1->getType()+ "RPAREN SEMICOLON\n";
	st.EnterScope();
	st.ExitScope();
	$$ = new SymbolInfo("func_declaration : type_specifier ID LPAREN" +$1->getType()+ "RPAREN SEMICOLON", "VARIABLE");
	if(isFuncDec){
		errorlog<<"Line#  "<<line_count<<": "<<"Conflicting types for '"+funcName<<"'"<<endl;
		error_count++;
	}

	SymbolInfo* temp = new SymbolInfo($2);
	temp->setisLeaf(true);
	temp->setName("SEMICOLON : ;");
	temp->setStartLine(line_count);
	temp->setEndLine(line_count);
	temp->addChild(NULL);

	$$->setStartLine($1->getStartLine());
	$$->setEndLine(temp->getEndLine());
	for(int i=0; i<$1->getChildren().size(); i++){
		$$->addChild(new SymbolInfo($1->getChildren()[i]));
	}
	$$->addChild(temp);

	isIDDec = false;
	isFuncDec = false;
	isFuncDef = false;
	funcName.clear();
	returnType.clear();
	param_list.clear();
	delete $1;
	delete $2;
}
| func_prototype error {
	textlog<<"func_declaration\t: type_specifier ID LPAREN" +$1->getType()+ "RPAREN\n";
	st.EnterScope();
	st.ExitScope();
	$$ = new SymbolInfo("func_declaration : type_specifier ID LPAREN" +$1->getType()+ "RPAREN SEMICOLON", "VARIABLE");
	if(isFuncDec){
		errorlog<<"Line#  "<<line_count<<": "<<"Conflicting types for '"+funcName<<"'"<<endl;
		error_count++;
	}

	$$->setStartLine($1->getStartLine());
	$$->setEndLine($1->getEndLine());
	for(int i=0; i<$1->getChildren().size(); i++){
		$$->addChild(new SymbolInfo($1->getChildren()[i]));
	}
	
	isIDDec = false;
	isFuncDec = false;
	isFuncDef = false;
	funcName.clear();
	returnType.clear();
	param_list.clear();
}
;
		 
func_definition : func_prototype compound_statement {
	textlog<<"func_definition\t: type_specifier ID LPAREN" << $1->getType() << "RPAREN compound_statement\n";
	$$ = new SymbolInfo("func_definition : type_specifier ID LPAREN"+$1->getType()+"RPAREN compound_statement", "VARIABLE");
	handleFuncDef();

	$$->setStartLine($1->getStartLine());
	$$->setEndLine($2->getEndLine());
	for(int i=0; i<$1->getChildren().size(); i++){
		$$->addChild(new SymbolInfo($1->getChildren()[i]));
	}
	$$->addChild(new SymbolInfo($2));

	isIDDec = false;
	isFuncDec = false;
	isFuncDef = false;
	hasReturn = false;
	funcName.clear();
	returnType.clear();
	param_list.clear();
	delete $1;
	delete $2;
}
;

enter_scope : {
	if(isFuncDec){
		Function* f = (Function*)st.LookUp(funcName);
		if(f->getReturnType() != returnType){
			errorlog<<"Line#  "<<line_count<<": "<<"Conflicting types for '"+funcName<<"'"<<endl;
			error_count++;
		}
		if(f->getParamList().size() != param_list.size()){
			errorlog<<"Line#  "<<line_count<<": "<<"Conflicting types for '"+funcName<<"'"<<endl;
			error_count++;
		}
		else{
			for(int i=0;i<f->getParamList().size();i++){
				if(("CONST_"+toUpper(param_list[i].second)) != f->getParamList()[i]){
					errorlog<<"Line#  "<<line_count<<": "<<"Parameter type mismatch in "+funcName<<endl;
					error_count++;
				}
				if(param_list[i].first == ""){
					errorlog<<"Line#  "<<line_count<<": "<<"warning: Parameter name missing in "+funcName<<endl;
					error_count++;
				}
			}
		}
	}
	st.EnterScope();
	for(int i=0; i<param_list.size(); i++){
		if(param_list[i].first != "" && st.Insert(param_list[i].first, "ID", "CONST_"+toUpper(param_list[i].second)) == false){
			errorlog<<"Line#  "<<line_count<<": "<<"Redefinition  of parameter '"<<param_list[i].first<<"'"<<endl;
			error_count++;
		}
	}
}
;

parameter_list  : parameter_list COMMA type_specifier ID {
	textlog<<"parameter_list\t: parameter_list COMMA type_specifier ID\n";
	param_list.push_back(make_pair($4->getName(),$3->getName()));
	if($3->getName() == "void"){
		errorlog<<"Line#  "<<line_count<<": "<<"Void can not be parameter"<<endl;
		error_count++;
	}
	$$ = new SymbolInfo("parameter_list : parameter_list COMMA type_specifier ID", "VARIABLE");

	SymbolInfo* temp = new SymbolInfo($2);
	temp->setisLeaf(true);
	temp->setName("COMMA : ,");
	temp->setStartLine(line_count);
	temp->setEndLine(line_count);
	temp->addChild(NULL);

	SymbolInfo* temp2 = new SymbolInfo($4);
	temp2->setisLeaf(true);
	temp2->setName("ID : "+$4->getName());
	temp2->setStartLine(line_count);
	temp2->setEndLine(line_count);
	temp2->addChild(NULL);

	$$->setStartLine($1->getStartLine());
	$$->setEndLine(temp2->getEndLine());
	$$->addChild(new SymbolInfo($1));
	$$->addChild(temp);
	$$->addChild(new SymbolInfo($3));
	$$->addChild(temp2);

	delete $1;
	delete $2;
	delete $3;
	delete $4;
}
		| parameter_list COMMA type_specifier {
	textlog<<"parameter_list\t: parameter_list COMMA type_specifier\n";
	param_list.push_back(make_pair("", $3->getName()));
	if($3->getName() == "void"){
		errorlog<<"Line#  "<<line_count<<": "<<"Void can not be parameter"<<endl;
		error_count++;
	}
	$$ = new SymbolInfo("parameter_list : parameter_list COMMA type_specifier", "VARIABLE");

	SymbolInfo* temp = new SymbolInfo($2);
	temp->setisLeaf(true);
	temp->setName("COMMA : ,");
	temp->setStartLine(line_count);
	temp->setEndLine(line_count);
	temp->addChild(NULL);

	$$->setStartLine($1->getStartLine());
	$$->setEndLine($3->getEndLine());
	$$->addChild(new SymbolInfo($1));
	$$->addChild(temp);
	$$->addChild(new SymbolInfo($3));

	delete $1;
	delete $2;
	delete $3;
}
		| parameter_list COMMA error {
	textlog<<"parameter_list\t: parameter_list COMMA\n";
	$$ = new SymbolInfo("parameter_list : parameter_list COMMA", $1->getType());

	$$->setStartLine($1->getStartLine());
	$$->setEndLine($1->getEndLine());
	$$->addChild(new SymbolInfo($1));
}
 		| type_specifier ID {
	textlog<<"parameter_list\t: type_specifier ID\n";
	param_list.push_back(make_pair($2->getName(),$1->getName()));
	if($1->getName() == "void"){
		errorlog<<"Line#  "<<line_count<<": "<<"Void can not be parameter"<<endl;
		error_count++;
	}
	$$ = new SymbolInfo("parameter_list : type_specifier ID", "VARIABLE");

	SymbolInfo* temp = new SymbolInfo($1);
	temp->setisLeaf(true);
	temp->setName("ID : "+$2->getName());
	temp->setStartLine(line_count);
	temp->setEndLine(line_count);
	temp->addChild(NULL);

	$$->setStartLine($1->getStartLine());
	$$->setEndLine(temp->getEndLine());
	$$->addChild(new SymbolInfo($1));
	$$->addChild(temp);

	delete $1;
	delete $2;
}
		| type_specifier {
	textlog<<"parameter_list\t: type_specifier\n";
	param_list.push_back(make_pair("", $1->getName()));
	if($1->getName() == "void"){
		errorlog<<"Line#  "<<line_count<<": "<<"Void can not be parameter"<<endl;
		error_count++;
	}
	$$ = new SymbolInfo("parameter_list : type_specifier", $1->getType());

	$$->setStartLine($1->getStartLine());
	$$->setEndLine($1->getEndLine());
	$$->addChild(new SymbolInfo($1));
}
;

compound_statement : LCURL enter_scope statements RCURL {
	textlog<<"compound_statement\t: LCURL statements RCURL\n";
	$$ = new SymbolInfo("compound_statement : LCURL statements RCURL", "VARIABLE");

	SymbolInfo* temp = new SymbolInfo($1);
	temp->setisLeaf(true);
	temp->setName("LCURL : {");
	temp->setStartLine(line_count);
	temp->setEndLine(line_count);
	temp->addChild(NULL);

	SymbolInfo* temp2 = new SymbolInfo($4);
	temp2->setisLeaf(true);
	temp2->setName("RCURL : }");
	temp2->setStartLine(line_count);
	temp2->setEndLine(line_count);
	temp2->addChild(NULL);

	$$->setStartLine(temp->getStartLine());
	$$->setEndLine(temp2->getEndLine());
	$$->addChild(temp);
	$$->addChild(new SymbolInfo($3));
	$$->addChild(temp2);

	st.PrintAllScope();
	st.ExitScope();
	delete $1;
	delete $3;
	delete $4;
}
 		
 	| LCURL enter_scope RCURL {
	textlog<<"compound_statement\t: LCURL RCURL\n";
	$$ = new SymbolInfo("compound_statement : LCURL RCURL", "VARIABLE");

	SymbolInfo* temp = new SymbolInfo($1);
	temp->setisLeaf(true);
	temp->setName("LCURL : {");
	temp->setStartLine(line_count);
	temp->setEndLine(line_count);
	temp->addChild(NULL);

	SymbolInfo* temp2 = new SymbolInfo($3);
	temp2->setisLeaf(true);
	temp2->setName("RCURL : }");
	temp2->setStartLine(line_count);
	temp2->setEndLine(line_count);
	temp2->addChild(NULL);

	$$->setStartLine(temp->getStartLine());
	$$->setEndLine(temp2->getEndLine());
	$$->addChild(temp);
	$$->addChild(temp2);

	st.PrintAllScope();
	st.ExitScope();

	delete $1;
	delete $3;
	}
 	;
 		    
var_declaration : type_specifier declaration_list SEMICOLON {
	textlog<<"var_declaration\t: type_specifier declaration_list SEMICOLON\n";
	$$ = new SymbolInfo("var_declaration : type_specifier declaration_list SEMICOLON","VARIABLE");
	if(varType == "void"){
		errorlog<<"Line#  "<<line_count<<": "<<"Variable or field ";
		for(int i=0;i<decL.size()-1;i++){
			errorlog<<"'"<<decL[i]<<"',";
		}
		errorlog<<"'"<<decL[decL.size()-1]<<"' declared void"<<endl;
		error_count++;
	}

	SymbolInfo* temp = new SymbolInfo($3);
	temp->setisLeaf(true);
	temp->setName("SEMICOLON : ;");
	temp->setStartLine(line_count);
	temp->setEndLine(line_count);
	temp->addChild(NULL);

	$$->setStartLine($1->getStartLine());
	$$->setEndLine(temp->getEndLine());
	$$->addChild(new SymbolInfo($1));
	$$->addChild(new SymbolInfo($2));
	$$->addChild(temp);

	varType.clear();
	decL.clear();
	delete $1;
	delete $2;
	delete $3;
}
 ;
 		 
type_specifier	: INT {
	textlog<<"type_specifier\t: INT\n";
	varType = "int";
	$$ = new SymbolInfo("int","VARIABLE");

	SymbolInfo* temp = new SymbolInfo($1);
	temp->setisLeaf(true);
	temp->setName("INT : int");
	temp->setStartLine(line_count);
	temp->setEndLine(line_count);
	temp->addChild(NULL);

	$$->setStartLine(temp->getStartLine());
	$$->setEndLine(temp->getEndLine());
	$$->addChild(temp);

	delete $1;
}
 		| FLOAT {
			textlog<<"type_specifier\t: FLOAT\n";
			varType = "float";
			$$ = new SymbolInfo("float","VARIABLE");

			SymbolInfo* temp = new SymbolInfo($1);
			temp->setisLeaf(true);
			temp->setName("FLOAT : float");
			temp->setStartLine(line_count);
			temp->setEndLine(line_count);
			temp->addChild(NULL);

			$$->setStartLine(temp->getStartLine());
			$$->setEndLine(temp->getEndLine());
			$$->addChild(temp);

			delete $1;
		}
 		| VOID {
			textlog<<"type_specifier\t: VOID\n";
			varType = "void";
			$$ = new SymbolInfo("void","VARIABLE");

			SymbolInfo* temp = new SymbolInfo($1);
			temp->setisLeaf(true);
			temp->setName("VOID : void");
			temp->setStartLine(line_count);
			temp->setEndLine(line_count);
			temp->addChild(NULL);

			$$->setStartLine(temp->getStartLine());
			$$->setEndLine(temp->getEndLine());
			$$->addChild(temp);

			delete $1;
		}
 		;
 		
declaration_list : declaration_list COMMA ID {
	textlog<<"declaration_list\t: declaration_list COMMA ID\n";
	$$ = new SymbolInfo("declaration_list : declaration_list COMMA ID","VARIABLE");
	insertID($3, varType);

	SymbolInfo* temp = new SymbolInfo($2);
	temp->setisLeaf(true);
	temp->setName("COMMA : ,");
	temp->setStartLine(line_count);
	temp->setEndLine(line_count);
	temp->addChild(NULL);

	SymbolInfo* temp2 = new SymbolInfo($3);
	temp2->setisLeaf(true);
	temp2->setName("ID : "+$3->getName());
	temp2->setStartLine(line_count);
	temp2->setEndLine(line_count);
	temp2->addChild(NULL);

	$$->setStartLine($1->getStartLine());
	$$->setEndLine(temp2->getEndLine());
	$$->addChild(new SymbolInfo($1));
	$$->addChild(temp);
	$$->addChild(temp2);

	delete $1;
	delete $2;
	delete $3;
}
		  | declaration_list error ID {
			$$ = new SymbolInfo("declaration_list : declaration_list ID", $1->getType());

			SymbolInfo* temp = new SymbolInfo($3);
			temp->setisLeaf(true);
			temp->setName("ID : "+$3->getName());
			temp->setStartLine(line_count);
			temp->setEndLine(line_count);
			temp->addChild(NULL);

			$$->setStartLine($1->getStartLine());
			$$->setEndLine(temp->getEndLine());
			$$->addChild(new SymbolInfo($1));
			$$->addChild(temp);

		  }
 		  | declaration_list COMMA ID LSQUARE CONST_INT RSQUARE {
			textlog<<"declaration_list\t: declaration_list COMMA ID LSQUARE CONST_INT RSQUARE\n";
			$$ = new SymbolInfo("declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE","VARIABLE");
			$3->setArr(true);
			$3->setArrSize($5->getName());
			insertID($3, varType+"*");

			SymbolInfo* temp = new SymbolInfo($2);
			temp->setisLeaf(true);
			temp->setName("COMMA : ,");
			temp->setStartLine(line_count);
			temp->setEndLine(line_count);
			temp->addChild(NULL);

			SymbolInfo* temp2 = new SymbolInfo($3);
			temp2->setisLeaf(true);
			temp2->setName("ID : "+$3->getName());
			temp2->setStartLine(line_count);
			temp2->setEndLine(line_count);
			temp2->addChild(NULL);

			SymbolInfo* temp3 = new SymbolInfo($4);
			temp3->setisLeaf(true);
			temp3->setName("LSQUARE : [");
			temp3->setStartLine(line_count);
			temp3->setEndLine(line_count);
			temp3->addChild(NULL);

			SymbolInfo* temp4 = new SymbolInfo($5);
			temp4->setisLeaf(true);
			temp4->setName("CONST_INT : "+$5->getName());
			temp4->setStartLine(line_count);
			temp4->setEndLine(line_count);
			temp4->addChild(NULL);

			SymbolInfo* temp5 = new SymbolInfo($6);
			temp5->setisLeaf(true);
			temp5->setName("RSQUARE : ]");
			temp5->setStartLine(line_count);
			temp5->setEndLine(line_count);
			temp5->addChild(NULL);

			$$->setStartLine($1->getStartLine());
			$$->setEndLine(temp5->getEndLine());
			$$->addChild(new SymbolInfo($1));
			$$->addChild(temp);
			$$->addChild(temp2);
			$$->addChild(temp3);
			$$->addChild(temp4);
			$$->addChild(temp5);

			delete $1;
			delete $2;
			delete $3;
			delete $4;
			delete $5;
			delete $6;
		  }
		  | declaration_list COMMA ID LSQUARE error RSQUARE {
			$$ = new SymbolInfo("declaration_list : declaration_list COMMA ID LSQUARE RSQUARE","VARIABLE");
			$3->setArr(true);
			$3->setArrSize("0");
			insertID($3, varType+"*");
			errorlog<<"Line#  "<<line_count<<": "<<"Array size missing"<<endl;
			error_count++;

			SymbolInfo* temp = new SymbolInfo($2);
			temp->setisLeaf(true);
			temp->setName("COMMA : ,");
			temp->setStartLine(line_count);
			temp->setEndLine(line_count);
			temp->addChild(NULL);

			SymbolInfo* temp2 = new SymbolInfo($3);
			temp2->setisLeaf(true);
			temp2->setName("ID : "+$3->getName());
			temp2->setStartLine(line_count);
			temp2->setEndLine(line_count);
			temp2->addChild(NULL);

			SymbolInfo* temp3 = new SymbolInfo($4);
			temp3->setisLeaf(true);
			temp3->setName("LSQUARE : [");
			temp3->setStartLine(line_count);
			temp3->setEndLine(line_count);
			temp3->addChild(NULL);

			SymbolInfo* temp4 = new SymbolInfo($6);
			temp4->setisLeaf(true);
			temp4->setName("RSQUARE : ]");
			temp4->setStartLine(line_count);
			temp4->setEndLine(line_count);
			temp4->addChild(NULL);

			$$->setStartLine($1->getStartLine());
			$$->setEndLine(temp4->getEndLine());
			$$->addChild(new SymbolInfo($1));
			$$->addChild(temp);
			$$->addChild(temp2);
			$$->addChild(temp3);
			$$->addChild(temp4);

			delete $1;
			delete $2;
			delete $3;
			delete $4;
			delete $6;
		  }
 		  | ID {
			textlog<<"declaration_list\t: ID\n";
			insertID($1, varType);
			$$ = new SymbolInfo("declaration_list : ID", $1->getType());

			SymbolInfo* temp = new SymbolInfo($1);
			temp->setisLeaf(true);
			temp->setName("ID : "+$1->getName());
			temp->setStartLine(line_count);
			temp->setEndLine(line_count);
			temp->addChild(NULL);

			$$->setStartLine(temp->getStartLine());
			$$->setEndLine(temp->getEndLine());
			$$->addChild(temp);
		  }
 		  | ID LSQUARE CONST_INT RSQUARE {
			textlog<<"declaration_list\t: ID LSQUARE CONST_INT RSQUARE\n";
			$$ = new SymbolInfo("declaration_list : ID LSQUARE CONST_INT RSQUARE","VARIABLE");
			$1->setArr(true);
			$1->setArrSize($3->getName());
			insertID($1, varType+"*");

			SymbolInfo* temp = new SymbolInfo($1);
			temp->setisLeaf(true);
			temp->setName("ID : "+$1->getName());
			temp->setStartLine(line_count);
			temp->setEndLine(line_count);
			temp->addChild(NULL);

			SymbolInfo* temp2 = new SymbolInfo($2);
			temp2->setisLeaf(true);
			temp2->setName("LSQUARE : [");
			temp2->setStartLine(line_count);
			temp2->setEndLine(line_count);
			temp2->addChild(NULL);

			SymbolInfo* temp3 = new SymbolInfo($3);
			temp3->setisLeaf(true);
			temp3->setName("CONST_INT : "+$3->getName());
			temp3->setStartLine(line_count);
			temp3->setEndLine(line_count);
			temp3->addChild(NULL);

			SymbolInfo* temp4 = new SymbolInfo($4);
			temp4->setisLeaf(true);
			temp4->setName("RSQUARE : ]");
			temp4->setStartLine(line_count);
			temp4->setEndLine(line_count);
			temp4->addChild(NULL);

			$$->setStartLine(temp->getStartLine());
			$$->setEndLine(temp4->getEndLine());
			$$->addChild(temp);
			$$->addChild(temp2);
			$$->addChild(temp3);
			$$->addChild(temp4);

			delete $1;
			delete $2;
			delete $3;
			delete $4;
		  }
		  | ID LSQUARE error RSQUARE {
			$$ = new SymbolInfo("declaration_list : ID LSQUARE RSQUARE","VARIABLE");
			$1->setArr(true);
			$1->setArrSize("0");
			insertID($1, varType+"*");

			SymbolInfo* temp = new SymbolInfo($1);
			temp->setisLeaf(true);
			temp->setName("ID : "+$1->getName());
			temp->setStartLine(line_count);
			temp->setEndLine(line_count);
			temp->addChild(NULL);

			SymbolInfo* temp2 = new SymbolInfo($2);
			temp2->setisLeaf(true);
			temp2->setName("LSQUARE : [");
			temp2->setStartLine(line_count);
			temp2->setEndLine(line_count);
			temp2->addChild(NULL);

			SymbolInfo* temp3 = new SymbolInfo($4);
			temp3->setisLeaf(true);
			temp3->setName("RSQUARE : ]");
			temp3->setStartLine(line_count);
			temp3->setEndLine(line_count);
			temp3->addChild(NULL);

			$$->setStartLine(temp->getStartLine());
			$$->setEndLine(temp3->getEndLine());
			$$->addChild(temp);
			$$->addChild(temp2);
			$$->addChild(temp3);

			delete $1;
			delete $2;
			delete $4;
		  }
 		  ;
 		  
statements : statement {
	textlog<<"statements\t: statement\n";
	$$ = new SymbolInfo("statements : statement", $1->getType());

	$$->setStartLine($1->getStartLine());
	$$->setEndLine($1->getEndLine());
	$$->addChild(new SymbolInfo($1));

	delete $1;
}
	   | statements statement {
			textlog<<"statements\t: statements statement\n";
			$$ = new SymbolInfo("statements : statements statement","VARIABLE");

			$$->setStartLine($1->getStartLine());
			$$->setEndLine($2->getEndLine());
			$$->addChild(new SymbolInfo($1));
			$$->addChild(new SymbolInfo($2));

			delete $1;
			delete $2;
	   }
	   ;
	   
statement : var_declaration {
			textlog<<"statement\t: var_declaration\n";
			$$ = new SymbolInfo("statement : var_declaration", $1->getType());

			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild(new SymbolInfo($1));

			delete $1;
}
	  | expression_statement {
			textlog<<"statement\t: expression_statement\n";
			$$ = new SymbolInfo("statement : expression_statement", $1->getType());

			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild(new SymbolInfo($1));

			delete $1;
	  }
	  | compound_statement {
			textlog<<"statement\t: compound_statement\n";
			$$ = new SymbolInfo("statement : compound_statement", $1->getType());

			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild(new SymbolInfo($1));

			delete $1;
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement {
		textlog<<"statement\t: FOR LPAREN expression_statement expression_statement expression RPAREN statement\n";
		string name = "statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement";
		$$ = new SymbolInfo(name,"VARIABLE");

		SymbolInfo* temp = new SymbolInfo($1);
		temp->setisLeaf(true);
		temp->setName("FOR : for");
		temp->setStartLine(line_count);
		temp->setEndLine(line_count);
		temp->addChild(NULL);

		SymbolInfo* temp2 = new SymbolInfo($2);
		temp2->setisLeaf(true);
		temp2->setName("LPAREN : (");
		temp2->setStartLine(line_count);
		temp2->setEndLine(line_count);
		temp2->addChild(NULL);

		SymbolInfo* temp3 = new SymbolInfo($6);
		temp3->setisLeaf(true);
		temp3->setName("RPAREN : )");
		temp3->setStartLine(line_count);
		temp3->setEndLine(line_count);
		temp3->addChild(NULL);

		$$->setStartLine(temp->getStartLine());
		$$->setEndLine($7->getEndLine());
		$$->addChild(temp);
		$$->addChild(temp2);
		$$->addChild(new SymbolInfo($3));
		$$->addChild(new SymbolInfo($4));
		$$->addChild(new SymbolInfo($5));
		$$->addChild(temp3);
		$$->addChild(new SymbolInfo($7));

		delete $1;
		delete $2;
		delete $3;
		delete $4;
		delete $5;
		delete $6;
		delete $7;
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE{
		textlog<<"statement\t: IF LPAREN expression RPAREN statement\n";
		string name = "statement : IF LPAREN expression RPAREN statement";
		$$ = new SymbolInfo(name,"VARIABLE");

		SymbolInfo* temp = new SymbolInfo($1);
		temp->setisLeaf(true);
		temp->setName("IF : if");
		temp->setStartLine(line_count);
		temp->setEndLine(line_count);
		temp->addChild(NULL);

		SymbolInfo* temp2 = new SymbolInfo($2);
		temp2->setisLeaf(true);
		temp2->setName("LPAREN : (");
		temp2->setStartLine(line_count);
		temp2->setEndLine(line_count);
		temp2->addChild(NULL);

		SymbolInfo* temp3 = new SymbolInfo($4);
		temp3->setisLeaf(true);
		temp3->setName("RPAREN : )");
		temp3->setStartLine(line_count);
		temp3->setEndLine(line_count);
		temp3->addChild(NULL);

		$$->setStartLine(temp->getStartLine());
		$$->setEndLine($5->getEndLine());
		$$->addChild(temp);
		$$->addChild(temp2);
		$$->addChild(new SymbolInfo($3));
		$$->addChild(temp3);
		$$->addChild(new SymbolInfo($5));

		delete $1;
		delete $2;
		delete $3;
		delete $4;
		delete $5;
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement {
		textlog<<"statement\t: IF LPAREN expression RPAREN statement ELSE statement\n";
		string name = "statement : IF LPAREN expression RPAREN statement ELSE statement";
		$$ = new SymbolInfo(name,"VARIABLE");

		SymbolInfo* temp = new SymbolInfo($1);
		temp->setisLeaf(true);
		temp->setName("IF : if");
		temp->setStartLine(line_count);
		temp->setEndLine(line_count);
		temp->addChild(NULL);

		SymbolInfo* temp2 = new SymbolInfo($2);
		temp2->setisLeaf(true);
		temp2->setName("LPAREN : (");
		temp2->setStartLine(line_count);
		temp2->setEndLine(line_count);
		temp2->addChild(NULL);

		SymbolInfo* temp3 = new SymbolInfo($4);
		temp3->setisLeaf(true);
		temp3->setName("RPAREN : )");
		temp3->setStartLine(line_count);
		temp3->setEndLine(line_count);
		temp3->addChild(NULL);

		SymbolInfo* temp4 = new SymbolInfo($6);
		temp4->setisLeaf(true);
		temp4->setName("ELSE : else");
		temp4->setStartLine(line_count);
		temp4->setEndLine(line_count);
		temp4->addChild(NULL);

		$$->setStartLine(temp->getStartLine());
		$$->setEndLine($7->getEndLine());
		$$->addChild(temp);
		$$->addChild(temp2);
		$$->addChild(new SymbolInfo($3));
		$$->addChild(temp3);
		$$->addChild(new SymbolInfo($5));
		$$->addChild(temp4);
		$$->addChild(new SymbolInfo($7));
		
		delete $1;
		delete $2;
		delete $3;
		delete $4;
		delete $5;
		delete $6;
		delete $7;
	  }
	  | WHILE LPAREN expression RPAREN statement {
		textlog<<"statement\t: WHILE LPAREN expression RPAREN statement\n";
		string name = "statement : WHILE LPAREN expression RPAREN statement";
		$$ = new SymbolInfo(name,"VARIABLE");

		SymbolInfo* temp = new SymbolInfo($1);
		temp->setisLeaf(true);
		temp->setName("WHILE : while");
		temp->setStartLine(line_count);
		temp->setEndLine(line_count);
		temp->addChild(NULL);

		SymbolInfo* temp2 = new SymbolInfo($2);
		temp2->setisLeaf(true);
		temp2->setName("LPAREN : (");
		temp2->setStartLine(line_count);
		temp2->setEndLine(line_count);
		temp2->addChild(NULL);

		SymbolInfo* temp3 = new SymbolInfo($4);
		temp3->setisLeaf(true);
		temp3->setName("RPAREN : )");
		temp3->setStartLine(line_count);
		temp3->setEndLine(line_count);
		temp3->addChild(NULL);

		$$->setStartLine(temp->getStartLine());
		$$->setEndLine($5->getEndLine());
		$$->addChild(temp);
		$$->addChild(temp2);
		$$->addChild(new SymbolInfo($3));
		$$->addChild(temp3);
		$$->addChild(new SymbolInfo($5));

		delete $1;
		delete $2;
		delete $3;
		delete $4;
		delete $5;
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON {
		textlog<<"statement\t: PRINTLN LPAREN ID RPAREN SEMICOLON\n";
		string name = "statement : PRINTLN LPAREN ID RPAREN SEMICOLON";
		$$ = new SymbolInfo(name,"VARIABLE");
		if(st.LookUp($3->getName())==NULL){
			errorlog<<"Line#  "<<line_count<<": Undeclared variable '"<<$3->getName()<<"'"<<endl;
			error_count++;
		}
		
		SymbolInfo* temp = new SymbolInfo($1);
		temp->setisLeaf(true);
		temp->setName("PRINTLN : println");
		temp->setStartLine(line_count);
		temp->setEndLine(line_count);
		temp->addChild(NULL);

		SymbolInfo* temp2 = new SymbolInfo($2);
		temp2->setisLeaf(true);
		temp2->setName("LPAREN : (");
		temp2->setStartLine(line_count);
		temp2->setEndLine(line_count);
		temp2->addChild(NULL);

		SymbolInfo* temp3 = new SymbolInfo($3);
		temp3->setisLeaf(true);
		temp3->setName("ID : "+$3->getName());
		temp3->setStartLine(line_count);
		temp3->setEndLine(line_count);
		temp3->addChild(NULL);

		SymbolInfo* temp4 = new SymbolInfo($4);
		temp4->setisLeaf(true);
		temp4->setName("RPAREN : )");
		temp4->setStartLine(line_count);
		temp4->setEndLine(line_count);
		temp4->addChild(NULL);

		SymbolInfo* temp5 = new SymbolInfo($5);
		temp5->setisLeaf(true);
		temp5->setName("SEMICOLON : ;");
		temp5->setStartLine(line_count);
		temp5->setEndLine(line_count);
		temp5->addChild(NULL);

		$$->setStartLine(temp->getStartLine());
		$$->setEndLine(temp5->getEndLine());
		$$->addChild(temp);
		$$->addChild(temp2);
		$$->addChild(temp3);
		$$->addChild(temp4);
		$$->addChild(temp5);

		errorlog<<"Line#  "<<line_count<<": Undeclared function 'printf'"<<endl;
		error_count++;

		delete $1;
		delete $2;
		delete $3;
		delete $4;
		delete $5;
	  }
	  | RETURN expression SEMICOLON {
		textlog<<"statement\t: RETURN expression SEMICOLON\n";
		hasReturn = true;
		string name = "statement : RETURN expression SEMICOLON";
		string type = $2->getType();
		if(returnType != ""){
			if(returnType == "CONST_FLOAT" && (type == "CONST_FLOAT" || type == "CONST_INT")){
				type = "CONST_FLOAT";
			}
			else{
				typeCast(returnType,$2->getType());
			}
		}
		$$ = new SymbolInfo(name,type);

		SymbolInfo* temp = new SymbolInfo($1);
		temp->setisLeaf(true);
		temp->setName("RETURN : return");
		temp->setStartLine(line_count);
		temp->setEndLine(line_count);
		temp->addChild(NULL);

		SymbolInfo* temp2 = new SymbolInfo($3);
		temp2->setisLeaf(true);
		temp2->setName("SEMICOLON : ;");
		temp2->setStartLine(line_count);
		temp2->setEndLine(line_count);
		temp2->addChild(NULL);

		$$->setStartLine(temp->getStartLine());
		$$->setEndLine(temp2->getEndLine());
		$$->addChild(temp);
		$$->addChild(new SymbolInfo($2));
		$$->addChild(temp2);

		delete $1;
		delete $2;
		delete $3;
	  }
	  | RETURN expression error {
		textlog<<"statement\t: RETURN expression\n";
		hasReturn = true;
		string name = "statement : RETURN expression";
		string type = $2->getType();
		if(returnType != ""){
			if(returnType == "CONST_FLOAT" && (type == "CONST_FLOAT" || type == "CONST_INT")){
				type = "CONST_FLOAT";
			}
			else{
				typeCast(returnType,$2->getType());
			}
		}
		$$ = new SymbolInfo(name,type);

		SymbolInfo* temp = new SymbolInfo($1);
		temp->setisLeaf(true);
		temp->setName("RETURN : return");
		temp->setStartLine(line_count);
		temp->setEndLine(line_count);
		temp->addChild(NULL);

		$$->setStartLine(temp->getStartLine());
		$$->setEndLine($2->getEndLine());
		$$->addChild(temp);
		$$->addChild(new SymbolInfo($2));

	  }
	  ;
	  
expression_statement 	: SEMICOLON	{
			textlog<<"expression_statement\t: SEMICOLON\n";
			$$ = new SymbolInfo("expression_statement : SEMICOLON","VARIABLE");

			SymbolInfo* temp = new SymbolInfo($1);
			temp->setisLeaf(true);
			temp->setName("SEMICOLON : ;");
			temp->setStartLine(line_count);
			temp->setEndLine(line_count);
			temp->addChild(NULL);

			$$->setStartLine(temp->getStartLine());
			$$->setEndLine(temp->getEndLine());
			$$->addChild(temp);

			delete $1;
}	
			| expression SEMICOLON {
				textlog<<"expression_statement\t: expression SEMICOLON\n";
				$$ = new SymbolInfo("expression_statement : expression SEMICOLON",$1->getType());

				SymbolInfo* temp = new SymbolInfo($2);
				temp->setisLeaf(true);
				temp->setName("SEMICOLON : ;");
				temp->setStartLine(line_count);
				temp->setEndLine(line_count);
				temp->addChild(NULL);

				$$->setStartLine($1->getStartLine());
				$$->setEndLine(temp->getEndLine());
				$$->addChild(new SymbolInfo($1));
				$$->addChild(temp);

				delete $1;
				delete $2;
			}
			| expression error{
				$$ = new SymbolInfo("","ERROR");

				$$->setStartLine($1->getStartLine());
				$$->setEndLine($1->getEndLine());
				$$->addChild(new SymbolInfo($1));

			}
			;
	  
variable : ID 	{
			textlog<<"variable\t: ID\n";
			string name = $1->getName();
			SymbolInfo* si = st.LookUp(name);
			if(si == NULL){
				errorlog<<"Line#  "<<line_count<<": "<<"Undeclared variable '"<<name<<"'"<<endl;
				error_count++;
				$$ = new SymbolInfo("variable : ID","UNDECLARED");
			}else{
				SymbolID* id = (SymbolID*)si;
				$$ = new SymbolInfo("variable : ID",id->getDataType());
			}

			SymbolInfo* temp = new SymbolInfo($1);
			temp->setisLeaf(true);
			temp->setName("ID : "+$1->getName());
			temp->setStartLine(line_count);
			temp->setEndLine(line_count);
			temp->addChild(NULL);

			$$->setStartLine(temp->getStartLine());
			$$->setEndLine(temp->getEndLine());
			$$->addChild(temp);

			delete $1;
}	
	 | ID LSQUARE expression RSQUARE {
		textlog<<"variable\t: ID LSQUARE expression RSQUARE\n";
		string name = "variable : ID LSQUARE expression RSQUARE";
		string type = "VARIABLE";
		SymbolInfo* si = st.LookUp($1->getName());
		if(si == NULL){
			errorlog<<"Line#  "<<line_count<<": "<<"Undeclared variable '"<<$1->getName()<<"'"<<endl;
			error_count++;
			type = "UNDECLARED";
	 	}else if(si->getType() == "ID"){
			SymbolID* id = (SymbolID*)si;
			string dataType = id->getDataType();
			if(dataType.size()>0 && dataType[dataType.size()-1] != '*'){
				errorlog<<"Line#  "<<line_count<<": '"<<$1->getName()<<"' is not an array"<<endl;
				error_count++;
				type = dataType;
				//cout<<"hi"<<type<<endl;
				//cout<<dataType[dataType.size()-1]<<endl;
			}else{
				type = dataType.substr(0,dataType.size()-1);
			}
		}else{
			errorlog<<"Line#  "<<line_count<<": '"<<$1->getName()<<"' is not an array"<<endl;
			error_count++;
			type = si->getType();
		}
		if($3->getType() != "CONST_INT"){
			errorlog<<"Line#  "<<line_count<<": "<<"Array subscript is not an integer"<<endl;
			error_count++;
		}
		$$ = new SymbolInfo(name,type);

		SymbolInfo* temp = new SymbolInfo($1);
		temp->setisLeaf(true);
		temp->setName("ID : "+$1->getName());
		temp->setStartLine(line_count);
		temp->setEndLine(line_count);
		temp->addChild(NULL);

		SymbolInfo* temp2 = new SymbolInfo($2);
		temp2->setisLeaf(true);
		temp2->setName("LSQUARE : [");
		temp2->setStartLine(line_count);
		temp2->setEndLine(line_count);
		temp2->addChild(NULL);

		SymbolInfo* temp3 = new SymbolInfo($4);
		temp3->setisLeaf(true);
		temp3->setName("RSQUARE : ]");
		temp3->setStartLine(line_count);
		temp3->setEndLine(line_count);
		temp3->addChild(NULL);

		$$->setStartLine(temp->getStartLine());
		$$->setEndLine(temp3->getEndLine());
		$$->addChild(temp);
		$$->addChild(temp2);
		$$->addChild(new SymbolInfo($3));
		$$->addChild(temp3);

		delete $1;
		delete $2;
		delete $3;
		delete $4;
	 }
	 ;
	 
 expression : logic_expression	{
	textlog<<"expression\t: logic_expression\n";
	$$ = new SymbolInfo("expression : logic_expression", $1->getType());

	$$->setStartLine($1->getStartLine());
	$$->setEndLine($1->getEndLine());
	$$->addChild(new SymbolInfo($1));

	delete $1;
 }
	   | variable ASSIGNOP logic_expression {
			textlog<<"expression\t: variable ASSIGNOP logic_expression\n";
			string name = "expression : variable ASSIGNOP logic_expression";
			string type = $1->getType();
			if(checkVoidFunc($3));
			else if($1->getType() != "UNDECLARED"){
				typeCast($1->getType(),$3->getType());
			}
			$$ = new SymbolInfo(name,type);

			SymbolInfo* temp = new SymbolInfo($2);
			temp->setisLeaf(true);
			temp->setName("ASSIGNOP : =");
			temp->setStartLine(line_count);
			temp->setEndLine(line_count);
			temp->addChild(NULL);

			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());
			$$->addChild(new SymbolInfo($1));
			$$->addChild(temp);
			$$->addChild(new SymbolInfo($3));

			delete $1;
			delete $2;
			delete $3;
	   }
	   | variable ASSIGNOP error {
			textlog<<"expression\t: variable ASSIGNOP \n";
			$$ = new SymbolInfo("expression : variable ASSIGNOP", $1->getType());

			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild(new SymbolInfo($1));
	   }	
	   ;
			
logic_expression : rel_expression 	{
	textlog<<"logic_expression\t: rel_expression\n";
	$$ = new SymbolInfo("logic_expression : rel_expression", $1->getType());

	$$->setStartLine($1->getStartLine());
	$$->setEndLine($1->getEndLine());
	$$->addChild(new SymbolInfo($1));

	delete $1;
}
		 | rel_expression LOGICOP rel_expression {
			textlog<<"logic_expression\t: rel_expression LOGICOP rel_expression\n";
			string name = "logic_expression : rel_expression LOGICOP rel_expression";
			string type = "CONST_INT";
			if(checkVoidFunc($1));
			else {checkVoidFunc($3);}
			$$ = new SymbolInfo(name,type);

			SymbolInfo* temp = new SymbolInfo($2);
			temp->setisLeaf(true);
			temp->setName("LOGICOP : "+$2->getName());
			temp->setStartLine(line_count);
			temp->setEndLine(line_count);
			temp->addChild(NULL);

			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());
			$$->addChild(new SymbolInfo($1));
			$$->addChild(temp);
			$$->addChild(new SymbolInfo($3));

			delete $1;
			delete $2;
			delete $3;
		 }	
		 ;
			
rel_expression	: simple_expression {
	textlog<<"rel_expression\t: simple_expression\n";
	$$ = new SymbolInfo("rel_expression : simple_expression", $1->getType());

	$$->setStartLine($1->getStartLine());
	$$->setEndLine($1->getEndLine());
	$$->addChild(new SymbolInfo($1));

	delete $1;
}
		| simple_expression RELOP simple_expression	{
			textlog<<"rel_expression\t: simple_expression RELOP simple_expression\n";
			string name = "rel_expression : simple_expression RELOP simple_expression";
			string type = "CONST_INT";

			if(checkVoidFunc($1));
			else if(checkVoidFunc($3));
			else{
				typeCast2($1->getType(),$3->getType());
			}
			$$ = new SymbolInfo(name,type);

			SymbolInfo* temp = new SymbolInfo($2);
			temp->setisLeaf(true);
			temp->setName("RELOP : "+$2->getName());
			temp->setStartLine(line_count);
			temp->setEndLine(line_count);
			temp->addChild(NULL);

			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());
			$$->addChild(new SymbolInfo($1));
			$$->addChild(temp);
			$$->addChild(new SymbolInfo($3));

			delete $1;
			delete $2;
			delete $3;
		}
		;
				
simple_expression : term {
	textlog<<"simple_expression\t: term\n";
	$$ = new SymbolInfo("simple_expression : term", $1->getType());

	$$->setStartLine($1->getStartLine());
	$$->setEndLine($1->getEndLine());
	$$->addChild(new SymbolInfo($1));

	delete $1;
}
		  | simple_expression ADDOP term {
			textlog<<"simple_expression\t: simple_expression ADDOP term\n";
			string name = "simple_expression : simple_expression ADDOP term";
			string type = $3->getType();
			if(checkVoidFunc($1));
			else if(checkVoidFunc($3)){
				type = $1->getType();
			}
			else{
				type = typeCast2($1->getType(),$3->getType());
			}
			$$ = new SymbolInfo(name,type);

			SymbolInfo* temp = new SymbolInfo($2);
			temp->setisLeaf(true);
			temp->setName("ADDOP : "+$2->getName());
			temp->setStartLine(line_count);
			temp->setEndLine(line_count);
			temp->addChild(NULL);

			$$->setStartLine($1->getStartLine());
			$$->setEndLine($3->getEndLine());
			$$->addChild(new SymbolInfo($1));
			$$->addChild(temp);
			$$->addChild(new SymbolInfo($3));

			delete $1;
			delete $2;
			delete $3;
		  }
		  ;
					
term :	unary_expression {
	textlog<<"term\t: unary_expression\n";
	$$ = new SymbolInfo("term : unary_expression", $1->getType());

	$$->setStartLine($1->getStartLine());
	$$->setEndLine($1->getEndLine());
	$$->addChild(new SymbolInfo($1));

	delete $1;
}
     |  term MULOP unary_expression {
		textlog<<"term\t: term MULOP unary_expression\n";
		string name = "term : term MULOP unary_expression";
		string type = $3->getType();
		if(checkVoidFunc($1)) ;
		else if(checkVoidFunc($3)){
			type = $1->getType();
		}
		else if($2->getName() == "%"){
			if($1->getType() != "CONST_INT" || $3->getType() != "CONST_INT"){
				errorlog<<"Line#  "<<line_count<<": "<<"Operands of modulas must be integers"<<endl;
				error_count++;
			}
			type = "CONST_INT";
		}
		else if($2->getName() == "%" && zeroFlag==true){
			errorlog<<"Line#  "<<line_count<<": "<<"Warning: division by zero"<<endl;
			error_count++;
			type = "CONST_INT";
		}
		else{
			type = typeCast2($1->getType(), $3->getType());
		}
		$$ = new SymbolInfo(name, type);

		SymbolInfo* temp = new SymbolInfo($2);
		temp->setisLeaf(true);
		temp->setName("MULOP : "+$2->getName());
		temp->setStartLine(line_count);
		temp->setEndLine(line_count);
		temp->addChild(NULL);

		$$->setStartLine($1->getStartLine());
		$$->setEndLine($3->getEndLine());
		$$->addChild(new SymbolInfo($1));
		$$->addChild(temp);
		$$->addChild(new SymbolInfo($3));

		delete $1;
		delete $2;
		delete $3;
		}
     ;

unary_expression : ADDOP unary_expression {
	textlog<<"unary_expression\t: ADDOP unary_expression\n";
	$$ = new SymbolInfo("unary_expression : ADDOP unary_expression", $2->getType());
	
	SymbolInfo* temp = new SymbolInfo($1);
	temp->setisLeaf(true);
	temp->setName("ADDOP : "+$1->getName());
	temp->setStartLine(line_count);
	temp->setEndLine(line_count);
	temp->addChild(NULL);

	$$->setStartLine(temp->getStartLine());
	$$->setEndLine($2->getEndLine());
	$$->addChild(temp);
	$$->addChild(new SymbolInfo($2));

	delete $1;
	delete $2;
} 
		 | NOT unary_expression {
			textlog<<"unary_expression\t: NOT unary_expression\n";
			$$ = new SymbolInfo("unary_expression : NOT unary_expression", $2->getType());

			SymbolInfo* temp = new SymbolInfo($1);
			temp->setisLeaf(true);
			temp->setName("NOT : !");
			temp->setStartLine(line_count);
			temp->setEndLine(line_count);
			temp->addChild(NULL);

			$$->setStartLine(temp->getStartLine());
			$$->setEndLine($2->getEndLine());
			$$->addChild(temp);
			$$->addChild(new SymbolInfo($2));

			delete $1;
			delete $2;
		 }
		 | factor {
			textlog<<"unary_expression\t: factor\n";
			$$ = new SymbolInfo("unary_expression : factor", $1->getType());

			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild(new SymbolInfo($1));

			delete $1;
		 }
		 ;
	
factor	: variable {
	textlog<<"factor\t: variable\n";
	$$ = new SymbolInfo("factor : variable", $1->getType());

	$$->setStartLine($1->getStartLine());
	$$->setEndLine($1->getEndLine());
	$$->addChild(new SymbolInfo($1));

	delete $1;
}
	| ID LPAREN argument_list RPAREN {
		textlog<<"factor\t: ID LPAREN argument_list RPAREN\n";
		string name = $1->getName();
		string varName = $1->getName()+"("+$3->getName()+")";

		SymbolInfo *si = st.LookUp(name);
		if(si==NULL){
			errorlog<<"Line#  "<<line_count<<": Undeclared function: '"<<name<<"'\n";
			error_count++;
			$$ = new SymbolInfo("factor : ID LPAREN argument_list RPAREN","UNDECLARED");
		}
		else if(si->getFunc()){
			Function* f = (Function*)si;
			string ret = f->getReturnType();
			//$$ = new SymbolInfo(varName,ret);
			$$ = new SymbolInfo("factor : ID LPAREN argument_list RPAREN",ret);

			if(f->getParamList().size() > arg_list.size()){
				errorlog<<"Line#  "<<line_count<<": Too few arguments to function '"<<name<<"'\n";
				error_count++;
			}
			else if(f->getParamList().size() < arg_list.size()){
				errorlog<<"Line#  "<<line_count<<": Too many arguments to function '"<<name<<"'\n";
				error_count++;
			}
			else{
				for(int i=0; i<arg_list.size(); i++){
					typeCast(f->getParamList()[i],arg_list[i]->getType());
					
				}
				//for(int i=0; i<arg_list.size(); i++){
					//arg_list.erase(arg_list.begin()++);}
			}
		}
		else{
			errorlog<<"Line#  "<<line_count<<": "<<name<<" is not a function\n";
			error_count++;
			SymbolID* id = (SymbolID*)si;
			$$ = new SymbolInfo(varName,id->getDataType());
		}
		arg_list.clear();

		SymbolInfo* temp = new SymbolInfo($1);
		temp->setisLeaf(true);
		temp->setName("ID : "+$1->getName());
		temp->setStartLine(line_count);
		temp->setEndLine(line_count);
		temp->addChild(NULL);

		SymbolInfo* temp2 = new SymbolInfo($2);
		temp2->setisLeaf(true);
		temp2->setName("LPAREN : (");
		temp2->setStartLine(line_count);
		temp2->setEndLine(line_count);
		temp2->addChild(NULL);

		SymbolInfo* temp3 = new SymbolInfo($4);
		temp3->setisLeaf(true);
		temp3->setName("RPAREN : )");
		temp3->setStartLine(line_count);
		temp3->setEndLine(line_count);
		temp3->addChild(NULL);

		$$->setStartLine(temp->getStartLine());
		$$->setEndLine(temp3->getEndLine());
		$$->addChild(temp);
		$$->addChild(temp2);
		$$->addChild(new SymbolInfo($3));
		$$->addChild(temp3);

		delete $1;
		delete $2;
		delete $3;
		delete $4;
	}
	| LPAREN expression RPAREN {
		textlog<<"factor\t: LPAREN expression RPAREN\n";
		$$ = new SymbolInfo("factor : LPAREN expression RPAREN",$2->getType());

		SymbolInfo* temp = new SymbolInfo($1);
		temp->setisLeaf(true);
		temp->setName("LPAREN : (");
		temp->setStartLine(line_count);
		temp->setEndLine(line_count);
		temp->addChild(NULL);

		SymbolInfo* temp2 = new SymbolInfo($3);
		temp2->setisLeaf(true);
		temp2->setName("RPAREN : )");
		temp2->setStartLine(line_count);
		temp2->setEndLine(line_count);
		temp2->addChild(NULL);

		$$->setStartLine(temp->getStartLine());
		$$->setEndLine(temp2->getEndLine());
		$$->addChild(temp);
		$$->addChild(new SymbolInfo($2));
		$$->addChild(temp2);

		delete $1;
		delete $2;
		delete $3;
	}
	| CONST_INT {
		textlog<<"factor\t: CONST_INT\n";
		$$ = new SymbolInfo("factor : CONST_INT", $1->getType());
		if($1->getName() == '0'){
			zeroFlag = true;
		}

		SymbolInfo* temp = new SymbolInfo($1);
		temp->setisLeaf(true);
		temp->setName("CONST_INT : "+$1->getName());
		temp->setStartLine(line_count);
		temp->setEndLine(line_count);
		temp->addChild(NULL);

		$$->setStartLine(temp->getStartLine());
		$$->setEndLine(temp->getEndLine());
		$$->addChild(temp);

		delete $1;
	}
	| CONST_FLOAT {
		textlog<<"factor\t: CONST_FLOAT\n";
		$$ = new SymbolInfo("factor : CONST_FLOAT", $1->getType());
		if($1->getName() == '0'){
			zeroFlag = true;
		}

		SymbolInfo* temp = new SymbolInfo($1);
		temp->setisLeaf(true);
		temp->setName("CONST_FLOAT : "+$1->getName());
		temp->setStartLine(line_count);
		temp->setEndLine(line_count);
		temp->addChild(NULL);

		$$->setStartLine(temp->getStartLine());
		$$->setEndLine(temp->getEndLine());
		$$->addChild(temp);

		delete $1;
	}

	| CONST_CHAR {
		textlog<<"factor\t: CONST_CHAR\n";
		$$ = new SymbolInfo("factor : CONST_CHAR", $1->getType());

		SymbolInfo* temp = new SymbolInfo($1);
		temp->setisLeaf(true);
		temp->setName("CONST_CHAR : "+$1->getName());
		temp->setStartLine(line_count);
		temp->setEndLine(line_count);
		temp->addChild(NULL);

		$$->setStartLine(temp->getStartLine());
		$$->setEndLine(temp->getEndLine());
		$$->addChild(temp);

		delete $1;
	}
	| variable INCOP %prec POSTFIX_INCOP {
		textlog<<"factor\t: variable INCOP\n";
		$$ = new SymbolInfo("factor : variable INCOP : ",$1->getType());

		SymbolInfo* temp = new SymbolInfo($2);
		temp->setisLeaf(true);
		temp->setName("INCOP : ++");
		temp->setStartLine(line_count);
		temp->setEndLine(line_count);
		temp->addChild(NULL);

		$$->setStartLine($1->getStartLine());
		$$->setEndLine(temp->getEndLine());
		$$->addChild(new SymbolInfo($1));
		$$->addChild(temp);

		delete $1;
		delete $2;
	}
	| variable DECOP %prec POSTFIX_DECOP {
		textlog<<"factor\t: variable DECOP\n";
		$$ = new SymbolInfo("factor : variable DECOP",$1->getType());

		SymbolInfo* temp = new SymbolInfo($2);
		temp->setisLeaf(true);
		temp->setName("DECOP : --");
		temp->setStartLine(line_count);
		temp->setEndLine(line_count);
		temp->addChild(NULL);

		$$->setStartLine($1->getStartLine());
		$$->setEndLine(temp->getEndLine());
		$$->addChild(new SymbolInfo($1));
		$$->addChild(temp);

		delete $1;
		delete $2;
	}
	| INCOP variable %prec PREFIX_INCOP {
		textlog<<"factor\t: INCOP variable\n";
		$$ = new SymbolInfo("factor : INCOP variable",$2->getType());

		SymbolInfo* temp = new SymbolInfo($1);
		temp->setisLeaf(true);
		temp->setName("INCOP : ++");
		temp->setStartLine(line_count);
		temp->setEndLine(line_count);
		temp->addChild(NULL);

		$$->setStartLine(temp->getStartLine());
		$$->setEndLine(temp->getEndLine());
		$$->addChild(temp);
		$$->addChild(new SymbolInfo($2));

		delete $1;
		delete $2;
	}
	| DECOP variable %prec PREFIX_DECOP {
		textlog<<"factor\t: DECOP variable\n";
		$$ = new SymbolInfo("factor : DECOP variable : --"+$2->getName(),$2->getType());

		SymbolInfo* temp = new SymbolInfo($1);
		temp->setisLeaf(true);
		temp->setName("DECOP : --");
		temp->setStartLine(line_count);
		temp->setEndLine(line_count);
		temp->addChild(NULL);

		$$->setStartLine(temp->getStartLine());
		$$->setEndLine(temp->getEndLine());
		$$->addChild(temp);
		$$->addChild(new SymbolInfo($2));

		delete $1;
		delete $2;
	}
	;
	
argument_list : arguments {
	textlog<<"argument_list\t: arguments\n";
	$$ = new SymbolInfo("argument_list : arguments", $1->getType());

			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild(new SymbolInfo($1));

			delete $1;
}
			  | {
	textlog<<"argument_list\t: empty\n";
	$$ = new SymbolInfo("argument_list : ","VARIABLE");

			//$$->setStartLine($1->getStartLine());
			//$$->setEndLine($1->getEndLine());

}
 ;
	
arguments : arguments COMMA logic_expression {
	textlog<<"arguments\t: arguments COMMA logic_expression\n";
	arg_list.push_back(new SymbolInfo($3->getName(), $3->getType()));
	$$ = new SymbolInfo($1->getName() + "," + $3->getName(),"VARIABLE");

	SymbolInfo *temp = new SymbolInfo($2);
	temp->setisLeaf(true);
	temp->setName("COMMA : ,");
	temp->setStartLine(line_count);
	temp->setEndLine(line_count);
	temp->addChild(NULL);

	$$->setStartLine($1->getStartLine());
	$$->setEndLine($3->getEndLine());
	$$->addChild(new SymbolInfo($1));
	$$->addChild(temp);
	$$->addChild(new SymbolInfo($3));

	delete $1;
	delete $2;
	delete $3;
}
	      | logic_expression {
			textlog<<"arguments\t: logic_expression\n";
			arg_list.push_back(new SymbolInfo($1->getName(), $1->getType()));
			$$ = new SymbolInfo("arguments : logic_expression", $1->getType());

			$$->setStartLine($1->getStartLine());
			$$->setEndLine($1->getEndLine());
			$$->addChild(new SymbolInfo($1));

			delete $1;
		  }
	      ;
 

%%
int main(int argc,char *argv[])
{

	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	textlog.open("1905088_log.txt");
	errorlog.open("1905088_error.txt");
	parselog.open("1905088_parse.txt");
	

	yyin=fp;
	yyparse();
	
	textlog.close();
	errorlog.close();
	parselog.close();
	fclose(fp);
	
	return 0;
}