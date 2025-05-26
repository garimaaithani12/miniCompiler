// ast.h
#ifndef AST_H
#define AST_H

typedef struct ASTNode {
    const char* label;
    struct ASTNode* left;
    struct ASTNode* right;
    const char* extra;
    int id;
} ASTNode;

#endif
