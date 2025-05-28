%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"  
#include "parser.tab.h"
%}

%%
"int"      { printf("<INT> "); return INT; }
"main"     { printf("<MAIN> "); return MAIN; }
"return"   { printf("<RETURN> "); return RETURN; }
[0-9]+     { yylval.ival = atoi(yytext); printf("<NUM:%s> ", yytext); return NUM; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.id = strdup(yytext); printf("<ID:%s> ", yytext); return ID; }
"+"        { printf("<PLUS> "); return PLUS; }
"="        { printf("<ASSIGN> "); return ASSIGN; }
";"        { printf("<SEMICOLON> \n"); return SEMICOLON; }
"("        { printf("<LPAREN> "); return LPAREN; }
")"        { printf("<RPAREN> "); return RPAREN; }
"{"        { printf("<LBRACE> "); return LBRACE; }
"}"        { printf("<RBRACE> "); return RBRACE; }


[ \t\n\r]+ { /* skip whitespace */ }
.          { /* ignore unknown char silently. */ }

%%

int yywrap() { return 1; }
