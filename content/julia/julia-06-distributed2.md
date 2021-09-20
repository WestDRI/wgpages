+++
title = "Distributed.jl - part 2"
slug = "julia-06-distributed2"
weight = 6
katex = true
+++

### Solution 1: an array of Future references

We could create an array (using *array comprehension*) of Future references and then add up their respective
results. An array comprehension is similar to Python's list comprehension:

```julia
a = [i for i in 1:5];
typeof(a)   # 1D array of Int64
```
We can cycle through all available workers:

```julia
[w for w in workers()]                      # array of worker IDs
[(i,w) for (i,w) in enumerate(workers())]   # array of tuples (counter, worker ID)
```

> ## Exercise 6
> Using this syntax, construct an array `r` of Futures, and then get their results and sum them up with
> ```julia
> print("total = ", sum([fetch(r[i]) for i in 1:nworkers()]))
> ```

<!-- ```julia -->
<!-- r = [@spawnat p slow(Int64(1e9), 9, i, nworkers()) for (i,p) in enumerate(workers())] -->
<!-- print("total = ", sum([fetch(r[i]) for i in 1:nworkers()])) -->
<!-- # runtime with 2 simultaneous processes: 10.26+12.11s -->
<!-- ``` -->

With two workers and two CPU cores, we should get times very similar to the last run. However, now our code can scale to
much larger number of cores!

> ## Exercise 7
> Now submit a Slurm job asking for four processes, and run the same code on two full Cassiopeia nodes (4 CPU
> cores). Did your timing change?

### Solution 2: parallel `for` loop with summation reduction

Unlike **Base.Threads** module, **Distributed** provides a parallel loop with reduction. This means that we can
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
slow(10, 9)
slow(Int64(1e9), 9)   # total = 14.241913010399013
```

This will produce the single time for the entire parallel loop (19.03s in my case).

> ## Exercise 8
> Repeat on two full Cassiopeia nodes (4 CPU cores). Did your timing change?

I tested this code (`parallelFor.jl`) on Cedar with v1.5.2:

```sh
#SBATCH --ntasks=...   # number of MPI tasks
#SBATCH --cpus-per-task=1
#SBATCH --nodes=1-1   # change process distribution across nodes
#SBATCH --mem-per-cpu=3600M
#SBATCH --time=0:5:0
#SBATCH --account=...
module load julia/1.5.2
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
    for i in taskid:ntasks:n   # partial sum
        if !digitsin(digits, i)
            total += 1.0 / i
        end
    end
    return(total)
end
```

and launch the function on each worker:

```julia
slow((10, 9, 1, 1))   # package arguments in a tuple
nw = nworkers()
args = [(Int64(1e9),9,j,nw) for j in 1:nw]   # array of tuples to be mapped to workers
println("total = ", sum(pmap(slow, args)))   # launch the function on each worker and sum the results
```

These two syntaxes are equivalent:

```julia
sum(pmap(slow, args))
sum(pmap(x->slow(x), args))
```

### Optional integration with Slurm

[ClusterManagers.jl](https://github.com/JuliaParallel/ClusterManagers.jl) package lets you submit Slurm jobs from your
Julia code. This way you can avoid writing a separate Slurm script in bash, and put everything (Slurm submission +
parallel launcher + computations) into a single code. Moreover, you can use Julia as a language for writing complex HPC
workflows, i.e. write your own distributed worflow manager for the cluster.

However, for the types of workflows we consider in this workshop ClusterManagers.jl is an overkill, and we don't
recommend it for beginner Julia users.
