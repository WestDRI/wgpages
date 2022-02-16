+++
title = "DistributedArrays.jl"
slug = "julia-09-distributed-arrays"
weight = 9
katex = true
+++

**DistributedArrays** package provides **DArray** object that can be split across several processes (set of workers),
either on the same or multiple nodes. This allows use of arrays that are too large to fit in memory on one node. Each
process operates on the part of the array that it owns -- this provides a very natural way to achieve parallelism for
large problems.

- Each worker can *read any elements* using their global indices
- Each worker can *write only to the part that it owns* $~\Rightarrow~$ automatic parallelism and safe execution


DistributedArrays is not part of the standard
library, so usually you need to install it yourself (it will typically write into `~/.julia/environments/versionNumber`
directory):

```julia
] add DistributedArrays
```

We need to load DistributedArrays on every worker:

```julia
using Distributed
addprocs(4)
@everywhere using DistributedArrays
```

```julia
n = 10
data = dzeros(Float32, n, n);          # distributed 2D array of 0's
data                                   # can access the entire array
data[1,1], data[n,5]                   # can use global indices
data.dims                              # global dimensions (10, 10)
data[1,1] = 1.0                        # error: cannot write from the control process!
@spawnat 2 data.localpart[1,1] = 1.5   # success: can write locally
data
```

Let's check `data` distribution across workers:

```julia
for i in workers()
    @spawnat i println(localindices(data))
end
```

```julia
rows, cols = @fetchfrom 3 localindices(data)
println(rows)     # the rows owned by worker 3
```

We can only write into `data` from its "owner" workers using local indices on these workers:

```julia
@everywhere function fillLocalBlock(data)
    h, w = localindices(data)
    for iGlobal in h                         # or collect(h)
        iLoc = iGlobal - h.start + 1         # always starts from 1
        for jGlobal in w                     # or collect(w)
            jLoc = jGlobal - w.start + 1     # always starts from 1
            data.localpart[iLoc,jLoc] = iGlobal + jGlobal
        end
    end
end
```

```julia
for i in workers()
    @spawnat i fillLocalBlock(data)
end
data   # now the distributed array is filled
@fetchfrom 3 data.localpart    # stored on worker 3
minimum(data), maximum(data)   # parallel reduction
```

One-liners to generate distributed arrays:

```julia
a = dzeros(100,100,100);      # 100^3 distributed array of 0's
b = dones(100,100,100);       # 100^3 distributed array of 1's
c = drand(100,100,100);       # 100^3 uniform [0,1]
d = drandn(100,100,100);      # 100^3 drawn from a Gaussian distribution
d[1:10,1:10,1]
e = dfill(1.5,100,100,100);   # 100^3 fixed value
```

You can find more information about the arguments by typing `?DArray`. For example, you have a lot of control over the
DArray's distribution across workers. Before I show the examples, let's define a convenient function to show the array's
distribution:

```julia
function showDistribution(x::DArray)
    for i in workers()
        @spawnat i println(localindices(x))
    end
end
```
```julia
nworkers()                                  # 4
data = dzeros((100,100), workers()[1:2]);   # define only on the first two workers
showDistribution(data)
```
```julia
square = dzeros((100,100), workers()[1:4], [2,2]);   # 2x2 decomposition
showDistribution(square)
```
```julia
slab = dzeros((100,100), workers()[1:4], [1,4]);   # 1x4 decomposition
showDistribution(slab)
```

You can take a local array and distribute it across workers:

```julia
e = fill(1.5, (10,10))   # local array
de = distribute(e)       # distribute `e` across all workers
showDistribution(de)
```

> ### Exercise "DArrays.1"
> Using either `top` or `htop` command on Uu, study memory usage with DistributedArrays. Are these arrays really
> distributed across processes? Use a _largish_ array for this: large enough to spot memory usage, but not too large not
> to exceed physical memory and not to block other participants (especially if you do this on the login node).

### Building a distributed array from local pieces [^1]

[^1]: This example was adapted from Ge Baolai's presentation "Julia: A third perspective - parallel computing explained" (https://www.youtube.com/watch?v=HWLV6oTmfO8&t=2420s), Western University, SHARCNET, 2020.

Let's restart Julia with `julia` (single control process) and load the packages:

```julia
using Distributed
addprocs(4)
using DistributedArrays       # important to load this after addprocs()
@everywhere using LinearAlgebra
```

We will define an $8 \times 8$ matrix with the main diagonal and two off-diagonals (*tridiagonal* matrix). The lines show our
matrix distribution across workers:

{{< figure src="/img/matrix.png" >}}

Notice that with the 2x2 decomposition two of the 4 blocks are also tridiagonal matrices. We'll define a function to
initiate them:

```julia
@everywhere function tridiagonal(n)
    la = zeros(n,n)
    la[diagind(la,0)] .= 2.     # diagind(la,k) provides indices of the kth diagonal of a matrix
    la[diagind(la,1)] .= -1.    # below the main diagonal
    la[diagind(la,-1)] .= -1.   # above the main diagonal
    return la
end
```

We also need functions to define the other two blocks:

```julia
@everywhere function upperRight(n)
    la = zeros(n,n)
    la[n,1] = -1.
    return la
end
@everywhere function lowerLeft(n)
    la = zeros(n,n)
    la[1,n] = -1.
    return la
end
```

We use these functions to define local pieces on each block and then create a distributed 8x8 matrix on a 2x2 process
grid:

```julia
d11 = @spawnat 2 tridiagonal(4)
d21 = @spawnat 3 lowerLeft(4)
d12 = @spawnat 4 upperRight(4)
d22 = @spawnat 5 tridiagonal(4)
d = DArray(reshape([d11 d21 d12 d22],(2,2)))   # create a distributed 8x8 matrix on a 2x2 process grid
d
```

> ### Exercise "DArrays.2"
> Redefine `showDistribution()` on the control process and run `showDistribution(d)`.

<!-- Solution: need to run `using DistributedArrays` on all workers. -->

### Accessing distributed arrays

While using distribited array saves memory and allows one to access the entire array in global address, it is tedious and sometimes challenging to do book keeping. For instance, setting values to a specific location in a distributed array is no easy job, as the DistributedArrays package only allows the process that owns the portion of the data to alter the values. Finding the boundary of the portion of data owned by each process is the first step towards setting values at the right locations within the boundaries.

Consider two scenarios in which we are to write a slice of data to an one dimensional array `A[istart:iend]`:

1. The range `istart:iend` falls into the range of indices of data owned by a process;
2. The range `istart:iend` falls across two adjacent portion of data owned by two different processes.

as depicted in the diagram below, the shaped areas represent the portion of the array `A` to be updated

{{< figure src="/img/darray_part.png" width=550px >}}

To set the value of `A[i]`, we need to use the method `.localpart`

```julia
A.localpart[i] = value
```

We wish this can be improved in the future, such that we can simply do

```julia
A[i] = value
```

But the time being, this is the way it is.

Logically, to accomplish the setting values at `A[istart:iend]`, we need perform the following

1. On each worker, find the lower and upper indices `ilo` and `iup`, respectively, of the data portion owned by the worker process; 
2. Find the intersection `iset` of indices of range `istart` and `iend` and the set of indices of local portion of data ranging from `ilo` to `iup;
3. Find the range of local indices of `iset` 
```julia
lstart = iset[1] - ilo + 1;
lend = iset[2] - ilo + 1;
```
4. Set the values with 
```julia
A.localpart[lstart:lend] = ...
```

### Solving 1D heat equation using distributed array[^2]

[^2]: This example is included in some of the SHARCNET training courses including Modern Fortran, Python, MPI and a few others.

Consider a (simplified) physics problem: A rod of length $[-L,L]$ heated in the middle, then the heat source is removed. The temperature distribution $T(x,t)$ across the rod over time can be simulated by the following equation

\\[
T(x,t+\Delta t) = \frac{1}{2}T(x-\Delta x,t) + \frac{1}{2}T(x+\Delta x,t)
\\]

on a set of evenly spaced points apart by $\Delta x$. The initial condition is shown in the diagram below. At $t=0$, $T(x,0) = T_0$ for $-h \leq x \leq h$ and $T(x,0) = 0$ elsewhere.

{{< figure src="/img/grid_coords.png" width=650px >}}

At both ends, we impose the boundary conditions $T(-L,t)=0$ and $T(L,t)=0$.

The solution of the temperature across the rod is a bell shaped curve being flattened over time. The figure below shows a snapshot of the solution (with $T_0 = 1$) on an interval $[-1,1]$ at certain time.

{{< figure src="/img/1d_heat_eq_solution.png" >}}

This example is used in many of our training courses, for example, MPI, Fortran and Python courses to illustrate parallel processing in advanced research computing. A more "accurate" formula involving three spatial points $x_i - \Delta x$, $x_i$ and $x_i + \Delta x$ for computing the temperature at the next time step $t_n+\Delta t$ for interior points $i=1,\ldots,N$ is given below

\\[
T(x_i,t_n+\Delta t) = (1-2k)T(x_i,t_n) + k((T(x_{i-1},t_n)+T(x_{i+1},t_n))
\\]

where $k$ is a parameter that shall be chosen properly in order for the numerical procedure to be stable.

Note in the formula, the temperature $T(x_i,t_n+\Delta t)$ at the next time step $t_{n+1} = t_n +\Delta t$ can be computed explicitly using the values of $T$ at three points at current time step $t_n$, which are all known. This allows us to compute all grid values of $T$ at time $t_n+\Delta t$ independent of each other, hence to achieve parallelism.

Let $U_i^n$ denote the value of $T(x_i,t_n)$ at grid points $x_i$, $i=1,\ldots,N$ at time $t_n$, we use the short notation

\\[
U_i^{n+1} = (1-2k)U_i^n + k(U_{i-1}^n + U_{i+1}^n).
\\]

for $i=1,\ldots,N$. This can be translated into the following code with one dimensional two arrays `unew[1:N]` and `u[1:N]` holding values at the $N$ grid points at $t_{n+1}$ and $t_n$ respectively[^1]

```julia
for i=1:N
    unew[i] = (1-2k)u[i] + k*(u[i-1] + u[i+1])
end
```
[^1]: Note that `2k` is not a typo, it is a legal Julia expression, meaning `2*k`.  

This loop in fact can be replaced by the following one line of code using a single array `u[1:N]`

```julia
u[2:N-1] = (1-2k)*u[2:N-1] + k*(u[1:N-2) + u[3:N])
```

In this case, vectorized operations on the right hand side take place first before the individual elements on the left hand side are updated.

__Serial code__. A serial code is given below. The time evolution loop is at the end of the code.

```julia
using Plots, Base

# Input parameters
a = 1.0
n = 65			# Number of end points 1 to n (n-1 intervals).
dt = -0.0005 		# dt <= 0.5*dx^2/a, ignored if set negative
k = 0.1
num_steps = 10000       # Number of stemps in t.
output_freq = 1		# Number of stemps per display.
xlim = zeros(Float64,2)
xlim[1] = -1.0
xlim[2] = 1.0
heat_range = zeros(Float64,2)
heat_range[1] = -0.1
heat_range[2] = 0.1
heat_temp = 1.0

# Set the k value
dx = (xlim[2] - xlim[1])/(n-1)
if (dt > 0)
    k = a*dt/(dx*dx)
end

# Create space for u; create coordinates x for demo
x = xlim[1] .+ dx*(collect(1:n) .-1);
u = zeros(Float64,n);

# Set initial condition
ix = findall(x->(heat_range[1] .< x .&& x .< heat_range[2]),x);
@. u[ix] = heat_temp;

# Display plot (it could be really slow on some systems to launch)
display(plot(x,u[1:n],lw=3,ylim=(0,1),label=("u")))

# Compute the solution over time
for j=1:num_steps
    # Compute the solution for the next time step
    u[2:n-1] = (1.0-2.0k)*u[2:n-1] + k*(u[1:n-2]+u[3:n])
  
    # Display the solution (comment it out for pro
    if (j % output_freq == 0)
        display(plot(x,u[1:n],lw=3,ylim=(0,1),label=("u")))
    end		   
end
```

__Parallel code__. To demonstrate the use of distributed arrays, we implement the parallel version of the code using a distributed array `u` to store the solution. Since we can't write directly to a distributed array, the loop

```julia
for j=1:num_steps
    # Compute the solution for the next time step
    u[2:n-1] = (1.0-2.0k)*u[2:n-1] + k*(u[1:n-2]+u[3:n])
  
    # Display the solution (comment it out for pro
    if (j % output_freq == 0)
        display(plot(x,u[1:n],lw=3,ylim=(0,1),label=("u")))
    end		   
end
```

needs to be modified. Note the array `u` is distributed across workers. The grid is partitioned accordingly. The following illustrates the partition

{{< figure src="/img/grid_1-N.png" width=650px >}}

We need to modify the line

```julia
u[2:n-1] = (1.0-2.0k)*u[2:n-1] + k*(u[1:n-2]+u[3:n])
```

such that the computation is done on each worker locally. This is illustrated in the diagram below

{{< figure src="/img/grid_part_no_overlap.png" width=650px >}}

The indices on the right hand side need to be replaced by the start and end indices on the current process. On the left hand side, as we've seen before, we need to use the function `localindices(local_start, local_end)` to replace the global index (which is a huge draw back with the current design of the package DistributedArrays)

```julia
ll1 = ... # Local start index
lln = ... # Local end index
u.localpart[ll1:lln] = (1.0-2.0*k)*u[l1:ln] + k*(u[l1-1:ln-1]+u[l1+1:ln+1])
```

where `.localpart` is a method associated with the distributed array object that allows us to access and alter the values of the portion owned by the current worker process.

To avoid retrieving the start and end indices `l1` and `ln` on each worker repeatedly during the time loop, we extract that information before the time loop using a function

```julia
@everywhere function get_partition_info()
    global u;
    global l1, ln, ilo, iup;

    # Get the lower and upper boundary indices from distributed array
    idx = localindices(u);
    index_range = idx[1];
    ilo = index_range.start;
    iup = index_range.stop;
    l1 = ilo;
    ln = iup;

    # Local compute end indices (skip the left and right most end points)
    me = myid() - 1
    if (me == 1) 
        l1 = 2;
    end
    if (me == num_workers)
        ln = iup - 1;
    end
end

for p in workers()
    @async remotecall_fetch(get_partition_info, p)
end
```

Note we use the julia function `localindices()` to get the index range of the distributed array `u`. It returns a range, we then use the method `.start` and `.stop` to get the lower and upper indices `ilo` and `iup`, respectively, of the array owned by the current worker process. We adjust the start and end indices for the very first and very end of the sub-grid for skipping the boundary point there.

Another tricky task we need to accomplish is setting initial condition in `u`. We need to locate the range of indices corresponding to the condition

\\[
u(x,0) = 1,\ \ \mbox{for} -h \leq x \leq h.
\\]

We've done such in the previous exercise. We leave it to the reader as an exercise. A complete sample parallel can be found {{<a "/files/heat1d_darray.jl" "here">}}.
