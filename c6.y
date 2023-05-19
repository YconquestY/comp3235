%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "calc3.h"
#include <string.h>

/* prototypes
 * routines to construct tree node */
nodeType * opr(int oper, int nops, ...);
nodeType * id(int i);
nodeType * con(long value, int what);

int  shapeof(nodeType *p);
void freeNode(nodeType *p);
int  ex(nodeType *p);

int yylex(void);
void yyerror(char *s);

symbol table[100]; // symbol table
int    symIndex;   // max index; initialized to -1 in `main`

int i; // dummy variable in `for` loop
%}

%union  // bison command to declare `yylval`; `int` by default
{
    long   iValue;  // integer, character, and string value
    int    sIndex;  // symbol table index
    nodeType *nPtr; // node pointer
};

%token <iValue> INTEGER STRING VARIABLE
%token FOR WHILE IF PRINT PUTI_ PUTS PUTS_ PUTC PUTC_ GETS GETC READ ARRAY
%token DECL INIT ENTRY // dummy labels
// increasing order of precedence
%nonassoc IFX
%nonassoc ELSE // prevent dangling `else`

%left AND OR

%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/' '%'
%nonassoc UMINUS

%type <nPtr> stmt decl_list decl int_list stmt_list expr expr_list
%type <sIndex> var

%%

program: function { exit(0); }
       ;

function: function stmt { ex($2); freeNode($2); }
        | // ɛ
        ;

stmt: ';'      { $$ = opr(';', 2, NULL, NULL); }
    | expr ';' { $$ = $1; }
    | PRINT '(' expr ')' ';' { $$ = opr(PRINT, 1, $3); } // `puti` and `print`
    | PUTI_ '(' expr ')' ';' { $$ = opr(PUTI_, 1, $3); }
    | PUTS  '(' expr ')' ';' { $$ = opr(PUTS , 1, $3); }
    | PUTS_ '(' expr ')' ';' { $$ = opr(PUTS_, 1, $3); }
    | PUTC  '(' expr ')' ';' { $$ = opr(PUTC , 1, $3); }
    | PUTC_ '(' expr ')' ';' { $$ = opr(PUTC_, 1, $3); }
	| READ '(' var ')' ';' { $$ = opr(READ, 1, id($3)); } // `geti` and `read`
	| GETS '(' var ')' ';' { $$ = opr(GETS, 1, id($3)); }
	| GETC '(' var ')' ';' { $$ = opr(GETC, 1, id($3)); }
    | var '=' expr ';' { $$ = opr('=', 2, id($1), $3); }
    | ARRAY decl_list ';'                { $$ = $2; }       // new: array declaration
    | var '[' expr_list ']' '=' expr ';' { $$ = opr('=', 3, // new: array assignment
                                                    id($1), $3, $6); }
	| FOR '(' stmt stmt stmt ')' stmt { $$ = opr(FOR  , 4, $3, $4, $5, $7); }
    | WHILE '(' expr ')' stmt         { $$ = opr(WHILE, 2, $3, $5        ); }
    | IF '(' expr ')' stmt %prec IFX { $$ = opr(IF, 2, $3, $5    ); }
    | IF '(' expr ')' stmt ELSE stmt { $$ = opr(IF, 3, $3, $5, $7); }
    | '{' stmt_list '}' { $$ = $2; }
    ;

decl_list: decl               { $$ = opr(';', 2, $1, NULL); }
         | decl ',' /* maybe add a middle rule? */ decl_list { $$ = opr(';', 2, $1, $3  ); } // right recursion preferred
         ;

decl: var '[' int_list ']'          { table[symIndex].size = shapeof($3); // determine array shape and size
                                      $$ = opr(DECL, 2, id($1), $3);
                                    }
    | var '[' int_list ']' '=' expr { table[symIndex].size = shapeof($3); // determine array shape and size
                                      $$ = opr(INIT, 3, id($1), $3, $6);
                                    }
    ;
/* left recursion
 * A symbol uses a linked list to record the dimension of each axis for an
 * array. A new dimension is prepended to the head of `table[…].shape`, so it
 * is convenient to use left recursion to ensure the last to be inserted is the
 * first axis. */
int_list: INTEGER              { $$ = con($1, 0); }
        | int_list ',' INTEGER { $$ = opr(',', 2, $1, con($3, 0)); }
        ;

stmt_list: stmt           { $$ = $1;                  }
         | stmt_list stmt { $$ = opr(';', 2, $1, $2); }
         ;

expr: INTEGER { $$ = con($1, 0); }
	| STRING  { $$ = con($1, 1); }
    | var     { $$ = id($1);     }
    | var '[' expr_list ']' { $$ = opr(ENTRY, 2, id($1), $3); } // new: array access
    | '-' expr %prec UMINUS { $$ = opr(UMINUS, 1, $2); }
    | expr '+' expr { $$ = opr('+', 2, $1, $3); }
    | expr '-' expr { $$ = opr('-', 2, $1, $3); }
    | expr '*' expr { $$ = opr('*', 2, $1, $3); }
    | expr '%' expr { $$ = opr('%', 2, $1, $3); }
    | expr '/' expr { $$ = opr('/', 2, $1, $3); }
    | expr '<' expr { $$ = opr('<', 2, $1, $3); }
    | expr '>' expr { $$ = opr('>', 2, $1, $3); }
    | expr GE  expr { $$ = opr(GE , 2, $1, $3); }
    | expr LE  expr { $$ = opr(LE , 2, $1, $3); }
    | expr NE  expr { $$ = opr(NE , 2, $1, $3); }
    | expr EQ  expr { $$ = opr(EQ , 2, $1, $3); }
	| expr AND expr { $$ = opr(AND, 2, $1, $3); }
	| expr OR  expr { $$ = opr(OR , 2, $1, $3); }
    | '(' expr ')' { $$ = $2; }
    ;
/* right recursion
 * There is no need to stick to left recursion in match of `int_list`.
 * `table[…].shape` is a linked list with head being the first dimension. Right
 * recursion constructs a tree whose LHS is always a concrete expression,
 * making it convenient for array access. */
expr_list: expr               { $$ = $1; }
         | expr ',' expr_list { $$ = opr(',', 2, $1, $3); }
         ;

var: VARIABLE { for (i = 0; i <= symIndex; i++)
                {
                    // see https://en.cppreference.com/w/c/string/byte/strcmp
                    if (strcmp(table[i].name, (char *) $1) == 0) {
                        break;
                    }
                }
                if (i > symIndex) // new variable/array
                {
                    symIndex = i;
                    table[i].name = strdup((char *) $1);
                    if (i == 0) { // 1st variable
                        table[0].addr = 0;
                    }
                    else {
                        table[i].addr = table[i-1].addr + table[i-1].size;
                    }
                    // Shape and size remains to be determined.
                    table[i].sh = NULL;
                    table[i].size = 1;
                }
                $$ = i;
              }
   ;
%%

#define SIZEOF_NODETYPE ((char *) &p->con - (char *) p)

nodeType * con(long value, int what)
{
    nodeType *p;
    size_t nodeSize;
    // allocate node
    nodeSize = SIZEOF_NODETYPE + sizeof(conNodeType);
    if ((p = malloc(nodeSize)) == NULL) {
        yyerror("out of memory");
    }
    // copy information
    p->type = typeCon;
    p->con.value = value;
    p->con.what = what;

    return p;
}

nodeType * id(int i)
{
    nodeType *p;
    size_t nodeSize;
    // allocate node
    nodeSize = SIZEOF_NODETYPE + sizeof(idNodeType);
    if ((p = malloc(nodeSize)) == NULL) {
        yyerror("out of memory");
    }
    // copy information
    p->type = typeId;
    p->id.i = i; // symbol table index but not memory address

    return p;
}

nodeType * opr(int oper, int nops, ...)
{
    va_list ap;
    nodeType *p;
    size_t nodeSize;
    int i;
    // allocate node
    nodeSize = SIZEOF_NODETYPE + sizeof(oprNodeType)
                               + (nops - 1) * sizeof(nodeType*);
    if ((p = malloc(nodeSize)) == NULL) {
        yyerror("out of memory");
    }
    // copy information
    p->type = typeOpr;
    p->opr.oper = oper;
    p->opr.nops = nops;
    va_start(ap, nops);
    for (i = 0; i < nops; i++) {
        p->opr.op[i] = va_arg(ap, nodeType *);
    }
    va_end(ap);
    return p;
}

/* construct linked list for `table[…].sh`
 * return array size */
int shapeof(nodeType *p) // `p`: root of `int_list`
{
    int size = 1, left, right;
    shape *d = NULL, *tmp;
    // Leaves are `conNodeType` in declaration, so a NULL leaf must be invalid.
    if (!p) {
        yyerror("missing array dimension\n");
    }

    switch (p->type)
    {
        case typeCon: // leaf
            size = p->con.value;
            // instantiate a node
            if ((d = malloc(sizeof(shape))) == NULL) {
                yyerror("out of memory\n");
            }
            d->dim  = size;
            d->next = NULL;
            // insert to head
            tmp = table[symIndex].sh;
            table[symIndex].sh = d;
            d->next = tmp;

            return size;
        default: // result of `opr(',', 2, con($1), $3)`
            right = shapeof(p->opr.op[1]); // handle RHS dimension first
            left  = shapeof(p->opr.op[0]);
            size = size * left * right;
    }

    return size; 
}

void freeNode(nodeType *p)
{
    int i;

    if (!p) {
        return;
    }
    if (p->type == typeOpr) {
        for (i = 0; i < p->opr.nops; i++) {
            freeNode(p->opr.op[i]);
        }
    }
    free(p);
}

void yyerror(char *s) {
    fprintf(stdout, "%s\n", s);
}

int main(int argc, char **argv)
{
    extern FILE* yyin;
    yyin = fopen(argv[1], "r");
    symIndex = -1;
    printf("\tpush\t500\n\tpop\tsp\n"); // changed: global scope has 500 cells
    yyparse();
    return 0;
}
