+++
title = "Basic syntax and variables"
slug = "chapel-02-variables"
weight = 2
katex = true
+++

## Case study: solving the **_Heat transfer_** problem

- have a square metallic plate with some initial temperature distribution (**_initial conditions_**)
- its border is in contact with a different temperature distribution (**_boundary conditions_**)
- want to simulate the evolution of the temperature across the plate

To solve the 2nd-order heat diffusion equation, we need to **_discretize_** it, i.e., to consider the
plate as a grid of points, and to evaluate the temperature on each point at each iteration, according to
the following **_finite difference equation_**:

```chpl
Tnew[i,j] = 0.25 * (T[i-1,j] + T[i+1,j] + T[i,j-1] + T[i,j+1])
```

- `Tnew` = new temperature computed at the current iteration
- `T` = temperature calculated at the past iteration (or the initial conditions at the first iteration)
- the indices (i,j) indicate the grid point located at the i-th row and the j-th column

So, our objective is to:

1. Write a code to implement the difference equation above. The code should:
   - work for any given number of rows and columns in the grid,
   - run for a given number of iterations, or until the difference between `Tnew` and `T` is smaller than a given tolerance value, and
   - output the temperature at a desired position on the grid every given number of iterations.
1. Use task parallelism to improve the performance of the code and run it on a single cluster node.
1. Use data parallelism to improve the performance of the code and run it on multiple cluster nodes using
   hybrid parallelism.

## Variables

A variable has three elements: a **_name_**, a **_type_**, and a **_value_**. When we store a value in a
variable for the first time, we say that we **_initialized_** it. Further changes to the value of a
variable are called **_assignments_**, in general, `x=a` means that we assign the value *a* to the
variable *x*.

Variables in Chapel are declared with the `var` or `const` keywords. When a variable declared as const is
initialized, its value cannot be modified anymore during the execution of the program.

In Chapel, to declare a variable we must specify the type of the variable, or initialize it in place with
some value. The common variable types in Chapel are:

* integer `int`, 
* floating point number `real`, 
* boolean `bool`, or 
* string `string`

If a variable is declared without a type, Chapel will infer it from the given initial value, for example
(let's store this in file `baseSolver.chpl`)

```chpl
const rows, cols = 100;      // number of rows and columns in a matrix
const niter = 500;           // number of iterations
const iout, jout = 50;       // row and column to print
```

All these constant variables will be created as integers, and no other values can be assigned to these
variables during the execution of the program.

On the other hand, if a variable is declared without an initial value, Chapel will initialize it with a
default value depending on the declared type. The following variables will be created as real floating
point numbers equal to 0.0.

```chpl
var delta: real;    // the greatest temperature difference from one iteration to next
var tmp: real;      // for temporary results when computing the temperatures
```

Of course, we can use both, the initial value and the type, when declaring a varible as follows:

```chpl
const tolerance: real = 0.0001;   // temperature difference tolerance
var count: int = 0;               // the iteration counter
const nout: int = 20;             // the temperature at (iout,jout) will be printed every nout interations
```

> Note that these two notations are different, but produce the same result in the end:
>
> ```chpl
> var a: real = 10;   // we specify both the type and the value
> var a = 10: real;   // we specify only the value (10 converted to real)
> ```

Let's print out our configuration after we set all parameters:

```chpl
writeln('Working with a matrix ', rows, 'x', cols, ' to ', niter, ' iterations or dT below ', tolerance);
```

<!-- {{<note>}} -->
<!-- {{</note>}} -->

### Checking variable's type

To check a variable's type, use `.type` query:

```chpl
var x = 1e8:int;
type t = x.type;
writeln(t:string);
```

or in a single line:

```chpl
writeln((1e8:int).type:string);
writeln((0.355 + 0.355i).type: string);
```
