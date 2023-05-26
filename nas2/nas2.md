# `nas2`

## News

- To call a function (started by `L###` and ended by `ret`), `call …, …` has been replaced by `call …; var …, …` to reflect memory allocation for local data.
- Escape sequences can now be in strings and characters; examples are `"1st line\n2nd line"` and `'\t'`. Only `\n`, `\t`, `\"` (for strings), and `\'` (for characters) are allowed. If you want others, please add them to [`nas2.l`](./nas2.l) yourself.
- A stack overflow check is added to [`nas.y`](./nas2.y). There is no checking stack underflow, which should never occur unless you change `sp` manually in your code. There is also no check for maximum code size, now set $3000$;
maximum stack size is $5000$; maximum number of labels is $1000$.

## The `nas2` instruction set

The following push an item onto (or pops an item off) the stack, where `N` is an integer, `C` is a single-quoted character, and `S` is a double-quoted string. There are $3$ resisters in `nas2`.

| Register | Description |
| ---      | ---         |
| `sb` | Stack base; always $0$ when running a single `c6` program. |
| `fp` | Frame[^frame] pointer; frame base of the current function call. |
| `in` | General register; also called `ac`. |

The above are generally referred to as `R…` in the following. For preciseness, `{R}` means "the content of `R`", `T` refers to the stack top, and `T2` represents the item delow `T`.

| Instruction | Description |
| ---         | ---         |
| `push N` | Push an interger `N` as `T`|
| `push C` | … |
| `push S` | Pushes the address[^address] of a string `S` as `T` |
| `push R` | Push `{R}` as `T` |
| `push R[N]`   | Push `{{R} + N}` as `T` |
| `push R1[R2]` | Push `{{R1} + {R2}}` as `T` |
| `pop R`      | Pop `T` as `{R}` |
| `pop R[N]`   | Pop `T` as  `{{R} + N}` |
| `pop R1[R2]` | Pop `T` as  `{{R1} + {R2}}` |

The following **destructive** instructions operate on the stack top, i.e., all operands are popped, and the result  is pushed back as `T`. `L` is a label.

| Instruction | Description |
| ---         | ---         |
| `complt` | $\texttt{T} = \left\{\begin{matrix}1 & \texttt{T2 == T}~\\ 0 & \text{otherwise}\end{matrix}\right.$ |
| `compgt` | … |
| `compge` | … |
| `comple` | … |
| `compne` | … |
| `compeq` | … |
| `add`    | $\texttt{T} \leftarrow \texttt{T2} + \texttt{T}$ |
| `sub`    | $\texttt{T} \leftarrow \texttt{T2} - \texttt{T}$ |
| `mul`    | … |
| `div`    | $\texttt{T} \leftarrow \frac{\texttt{T2}}{\texttt{T}}$ |
| `mod`    | … |
| `neg`    | $\texttt{T} \leftarrow \texttt{-T}$ |
| `and`    | $\texttt{T} \leftarrow \texttt{T2}~\texttt{\&}~\texttt{T}$ |
| `or`     | … |
| `j1 L`   | Jump to `L` if `T` is $1$ (`T` popped) |
| `j0 L`   | Jump to `L` if `T` is $0$ |
| `puti`   | Print `T` as integer with newline (`T` popped) |
| `putc`   | … |
| `puts`   | … |
| `puti S` | Print `T` as integer in formatted string with newline |
| `puts S` | … |
| `putc S` | … |
| `puti_`  | Print `T` as integer without newline|
| `putc_`  | … |
| `puts_`  | … |

Below are non-destructive instructions.

| Instruction | Description |
| ---         | ---         |
| `geti`  | Read and push an integer |
| `getc`  | … |
| `gets`  | … |
| `jmp L` | Unconditional jump |
| `call L`   | Function call |
| `var P, L` | `P` is the number of function parameters, and `L` is the number of stack cells allocated to a function call. `var …, …` must immediately follow a function label. |
| `ret` | $\texttt{T} \leftarrow$ function return value; always returns the stack top |
| `end` | End execution |
| `//`  | Comment |
| `;`   | Treated as white-space; can be used to separate instructions on the same line |  		

## Usage

The stack is an integer stack. When dealing with characters, their ASCII's (integers) are pushed. No packing or unpacking in possible.

Strings are a primitive type, and are stored in some heap behind the scene.  They are represented and operated on by their addresses (`long`s). They are immutable. If you want mutable strings, build an array of characters. Both strings and characters can be empty; `push ''` pushes the null character.

`true` and `false` are represented by integers `1` and `0` respectively.

Labels are of the form `L###`, ranging from `L000` to `L999`.

In [`nas2.y`](./nas2.y), `sp` points at the next **empty** slot above top of the stack. To declare an array say of size $100$, you may fiddle with the stack
pointer: `push sp; push 100; add; pop sp`.


`nas2` has virtually no error checking, which should not be a problem since the assembly language input is coming
from a compiler rather than a human programmer.

[^frame]: An `nas2` frame is merely a conceptual idea. It is different from the fixed size frame of physic memory.

[^address]: The assembly is still, say, `push "Hello World!"`.