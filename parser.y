%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "ast.h"
extern FILE* yyin;

ASTNode* root = NULL;

typedef struct {
    char* name;
    int ival;
} Symbol;

Symbol table[100];
int symbol_count = 0;

int lookup(char* name) {
    for (int i = 0; i < symbol_count; i++) {
        if (strcmp(table[i].name, name) == 0) return i;
    }
    return -1;
}

void insert(char* name) {
    if (lookup(name) == -1) {
        table[symbol_count].name = strdup(name);
        table[symbol_count].ival = 0;
        symbol_count++;
    }
}

ASTNode* createNode(const char* label, ASTNode* left, ASTNode* right, const char* extra) {
    ASTNode* node = (ASTNode*) malloc(sizeof(ASTNode));
    node->label = label;
    node->left = left;
    node->right = right;
    node->extra = extra;
    static int ast_id_counter = 0;
node->id = ast_id_counter++; // or use a separate counter if preferred
    return node;
}

void printDOTNode(ASTNode* node, FILE* out);
void printDOT(ASTNode* root);
void yyerror(const char *s);
int yylex(void);

int temp_count = 0;

char* newTemp() {
    char* buf = (char*) malloc(16);
    sprintf(buf, "t%d", temp_count++);
    return buf;
}

char* reportedUndeclared[100];
int undeclaredCount = 0;

int alreadyReported(char* name) {
    for (int i = 0; i < undeclaredCount; i++) {
        if (strcmp(reportedUndeclared[i], name) == 0) return 1;
    }
    return 0;
}

void reportUndeclared(char* name) {
    if (!alreadyReported(name)) {
        printf("Error: Undeclared variable %s\n", name);
        reportedUndeclared[undeclaredCount++] = strdup(name);
    }
}

int hasSemanticError = 0;
char* full3ACCode = NULL;

%}


%union {
    int ival;
    char* id;
    struct {
        int val;
        char* code;
        ASTNode* ast;
        char* place;
    } exprAttr;
    ASTNode* ast;
}

%token <id> ID
%token INT RETURN
%token PLUS ASSIGN SEMICOLON LPAREN RPAREN LBRACE RBRACE
%token <ival> NUM

%type <ast> stmt statement_list function function_list
%type <exprAttr> expr

%%

program:
    function_list { root = $1; }
;

function_list:
    function
    {
        $$ = $1;
    }
  | function_list function
    {
        $$ = createNode("function_list", $1, $2, NULL);
    }
;

function:
    INT ID LPAREN RPAREN LBRACE statement_list RBRACE
    {
        $$ = createNode("function", $6, NULL, $2);
    }
;

statement_list:
    stmt
    {
        $$ = $1;
    }
  | statement_list stmt
    {
        $$ = createNode("stmt_list", $1, $2, NULL);
    }
;

stmt:
    INT ID SEMICOLON
    {
        insert($2);
        printf("Declared int variable: %s\n", $2);
        $$ = createNode("decl", NULL, NULL, $2);
    }
  | ID ASSIGN expr SEMICOLON
    {
        int idx = lookup($1);
        if (idx == -1) {
            reportUndeclared($1);
            hasSemanticError = 1;
        } else {
            table[idx].ival = $3.val;
           if (!hasSemanticError) {
            char buffer[256];
            sprintf(buffer, "%s%s = %s\n", $3.code, $1, $3.place);
            strcat(full3ACCode, buffer);
        }
        }

        $$ = createNode("assign", createNode($1, NULL, NULL, NULL), $3.ast, NULL);
    }
  | RETURN expr SEMICOLON
    {
        if (!hasSemanticError) {
        printf("Return statement: %d\n\n", $2.val);
    }
    $$ = createNode("return", $2.ast, NULL, NULL); 
    }
;


expr:
    NUM {
        $$.val = $1;
        $$.place = newTemp();
        $$.code = (char*) malloc(64);
        sprintf($$.code, "%s = %d\n", $$.place, $1);

        char* buf = (char*) malloc(16);
        sprintf(buf, "%d", $1);
        $$.ast = createNode("const", NULL, NULL, buf);
    }
  | ID {
        int idx = lookup($1);
        if (idx == -1) {
           reportUndeclared($1);
            $$.val = 0;
        } else {
            $$.val = table[idx].ival;
        }
        $$.place = strdup($1);  // use variable name directly
        $$.code = strdup("");   // no code needed
        $$.ast = createNode("var", NULL, NULL, $1);
    }
  | expr PLUS expr {
        $$.val = $1.val + $3.val;
        $$.place = newTemp();

        // generate 3AC code: combine left, right and result
        $$.code = (char*) malloc(strlen($1.code) + strlen($3.code) + 64);
        sprintf($$.code, "%s%s%s = %s + %s\n", 
                $1.code, $3.code, $$.place, $1.place, $3.place);

        $$.ast = createNode("+", $1.ast, $3.ast, NULL);
    }
;


%%

void printDOTNode(ASTNode* node, FILE* out) {
    if (!node) return;
    fprintf(out, "  node%d [label=\"%s", node->id, node->label);
    if (node->extra)
        fprintf(out, ": %s", node->extra);
    fprintf(out, "\"];\n");

    if (node->left) {
        printDOTNode(node->left, out);
        fprintf(out, "  node%d -> node%d;\n", node->id, node->left->id);
    }
    if (node->right) {
        printDOTNode(node->right, out);
        fprintf(out, "  node%d -> node%d;\n", node->id, node->right->id);
    }
}

void printDOT(ASTNode* root) {
    FILE* out = fopen("ast.dot", "w");
    if (!out) {
        fprintf(stderr, "Error opening ast.dot for writing\n");
        return;
    }
    fprintf(out, "digraph AST {\n");
    printDOTNode(root, out);
    fprintf(out, "}\n");
    fclose(out);
    printf("AST written to ast.dot\n");
}

void yyerror(const char *s) {
    fprintf(stderr, "Error: %s\n", s);
}

void generateAssembly(const char* code) {
    printf("\n=== Assembly Code ===\n");

    char* codeCopy = strdup(code);
    char* line = strtok(codeCopy, "\n");

    while (line != NULL) {
        char dest[32], src1[32], src2[32];
        int val;

        // Case 1: direct assignment: t0 = 5
        if (sscanf(line, "%s = %d", dest, &val) == 2) {
            printf("MOV %s, %d\n", dest, val);
        }
        // Case 2: addition: t2 = a + t1
        else if (sscanf(line, "%s = %s + %s", dest, src1, src2) == 3) {
            printf("ADD %s, %s, %s\n", dest, src1, src2);
        }
        // Case 3: copy assignment: a = t0
        else if (sscanf(line, "%s = %s", dest, src1) == 2) {
            printf("MOV %s, %s\n", dest, src1);
        }
        else {
            printf("; Unrecognized: %s\n", line);
        }

        line = strtok(NULL, "\n");
    }

    free(codeCopy);
}


int main(int argc, char* argv[]) {
    printf("Mini C Compiler Starting...\n");

if (argc > 1) {
        FILE* in = fopen(argv[1], "r");
        if (!in) {
            perror("Error opening input file");
            return 1;
        }
        yyin = in;  
    }

    full3ACCode = (char*) malloc(10000);
    full3ACCode[0] = '\0';
    yyparse();

    if (hasSemanticError) {
        printf("\nCompilation failed due to semantic errors.\n");
        return 1;   // stop here, do NOT generate AST or 3AC
    }
    if (!hasSemanticError) {
    printf("3AC:\n%s", full3ACCode);
    generateAssembly(full3ACCode);

    
}

    printf("=== Symbol Table ===\n");
    for (int i = 0; i < symbol_count; i++) {
        printf("%s : int : %d\n", table[i].name, table[i].ival);
    }

    if (root) {
        printDOT(root);

        
        printf("AST image generated and opened.\n");
    }

    printf("Parsing complete.\n");
    return 0;
}



