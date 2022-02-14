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

Note in the formula, the temperature $T(x_i,t_n+\Delta t)$ to be computed at the next time step $t_{n+1} = t_n +\Delta t$ depends on the values of $T$ at three points at current time step $t_n$, which are all known. This allows us to compute all grid values of $T$ at time $t_n+\Delta t$ independent of each other, hence to achieve parallelism.

Let $U_i^n$ denote the value of $T(x_i,t_n)$ at grid points $x_i$, $i=1,\ldots,N$ at time $t_n$, we use the short notation

\\[
U_i^{n+1} = (1-2k)U_i^n + k(U_{i-1}^n + U_{i+1}^n).
\\]

for $i=1,\ldots,N$. This can be translated into the following code with one dimensional two arrays `unew[1:N]` and `u[1:N]` holding values at the $N$ grid points at $t_{n+1}$ and $t_n$ respectively

```julia
for i=1:N
    unew[i] = (1-2*k)u[i] + k*(u[i-1] + u[i+1])
end
```

This in fact can be replaced by the following one line of code using a single array `u[1:N]`

```julia
u[2:N-1] = (1-2k)*u[2:N-1] + k*(u[1:N-2) + u[3:N])
```

In this case, vectorized operations on the right hand side take place first before the individual elements on the left hand side are updated.

__Serial code__. A serial code is given below

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
display(plot(x,u[1:n],lw=3,ylim=(0,1),lable=("u")))

# Compute the solution over time
for j=1:num_steps
    # Compute the solution for the next time step
    u[2:n-1] = (1.0-2.0*k)*u[2:n-1] + k*(u[1:n-2]+u[3:n])
  
    # Display the solution (comment it out for pro
    if (j % output_freq == 0)
        display(plot(x,u[1:n],lw=3,ylim=(0,1),lable=("u")))
    end		   
end
```

__Parallel solution__. We divide the domain - the set of grid points - into subdomains and assign each of them and the computational tasks to a worker. That's the basic idea

{{< figure src="/img/grid_1-N.png" width=650px >}}

Let $P$ be the number of participating processes - workers in Julia's term. The way of partitioning the domain is not unique. We choose a simple one: each subdomain gets $N \div P$ points and the last one includes the remainder, that is, for subdomain $1$ to $P-1$, the number of local grid points

\\[
N_{\ell} = N \div P
\\]

and for the last subdomain

\\[
N_P = N \div P + N \bmod P.
\\]

This is in fact what Julia does for the partition of one dimensional arrays. For example, let $N=17$. The following code shows how the shared array `u[1:N]` is "partitioned" on each worker

```julia
using SharedArrays
N = 17
u = zeros(N)
for p = workers() # Assume we have created 4 workers
    @fetchfrom p println(localindices(u))
end
```
The output looks like the following

```bash
      From worker 2:	1:4
      From worker 3:	5:8
      From worker 4:	9:12
      From worker 5:	13:17
```

The calculation of
```julia
u[2:N-1] = (1-2k)*u[2:N-1] + k*(u[1:N-2) + u[3:N])
```
is now will done on each subset of the grid points, as shown in the diagram below

{{< figure src="/img/grid_part_no_overlap.png" width=650px >}}

We need to replace the start and end indices with the local ones `l1` and `lN`

```julia
u[l1:lN] = (1-2k)*u[l1:lN] + k*(u[l1-1:lN-1) + u[l1+1:lN+1])
```

Note for the left most subset, we need to skip the very first one, as it is the boundary point, no need to compute the solution for. So is for the right most one, we need to skip the very last one.

We define a function `update` that computes the solution only for the portion that the worker owns it. For demo purpose, we have it compute the local start and end indices

```julia
@everywhere function update(u,me)
    # Determine the start and end indices
    i1 = np*(me - 1) + 1;
    in = i1 + np + n % num_workers - 1;

    # Skip the left most and right most end points
    if (me == 1) 
        i1 = 2;
    end
    if (me == num_workers)
        in = n - 1;
    end 
    u[i1:in] = (1.0-2*k)*u[i1:in] + k*(u[i1-1:in-1]+u[i1+1:in+1])
end
```

Now our parallel version of the code looks like the following. 
```julia
for j=1:num_steps 
    @sync begin
        for p=1:num_workers
            @async remotecall(update,p+1,u,p);
        end
    end           
    if (j % output_freq == 0)
        display(plot(x,u,lw=3,ylim=(0,1),label=("u")))
    end
end
```

The time evolution for loop in one the control process. Inside the loop, it calls the function `update` on workers at each time step (in a fork-join fashion). The display is executed on the control process

