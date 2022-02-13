+++
title = "SharedArrays.jl"
slug = "julia-11-shared-arrays"
weight = 11
+++

Unlike distributed **DArray** from **DistributedArrays.jl**, a **SharedArray** object is stored in full on the control
process, but it is shared across all workers on the same node, with a significant cache on each worker. **SharedArrays**
package is part of Julia's Standard Library (comes with the language).

- Similar to DistributedArrays, you can read elements using their global indices from any worker.
- Unlike with DistributedArrays, with SharedArrays you can **write into any part of the array from any worker** using
  their global indices. This makes it very easy to parallelize any serial code.

There are certain downsides to **SharedArray** (compared to **DistributedArrays.jl**):
1. The ability to write into the same array elements from multiple processes creates the potential for a race condition
  and indeterministic outcome with a poorly written code!
1. You are limited to a set of workers on the same node (due to SharedArray's intrinsic implementation).
1. You will have very skewed (non-uniform across processes) memory usage.

Let's start with serial Julia (`julia`) and initialize a 1D shared array:

```julia
using Distributed, SharedArrays
addprocs(4)
a = SharedArray{Float64}(30);
a[:] .= 1.0           # assign from the control process
@fetchfrom 2 sum(a)   # correct (30.0)
@fetchfrom 3 sum(a)   # correct (30.0)
```

```julia
@sync @spawnat 2 a[:] .= 2.0   # can assign from any worker!
@fetchfrom 3 sum(a)            # correct (60.0)
```

You can use a function to initialize an array, however, pay attention to the result:

```julia
b = SharedArray{Int64}((1000), init = x -> x .= 0);    # use a function to initialize `b`
b = SharedArray{Int64}((1000), init = x -> x .+= 1)   # each worker updates the entire array in-place!
```

> **Key idea:** each worker runs this function!

Let's fill each element with its corresponding myd() value:

```julia
@everywhere println(myid())     # let's use these IDs in the next function
c = SharedArray{Int64}((20), init = x -> x .= myid())   # indeterminate outcome! each time a new result
```

Each worker updates every element, but the order in which they do this varies from one run to another, producing
indeterminate outcome.

```julia
@everywhere using SharedArrays   # otherwise `localindices` won't be found on workers
for i in workers()
    @spawnat i println(localindices(c))   # this block is assigned for processing on worker `i`
end
```

What we really want is each worker should fill only its assigned block (parallel init, same result every time):

```julia
c = SharedArray{Int64}((20), init = x -> x[localindices(x)] .= myid())
```

### Another way to avoid a race condition: use parallel `for` loop

Let's initialize a 2D SharedArray:

```julia
a = SharedArray{Float64}(100,100);
@distributed for i in 1:100     # parallel for loop split across all workers
    for j in 1:100
	    a[i,j] = myid()           # ID of the worker that initialized this element
    end
end
for i in workers()
    @spawnat i println(localindices(a))   # weird: shows 1D indices for 2D array
end
a                           # available on all workers
a[1:10,1:10]                # on the control process
@fetchfrom 2 a[1:10,1:10]   # on worker 2
```

### 1D heat equation

Consider a (simplified) physics problem: A rod of length $[-L,L]$ heated at the middle, then the heat source is removed. The temperature distribution $T(x,t)$ across the rod over time can be simulated by the following equation

\\[
T(x,t+\Delta t) = \frac{1}{2}T(x-\Delta x,t) + \frac{1}{2}T(x+\Delta x,t)
\\]

on a set of evenly spaced points apart by $\Delta x$. The initial condition is shown in the diagram below. At $t=0$, $T(x,0) = T_0$ for $-h \leq x \leq h$ and $T(x,0) = 0$ elsewhere.

{{< figure src="/img/grid_coords.png" width=650px >}}

At both ends, we impose the boundary conditions $T(-L,t)=0$ and $T(L,t)=0$.

This example is seen in many of our training courses, for example, MPI, Fortran and Python courses for advanced research computing. A more "accurate" formula involving three spatial points $x_i - \Delta x$, $x_i$ and $x_i + \Delta x$ for computing the temperature at the next time step $t_n+\Delta t$ for interior points $i=1,\ldots,N$ is given below

\\[
T(x_i,t_n+\Delta t) = (1-2k)T(x_i,t_n) + k((T(x_{i-1},t_n)+T(x_{i+1},t_n))
\\]

where $k$ is a parameter that shall be chosen properly in order for the numerical procedure to be stable.

Note in the formula, $T(x_i,t_n+\Delta t)$ depends on the values of $T$ at three points at current time step $t_n$, which are all known. This allows us to compute $T$ at $t_n+\Delta t$ independent of each other, hence this can be done in parallel.

Let $U_i^n$ denote the value of $T(x_i,t_n)$ at grid points $x_i$, $i=1,\ldots,N$, we use the short notation

\\[
U_i^{n+1} = (1-2k)U_i^n + k(U_{i-1}^n + U_{i+1}^n).
\\]

for $i=1,\ldots,N$. This can be translated into the following code with one dimensional two arrays `unew[1:N]` and `u[1:N]` holding values at the $N$ grid points at $t_{n+1}$ and $t_n$ respectively

```julia
for i=1:N
    unew[i] = (1-2*k)u[i] + k*(u[i-1] + u[i+1])
end
```

This in fact can be replaced by the following one line of code using a single array `u`

```julia
u[2:N-1] = (1-2k)*u[2:N-1] + k*(u[1:N-2) + u[3:N])
```

In this case, vectorized operations on the right hand side take place first before the individual elements on the left hand side are updated.
