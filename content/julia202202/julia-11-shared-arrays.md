+++
title = "SharedArrays.jl"
slug = "julia-11-shared-arrays"
weight = 11
+++

### Local vs shared arrays in Julia

Let's reiterate this concept in Julia. Any variables created in the control process are only accessible on the control process. In order to make the content stored in a variable accessible by another process, we either need to copy it to the other process or use a shared variable.

In the following example
```julia
n = 10
a = zeros(n)
@distributed for i=1:n
    a[i] = i
end
```

we attempt to assign values to array `a` concurrently by distributing the task in the loop to workers randomly (determined by Julia). But this is not going to happen

```julia
println(a)
[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
``` 

This is because, the distributed assignments took place on workers, not on the control process. Let's see what's on workers

```julia
@everywhere function show()
    println(a)
end
for p in workers()
    remotecall_fetch(show,p)
end
```

The output might surprise us

```bash
      From worker 2:	[1.0, 2.0, 3.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
      From worker 3:	[0.0, 0.0, 0.0, 4.0, 5.0, 6.0, 0.0, 0.0, 0.0, 0.0]
      From worker 4:	[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 7.0, 8.0, 0.0, 0.0]
      From worker 5:	[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 9.0, 10.0]
```

Two things worth noting here. First, `a` gets copied on the workers, otherwise, the workers will have nothing to work on as they don't have access to variables defined on the control process. Second, the result shows, each worker does only a portion of the work, thanks to the rule of `@distributed`. As a result, workers have different "images" of the variable `a` afterwards.

With package `SharedArrays`, a shared array of type `SharedArray` will have a universal view across all process. The following example illustrates the effect of using shared arrays

```julia
using SharedArrays
n = 10
a = SharedArray{Float64}(n)
@distributed for i=1:n
    a[i] = i
end

@everywhere SharedArrays
@everywhere showa()
    println(a)
end
for p in workers()
    remotecall_fetch(showa,p)
end
```

This is the output

```bash
      From worker 2:	[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
      From worker 3:	[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
      From worker 4:	[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
      From worker 5:	[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0]
```

Every worker has the same content. Note in the above we used `remotecall` rather than the macro `@fetchfrom`, as seen elsewhere. We will explain why in the section of pitfalls.

### Shared arrays

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

Each worker updates every element, but the order in which they do this varies from one run to another, producing indeterminate outcome. Let's see how to avoid such unexpected outcomes.

### Partition of shared arrays

Julia defines a "virtual boundary" around the portion of a shared array mapped to a worker. Let's take a look at the following example. We create a shared array `u` of length 17.

```julia
N = 17
u = SharedArray{Float64}(n)
```

Then we use function `localindices` to see the start and end indices of the partitions of the array object `u`. First we run this on the control process

```julia
localindices(u)
```

The output might be a little surprise
```bash
1:0
```

Next we run `localindices(u)` on each worker

```julia
@everywhere using SharedArrays
for p in workers()
    @fetchfrom p println(localindices(u))
end
```

Now the output is what we expected
```bash
      From worker 2:	1:4
      From worker 3:	5:8
      From worker 4:	9:12
      From worker 5:	13:17
```

Now come back to the task we want to accomplish while we hit the unexpected outcomes. What we really want is each worker should fill only its assigned block (parallel init, same result every time. This can be achieved as follows

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

### Pitfall of using shared objects

Let's have a look at the following example, restart Julia with `julia -p 4`

```julia
using SharedArrays
a = SharedArray{Float64}(5_000_000);
varinfo()
```

We will see the output looks like this

```bash
  name                    size summary                              
  –––––––––––––––– ––––––––––– –––––––––––––––––––––––––––––––––––––
  A                 38.148 MiB 5000000-element SharedVector{Float64}
  Base                         Module                               
  Core                         Module                               
  Distributed       39.861 MiB Module                               
  InteractiveUtils 253.909 KiB Module                               
  Main                         Module                               
  ans               38.148 MiB 5000000-element SharedVector{Float64}
```

If we run `varinfo()` on a worker process, say, 3

```julia
@everywhere using InteractiveUtils
@fetchfrom 3 varinfo()
```

we get

```bash
  name              size summary
  ––––––––––– –––––––––– –––––––
  Base                   Module 
  Core                   Module 
  Distributed 39.155 MiB Module 
  Main                   Module 
```

We do not see the variable `A` per se. But we do see the same amount of data 39.861 MiB claimed by `Distributed` as on the control process.

If we try to set the values in `A` on worker 3 to its worker ID with the following code

```julia
@everywhere using SharedArrays
@everywhere function set_to_myid()
    idx = localindices(A);
    A[idx] .= myid();
end
@fetchfrom 3 set_to_myid()
```

we will get the following error

```julia
ERROR: On worker 3:
UndefVarError: A not defined
```

This suggests that, the data is shared across all processes, but the name space of the variable itself is not.

We now modify the function `set_to_myid` a bit as follows

```julia
@everywhere function set_to_myid(a)
    idx = localindices(a);
    a[idx] .= myid();
end
remotecall_fetch(set_to_myid,3,A)
```

This time it should not give any error. The portion of `A` is properly set. If we check the output of `varinfo()` again, wee

```julia
@fetchfrom 3 varinfo()
  name              size summary                                      
  ––––––––––– –––––––––– –––––––––––––––––––––––––––––––––––––––––––––
  Base                   Module                                       
  Core                   Module                                       
  Distributed 39.159 MiB Module                                       
  Main                   Module                                       
  set_to_myid    0 bytes set_to_myid (generic function with 2 methods)
```

Still, `A` is not present. But the assignment of worker ID to `A` on worker 3 has worked.

If we run the following command

```julia
@fetchfrom 3 A[localindices(A)] .= myid()
```

it works, but it has a different meaning. It copies `A` to worker 3 and performs the operation of assignments there. This becomes evident when we see the output of `varinfo` on worker 3

```bash
  name              size summary                                      
  ––––––––––– –––––––––– –––––––––––––––––––––––––––––––––––––––––––––
  A           38.147 MiB 5000000-element SharedVector{Float64}        
  Base                   Module                                       
  Core                   Module                                       
  Distributed 39.161 MiB Module                                       
  Main                   Module                                       
  set_to_myid    0 bytes set_to_myid (generic function with 2 methods)
```

The conclusion so far is, use `remotecall` to execute the code on workers. Use macros `@fetch` etc carefully.

### Solving 1D heat equation using shared array

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
The output of the start and end indices of each subset on each of the workers looks like the following

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
is now done on each subset of the grid points, as shown in the diagram below

{{< figure src="/img/grid_sarray.png" width=600px >}}

We need to replace the start and end indices with the local ones `l1` and `lN`

```julia
u[l1:lN] = (1-2k)*u[l1:lN] + k*(u[l1-1:lN-1) + u[l1+1:lN+1])
```

Note for the left most subset, we need to skip the very first one, as it is the boundary point, no need to compute the solution for. So is for the right most one, we need to skip the very last one.

We define a function `update` that computes the solution only for the portion that the worker owns it. For demo purpose, we have it compute the local start and end indices as well, which could be set in a different way.

```julia
@everywhere function update(u,me)
    # Determine the start and end indices
    l1 = np*(me - 1) + 1;
    ln = l1 + np + n % num_workers - 1;

    # Skip the left most and right most end points
    if (me == 1) 
        l1 = 2;
    end
    if (me == num_workers)
        ln = n - 1;
    end 
    u[l1:ln] = (1.0-2k)*u[l1:ln] + k*(u[l1-1:ln-1]+u[l1+1:ln+1])
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

The time evolution for loop is on the control process. Inside the loop, it calls the function `update` on workers at each time step (in a fork-join fashion). The workers are synchronized after they complete their own computation before moving ahead to the time step. The display is executed on the control process

> ### Exercise 1D heat equation using shared arrays
> 1. Use the serial code as the base. Write a skeleton of the parallel code
> 
```julia
using Base, Distributed, SharedArrays
using Plots

# Input parameters
... ...

# Set the k value
... ...

# Set x-coordinates for plot
... ...

# For demo purpose, set number of workers to 4
num_workers = nworkers() # Number of workder processes
np = div(n,nprocs())	# Number of points local to the process

# Allocate spaces
u = SharedArray{Float64}(n);
u .= 0;

# Set initial condition
ix = findall(x->(heat_range[1] .< x .&& x .< heat_range[2]),x);
@. u[ix] = heat_temp;

# Broadcast parameters to all
@everywhere k=$k
@everywhere n=$n
@everywhere np=$np
@everywhere num_workers=$num_workers
@everywhere l1=1
@everywhere ln=1

# Define the function update on all processes
@everywhere using SharedArrays
@everywhere function get_partition(me)
    # Determine the start and end indices l1, ln (they are global)
    l1 = ... 
    ln = ...

    # Skip the left most and right most end points
    if (me == 1) 
        l1 = 2;
    end
    if (me == num_workers)
        ln = n - 1;
    end 
end
display(plot(x,u,lw=3,ylim=(0,1),label=("u")))

# Get partition info
for p in workers()
    @async remotecall_fetch(get_partition,p,p-1)
end

# Update u in time on workders
@time begin
for j=1:num_steps 
    @sync begin
        for p in workers()
            @async remotecall(update,p,u);
        end
    end           
    if (j % output_freq == 0)
        display(plot(x,u,lw=3,ylim=(0,1),label=("u")))
    end
end
end

sleep(10)
```
> 2. Complete the function `get_partition`
```julia
@everywhere function get_partition(me)
    # Determine the start and end indices
    l1 = ... 
    ln = ...

    # Skip the left most and right most end points
    if (me == 1) 
        l1 = 2;
    end
    if (me == num_workers)
        ln = n - 1;
    end 
end
```
> 3. Write a function `update` as follows
> 
```julia
@everywhere function update(u)
    u[l1:ln] = (1.0-2k)*u[l1:ln] + k*(u[l1-1:ln-1]+u[l1+1:ln+1])
end
```
> 4. Complete the parallel code and see if you can get the same output (graphical display) as the serial code.
