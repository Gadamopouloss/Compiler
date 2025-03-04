%{
    #include "syntax.tab.h"
    #include <stdio.h>
    #include <stdlib.h>
    #include <math.h>
    #include <string.h>
	#include <ctype.h>
	#include <errno.h>

    char buffer[256];
    int er_counter = 0;

    void token_output(int id_token);
    
    int str_int(const char *str);
	float HexToFloat(const char *str);
	float BinToFloat(const char *str);
	float str_float(const char *str);
	void token_output(int id_token);
	void yyerror(const char* err);

%}

%option case-insensitive
%option yylineno

%x SCONST
%x SINGLE_COMMENTS
%x MULTIPLE_COMMENTS


WHITESPACE			[ \t]
LETTER				[a-zA-Z]
DIGIT				[0-9]
CHARACTER			{LETTER}|{DIGIT}
NZNUMBER			[1-9]{DIGIT}*|0
IDENTIFIER		    _?{LETTER}{CHARACTER}*(_*{CHARACTER}+)*
HEX					(0[hH][1-9a-fA-F]+[0-9a-fA-F]*)|(0[bB][1-9a-fA-F]+[0-9a-fA-F]*)
ICONST				{NZNUMBER}|{HEX}
POWER				[eE][+-]?([1-9][0-9]*|0)
FLOAT				(([1-9][0-9]*)*|0?)\.(([1-9]([0-9][1-9])*)+|0){POWER}?
CONSTP				({NZNUMBER})({POWER})
FLOATHEX			((0[hH]([1-9a-fA-F]+[0-9a-fA-F]*)*)\.(([0-9a-fA-F]*[1-9a-fA-F]+)|0))|((0[bB]([1-9a-fA-F]+[0-9a-fA-F]*)*)\.(([0-9a-fA-F]*[1-9a-fA-F]+)|0))
FCONST				{FLOAT}|{CONSTP}|{FLOATHEX}              
CCONST              '(([^\\])|(\\[ntfrbv]))'|'\\'
LISTFUNC            ((CAD*R)|(CD+R))


%%

"TYPEDEF"                       { token_output(T_TYPEDEF); return T_TYPEDEF; }
"CHAR"                          { token_output(T_CHAR); return T_CHAR; }
"INT"                           { token_output(T_INT); return T_INT; }
"FLOAT"                         { token_output(T_FLOAT); return T_FLOAT; }
"STRING"                        { token_output(T_STRING); return T_STRING; }
"CONST"                         { token_output(T_CONST); return T_CONST; }
"UNION"                         { token_output(T_UNION); return T_UNION; }
"CLASS"                         { token_output(T_CLASS); return T_CLASS; }
"PRIVATE"                       { token_output(T_PRIVATE); return T_PRIVATE; }
"PROTECTED"                     { token_output(T_PROTECTED); return T_PROTECTED; }
"PUBLIC"                        { token_output(T_PUBLIC); return T_PUBLIC; }
"STATIC"                        { token_output(T_STATIC); return T_STATIC; }
"VOID"                          { token_output(T_VOID); return T_VOID; }
"LIST"                          { token_output(T_LIST); return T_LIST; }
"CONTINUE"                      { token_output(T_CONTINUE); return T_CONTINUE; }
"BREAK"                         { token_output(T_BREAK); return T_BREAK; }
"THIS"                          { token_output(T_THIS); return T_THIS; }
"IF"                            { token_output(T_IF); return T_IF; }
"ELSE"                          { token_output(T_ELSE); return T_ELSE; }
"WHILE"                         { token_output(T_WHILE); return T_WHILE; }
"FOR"                           { token_output(T_FOR); return T_FOR; }
"RETURN"                        { token_output(T_RETURN); return T_RETURN; }
"LENGTH"                        { token_output(T_LENGTH); return T_LENGTH; }
"NEW"                           { token_output(T_NEW); return T_NEW; }
"CIN"                           { token_output(T_CIN); return T_CIN; }
"COUT"                          { token_output(T_COUT); return T_COUT; }
"MAIN"                          { token_output(T_MAIN); return T_MAIN; }
{LISTFUNC}                      { token_output(T_LISTFUNC); return T_LISTFUNC; }
 
{IDENTIFIER}                    { token_output(T_ID); yylval.id = strdup(yytext); return T_ID; }
{ICONST}                        { token_output(T_ICONST); yylval.iconst = str_int(yytext); return T_ICONST;}
{FCONST}                        { token_output(T_FCONST); yylval.fconst = str_float(yytext); return T_FCONST;}
{CCONST}                        { token_output(T_CCONST); yylval.cconst = strdup(yytext); return T_CCONST;}


\"                       { strcpy(buffer, ""); BEGIN(SCONST); }
<SCONST>\"               { BEGIN(INITIAL); printf("Found String: '%s' \n", buffer); yylval.sconst = strdup(yytext); return T_SCONST;}
<SCONST>(\\\n|\\\r\n)    { }
<SCONST>(\\.|[^"\\])     { 
                             
                            if(strlen(yytext) == 2) {                               
                                if(strcmp(yytext,"\\n") == 0) {
                                    strcat(buffer,"\n");
                                }else if (strcmp(yytext, "\\t") == 0) {
                                    strcat(buffer,"\t");
                                }else if (strcmp(yytext, "\\r") == 0) {
                                    strcat(buffer,"\r");
                                }else if (strcmp(yytext, "\\f") == 0) {
                                    strcat(buffer,"\f");
                                }else if (strcmp(yytext, "\\b") == 0) {
                                    strcat(buffer,"\b");
                                }else if (strcmp(yytext, "\\v") == 0) {
                                    strcat(buffer,"\v");
                                }else {
                                    strcat(buffer, &yytext[1]);
                                }
                            }else {
                                strcat(buffer, yytext); 
                            }   
                         }
<SCONST>(\n|\r\n)        { yyerror("New line found without \\."); }
<SCONST><<EOF>>          { yyerror("End of string without closing it."); }   
<SCONST>.                { yyerror("Unkown Character."); }


"//"                                { printf("Comment found\n"); BEGIN(SINGLE_COMMENTS); }
<SINGLE_COMMENTS>(\n|\r\n)     		{ BEGIN(INITIAL); printf("Comment ended\n"); } 
<SINGLE_COMMENTS>.             		{    }

"/*"                                { printf("Comment found\n"); BEGIN(MULTIPLE_COMMENTS); }
<MULTIPLE_COMMENTS>"*"+"/"          { BEGIN(INITIAL);  printf("Comment ended\n"); }
<MULTIPLE_COMMENTS>[*]*             {    }
<MULTIPLE_COMMENTS><<EOF>>          { yyerror("Unterminated comment"); return 0;}


"||"          		{ token_output(T_OROP); return T_OROP; }
"&&"         		{ token_output(T_ANDOP); return T_ANDOP; }
"=="         		{ token_output(T_EQUOP); return T_EQUOP; }
"!="         		{ token_output(T_EQUOP); return T_EQUOP; }
"!"         		{ token_output(T_NOTOP); return T_NOTOP; }
">"          		{ token_output(T_RELOP); return T_RELOP; }
">="          		{ token_output(T_RELOP); return T_RELOP; }
"<"          		{ token_output(T_RELOP); return T_RELOP; }
"<="         		{ token_output(T_RELOP); return T_RELOP; }
"+"             { token_output(T_ADDOP); return T_ADDOP; }
"-"             { token_output(T_ADDOP); return T_ADDOP; }
"*"             { token_output(T_MULOP); return T_MULOP; }
"/"             { token_output(T_MULOP); return T_MULOP; }
"%"             { token_output(T_MULOP); return T_MULOP; }
"++"            { token_output(T_INCDEC); return T_INCDEC; }
"--"            { token_output(T_INCDEC); return T_INCDEC; }
"("             { token_output(T_LPAREN); return T_LPAREN; }
")"             { token_output(T_RPAREN); return T_RPAREN; }
";"             { token_output(T_SEMI); return T_SEMI; }
"."             { token_output(T_DOT); return T_DOT; }
","             { token_output(T_COMMA); return T_COMMA; }
"="             { token_output(T_ASSIGN); return T_ASSIGN; }
":"             { token_output(T_COLON); return T_COLON; }
"["             { token_output(T_LBRACK); return T_LBRACK; }
"]"             { token_output(T_RBRACK); return T_RBRACK; }
"&"             { token_output(T_REFER); return T_REFER; }
"{"             { token_output(T_LBRACE); return T_LBRACE; }
"}"             { token_output(T_RBRACE); return T_RBRACE; }

"::"             { token_output(T_METH); return T_METH; }
">>"             { token_output(T_INP); return T_INP; }
"<<"             { token_output(T_OUT); return T_OUT; }
"[  \t]"        {   } /*Αναγκώριση κενών*/
"\n"            {  }/*Αναγνώριση new line (Linux)*/

<<EOF>>         { token_output(T_EOF); return T_EOF; }


%%


//Parses an integer
int str_int(const char *str) {
    if (str == NULL) {
        return 0; 
    }
    
    while (isspace((unsigned char)*str)) {
        str++;
    }

    int negative = 0;
    if (*str == '-') {
        negative = 1;
        str++;
    }

    if (strncasecmp(str, "0B", 2) == 0) {
        long long val = strtoll(str + 2, NULL, 2);
        return negative ? -(int)val : (int)val;
    } 
    else if (strncasecmp(str, "0H", 2) == 0) {
        long long val = strtoll(str + 2, NULL, 16);
        return negative ? -(int)val : (int)val;
    } 
    else {
        long long val = strtoll(str, NULL, 10);
        return negative ? -(int)val : (int)val;
    }
}

//Helper function to parse a string of [0-9A-Fa-f] digits
static long parseHexInteger(const char *start, char **endPtr) {

    // strtol automatically stops at invalid hex digit
    return strtol(start, endPtr, 16);
}


static float parseHexFraction(const char *str) {

    float fraction = 0.0f;
    float base = 1.0f / 16.0f;

    while (*str) {
        char c = (char)toupper((unsigned char)*str);
        int digit;

        if (c >= '0' && c <= '9') {
            digit = c - '0';
        } 
        else if (c >= 'A' && c <= 'F') {
            digit = 10 + (c - 'A');
        } 
        else {
            // Invalid hex digit – stop parsing or handle error
            break;
        }

        fraction += digit * base;
        base /= 16.0f;
        str++;
    }

    return fraction;
}

//Converts a string "0H..." to a float in a simple format:
float HexToFloat(const char *str) {

    if (str == NULL) {
        return 0.0f; 
    }

    str += 2;

    const char *dotPtr = strchr(str, '.');
    if (!dotPtr) {
        return (float)strtol(str, NULL, 16);
    }

    char *endPtr;
    long integerPart = parseHexInteger(str, &endPtr);

    float result = (float)integerPart;

    dotPtr++;
    float fracPart = parseHexFraction(dotPtr);

    return result + fracPart;
}

//Helper function to parse an integer part in base 2 using strtol.
static long parseBinInteger(const char *start, char **endPtr) {

    return strtol(start, endPtr, 2);
}

//Parses the fractional part of a binary string:
static float parseBinFraction(const char *str) {

    float fraction = 0.0f;
    float base = 1.0f / 2.0f;

    while (*str) {
        if (*str == '0' || *str == '1') {
            fraction += (*str - '0') * base;
            base /= 2.0f;
        } 
        else {
           
            break;
        }
        str++;
    }
    return fraction;
}

//Converts a string "0B..." to a float in a simple format:
float BinToFloat(const char *str) {

    if (str == NULL) {
        return 0.0f; 
    }

    str += 2;

    const char *dotPtr = strchr(str, '.');
    if (!dotPtr) {
        return (float)strtol(str, NULL, 2);

    }

    char *endPtr;
    long integerPart = parseBinInteger(str, &endPtr);
    float result = (float)integerPart;

    dotPtr++;
    float fracPart = parseBinFraction(dotPtr);

    return result + fracPart;
}


float str_float(const char *str) {

    if (str == NULL) {
        return 0.0f; 
    }

    while (isspace((unsigned char)*str)) {
        str++;
    }

    int negative = 0;
    if (*str == '-') {
        negative = 1;
        str++;
    }

    float result;
    if (strncasecmp(str, "0B", 2) == 0) {
        result = BinToFloat(str);
    } 
    else if (strncasecmp(str, "0H", 2) == 0) {
        result = HexToFloat(str);
    } 
    else {
        result = strtof(str, NULL);
    }

    return negative ? -result : result;
}


void token_output(int id_token) {

    if (id_token == T_ICONST) {
        printf("LINE %d INTEGER TOKEN %s (%d). Base 10: %d\n",
               yylineno, yytext, id_token, str_int(yytext));
    } 
    else if (id_token == T_FCONST) {
        printf("LINE %d FLOAT TOKEN %s (%d). Base 10: %f\n",
               yylineno, yytext, id_token, str_float(yytext));
    } 
    else {
        printf("LINE:%d TOKEN:%s (%d)\n", yylineno, yytext, id_token);
    }
}


void yyerror(const char *err) {

    er_counter++;
    printf("[ERROR - LINE %d] %s\n", yylineno, err);

    if (er_counter == 5) {
        printf("MAX ERRORS FOUND\n");
        exit(EXIT_FAILURE);
    }

    yyless(1);
}

int yywrap() {
    
    return 1;
}





