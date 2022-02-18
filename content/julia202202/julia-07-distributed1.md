+++
title = "Distributed.jl - part 1"
slug = "julia-07-distributed1"
weight = 7
katex = true
+++

### Parallelizing with multiple Unix processes (MPI tasks)

Julia's **Distributed** package provides multiprocessing environment to allow programs to run on multiple processors in
shared or distributed memory. On each CPU core you start a separate Unix / MPI process, and these processes communicate
via messages. Unlike in MPI, Julia's implementation of message passing is **one-sided**, typically with
higher-level operations like calls to user functions on a remote process.

- a **remote call** is a request by one processor to call a function on another processor; returns a **remote/future
  reference**
- the processor that made the call proceeds to its next operation while the remote call is computing, i.e. the call is
  **non-blocking**
- you can obtain the remote result with `fetch()` or make the calling processor block with `wait()`

In this workflow you have a single control process + multiple worker processes. Processes pass information via messages
underneath, not via variables in shared memory.

### Launching worker processes

There are three different ways you can launch worker processes:

1. with a flag from bash:

```sh
julia -p 8             # open REPL, start Julia control process + 8 worker processes
julia -p 8 code.jl     # run the code with Julia control process + 8 worker processes
```

2. from a job submission script:

```sh
#!/bin/bash
#SBATCH --ntasks=8
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=3600M
#SBATCH --time=00:10:00
#SBATCH --account=def-someuser
srun hostname -s > hostfile   # parallel I/O
sleep 5
module load julia/1.7.0
julia --machine-file ./hostfile ./code.jl
```

3. from the control process, after starting Julia as usual with `julia`:

```jl
using Distributed
addprocs(8)
```

> **Note:** All three methods launch workers, so combining them will result in 16 (or 24!) workers (probably not the
> best idea). Select one method and use it.

With Slurm, methods (1) and (3) work very well, so—when working on a CC cluster—usually there is no need to construct a
machine file.

### Process control

Let's start an interactive MPI job:

```sh
source /project/def-sponsor00/shared/julia/config/loadJulia.sh
salloc --mem-per-cpu=3600M --time=01:00:00 --ntasks=4
```

Inside this job, start Julia with `julia` (single control process).

```jl
using Distributed
addprocs(4)   # add 4 worker processes; this might take a while on uu
println("number of cores = ", nprocs())       # 5 cores
println("number of workers = ", nworkers())   # 4 workers
workers()                                     # list worker IDs
```

You can easily remove selected workers from the pool:

```jl
rmprocs(2, 3, waitfor=0)   # remove processes 2 and 3 immediately
workers()
```

or you can remove all of them:

```jl
for i in workers()     # cycle through all workers
    t = rmprocs(i, waitfor=0)
    wait(t)            # wait for this operation to finish
end
workers()
interrupt()   # will do the same (remove all workers)
addprocs(4)   # add 4 new worker processes (notice the new IDs!)
workers()
```

> ### Discussion
> If from the control process we start $N=8$ workers, where will these processes run? Consider the following cases:
> 1. a laptop with 2 CPU cores,
> 1. a cluster login node with 16 CPU cores,
> 1. a cluster Slurm job with 4 CPU cores.

### Remote calls

Let's restart Julia with `julia` (single control process).

```jl
using Distributed
addprocs(4)       # add 4 worker processes
```

Let's define a function on the control process and all workers and run it:

```jl
@everywhere function showid()   # define the function everywhere
    println("my id = ", myid())
end
showid()                        # run the function on the control process
@everywhere showid()            # run the function on the control process + all workers
```

`@everywhere` does not capture any local variables (unlike `@spawnat` that we'll study below), so on workers we don't
see any variables from the control process:

```jl
x = 5     # local (control process only)
@everywhere println(x)    # get errors: x is not defined elsewhere
```

However, you can still obtain the value of `x` from the control process by using this syntax:

```jl
@everywhere println($x)   # use the value of `x` from the control process
```

The macro that we'll use a lot today is `@spawnat`. If we type:

```jl
a = 12
@spawnat 2 println(a)     # will print 12 from worker 2
```

it will do the following:

1. pass the namespace of local variables to worker 2
1. spawn function execution on worker 2
1. return a Future handle (referencing this running instance) to the control process
1. return the REPL to the control process (while the function is running on worker 2), so we can continue running commands

Now let's modify our code slightly:

```jl
a = 12
@spawnat 2 a+10          # Future returned but no visible calculation
```

There is no visible calculation happening; we need to fetch the result from the remote function before we can print it:

```jl
r = @spawnat 2 a+10
typeof(r)
fetch(r)                 # get the result from the remote function; this will pause
                         #         the control process until the result is returned
```

You can combine both `@spawnat` and `fetch()` in one line:

```jl
fetch(@spawnat 2 a+10)   # combine both in one line; the control process will pause
@fetchfrom 2 a+10        # shorter notation; exactly the same as the previous command
```

> ### Exercise "Distributed.1"
> Try to define and run a function on one of the workers, e.g.
> ```julia
> function cube(x)
>     return x*x*x
> end
> ```
> **Hint**: Use `@everywhere` to define the function on all workers. Julia may not have a high-level mechanism to define
> a function on a specific worker, short of loading that function as a module from a file. Something like this
> ```jl
> @fetchfrom 2 function cube(x)
>     return x*x*x
> end
> ```
> does not seem to have any effect.

> ### Exercise "Distributed.2"
> Now run the same function on all workers, but not on the control process. **Hint**: use `workers()` to cycle through
> all worker processes and `println()` to print from each worker.

<!-- ```jl -->
<!-- using Distributed -->
<!-- addprocs(4) -->
<!-- @everywhere function cube(x) -->
<!--     return x*x*x -->
<!-- end -->
<!-- # one solution -->
<!-- for w in workers() -->
<!--     @spawnat w println(cube(w)) -->
<!-- end -->
<!-- # another solution -->
<!-- for w in workers() -->
<!--     println(@fetchfrom w cube(w)) -->
<!-- end -->
<!-- ``` -->

You can also spawn computation on *any* available worker:

```jl
r = @spawnat :any log10(a)   # start running on one of the workers
fetch(r)
```

### Back to the slow series: serial code

Let's restart Julia with `julia -p 2` (control process + 2 workers). We'll start with our serial code (below), save it as `serialDistributed.jl`, and run it.

```jl
using Distributed
using BenchmarkTools

@everywhere function digitsin(digits::Int, num)
    base = 10
    while (digits ÷ base > 0)
        base *= 10
    end
    while num > 0
        if (num % base) == digits
            return true
        end
        num ÷= 10
    end
    return false
end

@everywhere function slow(n::Int64, digits::Int)
    total = Int64(0)
    for i in 1:n
        if !digitsin(digits, i)
            total += 1.0 / i
        end
    end
    return total
end

@btime slow(Int64(1e8), 9)     # serial run: total = 13.277605949858103
```

For me this serial run takes 3.192 s on uu. Next, let's run it on 3 (control + 2 workers) cores simultaneously:

```jl
@everywhere using BenchmarkTools
@everywhere @btime slow(Int64(1e8), 9)   # runs on 3 (control + 2 workers) cores simultaneously
```

Here we are being silly: this code is serial, so each core performs the same calculation ... I see the following times
printed on my screen: 3.220 s, 2.927 s, 3.211 s—each is from a separate process running the code in a serial fashion.

<!-- When I try to run this code on my laptop (2 CPU cores), and I switch to timing with `@time` (resulting in only one run -->
<!-- per process): -->

<!-- ```jl -->
<!-- @everywhere @time slow(Int64(1e8), 9)   # runs on 3 (control + 2 workers) cores simultaneously -->
<!-- ``` -->

<!-- Overall, it took ~57s of wallclock -->
<!-- time to run the last command. -->

<!-- > ### Exercise 5 -->
<!-- > Why does it take longer than on a single core? On a related question, anyone can guess how long the following -->
<!-- > computation will take: -->
<!-- ```jl -->
<!-- addprocs(2)   # for the total of 4 workers -->
<!-- >>> redefine digitsin() and slow() everywhere -->
<!-- @everywhere using BenchmarkTools -->
<!-- @everywhere slow(Int64(1e9), 9) -->
<!-- ``` -->

How can we make this code parallel and faster?

### Parallelizing our slow series: non-scalable version

Let's restart Julia with `julia` (single control process) and add 2 worker processes:

```jl
using Distributed
addprocs(2)
workers()
```

We need to redefine `digitsin()` everywhere, and then let's modify `slow()` to compute a partial sum:

```jl
@everywhere function slow(n::Int, digits::Int, taskid, ntasks)   # two additional arguments
    println("running on worker ", myid())
    total = 0.0
    @time for i in taskid:ntasks:n   # partial sum with a stride `ntasks`
        if !digitsin(digits, i)
            total += 1.0 / i
        end
    end
    return(total)
end
```

Now we can actually use it:

```jl
# slow(Int64(10), 9, 1, 2)   # precompile the code
precompile(slow, (Int, Int, Int, Int))
a = @spawnat :any slow(Int64(1e8), 9, 1, 2)
b = @spawnat :any slow(Int64(1e8), 9, 2, 2)
print("total = ", fetch(a) + fetch(b))   # 13.277605949852546
```

For timing I got 1.30 s and 1.66 s, running concurrently, which is a 2X speedup compared to the serial run—this is
great! Notice that we received a slightly different numerical result, due to a different order of summation.

However, our code is **not scalable**: it is limited to a small number of sums each spawned with its own Future
reference. If we want to scale it to 100 workers, we'll have a problem.

How do we solve this problem—any idea before I show the solution in the next section?
