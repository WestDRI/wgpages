+++
title = "Parallelizing Julia set"
slug = "../summer/julia-11-distributed-julia-set"
weight = 11
katex = true
+++

The Julia set problem was [described in one of the earlier sections](../julia-05-threads-julia-set).

### Parallelizing

How would we parallelize this problem with multi-processing? We have a large array, so we can use
DistributedArrays and compute it in parallel. Copy `juliaSetSerial.jl` to `juliaSetDistributedArrays.jl` and
start editing the latter:

1. Load `Distributed` on the control process.
1. Load `DistributedArrays` on all processes.
1. `stability` array should be distributed:
```jl
stability = dzeros(Int32, height, width);   # distributed 2D array of 0's
```
4. Define function `pixel()` on all processes.
4. Create `fillLocalBlock(stability)` to compute local pieces `stability.localpart` on each worker in parallel. If you
   don't know where to start, begin with checking the complete example with `fillLocalBlock()` from the previous
   section. This function will cycle through all local indices `localindices(stability)`. This function needs to be
   defined on all processes.
4. Replace the loop
```jl
@btime for i in 1:height, j in 1:width
    point = (2*(j-0.5)/width-1) + (2*(i-0.5)/height-1)im
    stability[i,j] = pixel(point)
end
```
with
```jl
@btime @sync for w in workers()
    @spawnat w fillLocalBlock(stability)
end
```
7. Why do we need `@sync` in the previous `for` block?
7. To the best of my knowledge, both Plots' `heatmap()` and NetCDF's `ncwrite()` are serial in Julia, and they cannot
   take distributed arrays. How do we convert a distributed array to a local array to pass to one of these functions?
7. Is your parallel code faster?





To get the full script, click on "Solution" below.

{{< solution >}}
```jl
using Distributed, BenchmarkTools
@everywhere using DistributedArrays

@everywhere function pixel(z)
    c = 0.355 + 0.355im
    z *= 1.2   # zoom out
    for i = 1:255
        z = z^2 + c
        if abs(z) >= 4
            return i
        end
    end
    return 255
end

@everywhere function fillLocalBlock(stability)
    height, width = size(stability)
    h, w = localindices(stability)
    for iGlobal in collect(h)
        iLocal = iGlobal - h.start + 1
        y = 2*(iGlobal-0.5)/height - 1
        for jGlobal in collect(w)
            jLocal = jGlobal - w.start + 1
            point = (2*(jGlobal-0.5)/width-1) + (y)im # rescale to -1:1 in the complex plane
            @inbounds stability.localpart[iLocal,jLocal] = pixel(point)
        end
    end
end

height, width = repeat([2_000],2)   # 2000^2 image

println("Computing Julia set ...")
stability = dzeros(Int32, height, width);   # distributed 2D array of 0's
@btime @sync for w in workers()
    @spawnat w fillLocalBlock(stability)
end

println("Plotting to PNG ...")
using Plots
gr()                       # initialize the gr backend
ENV["GKSwstype"] = "100"   # operate in headless mode
fname = "$(height)x$(width)"
nonDistributed = zeros(Int32, height, width);
nonDistributed[:,:] = stability[:,:];   # ncwrite does not accept DArray type
png(heatmap(nonDistributed, size=(width,height), color=:gist_ncar), fname)

println("Writing NetCDF ...")
using NetCDF
filename = "test.nc"
isfile(filename) && rm(filename)
nccreate(filename, "stability", "x", collect(1:height), "y", collect(1:width), t=NC_INT, mode=NC_NETCDF4, compress=9);
nonDistributed = zeros(Int32, height, width);
nonDistributed[:,:] = stability[:,:];   # ncwrite does not accept DArray type
ncwrite(nonDistributed, filename, "stability");
```
{{< /solution >}}






### Results for 1000^2

Finally, here are my timings on (some old iteration of) the training cluster:

| Code | Time on login node (p-flavour vCPUs) | Time on compute node (c-flavour vCPUs) |
| ------------- | ----- | ----- |
| `julia juliaSetSerial.jl` (serial runtime) | 147.214 ms | 123.195 ms |
| `julia -p 1 juliaSetDistributedArrays.jl` (on 1 worker) | 157.043 ms | 128.601 ms |
| `julia -p 2 juliaSetDistributedArrays.jl` (on 2 workers) | 80.198 ms | 66.449 ms |
| `julia -p 4 juliaSetDistributedArrays.jl` (on 4 workers) | 42.965 ms | 66.849 ms |
| `julia -p 8 juliaSetDistributedArrays.jl` (on 8 workers) | 36.067 ms | 67.644 ms |

<!-- | `julia -p 2 juliaSetDistributedArrays.jl` (on 2 workers) | 15.4s &nbsp;&nbsp; 15.6s &nbsp;&nbsp; 15.2s | -->

Lots of things here to discuss!

One could modify our parallel code to offload some computation to the control process (not just compute on workers as we
do now), so that you would see speedup when running on 2 CPUs (control process + 1 worker).
