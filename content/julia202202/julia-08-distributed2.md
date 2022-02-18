+++
title = "Distributed.jl - part 2"
slug = "julia-08-distributed2"
weight = 8
katex = true
+++

### Solution 1: an array of Future references

We could create an array (using *array comprehension*) of Future references and then add up their respective
results. An array comprehension is similar to Python's list comprehension:

```julia
a = [i for i in 1:5];   # array comprehension in Julia
typeof(a)               # 1D array of Int64
```
We can cycle through all available workers:

```julia
[w for w in workers()]                      # array of worker IDs
[(i,w) for (i,w) in enumerate(workers())]   # array of tuples (counter, worker ID)
```

> ### Exercise "Distributed.3"
> Using this syntax, construct an array `r` of Futures, and then get their results and sum them up with
> ```julia
> print("total = ", sum([fetch(r[i]) for i in 1:nworkers()]))
> ```
> You can do this exercise using either the array comprehension from above, or the good old `for` loops.

<!-- ```julia -->
<!-- r = [@spawnat w slow(Int64(1e8), 9, i, nworkers()) for (i,w) in enumerate(workers())] -->
<!-- print("total = ", sum([fetch(r[i]) for i in 1:nworkers()])) -->
<!-- # runtime with 2 simultaneous processes: 10.26+12.11s -->
<!-- ``` -->

With two workers and two CPU cores, we should get times very similar to the last run. However, now our code can scale to
much larger numbers of cores!

> ### Exercise "Distributed.4"
> If you did the previous exercise with an interactive job, now submit a Slurm batch job running the same code on 4 CPU
> cores. Next, try 8 cores. Did your timing change?

### Solution 2: parallel `for` loop with summation reduction

Unlike the **Base.Threads** module, **Distributed** provides a parallel loop with reduction. This means that we can
implement a parallel loop for computing the sum. Let's write `parallelFor.jl` with this version of the function:

```julia
function slow(n::Int64, digits::Int)
    @time total = @distributed (+) for i in 1:n
        !digitsin(digits, i) ? 1.0 / i : 0
    end
    println("total = ", total);
end
```

A couple of important points:

1. We don't need `@everywhere` to define this function. It is a parallel function defined on the control process, and
   running on the control process.
1. The only expression inside the loop is the compact if/else statement. Consider this:

```julia
1==2 ? println("Yes") : println("No")
```

The outcome of the if/else statement is added to the partial sums at each loop iteration, and all these partial sums are
added together.

Now let's measure the times:

```julia
# slow(10, 9)
precompile(slow, (Int, Int))
slow(Int64(1e8), 9)   # total = 13.277605949855722
```

> ### Exercise "Distributed.5"
> Switch from using `@time` to using `@btime` in this code. What changes did you have to make?

<!-- 1. remove `@time` from inside `slow()` definition, add `@btime` when calling the function -->
<!-- 1. replace printing `total` with `return total` -->
<!-- 1. now don't have to precompile the function -->

This will produce the single time for the entire parallel loop (1.498s in my case).

> ### Exercise "Distributed.6"
> Repeat on 8 CPU cores. Did your timing improve?

I tested this code (`parallelFor.jl`) on Cedar with v1.5.2 and `n=Int64(1e9)`:

```sh
#!/bin/bash
#SBATCH --ntasks=...   # number of MPI tasks
#SBATCH --cpus-per-task=1
#SBATCH --nodes=1-1   # change process distribution across nodes
#SBATCH --mem-per-cpu=3600M
#SBATCH --time=0:5:0
#SBATCH --account=...
module load julia
echo $SLURM_NODELIST
# comment out addprocs() in the code
julia -p $SLURM_NTASKS parallelFor.jl
```

| Code | Time  |
| ------------- | ----- |
| serial              | 48.2s |
| 4 cores, same node  | 12.2s |
| 8 cores, same node  |  7.6s |
| 16 cores, same node |  6.8s |
| 32 cores, same node |  2.0s |
| 32 cores across 6 nodes | 11.3s |

### Solution 3: use `pmap` to map arguments to processes

Let's write `mappingArguments.jl` with a new version of `slow()` that will compute partial sum on each worker:

```julia
@everywhere function slow((n, digits, taskid, ntasks))   # the argument is now a tuple
    println("running on worker ", myid())
	total = 0.0
	@time for i in taskid:ntasks:n   # partial sum with a stride `ntasks`
        !digitsin(digits, i) && (total += 1.0 / i)   # compact if statement
    end
    return(total)
end
```

and launch the function on each worker:

```julia
slow((10, 9, 1, 1))   # package arguments in a tuple
nw = nworkers()
args = [(Int64(1e8), 9, j, nw) for j in 1:nw]   # array of tuples to be mapped to workers
println("total = ", sum(pmap(slow, args)))   # launch the function on each worker and sum the results
```

These two syntaxes are equivalent:

```julia
sum(pmap(slow, args))
sum(pmap(x->slow(x), args))
```

We see the following times from individual processes:

```sh
From worker 2:	running on worker 2
From worker 3:	running on worker 3
From worker 4:	running on worker 4
From worker 5:	running on worker 5
From worker 2:	  0.617099 seconds
From worker 3:	  0.619604 seconds
From worker 4:	  0.656923 seconds
From worker 5:	  0.675806 seconds
total = 13.277605949854518
```

### Hybrid parallelism

Here is a simple example of a hybrid multi-threaded / multi-processing code contributed by Xavier Vasseur following the
October 2021 workshop:

```jl
using Distributed
@everywhere using Base.Threads

@everywhere function greetings_from_task(())
    @threads for i=1:nthreads()
	println("Hello from thread $(threadid()) on proc $(myid())")
    end
end

args_pmap  = [() for j in workers()];
pmap(x->greetings_from_task(x), args_pmap)

```

Save this code as `hybrid.jl` and then run it specifying the number of workers with `-p` and the number of threads per
worker with `-t` flags:

```sh
[~/tmp]$ julia -p 4 -t 2 hybrid.jl 
      From worker 5:	Hello, I am thread 2 on proc 5
      From worker 5:	Hello, I am thread 1 on proc 5
      From worker 2:	Hello, I am thread 1 on proc 2
      From worker 2:	Hello, I am thread 2 on proc 2
      From worker 3:	Hello, I am thread 1 on proc 3
      From worker 3:	Hello, I am thread 2 on proc 3
      From worker 4:	Hello, I am thread 1 on proc 4
      From worker 4:	Hello, I am thread 2 on proc 4
```

### Optional integration with Slurm

[ClusterManagers.jl](https://github.com/JuliaParallel/ClusterManagers.jl) package lets you submit Slurm jobs from your
Julia code. This way you can avoid writing a separate Slurm script in bash, and put everything (Slurm submission +
parallel launcher + computations) into a single code. Moreover, you can use Julia as a language for writing complex HPC
workflows, i.e. write your own distributed worflow manager for the cluster.

However, for the types of workflows we consider in this workshop ClusterManagers.jl is an overkill, and we don't
recommend it for beginner Julia users.
