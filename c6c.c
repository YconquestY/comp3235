#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "calc3.h"
#include "y.tab.h"

/* A `static` variable cannot be accessed by other files.
 * see https://stackoverflow.com/a/12728454 */
int lbl;

int  ispref(int);
void traverse(nodeType *, shape *);
void offsetof(nodeType *, int, int, int);

void pusharg(nodeType *, int, int);
void argsof(nodeType *, int, int);

void yyerror(char *);

int ex(nodeType *p)
{
    int lblx, lbly, lbl1, lbl2,
        idx , // symbol table index
        pref, // pass by reference
        callee;

    if (!p) { // Function definition are `NULL` nodes.
        return 0;
    }
    char *base = (scopeIndex == 0) ? "sb" : "fp", *_base,
         *fcall;

    switch(p->type)
    {
        case typeCon:
            if (p->con.what == 0) // 0 for integer/character
                printf("\tpush\t%d\n", (int) p->con.value); 
            else // 1 for string
                printf("\tpush\t\"%s\"\n", (char *) p->con.value);
            break;
        case typeId: // variable in current scope
            printf("\tpush\t%s[%0d]\n", base, tables[scopeIndex][p->id.i].addr);
            break;
        case typeOpr:
            switch(p->opr.oper)
            {
                // an example:
                //     for (int i = 0; i < 10; i = i + 1) {
                //         └─────────┘└──────┘└─────────┘
                //            op[0]    op[1]     op[2]
                //         print(i);
                //        └────────┘
                //          op[3]
                //     }
                case FOR:
                    ex(p->opr.op[0]);
                    printf("L%03d:\n", lblx = lbl++);
                    ex(p->opr.op[1]);
                    printf("\tj0\tL%03d\n", lbly = lbl++);
                    ex(p->opr.op[3]);
                    ex(p->opr.op[2]);
                    printf("\tjmp\tL%03d\n", lblx);
                    printf("L%03d:\n", lbly);
                    break;
                case WHILE:
                    printf("L%03d:\n", lbl1 = lbl++);
                    ex(p->opr.op[0]);
                    printf("\tj0\tL%03d\n", lbl2 = lbl++);
                    ex(p->opr.op[1]);
                    printf("\tjmp\tL%03d\n", lbl1);
                    printf("L%03d:\n", lbl2);
                    break;
                case IF:
                    ex(p->opr.op[0]);
                    if (p->opr.nops == 3) // if-else
                    {
                        printf("\tj0\tL%03d\n", lbl1 = lbl++);
                        ex(p->opr.op[1]);
                        printf("\tjmp\tL%03d\n", lbl2 = lbl++);
                        printf("L%03d:\n", lbl1);
                        ex(p->opr.op[2]);
                        printf("L%03d:\n", lbl2);
                    }
                    else if (p->opr.nops == 2) // if
                    {
                        printf("\tj0\tL%03d\n", lbl1 = lbl++);
                        ex(p->opr.op[1]);
                        printf("L%03d:\n", lbl1);
                    }
                    break;
                case GETC: // update local variable
                    printf("\tgetc\n");
                    printf("\tpop\t%s[%0d]\n", base, tables[scopeIndex][p->opr.op[0]->id.i].addr);
                    break;
                case GGETC: // update global variable
                    printf("\tgetc\n");
                    printf("\tpop\tsb[%0d]\n", tables[0][p->opr.op[0]->id.i].addr);
                    break;
                case GETS: // update local variable
                    printf("\tgets\n");
                    printf("\tpop\t%s[%0d]\n", base, tables[scopeIndex][p->opr.op[0]->id.i].addr);
                    break;
                case GGETS: // update global variable
                    printf("\tgets\n");
                    printf("\tpop\tsb[%0d]\n", tables[0][p->opr.op[0]->id.i].addr);
                    break;
                case READ: // update local variable
                    printf("\tgeti\n");
                    printf("\tpop\t%s[%0d]\n", base, tables[scopeIndex][p->opr.op[0]->id.i].addr);
                    break;
                case GREAD: // update global variable
                    printf("\tgeti\n");
                    printf("\tpop\tsb[%0d]\n", tables[0][p->opr.op[0]->id.i].addr);
                    break;
                case PRINT: ex(p->opr.op[0]); printf("\tputi\n") ; break;
                case PUTI_: ex(p->opr.op[0]); printf("\tputi_\n"); break;
                case PUTS : ex(p->opr.op[0]); printf("\tputs\n") ; break;
                case PUTS_: ex(p->opr.op[0]); printf("\tputs_\n"); break;
                case PUTC : ex(p->opr.op[0]); printf("\tputc\n") ; break;
                case PUTC_: ex(p->opr.op[0]); printf("\tputc_\n"); break;
                case '=': // variable/array assignment in current scope
                    if (p->opr.nops == 2) { // local variable assignment
                        ex(p->opr.op[1]);
                        printf("\tpop\t%s[%0d]\t// variable assignment\n", base, tables[scopeIndex][p->opr.op[0]->id.i].addr);
                    }
                    else if (p->opr.nops == 3) // local array entry assignment
                    {   // WARNING
                        // It is a MUST to compute the RHS first to avoid `ac`
                        // conflict. The RHS expression may itself involves
                        // array access (see `ENTRY` case below), in which case
                        // `ac` is used to cache the offset from `sb`. Had we
                        // handled the LHS first, whatever in `ac` would be
                        // flushed by computation at the RHS.
                        ex(p->opr.op[2]); // result atop stack
                        printf("\t// result atop stack\n");
                        idx = p->opr.op[0]->id.i;
                        pref = ispref(idx);  // whether array argument is pass-by-reference
                        offsetof(p->opr.op[1], idx, scopeIndex, pref); // offset from `sb`/`fp` in `ac`

                        if (!(scopeIndex)) { _base = "sb"; }
                        else if (pref)     { _base = "sb"; }
                        else               { _base = "fp"; }
                        printf("\tpop\t%s[ac]\t// array entry assignment\n", _base); // modify element
                    }
                    break;
                case GASSIGN: // variable/array assignment in global scope
                    if (p->opr.nops == 2) { // global variable assignment
                        ex(p->opr.op[1]);
                        printf("\tpop\tsb[%0d]\t// global variable assignment\n", tables[0][p->opr.op[0]->id.i].addr);
                    }
                    else if (p->opr.nops == 3) { // global array entry assignment
                        ex(p->opr.op[2]); // result atop stack
                        offsetof(p->opr.op[1], p->opr.op[0]->id.i, 0, 0); // offset from `sb` in `ac`
                        printf("\tpop\tsb[ac]\t// global array entry assignment\n"); // modify element
                    }
                    break;
                case UMINUS:
                    ex(p->opr.op[0]);
                    printf("\tneg\n");
                    break;
                case ',':  // array
                    break; //     shape declaration
                           //     entry access
                           // function
                           //     arguments in call
                case DECL: // local array declaration
                    // space allocated when declaring next variable/array
                    break;
                case INIT: // local array initialization
                    idx = p->opr.op[0]->id.i;
                    // space allocated when declaring next variable/array
                    ex(p->opr.op[2]);      // result atop stack
                    printf("\tpop\tac\n"); // result in ac
                    // initialize array
                    for (int i = 0; i < tables[scopeIndex][idx].size; i++) {
                        printf("\tpush\tac\n");
                        printf("\tpop\t%s[%0d]\n", base, tables[scopeIndex][idx].addr + i);
                    }
                    break;
                case GVAR: // variable in global scope
                    printf("\tpush\tsb[%0d]\n", tables[0][p->opr.op[0]->id.i].addr);
                    break;
                case ENTRY: // array in local scope
                    idx = p->opr.op[0]->id.i;
                    pref = ispref(idx); // detect pass-by-reference
                    
                    offsetof(p->opr.op[1], idx, scopeIndex, pref); // offset from `sb`/`fp` in `ac`

                    if (!(scopeIndex)) { _base = "sb"; }
                    else if (pref)     { _base = "sb"; }
                    else               { _base = "fp"; }
                    printf("\tpush\t%s[ac]\t// array entry access\n", _base); // access element
                    break;
                case GENTRY: // array in global scope
                    offsetof(p->opr.op[1], p->opr.op[0]->id.i, 0, 0); // offset from `sb` in `ac`
                    printf("\tpush\tsb[ac]\t// global array entry access\n"); // access element
                    break;
                case CALL: // (global) function call
                    // determine callee
                    fcall = strtok((char *) p->opr.op[0]->con.value, " +-*/%()[]{}<>=,.;@");
                    for (callee = 1; callee < nscope; callee++) {
                        if (strcmp(funcs[callee].name, fcall) == 0) { // still correct since `strtok` also modifies original string
                            printf("\t// %s called as funcs[%d]\n", funcs[callee].name, callee);
                            break;
                        }
                    }
                    if (callee >= nscope) {
                        yyerror("undefined function");
                        exit(1);
                    }
                    
                    if (p->opr.op[1]) { // push arguments
                        argsof(p->opr.op[1], funcs[callee].nargs, callee);
                    }
                    printf("\tcall\tL%03d\n", funcs[callee].label); // invoke callee
                    // The callee returns nothing.
                    if (!(funcs[callee].ret))
                    {
                        printf("\tpush\tsp\n");
                        printf("\tpush\t1\n");
                        printf("\tsub\t\t// nothing returned\n"); // decrement `sp`
                        printf("\tpop\tsp\t// sp decremented\n");
                    }
                    break;
                case RTRN:
                    if (p->opr.op[0]) { // return single value
                        ex(p->opr.op[0]);
                    }
                    break;
                default: // ';' and binary operators
                    ex(p->opr.op[0]);
                    ex(p->opr.op[1]);
                    switch(p->opr.oper)
                    {
                        case '+': printf("\tadd\n")   ; break;
                        case '-': printf("\tsub\n")   ; break; 
                        case '*': printf("\tmul\n")   ; break;
                        case '/': printf("\tdiv\n")   ; break;
                        case '%': printf("\tmod\n")   ; break;
                        case '<': printf("\tcomplt\n"); break;
                        case '>': printf("\tcompgt\n"); break;
                        case GE : printf("\tcompge\n"); break;
                        case LE : printf("\tcomple\n"); break;
                        case NE : printf("\tcompne\n"); break;
                        case EQ : printf("\tcompeq\n"); break;
                        case AND: printf("\tand\n")   ; break;
                        case OR : printf("\tor\n")    ; break;
                    }
            }
    }
    return 0;
}

void exf()
{
    for (scopeIndex = 1; scopeIndex < nscope; scopeIndex++)
    {
        printf("L%03d:\t// func: %s\n", funcs[scopeIndex].label,
                                        funcs[scopeIndex].name);
        printf("\tvar\t%d, %d\n", funcs[scopeIndex].nargs, LOCAL);
        ex(funcs[scopeIndex].body);
        printf("\tret\n"); // return from callee
    }
    scopeIndex = 0; // reset scope index
}

int ispref(int idx)
{
    if (tables[scopeIndex][idx].size == 1 && tables[scopeIndex][idx].sh)
    {
        if (scopeIndex == 0) {
            yyerror("global array declaration error\n");
            exit(1);
        }
        else { // global array as argument: pass by reference
            return 1;
        }
    }
    else {
        return 0;
    }
}

void offsetof(nodeType *p, int idx, int scope, int pref)
{   // array base
    if (pref) { // array as argument: pass by reference
        printf("\tpush\tfp[%0d]\t// pass-by-reference address\n", tables[scope][idx].addr); // The value of memory cell is the array address.
    }
    else {
        printf("\tpush\t%d\t// base address\n", tables[scope][idx].addr); // directly push array address
    }
    if (!(tables[scope][idx].sh)) { // variable
        // Pay attention to variable-array duality, i.e., a variable `foo` is
        // equivalent to an array of size 1. When accessed, either `foo` or
        // `foo[0,0,…,0]` works.
        printf("\tpush\t0\n");
    }
    else // array
    {
        shape *s = tables[scope][idx].sh->next;
        // `s` leads a linked list, and `p` roots an AST. The goal is to
        // traverse them simulationously to compute the offset.
        if (s == NULL) { // single-dimensional array
            ex(p);       // `p` itself leads an expression.
        }
        else { // multi-dimensional array
            ex(p->opr.op[0]); // leading dimension
            traverse(p->opr.op[1], s);
        }
    }
    printf("\tadd\t\t// T = base + index\n"); // offset from `sb`/`fp` atop stack
    printf("\tpop\tac\n"); // store offset in `ac`
}

void traverse(nodeType *p, shape *s)
{   // ',' functions as the delimiter, i.e., `p->opr.oper`, a.k.a. AST root of
    // `expr_list`, which can be either array indices or arguments in a
    // function call. Meanwhile, a function call may appear as an array index.
    // Therefore, we cannot rely on attributes of `p`, such as `oper` (',') or
    // `nops` (also 2 in binary operations) to distinguish an expression tree
    // from an indices tree.
    printf("\tpush\t%0d\n", s->dim);
    printf("\tmul\n");
    if (s->next == NULL) { // final dimension: `p` leads an expression rather than rooting a tree
        ex(p);
        printf("\tadd\n");
    }
    else { // still an indices tree
        ex(p->opr.op[0]);
        printf("\tadd\n");
        traverse(p->opr.op[1], s->next);
    }
}

void argsof(nodeType *p, int level, int callee)
{
    if (!p) {
        return;
    }
    // `level` is a metric to trace the level of recursion. Similar to
    // `traverse`, this is the sole means to separate an function argument from
    // a "list".
    if (level == 0) { // no argument
        yyerror("missing function argument\n");
        exit(1);
    }
    else if (level == 1) { // final argument
        pusharg(p, level, callee);
    }
    else { // still a parameter list
        pusharg(p->opr.op[0], level, callee);
        argsof(p->opr.op[1], level-1, callee);
    }
}

void pusharg(nodeType *p, int level, int callee)
{
    int idx;
    char *base = (scopeIndex == 0) ? "sb" : "fp";

    if (p->type == typeId)
    {
        idx = p->id.i;
        if (tables[scopeIndex][idx].sh) // array as parameter: pass by reference
        {
            if (scopeIndex == 0) { // global array as argument
                printf("\tpush\t%0d\t// pass by reference\n", tables[0][idx].addr);
                tables[callee][ funcs[callee].nargs - level ].sh = tables[0][idx].sh; // `sh` non-`NULL` but `size` still 1
            }
            else { // local array as argument: base address already in `fp[…]`
                printf("\tpush\tfp[%0d]\t// pass by reference\n", tables[scopeIndex][idx].addr);
            }
        }
        else { // pass by value
            printf("\tpush\t%s[%0d]\t// pass by value\n", base, tables[scopeIndex][idx].addr);
            tables[callee][ funcs[callee].nargs - level ].sh = tables[scopeIndex][idx].sh; // `sh` non-`NULL` but `size` still 1
        }
    }
    else if ((p->type == typeOpr) && (p->opr.oper == GVAR))
    {
        idx = p->opr.op[0]->id.i;
        if (tables[0][idx].sh) { // global array as parameter: pass by reference
            printf("\tpush\t%0d\t// pass by reference\n", tables[0][idx].addr);
            tables[callee][ funcs[callee].nargs - level ].sh = tables[0][idx].sh; // `sh` non-`NULL` but `size` still 1
        }
        else { // pass by value
            printf("\tpush\tsb[%0d]\t// pass by value\n", tables[0][idx].addr);
        }
    }
    else {
        ex(p);
    }
}
