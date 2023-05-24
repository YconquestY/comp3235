# COMP3235 Assignment 3

| Name   | UID        |
| ---    | ---        |
| Yu Yue | 3035637709 |

## Submission

I implemented **all** features and bonuses.

| File | Description |
| ---  | ---         |
| `calc3.h` | Utilities |
| `c6.l`    | Scanner   |
| `c6.y`    | Parser    |
| `c6c.c`   | Backend   |
| `makefile` |  |
| `test/array.sc` | Test for feature 1; showcases nested arrays. |
| `test/bb1.sc` | Test for bonus (b); showcases passing an array as a function argument and accessing/modifying it inside the function call. |
| `test/bb2.sc` | Test for bonus (b); similar to `test/bb1.sc`. |
| `test/bb2.sc` | Test for bonus (b); showcases further passing an array as a function argument in **nested** functions |


## Usage

To get an executable compiler, run `make c6c.o`. Also,

- Use only alphanumeric characters for identifiers of variables. Underscores, such as `comp_3259`, are **not** allowed.
- Do **not** use floating-point numbers.

### Feature 1

New: `[`, `]`, and keyword `array`

- Do not declare arrays and variables with an identical name within a single scope. `c6` does not check duplicate error.<br>
  For instance, the following is allowed.
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

### Feature 2

New: `,`, `@`, keywords `func` and `return`

- `c6` implements **static** scoping, i.e., the function is bound to the data environment at the time of function **definition**. If there is global variable access within a function, then the global variable must be declared **before** the function is declared.
- `c6` supports up to $100$ scopes, the first of which is the global one. This means the ensuing $99$ scopes are reserved for functions. Correspondingly, one may define no more than $99$ functions in `c6`.
- `c6` implements **no** optimization at all. A function is always translated to `nas2` instructions regardless of whether it is called.
- A `c6` function may take at most $50$ parameters. Variables local to a function shall not occupy over $50$ memory cells in total.
- Do not define a function twice.
- Do not define a function with a different parameter list or body.
