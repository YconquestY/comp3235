# `c6`

`c6` is a toy compiler for an imperative, JavaScirpt-like language. Implemented with `flex` and `bison`, it targets the stack machine simulator [`nas2`](https://github.com/YconquestY/comp3235/tree/main/nas2).

## Features

`c6` supports loops, multi-dimensional arrays, and functions. It does not support `break;` or `continue;` statements inside loops yet, but these features may be readily implemented with minimal effort.

There is a hard limit on the number of global data (variable and arrays), local data (w.r.t. functions), and functions. One may declare at most $99$ functions, each with no more than $50$ paramenters, and global data occupying a maximum of $500$ stack cells. Local data inside a function shall not exceed $50$ stack cells. See [design choices](#design) for details.

`c6` implements no optimization and garbage collection at all.

## Usage

```bash
$ make nas2.o # build stack machine simulator
$ make c6c.o  # build compiler
$ ./c6c.o test/array.sc > test/array.nas2 # compile c6 program
$ ./nas2.o test/array.nas2                # run c6 executable on stack machine
```

One may also replace `test/array.sc` above with his/her own program.

## Design

`c6` uses $3$ tables to keep track of data and function environments.

| Array | Description |
| ---   | ---         |
| `tables[100][100]`| The symbol table, a.k.a. data environment. `tables[0][0..99]` is for the global scope, and each of the remaining corresponds to a new function. All calls of a recursive function that invokes itself repeatedly share $1$ table. |
| `symIndex[100]`| Maximum index of symbols per scope. `symIndex[i]` marks the number of variables and arrays in the $\texttt{i}^\text{th}$ scope. |
| `funcs[100]` | The function environment. `funcs[1..99]` are functions while `funcs[0]` is not in use. |

### Warning

- Use only alphanumeric characters for identifiers of variables. Underscores, such as `comp_3235`, are not allowed.
- `c6` is interger-only. Do not use floating-point numbers.
- Do not declare arrays and variables with an identical name within a single scope. `c6` does not check duplicate error. For instance, the following is allowed.<br>
  ```
  array foo[3] = 0;
  …
  func boo() {
    array foo[2] = 1;
    @foo[0] = foo[1] + @foo[2];
  }
  ```
  However, the code below is invalid.
  ```
  array foo[3] = 0;
  …
  foo = 1;
  ```
  Despite the above, `c6` does support variable-array duality, i.e., a variable `foo` is equivalent to an array of size $1$. When we later access it, either `foo` or `foo[0,0,…,0]` works.
- `c6` does not check out-of-index or axis mismatch error. Always write the correct code.<br>
  Suppose an array is declared as `array a[3,2,3,5];`, then neither `a[3,2,5,9] = …` nor `a[1,1,1,1,1]` works.
-  Do not update an array entry with `get…(a[…]);` or `get…(@a[…])`; always use an assignment statement `a[…] = …;`.
- Do not declare too many large arrays. The global scope can hold a maximum of $100$ variables/arrays with $500$ memory cells.
- Do not declare singleton arrays. `array a[1] = 3259;` is neither valid nor meaningful.
- `c6` does **not** support dynamic array declaration. `x = 1; y = 2; array z[x + y, x * y];` is invalid; always use concrete dimensions: `array z[3, 2];`.
- `c6` implements **static** scoping, i.e., the function is bound to the data environment at the time of function **definition**. If there is global variable access within a function, then the global variable must be declared **before** the function is declared.
- Do not define a function twice.
- Do not define a function with a different parameter list or body.

## Files

The repository is organized as follows.

```
./
├──nas2/
│   ├── nas2.md
│   ├── nas2.l
│   └── nas2.y
├── calc3.h
├── c6.l
├── c6.y
├── c6c.c
├── makefile
└── test/
    ├── array.sc
    ├── bb1.sc
    ├── bb2.sc
    └── bb3.sc
```

`nas2/` contains the stack machine simulator. `c6.*` is the compiler frontend; `c6c.c` is the backend. `test/` contains sample `c6` programs.

## [`nas2`](https://github.com/YconquestY/comp3235/tree/main/nas2)

`nas2` is a stack machine simulator used in [COMP3235](https://www.cs.hku.hk/index.php/programmes/course-offered?infile=2022/comp3235.html) *Compiling techinuqes* by the [University of Hong Kong](https://hku.hk). See the [doc](https://github.com/YconquestY/comp3235/blob/main/nas2/nas2.md) for details.

## Acknowledgement

`c6` extends [`calc3`](https://epaperpress.com/lexandyacc/download/LexAndYaccCode.zip), a calculator interpreter in [*Lex and Yacc*](https://www.epaperpress.com/lexandyacc/index.html) by [Tom Niemann](https://www.epaperpress.com/whoami/index.html). Building `c6` was assignment 3 of COMP3235.
