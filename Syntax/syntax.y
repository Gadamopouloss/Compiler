%{

#include "hashtable/hashtbl.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <math.h>
#include <string.h>

extern int yylineno;
extern int yylex();
extern FILE *yyin;
extern void yyerror(const char *s);

char *file;
int scope = 0;

HASHTBL *hashtbl;

%}

%define parse.error verbose
                         
%union {
	int iconst;
	float fconst;
	char *cconst;
	char *sconst;
	char *id;
}

%token <id>            T_ID         251
%token <iconst>        T_ICONST     252
%token <fconst>        T_FCONST     253
%token <cconst>        T_CCONST     254
%token <sconst>        T_SCONST     255

%token T_TYPEDEF        "TYPEDEF"
%token T_CHAR           "CHAR"       
%token T_INT            "INT"
%token T_FLOAT          "FLOAT"
%token T_STRING         "STRING"
%token T_CONST          "CONST"
%token T_UNION          "UNION"
%token T_CLASS          "CLASS"
%token T_PRIVATE        "PRIVATE"
%token T_PROTECTED      "PROTECTED"
%token T_PUBLIC         "PUBLIC"
%token T_STATIC         "STATIC"
%token T_VOID           "VOID"
%token T_LIST           "LIST"
%token T_CONTINUE       "CONTINUE"
%token T_BREAK          "BREAK"
%token T_THIS           "THIS"
%token T_IF             "IF"
%token T_ELSE           "ELSE"
%token T_WHILE          "WHILE"
%token T_FOR            "FOR"
%token T_RETURN         "RETURN"
%token T_LENGTH         "LENGTH"
%token T_NEW            "NEW"
%token T_CIN            "CIN"
%token T_COUT           "COUT"
%token T_MAIN           "MAIN"

%token T_OROP           "||"
%token T_ANDOP          "&&"
%token T_EQUOP          "== or !="
%token T_RELOP          "> or >= or < or <="
%token T_ADDOP          "+ or -"
%token T_MULOP          "* or / or %"
%token T_NOTOP          "!"
%token T_INCDEC         "++ or --"

%token T_LPAREN         "("
%token T_RPAREN         ")"
%token T_SEMI           ";"
%token T_DOT            "."
%token T_COMMA          "," 
%token T_ASSIGN         "="
%token T_COLON          ":"
%token T_LBRACK         "["
%token T_RBRACK         "]"
%token T_REFER          "&"
%token T_LBRACE         "{"
%token T_RBRACE         "}"
%token T_METH           "::"
%token T_INP            ">>"
%token T_OUT            "<<"

%token T_LISTFUNC       "LISTFUNC"

%token T_EOF           0            "END OF FILE"

%left T_COMMA
%right T_ASSIGN
%left T_OROP
%left T_ANDOP
%left T_EQUOP
%left T_RELOP
%left T_INP T_OUT
%left T_ADDOP
%left T_MULOP
%right T_REFER T_NOTOP
%left T_INCDEC
%nonassoc T_METH

%nonassoc IF
%nonassoc T_ELSE 

%start program
%%

program:                global_declarations main_function

global_declarations:    global_declarations global_declaration
                        | %empty

global_declaration:     typedef_declaration
                        | const_declaration
                        | class_declaration
                        | union_declaration
                        | global_var_declaration
                        | func_declaration

typedef_declaration:    T_TYPEDEF typename listspec T_ID
                        { hashtbl_insert(hashtbl, $4, NULL, scope); scope++; }
                        dims T_SEMI
                        { hashtbl_get(hashtbl, scope); scope--; }

typename:               standard_type
                        | T_ID
                        { hashtbl_insert(hashtbl, $1, NULL, scope); }

standard_type:          T_CHAR | T_INT | T_FLOAT | T_STRING | T_VOID

listspec:               T_LIST | %empty

dims:                   dims dim
                        | %empty

dim:                    T_LBRACK T_ICONST T_RBRACK
                        | T_LBRACK T_RBRACK

const_declaration:      T_CONST typename constdefs T_SEMI

constdefs:              constdefs T_COMMA constdef
                        | constdef

constdef:               T_ID
                        { hashtbl_insert(hashtbl, $1, NULL, scope); }
                        dims T_ASSIGN init_value

init_value:             expression
                        | T_LBRACE init_values T_RBRACE

expression:             expression T_OROP expression
                        | expression T_ANDOP expression
                        | expression T_EQUOP expression
                        | expression T_RELOP expression
                        | expression T_ADDOP expression
                        | expression T_MULOP expression
                        | T_NOTOP expression
                        | T_ADDOP expression
                        | T_INCDEC variable
                        | variable T_INCDEC
                        | variable
                        | variable T_LPAREN expression_list T_RPAREN
                        | T_LENGTH T_LPAREN general_expression T_RPAREN
                        | T_NEW T_LPAREN general_expression T_RPAREN
                        | constant
                        | T_LPAREN general_expression T_RPAREN
                        | T_LPAREN standard_type T_RPAREN
                        | listexpression

variable:               variable T_LBRACK general_expression T_RBRACK
                        | variable T_DOT T_ID
                        { hashtbl_insert(hashtbl, $3, NULL, scope); }
                        | T_LISTFUNC T_LPAREN general_expression T_RPAREN
                        | decltype T_ID
                        { hashtbl_insert(hashtbl, $2, NULL, scope); }
                        | T_THIS

general_expression:     general_expression T_COMMA general_expression
                        | assignment

assignment:             variable T_ASSIGN assignment
                        | expression

expression_list:        general_expression
                        | %empty

constant:               T_CCONST | T_ICONST | T_FCONST | T_SCONST

listexpression:         T_LBRACK expression_list T_RBRACK

init_values:            init_values T_COMMA init_value
                        | init_value

class_declaration:      T_CLASS T_ID
                        { hashtbl_insert(hashtbl, $2, NULL, scope); scope++; }
                        class_body
                        T_SEMI
                        { hashtbl_get(hashtbl, scope); scope--; }

class_body:             parent T_LBRACE members_methods T_RBRACE

parent:                 T_COLON T_ID
                        { hashtbl_insert(hashtbl, $2, NULL, scope); }
                        | %empty

members_methods:        members_methods access member_or_method
                        | access member_or_method

access:                 T_PRIVATE T_COLON
                        | T_PROTECTED T_COLON
                        | T_PUBLIC T_COLON
                        | %empty

member_or_method:       member
                        | method

member:                 var_declaration
                        | anonymous_union

var_declaration:        typename variabledefs T_SEMI

variabledefs:           variabledefs T_COMMA variabledef
                        | variabledef

variabledef:            T_LIST T_ID
                        { hashtbl_insert(hashtbl, $2, NULL, scope); }
                        dims
                        | T_ID
                        { hashtbl_insert(hashtbl, $1, NULL, scope); }
                        dims

anonymous_union:        T_UNION
                        { scope++; }
                        union_body
                        { hashtbl_get(hashtbl, scope); scope--; }
                        T_SEMI

union_body:             T_LBRACE fields T_RBRACE
                        | error fields T_RBRACE
                        { yyerrok; }
                        | T_LBRACE fields error
                        { yyerrok; }

fields:                 fields field
                        | field

field:                  var_declaration

method:                 short_func_declaration

short_func_declaration: short_par_func_header T_SEMI
                        { hashtbl_get(hashtbl, scope); scope--; }
                        | nopar_func_header T_SEMI
                        { hashtbl_get(hashtbl, scope); scope--; }

short_par_func_header:  func_header_start T_LPAREN parameter_types T_RPAREN

func_header_start:      typename T_ID
                        { hashtbl_insert(hashtbl, $2, NULL, scope); scope++; }
                        | T_LIST T_ID
                        { hashtbl_insert(hashtbl, $2, NULL, scope); scope++; }

parameter_types:        parameter_types T_COMMA typename pass_list_dims
                        | typename pass_list_dims

pass_list_dims:         listspec dims
                        | T_REFER

nopar_func_header:      func_header_start T_LPAREN T_RPAREN
                        { }

union_declaration:      T_UNION T_ID
                        { hashtbl_insert(hashtbl, $2, NULL, scope); scope++; }
                        union_body
                        T_SEMI
                        { hashtbl_get(hashtbl, scope); scope--; }

global_var_declaration: typename init_variabledefs T_SEMI

init_variabledefs:      init_variabledefs T_COMMA init_variabledef
                        | init_variabledef

init_variabledef:       variabledef initializer

initializer:            T_ASSIGN init_value
                        | %empty

func_declaration:       short_func_declaration
                        | full_func_declaration

full_func_declaration:  full_par_func_header T_LBRACE decl_statements T_RBRACE
                        { hashtbl_get(hashtbl, scope); scope--; }
                        | nopar_class_func_header T_LBRACE decl_statements T_RBRACE
                        { hashtbl_get(hashtbl, scope); scope--; }
                        | nopar_func_header T_LBRACE decl_statements T_RBRACE
                        { hashtbl_get(hashtbl, scope); scope--; }

full_par_func_header:   class_func_header_start T_LPAREN parameter_list T_RPAREN
                        | func_header_start T_LPAREN parameter_list T_RPAREN

class_func_header_start: typename func_class T_ID
                        { hashtbl_insert(hashtbl, $3, NULL, scope); scope++; }
                        | T_LIST func_class T_ID
                        { hashtbl_insert(hashtbl, $3, NULL, scope); scope++; }

func_class:             T_ID T_METH
                        { hashtbl_insert(hashtbl, $1, NULL, scope); }

parameter_list:         parameter_list T_COMMA typename pass_variabledef
                        | typename pass_variabledef

pass_variabledef:       variabledef
                        | T_REFER T_ID
                        { hashtbl_insert(hashtbl, $2, NULL, scope); }

nopar_class_func_header: class_func_header_start T_LPAREN T_RPAREN
                        { }

decl_statements:        declarations statements
                        | declarations
                        | statements
                        | %empty

declarations:           declarations decltype typename variabledefs T_SEMI
                        | decltype typename variabledefs T_SEMI

decltype:               T_STATIC
                        | %empty

statements:             statements statement
                        | statement

statement:              expression_statement
                        | if_statement
                        | while_statement
                        | for_statement
                        | return_statement
                        | io_statement
                        | comp_statement
                        | T_CONTINUE T_SEMI
                        | T_BREAK T_SEMI
                        | T_SEMI

expression_statement:   general_expression T_SEMI

if_statement:           T_IF T_LPAREN
                        { scope++; }
                        general_expression T_RPAREN statement
                        { hashtbl_get(hashtbl, scope); scope--; }
                        if_tail

if_tail:                T_ELSE
                        { scope++; }
                        statement
                        { hashtbl_get(hashtbl, scope); scope--; }
                        | %empty %prec IF
                        { }

while_statement:        T_WHILE T_LPAREN
                        { scope++; }
                        general_expression T_RPAREN statement
                        { hashtbl_get(hashtbl, scope); scope--; }

for_statement:          T_FOR T_LPAREN
                        { scope++; }
                        optexpr T_SEMI optexpr T_SEMI optexpr T_RPAREN statement
                        { hashtbl_get(hashtbl, scope); scope--; }

optexpr:                general_expression
                        | %empty

return_statement:       T_RETURN optexpr T_SEMI
                        | T_RETURN optexpr error
                        { yyerrok; }

io_statement:           T_CIN T_INP in_list T_SEMI
                        | T_COUT T_OUT out_list T_SEMI

in_list:                in_list T_INP in_item
                        | in_item

in_item:                variable

out_list:               out_list T_OUT out_item
                        | out_item

out_item:               general_expression

comp_statement:         T_LBRACE decl_statements T_RBRACE

main_function:          main_header
                        T_LBRACE decl_statements T_RBRACE
                        { hashtbl_get(hashtbl, scope); scope--; }

main_header:            T_INT T_MAIN T_LPAREN T_RPAREN
                        | error T_MAIN T_LPAREN T_RPAREN
                        { yyerrok; }
                        | T_INT error T_LPAREN T_RPAREN
                        { yyerrok; }
                        | T_INT T_MAIN error T_RPAREN
                        { yyerrok; }
                        | T_INT T_MAIN T_LPAREN error
                        { yyerrok; }

%%


int main(int argc, char *argv[]){
	
    int token;        

    if(!(hashtbl = hashtbl_create(10, NULL))){
        puts("Error, failed to initialize");
        return EXIT_FAILURE;
    }

	if(argc > 1){       
		yyin = fopen(argv[1], "r");
		if (yyin == NULL){
			perror ("[ERROR] Could not open file"); 
			return EXIT_FAILURE;
		}
	}        

	yyparse();

    fclose(yyin);
    hashtbl_destroy(hashtbl);
    
    return 0;
}
