+++
title = "Multi-threading - part 2"
slug = "julia-04-threads2"
weight = 4
+++

### 1st multi-threaded version: using an atomic variable

Recall that with an atomic variable only one thread can write to this variable at a time: other threads have to wait
before this variable is released, before they can write. With several threads running in parallel, there will be a lot
of waiting involved, and the code should be relatively slow.

```julia
using Base.Threads
function slow(n::Int64, digits::Int)
    total = Atomic{Float64}(0)
    @time @threads for i in 1:n
        if !digitsin(digits, i)
            atomic_add!(total, 1.0 / i)
	end
    end
    println("total = ", total[])
end
```

> ## Exercise 1
> Put this version of `slow()` along with `digitsin()` into a file `atomicThreads.jl` and run it from the bash terminal
> (not from REPL!), making sure to precompile the functions. First, time this code with 1e9 terms using one thread
> (serial run `julia atomicThreads.jl`). Next, time it with four threads (parallel run `julia -t 4
> atomicThreads.jl`). Did you get any speedup?  Do this exercise on the login node. Make sure you obtain the correct
> numerical result.

With one thread I measured 39.63s 38.77s 38.62s. The runtime increased only marginally (now we are using `atomic_add()`)
which makes sense: with one thread there is no waiting for the variable to be released.

With four threads I measured 27.98s 29.01s 28.15s -- let's discuss! Is this what we expected?

> ## Exercise 2:
> Let's run using four threads on a compute node. Do you get similar or different numbers compared to the login node?
>

> Hint: you will need to submit a multi-core job with `sbatch shared.sh`. Consult your notes from
> [Introduction to HPC](../../basics_hpc), or look up the script in [the Chapel course](../../parallel_chapel).

### 2nd multi-threaded version: alternative thread-safe implementation

In this version each thread is updating its own sum, so there is no waiting for the atomic variable to be released? Is
this code faster?

```julia
using Base.Threads
function slow(n::Int64, digits::Int)
    total = zeros(Float64, nthreads())
    @time @threads for i in 1:n
        if !digitsin(digits, i)
            total[threadid()] += 1.0 / i
        end
    end
    println("total = ", sum(total))
end
```

> ## Exercise 3
> Save this code as `separateSums.jl` (along with other necessary bits) and run it on four threads from the command line
> `julia -t 4 separateSums.jl`. What is your new code's timing?

With four threads I measured 22.02s 22.30s 21.75s -- let's discuss!

### 3rd multi-threaded version: using heavy loops

This version is classical **task parallelism**: we divide the sum into pieces, each to be processed by an individual
thread. For each thread we explicitly compute the `start` and `finish` indices it processes.

```julia
using Base.Threads
function slow(n::Int64, digits::Int)
    numthreads = nthreads()
    threadSize = floor(Int64, n/numthreads)   # number of terms per thread (except last thread)
    total = zeros(Float64, numthreads);
    @time @threads for threadid in 1:numthreads
        local start = (threadid-1)*threadSize + 1
        local finish = threadid < numthreads ? (threadid-1)*threadSize+threadSize : n
        println("thread $threadid: from $start to $finish");
        for i in start:finish
            if !digitsin(digits, i)
                total[threadid] += 1.0 / i
            end
        end
    end
    println("total = ", sum(total))
end
```

Let's time this version together with `heavyThreads.jl`: 22.58s 21.42s 21.56s -- is this the fastest version?

> ## Exercise 4
> Would the runtime be different if we use 2 threads instead of 4?

Finally, below are the timings on Cedar with `heavyThreads.jl`. Note that the times reported here were measured
with 1.5.2. Going from 1.5 to 1.6, Julia saw quite a big improvement (~30%) in performance, so treat these numbers only
as relative to each other (plus a CPU on Cedar is different from a vCPU on Cassiopeia!).

```sh
#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=...
#SBATCH --mem-per-cpu=3600M
#SBATCH --time=00:10:00
module load julia/1.5.2
julia -t $SLURM_CPUS_PER_TASK heavyThreads.jl
```

| | | | | |
|-|-|-|-|-|
|__Code__| serial | 2 cores | 4 cores | 16 cores |
|__Time__| 47.8s | 27.5s | 15.9s | 8.9s |

### Other Base.Threads tools

In addition to `@threads` (parallelize a loop with multiple threads), Base.Threads includes a couple of other tools to
launch computations on any available thread. One of them is `Threads.@spawn` that will run an expression / function on
another thread.

Consider this:

```julia
using Base.Threads
nthreads()   # make sure you have access to multiple threads
threadid()   # always shows 1 = local thread
import Base.Threads.@spawn    # no idea why this syntax
fetch(@spawn threadid())      # run this function on another available thread and get the result
```

Every time you run this, you will get a semi-random reponse, e.g.

```julia
for i in 1:30
    print(fetch(@spawn threadid()), " ")
end
```

Conceptually, this is similar to `@spawnat` from Distributed package that we will study in the next session, so we won't
spend time on this now. For more details, you can check
[this blog entry](https://julialang.org/blog/2019/07/multithreading).
