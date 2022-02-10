+++
title = "Parallelizing the Julia set with ThreadsX"
slug = "julia-06-threadsx-julia-set"
weight = 6
+++

So far with ThreadsX, most of our parallel codes featured reduction -- recall the functions `ThreadsX.mapreduce()` and
`ThreadsX.sum()`. However, in the Julia set problem we want to process an array without reduction.

Let's first modify the serial code! We will use another function from Base library:

```jl
?map
map(x -> x * 2, [1, 2, 3])
map(+, [1, 2, 3], [10, 20, 30, 400, 5000])   # not a reduction!
```

Let's modify our serial code `juliaSetSerial.jl`:

1. Define the complex array of points `point = zeros(Complex{Float32}, height, width);`.
2. Precompute these points
```jl
for i in 1:height, j in 1:width
    point[i,j] = (2*(j-0.5)/width-1) + (2*(i-0.5)/height-1)im # rescale to -1:1 in the complex plane
end
```
3. Replace the loop for computing `stability` with
```jl
stability = @btime map(pixel, point);
```

Running this new, vectorized version of the serial code, `@btime` reports 963.062 ms.

## Parallelizing the vectorized code

1. Load ThreadsX library.
1. Replace `map()` with `ThreadsX.map()`.

With 8 threads on my laptop, the runtime went down to 175.994 ms -- 5.5X speedup.

## Running multi-threaded Julia codes on a cluster

Before we jump to multi-processing in Julia, let us show you how you can run multi-threaded Julia codes on an HPC
cluster.

```sh
#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=...
#SBATCH --mem-per-cpu=3600M
#SBATCH --time=00:10:00
#SBATCH --account=def-user
module load julia
julia -t $SLURM_CPUS_PER_TASK juliaSetThreadsX.jl
```

Running the last example on Cedar cluster with julia/1.7.0, `@btime` reported 2.467 s (serial) and 180.003 ms (16 cores)
-- 13.7X speedup.

## Installing Julia packages on a production cluster

By default, all Julia packages you install from REPL will go into `$HOME/.julia`. If you want to put packages into
another location, you will need to (1) install inside your Julia session with:

```jl
empty!(DEPOT_PATH)
push!(DEPOT_PATH,"/scratch/path/to/julia/packages") 
] add BenchmarkTools
```

and (2) before running Julia modify two variables:

```sh
module load julia
export JULIA_DEPOT_PATH=/home/\$USER/.julia:/scratch/path/to/julia/packages
export JULIA_LOAD_PATH=@:@v#.#:@stdlib:/scratch/path/to/julia/packages
```

Don't do this on the training cluster! We already have everything installed in a central location for all guest
accounts.
