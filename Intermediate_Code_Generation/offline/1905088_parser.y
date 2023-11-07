%{
#include<fstream>
#include "1905088_Symbol_Table.h"
#include "1905088_ICGHelper.h"
#include "1905088_Optimizer.h"

using namespace std;

int yyparse(void);
int yylex(void);

//bool DEBUG = false;

ofstream asmFile;
ofstream optFile;

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

int labelcnt = 0;
int asmLinecnt = 0;
int asmDSend = 0;
int asmCSend = 0;

void yyerror(char *s)
{
	//errorlog<<"Line#  "<<line_count<<": "<<"Syntax error"<<endl;
	error_count++;
}

void typeCheck(string ltype,string rtype){
	if(ltype == "UNDECLARED" || rtype == "UNDECLARED"){
		return;
	}
	if(ltype != rtype){
		if(ltype[ltype.size()-1] == '*'){
			//errorlog<<"Line#  "<<line_count<<": "<<"Type mismatch"<<endl;
			error_count++;
		}
		else if(rtype[rtype.size()-1] == '*'){
			//errorlog<<"Line#  "<<line_count<<": "<<"Type mismatch"<<endl;
			error_count++;
		}
		else{
			//errorlog<<"Line# "<<line_count<<": "<<"Type mismatch"<<endl;
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
		//errorlog<<"Line#  "<<line_count<<": "<<"Void function used in expression"<<endl;
		error_count++;
		return true;
	}else{
		return false;
	}
}

void insertID(SymbolInfo* si, string type, int arraySize = 0) {
	string name = si->getName();
	type = "CONST_" + toUpper(type);
	bool flag = st.Insert(name, "ID" , type, arraySize);
	decL.push_back(name);
	if(st.getCurrentScopeID() != 1){
		if(arraySize == 0){
			append("1905088_Asm.asm","\tPUSH BX\t;line "+to_string(line_count)+": "+name+" declared",asmCSend);
			asmLinecnt++;
			asmCSend++;
		}
		else{
			int offsetEnd = st.getTotalIDofCurrFunc()*2;
			string s;
			s += "\tSUB SP, "+to_string(arraySize*2)+"\t;line "+to_string(line_count)+": "+name+"["+to_string(arraySize)+"] declared";
			append("1905088_Asm.asm",s,asmCSend);
			asmLinecnt++;
			asmCSend++;
		}
	}
	
}

void handleFuncDef(){
	if(isIDDec) { return; }
	if(isFuncDef) {return; }
	Function* f = (Function*)st.LookUpCurrentScope(funcName);
	f->setDefined(true);
	//if(f->getReturnType() == returnType && f->getName() != "main" && f->getReturnType() != "CONST_VOID" && !hasReturn){}
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
		isIDDec = true;
	}
 }
 else{
	SymbolInfo* si = st.LookUp(funcName);
	f = (Function*)si;
	f->setReturnType(returnType);
	for(int i=0;i<param_list.size();i++){
		f->addParam("CONST_"+toUpper(param_list[i].second));
	}
  }
}

void declareGlobalVar(SymbolInfo* si, string type){
	string name = si->getName();
	string s = "\t" + name + " DW 0";
	asmLinecnt++;
	asmCSend ++;
	append("1905088_Asm.asm",s,asmDSend++);
}

void declareGlobalArray(SymbolInfo* si, string type, int arraySize){
	string name = si->getName();
	string s = "\t" + name + " DW "+to_string(arraySize)+" DUP(0)";
	asmLinecnt++;
	asmCSend ++;
	append("1905088_Asm.asm",s,asmDSend++);
}

void endProc(string name, int Paramcnt){
	string s;
	if(funcName == "main"){
		s += "\tMOV AH, 4CH\n";
		s += "\tINT 21H";
		append("1905088_Asm.asm",s);
		asmLinecnt += 2;
		asmCSend += 2;
	}
	else if(returnType == "CONST_VOID"){
		s += "\tMOV SP, BP\n";
		s += "\tPOP BP\n";
		if(Paramcnt>0){
			s += "\tRET "+to_string(Paramcnt*2);
		}
		else{
			s += "\tRET";
		}
		append("1905088_Asm.asm",s,asmCSend);
		asmLinecnt += 3;
		asmCSend += 3;
	}
	append("1905088_Asm.asm",name+" ENDP\n");
	asmLinecnt++;
	asmCSend++;
}

void declareProc(SymbolInfo* si){
	string name = si->getName();
	st.reset();
	string s;
	if(name == "main"){
		s += "main PROC\n";
		s += "\tMOV AX, @DATA\n";
		s += "\tMOV DS, AX\n";
		s += "\tMOV BP, SP";
		append("1905088_Asm.asm",s);
		asmLinecnt += 4;
		asmCSend += 4;
	}
	else{
		s += name + " PROC\n";
		s += "\tPUSH BP\n";
		s += "\tMOV BP, SP\n";
		append("1905088_Asm.asm",s);
		asmLinecnt += 5;
		asmCSend += 5;
	}
}

/*
void PrintTree(SymbolInfo* a, int level){
if(a != NULL){
	for(int i=1;i<=level;i++){
		parselog<<"  ";
	}
	if(!(a->getisLeaf()))
	{
		if(a->getName()=="int" || a->getName()=="float" || a->getName()=="void" || a->getName()=="char");
			parselog<<"type_specifier : "<<toUpper(a->getName())<<" <Line: "<<a->getStartLine()<<"-"<<a->getEndLine()<<">"<<endl;
		else
			parselog<<a->getName()<<" <Line: "<<a->getStartLine()<<"-"<<a->getEndLine()<<">"<<endl;
	}
	else
		parselog<<a->getName()<<" <Line: "<<a->getStartLine()<<">"<<endl;

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
*/
%}

%union
{
	SymbolInfo *symbol;
	int intVal;
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
%type<symbol> logic_expression rel_expression simple_expression term unary_expression factor argument_list arguments generate_if_block

%destructor {delete $$;} <symbol>

%right PREFIX_INCOP
%left POSTFIX_INCOP
%right PREFIX_DECOP
%left POSTFIX_DECOP

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE


%%

start : program {
		$$ = new SymbolInfo($1->getName(), "VARIABLE");
		//PrintTree($$,0);
		//st.PrintAllScope();
		//st.ExitScope();
		//textlog<<"Total lines: "<<line_count<<endl;
		//textlog<<"Total errors: "<<error_count<<endl;
		// deleteTree($$);
		delete $1;
}
;

program : program unit {
		$$ = new SymbolInfo($1->getName()+"\n"+$2->getName(), "VARIABLE");
		delete $1;
		delete $2;
}
	| unit {
		$$ = new SymbolInfo($1->getName(), $1->getType());
		delete $1;
}
;
	
unit : var_declaration {
		$$ = new SymbolInfo($1->getName(), $1->getType());
		delete $1;
}
    | func_declaration {
		$$ = new SymbolInfo($1->getName(), $1->getType());
		delete $1;
	}
    | func_definition {
		$$ = new SymbolInfo($1->getName(), $1->getType());
		delete $1;
}
;

func_prototype: type_specifier ID LPAREN parameter_list RPAREN {
		string r = "CONST_" + toUpper($1->getName());
		handleFunDec($2->getName(),r);
		$$ = new SymbolInfo($1->getName()+" "+$2->getName()+"("+$4->getName()+")", "parameter_list");
		declareProc($2);

		delete $1;
		delete $2;
		delete $3;
		delete $4;
		delete $5;
}
	| type_specifier ID LPAREN RPAREN {
		string r = "CONST_" + toUpper($1->getName());
		handleFunDec($2->getName(),r);
		$$ = new SymbolInfo($1->getName()+" "+$2->getName()+"()", "");
		declareProc($2);

		delete $1;
		delete $2;
		delete $3;
		delete $4;
}
;  

func_declaration : func_prototype SEMICOLON {
		st.EnterScope();
		st.ExitScope();
		$$ = new SymbolInfo($1->getName()+";", "VARIABLE");
		isIDDec = false;
		isFuncDec = false;
		isFuncDef = false;
		funcName.clear();
		returnType.clear();
		param_list.clear();
		delete $1;
		delete $2;
}
;
		 
func_definition : func_prototype compound_statement {
		$$ = new SymbolInfo($1->getName()+$2->getName(), "VARIABLE");
		handleFuncDef();

		int j = ((Function*)st.LookUp(funcName))->getParamList().size();
		endProc(funcName,j);

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
	}
	st.EnterScope();
	int j = param_list.size();
	for(int i=0; i<param_list.size(); i++){
		bool flag = st.Insert(param_list[i].first, "ID", "CONST_"+toUpper(param_list[i].second),0,true);
		SymbolID* id = (SymbolID*)st.LookUp(param_list[i].first);
		id->setOffset(2 + j * 2);
		j--;
	}
}
;

parameter_list  : parameter_list COMMA type_specifier ID {
		param_list.push_back(make_pair($4->getName(),$3->getName()));
		$$ = new SymbolInfo($1->getName()+","+$3->getName()+" "+$4->getName(), "VARIABLE");
		delete $1;
		delete $2;
		delete $3;
		delete $4;
}
	| parameter_list COMMA type_specifier {
		param_list.push_back(make_pair("", $3->getName()));
		$$ = new SymbolInfo($1->getName()+","+$3->getName(), "VARIABLE");
		delete $1;
		delete $2;
		delete $3;
}
	| type_specifier ID {
		param_list.push_back(make_pair($2->getName(),$1->getName()));
		$$ = new SymbolInfo($1->getName()+" "+$2->getName(), "VARIABLE");
		delete $1;
		delete $2;
}
	| type_specifier {
		param_list.push_back(make_pair("", $1->getName()));
		$$ = new SymbolInfo($1->getName(), $1->getType());
		delete $1;
}
;

compound_statement : LCURL enter_scope statements RCURL {
		$$ = new SymbolInfo("{\n"+$3->getName()+"\n}" ,"VARIABLE");
		//st.PrintAllScope();
		st.ExitScope();
		delete $1;
		delete $3;
		delete $4;
}
 		
 	| LCURL enter_scope RCURL {
		$$ = new SymbolInfo("{}", "VARIABLE");
		//st.PrintAllScope();
		st.ExitScope();
		delete $1;
		delete $3;
}
;
 		    
var_declaration : type_specifier declaration_list SEMICOLON {
	$$ = new SymbolInfo($1->getName()+" "+$2->getName()+";","VARIABLE");
	varType.clear();
	decL.clear();
	delete $1;
	delete $2;
	delete $3;
}
;
 		 
type_specifier	: INT {
		varType = "int";
		$$ = new SymbolInfo("int","VARIABLE");
		delete $1;
}
 	| FLOAT {
		varType = "float";
		$$ = new SymbolInfo("float","VARIABLE");
		delete $1;
}
 	| VOID {
		varType = "void";
		$$ = new SymbolInfo("void","VARIABLE");
		delete $1;
}
;
 		
declaration_list : declaration_list COMMA ID {
	$$ = new SymbolInfo($1->getName()+","+$3->getName(),"VARIABLE");
	insertID($3, varType);
	if(st.getCurrentScopeID() == 1){
		declareGlobalVar($3, varType);
	}

	delete $1;
	delete $2;
	delete $3;
}
 	| declaration_list COMMA ID LSQUARE CONST_INT RSQUARE {
		$$ = new SymbolInfo($1->getName()+","+$3->getName()+"["+$5->getName()+"]","VARIABLE");
		insertID($3, varType+"*",stoi($5->getName()));
		if(st.getCurrentScopeID() == 1){
			declareGlobalArray($3, varType, stoi($5->getName()));
		}
		delete $1;
		delete $2;
		delete $3;
		delete $4;
		delete $5;
		delete $6;
}
	| ID {
		insertID($1, varType);
		$$ = new SymbolInfo($1->getName(), $1->getType());
		if(st.getCurrentScopeID() == 1){
			declareGlobalVar($1, varType);
		}
		delete $1;
}
 	| ID LSQUARE CONST_INT RSQUARE {
		$$ = new SymbolInfo($1->getName()+"["+$3->getName()+"]","VARIABLE");
		insertID($1, varType+"*",stoi($3->getName()));
		if(st.getCurrentScopeID() == 1){
			declareGlobalArray($1, varType, stoi($3->getName()));
		}
		delete $1;
		delete $2;
		delete $3;
		delete $4;
}
;
 		  
statements : statement {
		$$ = new SymbolInfo($1->getName(), $1->getType());
		delete $1;
}
	| statements statement {
		$$ = new SymbolInfo($1->getName()+"\n"+$2->getName(),"VARIABLE");
		delete $1;
		delete $2;
}
;

generate_if_block: {
		string label = "L"+to_string(++labelcnt);
		string labelBypass = "L"+to_string(++labelcnt);
		string s = ";line  "+to_string(line_count)+": evaluating if\n";
		$$ = new SymbolInfo(label,"LABEL");
		s += "\tPOP AX\n";
		s += "\tCMP AX, 0\n";
		s += "\tJNE "+labelBypass+"\n";
		s += "\tJMP "+label+"\n";
		s += labelBypass + ":\n";

		append("1905088_Asm.asm",s,asmCSend);
		asmLinecnt += 7;
		asmCSend += 7;
}	
;

statement : var_declaration {
			$$ = new SymbolInfo($1->getName(), $1->getType());
			delete $1;
}
	| expression_statement {
			$$ = new SymbolInfo($1->getName(), $1->getType());
			delete $1;
}
	| compound_statement {
			$$ = new SymbolInfo($1->getName(), $1->getType());
			delete $1;
}
	| FOR LPAREN expression_statement  {
		string label = "L"+to_string(++labelcnt);
		string s = ";line  "+to_string(line_count)+": for loop starts\n";
		s += label + ":\n";
		append("1905088_Asm.asm",s,asmCSend);
		asmLinecnt +=3;
		asmCSend +=3;

		$<symbol>$ = new SymbolInfo(label,"LABEL");
	  }
	  expression_statement {
		string labelEnd = "L"+to_string(++labelcnt);
		string labelBypass = "L"+to_string(++labelcnt);
		string s;
		s += "\tCMP AX,0\n";
		s += "\tJNE "+labelBypass+"\n";
		s += "\tJMP "+labelEnd+"\n";
		s += labelBypass+":\n";
		append("1905088_Asm.asm",s,asmCSend);
		asmLinecnt += 5;
		asmCSend += 5;

		$<symbol>$ = new SymbolInfo(labelEnd,"LABEL");
	  }
	  { $<intVal>$ = asmCSend; }
	   expression {
		string labelFor = $<symbol>4->getName();
		string labelEnd = $<symbol>6->getName();
		string s;
		s += "\tPOP AX\n";
		s += "\tJMP "+labelFor+"\n";
		s += labelEnd+":\t;for loop terminates\n";
		append("1905088_Asm.asm",s,asmCSend);
		asmLinecnt += 4;
		asmCSend += 4;
		asmCSend = $<intVal>7;
	   }
	   RPAREN statement {
		string name = "for("+$3->getName()+$5->getName()+$8->getName()+")"+$11->getName();
		$$ = new SymbolInfo(name,"VARIABLE");

		asmCSend = asmLinecnt;

		delete $1;
		delete $2;
		delete $3;
		delete $<symbol>4;
		delete $5;
		delete $<symbol>6;
		delete $8;
		delete $10;
		delete $11;
}
	| IF LPAREN expression RPAREN generate_if_block statement %prec LOWER_THAN_ELSE {
		$$ = new SymbolInfo("if("+$3->getName()+")"+$6->getName(),"VARIABLE");
		append("1905088_Asm.asm",$5->getName()+":\n",asmCSend);
		asmLinecnt +=2;
		asmCSend +=2;
		delete $1;
		delete $2;
		delete $3;
		delete $4;
		delete $5;
		delete $6;
}
	| IF LPAREN expression RPAREN generate_if_block statement ELSE {
		string labelEnd = "L"+to_string(++labelcnt);
		string s;
		s += "\tJMP "+labelEnd+"\n";
		s += $5->getName()+":";

		append("1905088_Asm.asm",s,asmCSend);
		asmLinecnt += 2;
		asmCSend += 2;

		$<symbol>$ = new SymbolInfo(labelEnd,"LABEL");
	  }
		statement {
		string name = "if("+$3->getName()+")"+$6->getName()+"else\n"+$9->getName();
		$$ = new SymbolInfo(name,"VARIABLE");

		string s;
		s += $<symbol>8->getName()+":\n";

		append("1905088_Asm.asm",s,asmCSend);
		asmLinecnt +=2;
		asmCSend +=2;
		
		delete $1;
		delete $2;
		delete $3;
		delete $4;
		delete $5;
		delete $6;
		delete $<symbol>8;
		delete $9;
}
	| WHILE {
		string label = "L"+to_string(++labelcnt);
		string s=";line  "+to_string(line_count)+": while loop starts\n";
		s += label + ":\n";
		$<symbol>$ = new SymbolInfo(label,"LABEL");
		append("1905088_Asm.asm",s,asmCSend);
		asmLinecnt += 3;
		asmCSend += 3;
	}
	LPAREN expression {
		string labelEnd = "L"+to_string(++labelcnt);
		string labelBypass = "L"+to_string(++labelcnt);
		string s;
		$<symbol>$ = new SymbolInfo(labelEnd,"LABEL");
		s += "\tPOP AX\n";
		s += "\tCMP AX, 0\n";
		s += "\tJNE "+labelBypass+"\n";
		s += "\tJMP "+labelEnd+"\n";
		s += labelBypass+":\n";
		append("1905088_Asm.asm",s,asmCSend);
		asmLinecnt += 6;
		asmCSend += 6;
	}
	RPAREN statement {
		string name = "while("+$4->getName()+")"+$7->getName();
		$$ = new SymbolInfo(name,"VARIABLE");

		string labelWhile = $<symbol>2->getName();
		string labelEnd = $<symbol>5->getName();
		string s;
		s += "\tJMP "+labelWhile+"\n";
		s += labelEnd+":\t;while loop ends\n";
		append("1905088_Asm.asm",s,asmCSend);
		asmLinecnt += 3;
		asmCSend += 3;

		delete $1;
		delete $<symbol>2;
		delete $4;
		delete $<symbol>5;
		delete $7;
}
	| PRINTLN LPAREN ID RPAREN SEMICOLON {
		string name = "println("+$3->getName()+");";
		$$ = new SymbolInfo(name,"VARIABLE");
		SymbolInfo* si = st.LookUp($3->getName());
		SymbolID* id = (SymbolID*)si;
		string s = ";line  "+to_string(line_count)+": println("+$3->getName()+");\n";

		if(id->getOffset() != -1){
			s += "\tPUSH [BP+"+to_string(id->getOffset())+"]\n";
		}
		else{
			s += "\tPUSH "+id->getName()+"\n";
		}
		s += "\tCALL PRINT_OUTPUT\n";
		s += "\tCALL NEW_LINE\n";
		append("1905088_Asm.asm",s,asmCSend);
		asmLinecnt += 5;
		asmCSend += 5;

		delete $1;
		delete $2;
		delete $3;
		delete $4;
		delete $5;
}
	| RETURN expression SEMICOLON {
		hasReturn = true;
		string name = "return "+$2->getName()+";";
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
		string s;
		s += "\tPOP AX\n";
		if(funcName != "main"){
			Function* f = (Function*)st.LookUp(funcName);
			int noOfParam = f->getParamList().size();
			s += "\tMOV SP, BP\t;restoring SP at the end of function\n";
			s += "\tPOP BP\n";
			if(noOfParam > 0){
				s += "\tRET "+to_string(noOfParam*2);
			}
			else{
				s += "\tRET";
			}
			append("1905088_Asm.asm",s,asmCSend);
			asmLinecnt += 4;
			asmCSend += 4;
		}
		else{
			string s;
			s += "\tMOV AH, 4CH\n";
			s += "\tINT 21H";
			append("1905088_Asm.asm",s);
			asmLinecnt += 2;
			asmCSend += 2;
		}

		delete $1;
		delete $2;
		delete $3;
}
;
	  
expression_statement 	: SEMICOLON	{
			$$ = new SymbolInfo(";","VARIABLE");
			delete $1;
}	
	| expression SEMICOLON {
		$$ = new SymbolInfo($1->getName()+";",$1->getType());
		append("1905088_Asm.asm","\tPOP AX\t;popped out "+$1->getName(),asmCSend);
		asmLinecnt++;
		asmCSend ++;
		delete $1;
		delete $2;
}
;
	  
variable : ID 	{
			string name = $1->getName();
			SymbolInfo* si = st.LookUp(name);
			SymbolID* id = (SymbolID*)si;
			$$ = new SymbolID(name,id->getDataType(),id->getDataType(),id->getOffset(),id->getArrsize());
			string s;
			if(id->getOffset() == -1){
				s += "\tPUSH "+name;
			}
			else{
				s += "\tPUSH [BP+"+to_string(id->getOffset())+"]";
			}

			append("1905088_Asm.asm",s,asmCSend);
			asmLinecnt++;
			asmCSend++;
			delete $1;
}	
	| ID LSQUARE expression RSQUARE {
		string type = "VARIABLE";
		SymbolInfo* si = st.LookUp($1->getName());
		if(si == NULL){
			type = "UNDECLARED";
			$$ = new SymbolInfo($1->getName(),type);
		}
		else if(si->getType() == "ID"){
			SymbolID* id = (SymbolID*)si;
			string dataType = id->getDataType();
			if(dataType.size()>0 && dataType[dataType.size()-1]!= '*'){
				type = dataType;
			}
			else{
				type = dataType.substr(0,dataType.size()-1);
				$$ = new SymbolID($1->getName(),type,type,id->getOffset(),id->getArrsize());
			
		string s = ";line  "+to_string(line_count)+": "+$1->getName()+$2->getName()+$3->getName()+"\n";
		s += "\tPOP BX\n";
		s += "\tSHL BX,1\n";
		if(id->getOffset() != -1){
			if(id->getOffset()<0){
				s += "\tNEG BX\n";
			}
			s += "\tADD BX,"+to_string(id->getOffset())+"\n";
			s += "\tPUSH BP\n";
			s += "\tADD BP,BX\n";
			s += "\tMOV BX,BP\n";
			s += "\tMOV AX,[BP]\n";
			s += "\tPOP BP\n";
		}
		else{
			s += "\tMOV AX,"+$1->getName()+"[BX]\n";
		}
		s += "\tPUSH AX\n";
		s += "\tPUSH BX";

		append("1905088_Asm.asm",s,asmCSend);
		int cnt = 0;
		for(int i=0;i<s.size();i++){
			if(s[i] == '\n')	cnt++;
		}
		cnt +=1;
		asmLinecnt += cnt;
		asmCSend += cnt;
		}
		}
		else{
			varType = si->getType();
		}
		delete $1;
		delete $2;
		delete $3;
		delete $4;
}
;
	 
 expression : logic_expression	{
	$$ = new SymbolInfo($1->getName(), $1->getType());
	delete $1;
 }
	| variable ASSIGNOP logic_expression {
		string type = $1->getType();
		if($1->getType() != "UNDECLARED"){
			typeCast($1->getType(),$3->getType());
		}
		$$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(),type);
		SymbolID* id = (SymbolID*)$1;

		string s;
		s += "\tPOP AX\t;"+$3->getName()+" popped\n";
		if(id->getArrsize()>0)
			s += "\tPOP BX\t;index of the array element popped\n";
			s += ";line  "+to_string(line_count)+": "+$1->getName()+$2->getName()+$3->getName()+"\n";
		if(id->getOffset() == -1){
			if(id->getArrsize()>0){
				s += "\tMOV "+$1->getName()+"[BX], AX\n";
			}
			else{
				s += "\tMOV "+$1->getName()+", AX";
			}
		}
		else{
			if(id->getArrsize()>0){
				s += "\tPUSH BP\n";
				s += "\tMOV BP, BX\n";
				s += "\tMOV [BP], AX\n";
				s += "\tPOP BP\n";
			}
			else{
				s += "\tMOV [BP+"+to_string(id->getOffset())+"], AX";
			}	
		}

		append("1905088_Asm.asm",s,asmCSend);
		int cnt =0;
		for(int i=0;i<s.size();i++){
			if(s[i] == '\n')
				cnt++;
		}
		cnt += 1;
		asmLinecnt += cnt;
		asmCSend += cnt;
		
		delete $1;
		delete $2;
		delete $3;
}
;

logic_expression : rel_expression 	{
	$$ = new SymbolInfo($1->getName(), $1->getType());
	delete $1;
}
	| rel_expression LOGICOP rel_expression {
		string type = "CONST_INT";
		$$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(),type);

		string s = ";line  "+to_string(line_count)+": "+$1->getName()+$2->getName()+$3->getName()+"\n";
		if($2->getName() == "&&"){
			string labeLeftT = "L"+to_string(++labelcnt);
			string labeT = "L"+to_string(++labelcnt);
			string labeEnd = "L"+to_string(++labelcnt);
			s += "\tPOP BX\n";
			s += "\tPOP AX\n";
			s += "\tCMP AX, 0\n";
			s += "\tJNE "+labeLeftT+"\n";
			s += "\tPUSH 0\n";
			s += "\tJMP "+labeEnd+"\n";
			s += labeLeftT+":\n";
			s += "\tCMP BX, 0\n";
			s += "\tJNE "+labeT+"\n";
			s += "\tPUSH 0\n";
			s += "\tJMP "+labeEnd+"\n";
			s += labeT+":\n";
			s += "\tPUSH 1\n";
			s += labeEnd+":\n";
		}
		else {
			string labeLeftF = "L"+to_string(++labelcnt);
			string labeF = "L"+to_string(++labelcnt);
			string labeEnd = "L"+to_string(++labelcnt);
			s += "\tPOP BX\n";
			s += "\tPOP AX\n";
			s += "\tCMP AX, 0\n";
			s += "\tJE "+labeLeftF+"\n";
			s += "\tPUSH 1\n";
			s += "\tJMP "+labeEnd+"\n";
			s += labeLeftF+":\n";
			s += "\tCMP BX, 0\n";
			s += "\tJE "+labeF+"\n";
			s += "\tPUSH 1\n";
			s += "\tJMP "+labeEnd+"\n";
			s += labeF+":\n";
			s += "\tPUSH 0\n";
			s += labeEnd+":\n";
		}

		append("1905088_Asm.asm",s,asmCSend);
		int cnt = 0;
		for(int i=0; i<s.size(); i++){
			if(s[i] == '\n') cnt++;
		}
		cnt +=1;
		asmLinecnt += cnt;
		asmCSend += cnt;

		delete $1;
		delete $2;
		delete $3;
}	
;
			
rel_expression	: simple_expression {
	$$ = new SymbolInfo($1->getName(), $1->getType());
	delete $1;
}
	| simple_expression RELOP simple_expression	{
		string type = "CONST_INT";
		//typeCast2($1->getType(),$3->getType());
		$$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(),type);

		string labelT = "L"+to_string(++labelcnt);
		string labelF = "L"+to_string(++labelcnt);

		string s = ";line  "+to_string(line_count)+": "+$1->getName()+$2->getName()+$3->getName()+"\n";
		s += "\tPOP BX\n";
		s += "\tPOP AX\n";
		s += "\tCMP AX, BX\n";
		if($2->getName() == "<"){
			s += "\tJL "+labelT+"\n";
		}
		else if($2->getName() == ">"){
			s += "\tJG "+labelT+"\n";
		}
		else if($2->getName() == "<="){
			s += "\tJLE "+labelT+"\n";
		}
		else if($2->getName() == ">="){
			s += "\tJGE "+labelT+"\n";
		}
		else if($2->getName() == "=="){
			s += "\tJE "+labelT+"\n";
		}
		else if($2->getName() == "!="){
			s += "\tJNE "+labelT+"\n";
		}
		s += "\tPUSH 0\n";
		s += "\tJMP "+labelF+"\n";
		s += labelT+":\n";
		s += "\tPUSH 1\n";
		s += labelF+":\n";

		append("1905088_Asm.asm",s,asmCSend);
		int cnt = 0;
		for(int i=0; i<s.size(); i++){
			if(s[i] == '\n') cnt++;
		}
		cnt +=1;
		asmLinecnt += cnt;
		asmCSend += cnt;

		delete $1;
		delete $2;
		delete $3;
}
;
				
simple_expression : term {
	$$ = new SymbolInfo($1->getName(), $1->getType());
	delete $1;
}
	| simple_expression ADDOP term {
		string type = $3->getType();
		if(checkVoidFunc($1));
		else if(checkVoidFunc($3)){
			type = $1->getType();
		}
		else{
			type = typeCast2($1->getType(),$3->getType());
		}
		$$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(),type);

		string s = ";line  "+to_string(line_count)+": "+$1->getName()+$2->getName()+$3->getName()+"\n";
		s += "\tPOP BX\n";
		s += "\tPOP AX\n";
		if($2->getName() == "+"){
			s += "\tADD AX, BX\n";
		}
		else{
			s += "\tSUB AX, BX\n";
		}
		s += "\tPUSH AX\n";

		append("1905088_Asm.asm",s,asmCSend);
		asmLinecnt += 6;
		asmCSend += 6;

		delete $1;
		delete $2;
		delete $3;
}
;
					
term :	unary_expression {
	$$ = new SymbolInfo($1->getName(), $1->getType());
	delete $1;
	}
    |  term MULOP unary_expression {
		string type = $3->getType();
		if(checkVoidFunc($1));
		else if(checkVoidFunc($3)){
			type = $1->getType();
		}
		else if($2->getName() == "%"){
			type = "CONST_INT";
		}
		else{
			type = typeCast2($1->getType(), $3->getType());
		}
		$$ = new SymbolInfo($1->getName()+$2->getName()+$3->getName(), type);

		string s = ";line  "+to_string(line_count)+": "+$1->getName()+$2->getName()+$3->getName()+"\n";
		s += "\tPOP BX\n";
		s += "\tPOP AX\n";
		if($2->getName() == "*"){
			s += "\tIMUL BX\n";
		}
		else{
			s += "\tXOR DX,DX\n";
			s += "\tIDIV BX\n";
			if($2->getName() == "%"){
				s += "\tMOV AX,DX\n";
			}
		}
		s += "\tPUSH AX\n";

		append("1905088_Asm.asm",s,asmCSend);
		int cnt = 0;
		for(int i=0; i<s.size(); i++){
			if(s[i] == '\n') cnt++;
		}
		cnt +=1;
		asmLinecnt += cnt;
		asmCSend += cnt;

		delete $1;
		delete $2;
		delete $3;
	}
    ;

unary_expression : ADDOP unary_expression {;
	$$ = new SymbolInfo($1->getName() + $2->getName(), $2->getType());
	string name = $2->getName();
	if($1->getName() == "-"){
		string s = ";line  "+to_string(line_count)+": -"+name+"\n";
		s += "\tPOP AX\n";
		s += "\tNEG AX\n";
		s += "\tPUSH AX\n";
		append("1905088_Asm.asm",s,asmCSend);
		asmLinecnt += 5;
		asmCSend += 5;
	}

	delete $1;
	delete $2;
} 
	| NOT unary_expression {
		$$ = new SymbolInfo("!"+$2->getName(), $2->getType());
		string name = $2->getName();
		string label1 = "L"+to_string(++labelcnt);
		string label2 = "L"+to_string(++labelcnt);

		string s = ";line  "+to_string(line_count)+": NOT "+name+"\n";
		s+="\tPOP AX\n";
		s+="\tCMP AX, 0\n";
		s+="\tJE "+label1+"\n";
		s+="\tPUSH 0\n";
		s+="\tJMP "+label2+"\n";
		s+= label1+":\n";
		s+="\tPUSH 1\n";
		s+= label2+":";

		append("1905088_Asm.asm",s,asmCSend);
		asmLinecnt += 9;
		asmCSend += 9;

		delete $1;
		delete $2;
	}
	| factor {
		$$ = new SymbolInfo($1->getName(), $1->getType());
		delete $1;
	}
	;
	
factor	: variable {
	$$ = new SymbolInfo($1->getName(), $1->getType());
	SymbolID* id = (SymbolID*)$1;
	if(id->getArrsize()>0){
		append("1905088_Asm.asm","POP BX\t;array index popped",asmCSend);
		asmLinecnt++;
		asmCSend++;
	}
	delete $1;
}
	| ID LPAREN argument_list RPAREN {
		string name = $1->getName();
		string varName = $1->getName()+"("+$3->getName()+")";

		SymbolInfo *si = st.LookUp(name);
		if(si == NULL){
			$$ = new SymbolInfo(varName,"UNDECLARED");
		}
		else if(si->getFunc()){
			Function* f = (Function*)si;
			string ret = f->getReturnType();
			if(ret == "CONST_VOID"){
				//ret = "FUNC_VOID";
			}
			$$ = new SymbolInfo(varName,ret);

				for(int i=0; i<arg_list.size(); i++){
					typeCast(f->getParamList()[i],arg_list[i]->getType());
					
				}
				for(int i=0; i<arg_list.size(); i++){
					arg_list.erase(arg_list.begin()++);
				}
		}
		else{
			$$ = new SymbolInfo(varName,((SymbolID*)si)->getDataType());
		}

		string s = "\tCALL "+name+"\n";
		s += "\tPUSH AX\t;pushed return value of "+name;
		append("1905088_Asm.asm",s,asmCSend);
		asmLinecnt+=2;
		asmCSend +=2;

		arg_list.clear();
		delete $1;
		delete $2;
		delete $3;
		delete $4;
	}
	| LPAREN expression RPAREN {
		$$ = new SymbolInfo("(" + $2->getName() + ")",$2->getType());

		delete $1;
		delete $2;
		delete $3;
	}
	| CONST_INT {
		string name = $1->getName();
		$$ = new SymbolInfo(name, $1->getType());

		string s = "\tPUSH "+name;
		append("1905088_Asm.asm",s,asmCSend);
		asmLinecnt++;
		asmCSend++;

		delete $1;
	}
	| CONST_FLOAT {
		$$ = new SymbolInfo($1->getName(), $1->getType());
		delete $1;
	}

	| CONST_CHAR {
		$$ = new SymbolInfo($1->getName(), $1->getType());
		delete $1;
	}
	| variable INCOP %prec POSTFIX_INCOP {
		$$ = new SymbolInfo($1->getName()+"++",$1->getType());
		string name = $1->getName();
		SymbolID* id = (SymbolID*)$1;
		string s=";line "+to_string(line_count)+": "+name+"++\n";
		if(id->getArrsize()>0){
			s +="\tPOP BX\n";
			if(id->getOffset() != -1){
				s +="\tPUSH BP\n";
				s +="\tMOV BP,BX\n";
				s +="\tMOV AX,[BP]\n";
			}
			else{
				s += "\tMOV AX,[BX]\n";
			}
		}
		else{
			s += "\tPOP AX\n";
			s += "\tPUSH AX\n";
		}
		s += "\tINC AX\n";

		if(id->getOffset() != -1){
			if(id->getArrsize()>0){
				s += "\tMOV [BP],AX\n";
				s += "\tPOP BP\n";
			}
			else{
				string num = to_string(id->getOffset());
				s += "\tMOV [BP+"+num+"],AX\n";
			}
		}
		else{
			if(id->getArrsize()>0){
				s += "\tMOV "+name+ "[BX],AX\n";
			}
			else{
				s += "\tMOV "+name+",AX\n";
			}
		}

		append("1905088_Asm.asm",s,asmCSend);
		int cnt = 0;
		for(int i=0; i<s.size(); i++){
			if(s[i]=='\n') cnt++;
		}
		cnt += 1;
		asmLinecnt +=cnt;
		asmCSend += cnt;
		
		delete $1;
		delete $2;
	}
	| INCOP variable %prec PREFIX_INCOP {}
	| variable DECOP %prec POSTFIX_DECOP{
		$$ = new SymbolInfo($1->getName()+"--",$1->getType());
		string name = $1->getName();
		SymbolID* id = (SymbolID*)$1;
		string s=";line "+to_string(line_count)+": "+name+"--\n";
		if(id->getArrsize()>0){
			s +="\tPOP BX\n";
			if(id->getOffset() != -1){
				s +="\tPUSH BP\n";
				s +="\tMOV BP,BX\n";
				s +="\tMOV AX,[BP]\n";
			}
			else{
				s += "\tMOV AX,[BX]\n";
			}
		}
		else{
			s += "\tPOP AX\n";
			s += "\tPUSH AX\n";
		}
		s += "\tDEC AX\n";

		if(id->getOffset() != -1){
			if(id->getArrsize()>0){
				s += "\tMOV [BP],AX\n";
				s += "\tPOP BP\n";
			}
			else{
				string num = to_string(id->getOffset());
				s += "\tMOV [BP+"+num+"],AX\n";
			}
		}
		else{
			if(id->getArrsize()>0){
				s += "\tMOV "+name+ "[BX],AX\n";
			}
			else{
				s += "\tMOV "+name+",AX\n";
			}
		}

		append("1905088_Asm.asm",s,asmCSend);
		int cnt = 0;
		for(int i=0; i<s.size(); i++){
			if(s[i]=='\n') cnt++;
		}
		cnt += 1;
		asmLinecnt +=cnt;
		asmCSend += cnt;
		
		delete $1;
		delete $2;
	}
	| DECOP variable %prec PREFIX_DECOP {}
	;
	
argument_list : arguments {
	$$ = new SymbolInfo($1->getName(), $1->getType());
	delete $1;
}
  | {
	$$ = new SymbolInfo("","VARIABLE");
}
;
	
arguments : arguments COMMA logic_expression {
	arg_list.push_back(new SymbolInfo($3->getName(), $3->getType()));
	$$ = new SymbolInfo($1->getName()+","+$3->getName(),"VARIABLE");
	delete $1;
	delete $2;
	delete $3;
}
	| logic_expression {
		arg_list.push_back(new SymbolInfo($1->getName(), $1->getType()));
		$$ = new SymbolInfo($1->getName(), $1->getType());
		delete $1;
}
;
 

%%
void ProcPrintln(){
	string s = "PRINT_OUTPUT PROC NEAR;print what is in AX\n";
	s += "\tPUSH BP\n";
	s += "\tMOV BP,SP\n";
	s += "\tMOV BX, [BP+4]\n";
	s += "\tCMP BX, 0  ;(BX<-1) for positive number\n";
	s += "\tJGE PRINT_POSITIVE\n";
	s += "\tMOV AH, 2   ;(AH<-2) for negative number\n";
	s += "\tMOV DL, '-'\n";
	s += "\tINT 21H\n";
	s += "\tNEG BX\n";
	s += "PRINT_POSITIVE:\n";
	s += "\tMOV AX, BX\n";
	s += "\tMOV CX, 0\n";
	s += "PUSH_WHILE:\n";
	s += "\tXOR DX, DX\n";
	s += "\tMOV BX, 10\n";
	s += "\tDIV BX\n";
	s += "\tPUSH DX\n";
	s += "\tINC CX\n";
	s += "\tCMP AX, 0\n";
	s += "\tJE PUSH_END_WHILE\n";
	s += "\tJMP PUSH_WHILE\n";
	s += "PUSH_END_WHILE:\n";
	s += "\tMOV AH, 2\n";
	s += "POP_WHILE:\n";
	s += "\tPOP DX\n";
	s += "\tADD DL, '0'\n";
	s += "\tINT 21H\n";
	s += "\tDEC CX\n";
	s += "\tCMP CX, 0\n";
	s += "\tJLE END_POP_WHILE\n";
	s += "\tJMP POP_WHILE\n";
	s += "END_POP_WHILE:\n";
	s += "\tPOP BP\n";
	s += "\tRET 2\n";
	s += "PRINT_OUTPUT ENDP\n";
	append("1905088_Asm.asm",s);
	int cnt = 0;
	for(int i=0; i<s.size(); i++){
		if(s[i]=='\n') cnt++;
	}
	cnt += 1;
	asmLinecnt +=cnt;
	asmCSend += cnt;
}

void ProcNewline(){
	string s;
	s += "NEW_LINE PROC\n";
	s += "\tPUSH AX\n";
	s += "\tPUSH DX\n";
	s += "\tMOV AH, 2\n";
	s += "\tMOV DL, CR\n";
	s += "\tINT 21H\n";
	s += "\tMOV AH, 2\n";
	s += "\tMOV DL, LF\n";
	s += "\tINT 21H\n";
	s += "\tPOP DX\n";
	s += "\tPOP AX\n";
	s += "\tRET\n";
	s += "NEW_LINE ENDP\n";
	append("1905088_Asm.asm",s);
	int cnt = 0;
	for(int i=0; i<s.size(); i++){
		if(s[i]=='\n') cnt++;
	}
	cnt += 1;
	asmLinecnt +=cnt;
	asmCSend += cnt;
}

int main(int argc,char *argv[])
{
	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	asmFile.open("1905088_Asm.asm");
	asmFile<<";-------"<<endl;
	asmFile<<";-------"<<endl;
	asmFile<<".MODEL SMALL"<<endl;
	asmFile<<".STACK 1000H"<<endl;
	asmFile<<".DATA"<<endl;
	asmFile<<"\tCR EQU 0DH"<<endl;
	asmFile<<"\tLF EQU 0AH"<<endl;
	asmLinecnt +=7;
	asmDSend = asmLinecnt;
	asmFile<<".CODE"<<endl;
	asmCSend = ++asmLinecnt;
	asmFile.close();

	yyin=fp;
	yyparse();

	ProcNewline();
	ProcPrintln();
	
	asmFile.open("1905088_Asm.asm",ios::app);
	asmFile<<"END MAIN"<<endl;
	asmLinecnt++;
	asmFile.close();
	
	fclose(fp);

	bool isOptimized = false;
	isOptimized = optimizeCode("1905088_Asm.asm", "1905088_AsmOptimized.asm");
	if(isOptimized){
		cout<<"Optimized Code Generated"<<endl;
	}
	else{
		cout<<"Optimization Failed"<<endl;
	}
	
	return 0;
}