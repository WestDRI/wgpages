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

1. `data` array should be distributed:
```jl
data = dzeros(Float32, height, width);   # distributed 2D array of 0's`
```
2. You need to replace `juliaSet(data, c, zoomOut)` with `fillLocalBlock(data, c, zoomOut)` to compute local pieces of
   `data` on each worker in parallel. If you don't know where to start in this project, begin with checking the complete
   example with `fillLocalBlock()` from the previous section.
2. Functions `pixel()` and `fillLocalBlock()` should be defined on all processes.
2. Load `Distributed` on the control process.
2. Load `DistributedArrays` on all processes.
2. Replace
```julia
@btime juliaSet(data, c, zoomOut)
```
with
```jl
@btime @sync for i in workers()
    @spawnat i fillLocalBlock(data, c, zoomOut)
end
```
5. Why do we need `@sync` in the previous `for` block?
5. To the best of my knowledge, NetCDF's `ncwrite()` is serial in Julia. Is there a parallel version of NetCDF for
   Julia? If not, then unfortunately we will have to use serial NetCDF. How do we do this with distributed `data`?
5. Is your parallel code faster?

### Results for 1000^2

Finally, here are my timings on Uu:

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
