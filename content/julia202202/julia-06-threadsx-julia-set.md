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
stability = @btime map(pixel, point);   # no const keyword this time!
```

Running this new, vectorized version of the serial code on my laptop, I see `@btime` report 1.011 s.

## Parallelizing the vectorized code

1. Load ThreadsX library.
1. Replace `map()` with `ThreadsX.map()`.

With 8 threads on my laptop, the runtime went down to 180.815 -- 5.6X speedup. On 8 cores on Uu I see 6.5X speedup.

## Alternative parallel solution

Jeremiah O'Neil suggested an alternative, slightly faster implementation using `ThreadsX.foreach` (not covered in this
workshop):

```jl
function juliaSet(height, width)
    stability = zeros(Int32, height, width)
    ThreadsX.foreach(1:height) do i
        for j = 1:width
            point = (2*(j-0.5)/width-1) + (2*(i-0.5)/height-1)im
            stability[i,j] = pixel(point)
        end
    end
    return stability
end
```

## Running multi-threaded Julia codes on a production cluster

Before we jump to multi-processing in Julia, let us remind you how to run multi-threaded Julia codes on an HPC cluster.

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

There may be some other lines after loading the Julia module, e.g. setting some variables, if you have installed
packages into a non-standard location (see [our introduction](../julia-01-intro-language)).

Running the last example on Cedar cluster with julia/1.7.0, `@btime` reported 2.467 s (serial) and 180.003 ms (16 cores)
-- 13.7X speedup.
