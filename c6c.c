#include <stdio.h>
#include <stdlib.h>
#include "calc3.h"
#include "y.tab.h"


static int lbl;

void traverse(nodeType *, shape *);
void offsetof(nodeType *, int);

int ex(nodeType *p)
{
    int lblx, lbly, lbl1, lbl2,
        idx; // symbol table index

    if (!p) {
        return 0;
    }
    switch(p->type)
    {
        case typeCon:       
            if (p->con.what == 0) // 0 for integer/character
                printf("\tpush\t%d\n", (int) p->con.value); 
            else // 1 for string
                printf("\tpush\t\"%s\"\n", (char *) p->con.value); 
            break;
        case typeId:        
            printf("\tpush\tsb[%0d]\n", table[p->id.i].addr); 
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
                    if (p->opr.nops > 2) // if-else
                    {
                        printf("\tj0\tL%03d\n", lbl1 = lbl++);
                        ex(p->opr.op[1]);
                        printf("\tjmp\tL%03d\n", lbl2 = lbl++);
                        printf("L%03d:\n", lbl1);
                        ex(p->opr.op[2]);
                        printf("L%03d:\n", lbl2);
                    }
                    else // if
                    {
                        printf("\tj0\tL%03d\n", lbl1 = lbl++);
                        ex(p->opr.op[1]);
                        printf("L%03d:\n", lbl1);
                    }
                    break;
                case GETC:
                    printf("\tgetc\n");
                    printf("\tpop\tsb[%0d]\n", table[p->opr.op[0]->id.i].addr);
                    break;
                case GETS:
                    printf("\tgets\n");
                    printf("\tpop\tsb[%0d]\n", table[p->opr.op[0]->id.i].addr);
                    break;
                case READ:
                    printf("\tgeti\n");
                    printf("\tpop\tsb[%0d]\n", table[p->opr.op[0]->id.i].addr);
                    break;
                case PRINT: ex(p->opr.op[0]); printf("\tputi\n") ; break;
                case PUTI_: ex(p->opr.op[0]); printf("\tputi_\n"); break;
                case PUTS : ex(p->opr.op[0]); printf("\tputs\n") ; break;
                case PUTS_: ex(p->opr.op[0]); printf("\tputs_\n"); break;
                case PUTC : ex(p->opr.op[0]); printf("\tputc\n") ; break;
                case PUTC_: ex(p->opr.op[0]); printf("\tputc_\n"); break;
                case '=':
                    if (p->opr.nops == 2) { // variable assignment
                        ex(p->opr.op[1]);
                        printf("\tpop\tsb[%0d]\n", table[p->opr.op[0]->id.i].addr);
                    }
                    else if (p->opr.nops == 3) // array entry assignment
                    {
                        // WARNING
                        // It is a MUST to compute the RHS first to avoid `ac`
                        // conflict. The RHS expression may itself involves
                        // array access (see `ENTRY` case below), in which case
                        // `ac` is used to cache the offset from `sb`. Had we
                        // handled the LHS first, whatever in `ac` would be
                        // flushed by computation at the RHS.
                        ex(p->opr.op[2]);                           // result atop stack
                        offsetof(p->opr.op[1], p->opr.op[0]->id.i); // offset from `sb` in `ac` 
                        printf("\tpop\tsb[ac]\n");                  // modify element
                    }
                    break;
                case UMINUS:
                    ex(p->opr.op[0]);
                    printf("\tneg\n");
                    break;
                case ',':
                    // array
                    //     shape declaration
                    //     entry access
                    break;
                case DECL:
                    // space allocated when declaring next variable/array
                    break;
                case INIT:
                    idx = p->opr.op[0]->id.i;
                    // space allocated when declaring next variable/array
                    ex(p->opr.op[2]);      // result atop stack
                    printf("\tpop\tac\n"); // result in ac
                    // initialize array
                    for (int i = 0; i < table[idx].size; i++) {
                        printf("\tpush\tac\n");
                        printf("\tpop\tsb[%0d]\n", table[idx].addr + i);
                    }
                    break;
                case ENTRY:
                    offsetof(p->opr.op[1], p->opr.op[0]->id.i); // offset from `sb` in `ac`
                    printf("\tpush\tsb[ac]\n"); // access element
                    break;
                default: // `;` and binary operators
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

void offsetof(nodeType *p, int idx) // no out-of-index or axis mismatch errors checking
{
    printf("\tpush\t%d\n", table[idx].addr); // array base
    // array index
    if (table[idx].sh == NULL) { // variable
        // Pay attention to variable-array duality, i.e., a variable `foo` is
        // equivalent to an array of size 1. When accessed, either `foo` or
        // `foo[0,0,…,0]` works.
        printf("\tpush 0\n");
    }
    else if (table[idx].size == 1) { // singleton array
        printf("\tpush 0\n");
    }
    else if (table[idx].size > 1)
    {
        shape *s = table[idx].sh->next;
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
    printf("\tadd\n");     // offset from `sb` atop stack
    printf("\tpop\tac\n"); // store offset in `ac`
}

void traverse(nodeType *p, shape *s)
{   // ',' functions as the delimiter, i.e., `p->opr.oper`, a.k.a. AST root of
    // `exp_list`, which can be either array indices or arguments in a function
    // call. Meanwhile, a function call may appear as an array index. Therefore,
    // we cannot rely on attributes of `p`, such as `oper` (',') or `nops`
    // (also 2 in binary operations) to distinguish an expression tree from an
    // indices tree.
    printf("\tpush\t%0d\n", s->dim);
    printf("\tmul\n");
    if (s->next == NULL) { // trailing dimension: `p` leads an expression rather than rooting a tree
        ex(p);
        printf("\tadd\n");
    }
    else { // still an indices tree
        ex(p->opr.op[0]);
        printf("\tadd\n");
        traverse(p->opr.op[1], s->next);
    }
}
