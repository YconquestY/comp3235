#define MAX_SCOPE 100
#define MAX_SYM   100
#define MAX_FUNC  100
#define GLOBAL    500
#define LOCAL      50

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
    int i; // data/function environment index
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

/* data environment
 * for variables and arrays */
struct shape { // shape of array
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
extern symbol tables[100][100];
extern int    symIndex[100];
extern int    scopeIndex;
extern int    nscope;

/* function environment */
struct param { // a positional parameter
    char *name; // parameter name
    int  pIdx;  // index of parameter list, useful in `pop fp[#]`
    struct param *next;
};
typedef struct param param;

struct func {
    char *name; // function name
    int  nargs; // no. of parameters
    nodeType *body; // function body
    int ret;   // whether a function returns something
    int label; // `L###` to jump to when called
};
typedef struct func func;

extern func funcs[100]; // max. 100 functions
extern int  funcIndex;  // function environment index

extern int lbl;
