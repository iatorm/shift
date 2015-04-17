# Shift

_Shift_ is an esoteric functional programming language.
It is stack-based, but also has automatic currying like Haskell.

# Specification

There are two datatypes in Shift:

- Functions, which can have an arbitrary positive _arity_ (number of inputs), and which return a list of outputs. For example, a function that duplicates its only input has arity 1, and a function that swaps its two inputs has arity 2.
- Blanks, which are all identical and have no other purpose than not being functions.

A Shift program consists of zero or more _commands_, each of which is a single ASCII character.
There are 8 commands in total:

- `!` (_apply_) pops a function `f` and a value `x` from the stack, and applies `f` to `x`. If `f` has arity 1, the list `f(x)` is appended to the stack. If it has arity `n > 1`, a new `(n-1)`-ary function `g` is pushed to the stack. It takes inputs <code>x<sub>1</sub>,x<sub>2</sub>,...,x<sub>n-1</sub></code> and returns <code>f(x,x<sub>1</sub>,x<sub>2</sub>,...,x<sub>n-1</sub>)</code>.
- `?` (_blank_) pushes a blank to the stack.
- `+` (_clone_) pushes to the stack a unary function that duplicates its input: any value `x` is mapped to `[x,x]`.
- `>` (_shift_) pushes to the stack a unary function that takes in an `n`-ary function `f`, and returns an `(n+1)`-ary function `g` that ignores its first argument, and calls `f` on the remaining ones.
- `/` (_fork_) pushes to the stack a ternary function that takes three inputs `a,b,c`, and returns `[b]` if `a` is a blank, and `[c]` otherwise.
- `$` (_call_) pushes to the stack a binary function that pops a function `f` and a value `x`, and applies `f` to `x` exactly as `!` does.
- `.` (_chain_) pushes to the stack a binary function that pops two functions `f` and `g`, and returns their composition: a function `h` that has the same arity as `f`, and which takes its inputs normally, applies `f` to them, and then _fully_ applies `g` to the result.
- `@` (_say_) pushes a unary function that simply returns its input, and prints `0` if it was a blank, and `1` if it was a function.

Note that all commands except `!` simply push a value to the stack, there is no way to perform input, and the only way to output anything is to use `@`.
A program is interpreted by evaluating the commands one by one, printing `0`s or `1`s whenever "say" is called, and exiting.
Any behavior not described here (applying a blank, applying a stack of length 0 or 1, calling "chain" on a blank etc.) is undefined.

# This Interpreter

The reference interpreter, written in Haskell, has the following extra features:

- Informative error messages.
- All functions can be referred to by their lowercase names, instead of the symbols. They must be separated by symbols or whitespace.
- All whitespace is ignored, except between lowercase words, where it acts as a separator. An uppercase letter begins a comment that extends to the end of the line.

Invoke it like

<pre><code>runhaskell shift.hs hello.sft</code></pre>
