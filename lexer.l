%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"  
#include "parser.tab.h"
%}

%%
"int"      { return INT; }
"return"   { return RETURN; }
[0-9]+     { yylval.ival = atoi(yytext); return NUM; }
[a-zA-Z_][a-zA-Z0-9_]* { yylval.id = strdup(yytext); return ID; }
"+"        { return PLUS; }
"="        { return ASSIGN; }
";"        { return SEMICOLON; }
"("        { return LPAREN; }
")"        { return RPAREN; }
"{"        { return LBRACE; }
"}"        { return RBRACE; }

[ \t\n\r]+ { /* skip whitespace */ }
.          { /* ignore unknown char silently */ }

%%

int yywrap() { return 1; }
