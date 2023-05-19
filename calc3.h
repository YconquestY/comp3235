typedef
enum { typeCon, typeId, typeOpr }
nodeEnum;

/* constants */
typedef
struct {
    long value; // value of constant
    int  what;  // 0 for integer/character
}               // 1 for string (memory address)
conNodeType;

/* identifiers */
typedef
struct {
    int i; // index of symbol table
}
idNodeType;

/* operators
 * non-leaf nodes */
typedef
struct {
    int oper;                   // operator
    int nops;                   // number of operands
    struct nodeTypeTag *op[1];  // expandable operands, i.e.,
                                // an array of pointers to nodes
                                // We do not use `nodeType` here because it has not be declared.
}
oprNodeType;

typedef
struct nodeTypeTag
{
    nodeEnum type; // type of node
    // `union` must be the last entry in `nodeType`
    // because `operNodeType` may dynamically increase.
    union {
        conNodeType con; // constants
        idNodeType id;   // identifiers
        oprNodeType opr; // operators
    };
}
nodeType;

struct shape {
    int dim; // dimension
    struct shape *next;
};
typedef struct shape shape;

typedef
struct symbol
{
    char  *name; // variable/array/function name
    int   addr ; // address, i.e., offset from `sb`
    shape *sh  ; // shape of array/function in the form of linked list
    int   size ; // size of array
    // pay attention to variable-array duality, i.e.,
    // variable `foo` is equivalent to `foo[0,0,…,0]`.
}
symbol;
extern symbol table[100];
extern int symIndex;
