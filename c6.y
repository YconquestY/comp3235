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
int  symIndexof(int, char *);
void freeNode(nodeType *p);
int  ex(nodeType *p);
void exf(int);

int yylex(void);
void yyerror(char *s);

symbol tables[MAX_SCOPE][MAX_SYM]; // symbol tables; `tables[0][…]`: global scope
int    scopeIndex;                 // index of current scope
int    nscope;                     // no. of scopes , i.e. index of next new scope
int    symIndex[MAX_SCOPE];        // max. index of newest variable (per scope)
func   funcs[MAX_FUNC]; // function environment; `funcs[0]` not used

int i, j; // dummy variables in `for` loop
%}

%union { // bison command to declare `yylval`; `int` by default
    long iValue;    // integer, character, and string value
    int  sIndex;    // data/function environment index
    nodeType *nPtr; // node pointer
};

%token <iValue> INTEGER STRING VARIABLE
%token FOR WHILE IF PRINT PUTI_ PUTS PUTS_ PUTC PUTC_ GETS GETC READ ARRAY FUNC RETURN
%token DECL         // array declaration
%token INIT         // array declaration w/ initialization
%token GVAR         // global variable access
%token GASSIGN      // global variable assignment
%token ENTRY GENTRY // (global) array    access
%token CALL         // (global) function call
%token RTRN         // exiplicat `return …` statement
%token GREAD GGETC GGETS // update global variable
// increasing order of precedence
%nonassoc IFX
%nonassoc ELSE // prevent dangling `else`

%left AND OR

%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/' '%'
%nonassoc UMINUS

%type <nPtr> mix func stmt str_list decl_list decl int_list stmt_list expr expr_list
%type <sIndex> var gvar
%type <sIndex> fdef /* fcall */

%%
/* It is a must to compile global statements first. The function body relies on
 * global statements to determine if there is pass-by-reference. */
program: mix { ex($1);            // compile global statements
               printf("\tend\n"); // end of program
               exf();             // compile functions
               freeNode($1);
               // TODO: free data/function environment
               exit(0);
             }
       ;

mix: mix stmt { $$ = opr(';', 2, $1, $2); }
   | mix func { $$ = opr(';', 2, $1, $2); } // new: function declaration
   | /* ɛ */  { $$ = NULL; }                // `$2`, i.e., function declaration, is `NULL`.
   ;
/* Entering the function scope must take place prior to the reduction of
 * `stmt_list`. This is because the reduction, which may include local
 * variables, already happens prior to end-of-rule actions. Had one entered the
 * function scope as an end-of-rule action, local variables would be put to the
 * global scope.
 *
 * This also enables a shared symbol table of function parameters and local
 * variables/arrays. */
func: FUNC fdef '(' str_list ')' '{' stmt_list '}'
      { // get function metadata
        // positional arguments at bottom `tables[…]…`
        funcs[scopeIndex].body  = $7;

        scopeIndex = 0; // return to global scope
        $$ = NULL;      // function body recorded in separate function environment
      }
    | FUNC fdef '(' ')' '{' stmt_list '}' // A function may come with no parameter.
      { // get function metadata
        funcs[scopeIndex].nargs = 0; // no positional parameters
        funcs[scopeIndex].body  = $6;

        scopeIndex = 0; // return to global scope
        $$ = NULL;      // function body recorded in separate function environment
      }
    ;

fdef: VARIABLE { scopeIndex = nscope++;
                 // get function metadata
                 printf("\t// func: %s, location: funcs[%d]\n", (char *) $1, scopeIndex);
                 funcs[scopeIndex].name  = strdup((char *) $1);
                 funcs[scopeIndex].ret   = 0;
                 funcs[scopeIndex].label = lbl++;

                 $$ = scopeIndex;
               }
    ;
/* right recursion
 * Function parameters and variables/arrays local to the function call share a
 * symbol table. Adopting right recursion to construct the AST guarantees the
 * left child is always a concrete prior parameter, and that the right one is
 * an AST of ensuing parameters. It is a must to use right recursion because
 * function arguments must be "pushed" to the symbol table in a left-to-right
 * order: it is useful in accessing those arguments, i.e., when calling
 * `push fp[…]`. `symIndex[…]` increases as a new parameter appears.
 *
 * This is different than `int_list`, which adopts left recursion and is
 * represented by a linked list. */
str_list: var              { funcs[scopeIndex].nargs++; $$ = con($1, 1);                  }
        | var ',' str_list { funcs[scopeIndex].nargs++; $$ = opr(',', 2, con($1, 1), $3); }
          /* ɛ is excluded from the production in that it makes the grammar
           * ambiguous. Instead, this case is handled in an upper level. */
        ;

stmt: ';'      { $$ = opr(';', 2, NULL, NULL); }
    | expr ';' { $$ = $1; }
    | RETURN expr ';' { funcs[scopeIndex].ret = 1; // new: return single value in function
                        $$ = opr(RTRN, 1, $2);
                      }
    | RETURN      ';' { $$ = opr(RTRN, 1, NULL); } // new: return nothing in function
    | PRINT '(' expr ')' ';' { $$ = opr(PRINT, 1, $3); } // `puti` and `print`
    | PUTI_ '(' expr ')' ';' { $$ = opr(PUTI_, 1, $3); }
    | PUTS  '(' expr ')' ';' { $$ = opr(PUTS , 1, $3); }
    | PUTS_ '(' expr ')' ';' { $$ = opr(PUTS_, 1, $3); }
    | PUTC  '(' expr ')' ';' { $$ = opr(PUTC , 1, $3); }
    | PUTC_ '(' expr ')' ';' { $$ = opr(PUTC_, 1, $3); }
	| READ '('      var ')' ';' { $$ = opr( READ, 1, id($3)); } // `geti` and `read`
    | READ '(' '@' gvar ')' ';' { $$ = opr(GREAD, 1, id($4)); } // new: update global variable
	| GETS '('      var ')' ';' { $$ = opr( GETS, 1, id($3)); }
    | GETS '(' '@' gvar ')' ';' { $$ = opr(GGETS, 1, id($4)); } // new: update global variable
	| GETC '('      var ')' ';' { $$ = opr( GETC, 1, id($3)); }
    | GETC '(' '@' gvar ')' ';' { $$ = opr(GGETC, 1, id($4)); } // new: update global variable
    |      var '=' expr ';' { $$ = opr('='    , 2, id($1), $3); } //      local  variable assignment
    | '@' gvar '=' expr ';' { $$ = opr(GASSIGN, 2, id($2), $4); } // new: global variable assignment
    | ARRAY decl_list ';' { $$ = $2; } // new: array declaration
    |      var '[' expr_list ']' '=' expr ';' { $$ = opr('=', 3, // new: local array assignment
                                                         id($1), $3, $6); }
    | '@' gvar '[' expr_list ']' '=' expr ';' { $$ = opr(GASSIGN, 3, // new: global array assignment
                                                         id($2), $4, $7); }
	| FOR '(' stmt stmt stmt ')' stmt { $$ = opr(FOR  , 4, $3, $4, $5, $7); }
    | WHILE '(' expr ')' stmt         { $$ = opr(WHILE, 2, $3, $5        ); }
    | IF '(' expr ')' stmt %prec IFX { $$ = opr(IF, 2, $3, $5    ); }
    | IF '(' expr ')' stmt ELSE stmt { $$ = opr(IF, 3, $3, $5, $7); }
    | '{' stmt_list '}' { $$ = $2; }
    ;

decl_list: decl               { $$ = opr(';', 2, $1, NULL); }
         | decl ',' decl_list { $$ = opr(';', 2, $1, $3  ); } // right recursion preferred
         ;

decl: var '[' int_list ']'          { // determine array shape and size
                                      tables[scopeIndex][ symIndex[scopeIndex] ].size = shapeof($3);
                                      $$ = opr(DECL, 2, id($1), $3);
                                    }
    | var '[' int_list ']' '=' expr { // determine array shape and size
                                      tables[scopeIndex][ symIndex[scopeIndex] ].size = shapeof($3);
                                      $$ = opr(INIT, 3, id($1), $3, $6);
                                    }
    ;
/* left recursion
 * A symbol uses a linked list to record the dimension of each axis for an
 * array. Adopting left recursion to construct the AST guarantees the right
 * child is always a concrete ensuing dimension, and that the left one is an
 * AST recording prior dimensions. A new dimension is prepended to the head of
 * `tables[…].shape`. By first prepending the right child and then proceeding
 * to the left subtree, left recursion ensures the last to be inserted is the
 * first axis. That is, `tables[…].sh` points to the leading dimension.
 *
 * This is different than `str_list`, which adopts right recursion and is
 * recorded directly in a symbol table. */
int_list: INTEGER              { $$ = con($1, 0); }
        | int_list ',' INTEGER { $$ = opr(',', 2, $1, con($3, 0)); }
        ;

stmt_list: stmt           { $$ = $1;                  }
         | stmt_list stmt { $$ = opr(';', 2, $1, $2); }
         ;

expr: INTEGER { $$ = con($1, 0); }
	| STRING  { $$ = con($1, 1); }
    |      var { $$ =              id($1) ; } //      local  variable access
    | '@' gvar { $$ = opr(GVAR, 1, id($2)); } // new: global variable access
    |      var '[' expr_list ']' { $$ = opr( ENTRY, 2, id($1), $3); } // new: local array access
    | '@' gvar '[' expr_list ']' { $$ = opr(GENTRY, 2, id($2), $4); } // new: global array access
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
    |     VARIABLE '(' expr_list ')' { $$ = opr(CALL, 2, con($1,1), $3  ); } // new: function call
    |     VARIABLE '('           ')' { $$ = opr(CALL, 2, con($1,1), NULL); } //      function call w/o parameter
    | '@' VARIABLE '(' expr_list ')' { $$ = opr(CALL, 2, con($2,1), $4  ); } // new: call global function
    | '@' VARIABLE '('           ')' { $$ = opr(CALL, 2, con($2,1), NULL); } //      call no-parameter global function
    | '(' expr ')' { $$ = $2; }
    ;
/* 
 * This production is shared by array indices and function arguments.
 *
 * Right recursion is adopted. There is no need to stick to left recursion in
 * match of `int_list`. `tables[…].shape` is a linked list with head being the
 * first dimension. Right recursion constructs a tree whose LHS is always a
 * concrete expression, making it convenient for array access. */
expr_list: expr               { $$ = $1; }
         | expr ',' expr_list { $$ = opr(',', 2, $1, $3); }
           /* ɛ is excluded from the production in that it makes the grammar
            * ambiguous. Instead, this case is handled in an upper level. */
         ;

var : VARIABLE { char *var = strdup(strtok((char *) $1, " +-*/%()[]{}<>=,.;@")); $$ = symIndexof(scopeIndex, var); }
    ;
gvar: VARIABLE { char *var = strdup(strtok((char *) $1, " +-*/%()[]{}<>=,.;@")); $$ = symIndexof(0, var); }
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

/* construct linked list for `tables[…][…].sh`
 * also return array size */
int shapeof(nodeType *p) // `p`: root of `int_list`
{
    int size = 1, left, right;
    shape *d = NULL, *tmp;
    // Leaves are `conNodeType` in declaration, so a NULL leaf must be invalid.
    if (!p) {
        yyerror("missing array dimension\n");
        exit(1);
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
            tmp = tables[scopeIndex][ symIndex[scopeIndex] ].sh;
            tables[scopeIndex][ symIndex[scopeIndex] ].sh = d;
            d->next = tmp;

            return size;
        default: // result of `opr(',', 2, $1, con($3,0))`
            right = shapeof(p->opr.op[1]); // handle RHS dimension first
            left  = shapeof(p->opr.op[0]);
            size = size * left * right;
    }

    return size; 
}

int symIndexof(int scope, char *var)
{
    for (i = 0; i <= symIndex[scope]; i++)
    {   // see https://en.cppreference.com/w/c/string/byte/strcmp
        if (strcmp(tables[scope][i].name, var) == 0) {
            printf("\t// var: %s, found in #%d at scope %d\n", var, i, scope);
            break;
        }
    }
    if (i > symIndex[scope]) // new variable/array
    {
        printf("\t// var: %s, new in #%d at scope %d\n", var, i, scope);
        symIndex[scope] = i;
        tables[scope][i].name = var;
        if (i == 0) { // 1st variable
            tables[scope][0].addr = 0;
        }
        else {
            tables[scope][i].addr = tables[scope][i-1].addr + tables[scope][i-1].size;
        }
        // Shape and size remains to be determined.
        tables[scope][i].sh = NULL;
        tables[scope][i].size = 1;
    }
    return i;
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
    // initialize indices and counters
    lbl = 0;

    scopeIndex = 0;
    nscope     = 1;
    for (int i = 0; i < MAX_SCOPE; i++) {
        symIndex[i] = -1;
    }

    printf("\tpush\t%d\n\tpop\tsp\n", GLOBAL); // changed: global scope has 500 cells
    yyparse();

    return 0;
}
