+++
title = "SharedArrays.jl"
slug = "julia-11-shared-arrays"
weight = 11
+++

<!-- Add Baolai's materials? -->

Unlike distributed **DArray** from **DistributedArrays.jl**, a **SharedArray** object is stored in full on the control
process, but it is shared across all workers on the same node, with a significant cache on each worker. **SharedArrays**
package is part of Julia's Standard Library (comes with the language).

- Similar to DistributedArrays, you can read elements using their global indices from any worker.
- Unlike with DistributedArrays, with SharedArrays you can **write into any part of the array from any worker** using
  their global indices. This makes it very easy to parallelize any serial code.

There are certain downsides to **SharedArray** (compared to **DistributedArrays.jl**):
1. The ability to write into the same array elements from multiple processes creates the potential for a race condition
  and indeterministic outcome with a poorly written code!
1. You are limited to a set of workers on the same node (does SharedArrays predate DistributedArrays?).
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

Here is another demo with a problem -- let's fill each element with its corresponding `myid()` value:

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
