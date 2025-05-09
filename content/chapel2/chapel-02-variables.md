+++
title = "Basic syntax and variables"
slug = "chapel-02-variables"
weight = 2
katex = true
+++

<!-- ACTION: talk about the 2 problems () \ -->

In the non-GPU part of this course we'll be solving two numerical problems: one is embarrassingly parallel
(**Julia set**), and one is tightly coupled (**heat diffusion**).

## Case study 1: computing the Julia set

This project is a mathematical problem to compute a [Julia set](https://en.wikipedia.org/wiki/Julia_set),
defined as a set of points on the complex plane that remain bound under infinite recursive transformation
$f(z)$. We will use the traditional form $f(z)=z^2+c$, where $c$ is a complex constant. Here is our algorithm:

1. pick a point $z_0\in\mathbb{C}$
1. compute iterations $z_{i+1}=z_i^2+c$ until $|z_i|>4$ (arbitrary fixed radius; here $c$ is a complex
   constant)
1. store the iteration number $\xi(z_0)$ at which $z_i$ reaches the circle $|z|=4$
1. limit max iterations at 255  
    4.1 if $\xi(z_0)=255$, then $z_0$ is a stable point  
    4.2 the quicker a point diverges, the lower its $\xi(z_0)$ is
1. plot $\xi(z_0)$ for all $z_0$ in a rectangular region $-1<=\mathfrak{Re}(z_0)<=1$,
   $-1<=\mathfrak{Im}(z_0)<=1$

We should get something conceptually similar to this figure (here $c = 0.355 + 0.355i$; we'll get drastically
different fractals for different values of $c$):

{{< figure src="/img/2000a.png" >}}

**Note**: you might want to try these values too:
- $c = 1.2e^{1.1πi}$ $~\Rightarrow~$ original textbook example
- $c = -0.4-0.59i$ and 1.5X zoom-out $~\Rightarrow~$ denser spirals
- $c = 1.34-0.45i$ and 1.8X zoom-out $~\Rightarrow~$ beans
- $c = 0.34-0.05i$ and 1.2X zoom-out $~\Rightarrow~$ connected spiral boots

Below is the serial code `juliaSetSerial.chpl`:

```chpl
use Time;
use NetCDF.C_NetCDF;

proc pixel(z0) {
  const c = 0.355 + 0.355i;
  var z = z0*1.2;   // zoom out
  for i in 1..255 do {
    z = z*z + c;
    if abs(z) >= 4 then
      return i:c_int;
  }
  return 255:c_int;
}

const height, width = 2_000;   // 2000^2 image
var point: complex, y: real, watch: stopwatch;

writeln("Computing Julia set ...");
var stability: [1..height,1..width] c_int;
watch.start();
for i in 1..height do {
  y = 2*(i-0.5)/height - 1;
  for j in 1..width do {
    point = 2*(j-0.5)/width - 1 + y*1i;   // rescale to -1:1 in the complex plane
    stability[i,j] = pixel(point);
  }
}
watch.stop();
writeln('It took ', watch.elapsed(), ' seconds');
```

The reason we are using C types (`c_int`) here -- and not Chapel's own int(32) or int(64) -- is that we can
save the resulting array `stability` into a compressed netCDF file. To the best of my knowledge, this can only
be done using `NetCDF.C_NetCDF` library that relies on C types. You can add this to your code:

```chpl
writeln("Writing NetCDF ...");
use NetCDF.C_NetCDF;
proc cdfError(e) {
  if e != NC_NOERR {
    writeln("Error: ", nc_strerror(e): string);
    exit(2);
  }
}
var ncid, xDimID, yDimID, varID: c_int;
var dimIDs: [0..1] c_int;   // two elements
cdfError(nc_create("test.nc", NC_NETCDF4, ncid));       // const NC_NETCDF4 => file in netCDF-4 standard
cdfError(nc_def_dim(ncid, "x", width, xDimID)); // define the dimensions
cdfError(nc_def_dim(ncid, "y", height, yDimID));
dimIDs = [xDimID, yDimID];                              // set up dimension IDs array
cdfError(nc_def_var(ncid, "stability", NC_INT, 2, dimIDs[0], varID));   // define the 2D data variable
cdfError(nc_def_var_deflate(ncid, varID, NC_SHUFFLE, deflate=1, deflate_level=9)); // compress 0=no 9=max
cdfError(nc_enddef(ncid));                              // done defining metadata
cdfError(nc_put_var_int(ncid, varID, stability[1,1]));  // write data to file
cdfError(nc_close(ncid));
```

Testing on my laptop, it took the code 0.471 seconds to compute a $2000^2$ fractal.

Try running it yourself! It will produce a file `test.nc` that you can download to your computer and render
with ParaView or other visualization tool. Does the size of `test.nc` make sense?









## Case study 2: solving the **_Heat transfer_** problem

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
