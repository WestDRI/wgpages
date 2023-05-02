+++
title = "Parallelizing Julia set"
slug = "julia-10-distributed-julia-set"
weight = 10
katex = true
+++

The Julia set problem was [described in one of the earlier sections](../julia-05-threads-julia-set).

### Parallelizing

How would we parallelize this problem with multi-processing? We have a large array, so we can use DistributedArrays and
compute it in parallel. Here are the steps:

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
```julia
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
