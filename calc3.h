typedef
enum { typeCon, typeId, typeOpr }
nodeEnum;

/* constants */
typedef
struct {
    long value; // value of constant
    int  what;  // 0 for integer/character
}               // 1 for string
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
struct nodeTypeTag {
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

extern char sym[100][30];
extern int symIndex;
