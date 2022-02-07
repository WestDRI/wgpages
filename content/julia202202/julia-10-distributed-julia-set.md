+++
title = "Parallelizing Julia set"
slug = "julia-10-distributed-julia-set"
weight = 10
katex = true
+++

In this section I will describe one of the two projects you can work on this afternoon. The project is the mathematical
problem to compute **Julia set** -- no relation to Julia language! A
[Julia set](https://en.wikipedia.org/wiki/Julia_set) is defined as a set of points on the complex plane that remain
bound under infinite recursive transformation $f(z)$. We will use the traditional form $f(z)=z^2+c$, where $c$ is a
complex constant. Here is our algorithm:

1. pick a point $z_0\in\mathbb{C}$
1. compute iterations $z_{i+1}=z_i^2+c$ until $|z_i|>4$ (arbitrary fixed radius; here $c$ is a complex constant)
1. store the iteration number $\xi(z_0)$ at which $z_i$ reaches the circle $|z|=4$
1. limit max iterations at 255  
    4.1 if $\xi(z_0)=255$, then $z_0$ is a stable point  
    4.2 the quicker a point diverges, the lower its $\xi(z_0)$ is
1. plot $\xi(z_0)$ for all $z_0$ in a rectangular region $-1<=\mathfrak{Re}(z_0)<=1$, $-1<=\mathfrak{Im}(z_0)<=1$

We should get something conceptually similar to this figure (here $c = 0.355 + 0.355i$; we'll get drastically different
fractals for different values of $c$):

{{< figure src="/img/2000a.png" >}}

Below is the serial code `juliaSetSerial.jl`. First, you need to install the required packages:

```julia
] add ProgressMeter
] add NetCDF
```

Next, let's study the code:

```julia
using BenchmarkTools, NetCDF

function pixel(z, c)
    for i = 1:255
        z = z^2 + c
        if abs2(z) >= 16.0
            return i
        end
    end
    return 255
end

function juliaSet(data, c, zoomOut)
    height, width = size(data)
    for i in 1:height
        y = (2*(i-0.5)/height - 1)*zoomOut      # rescale to -zoomOut:zoomOut in the complex plane
        for j in 1:width
            x = (2*(j-0.5)/width - 1)*zoomOut   # rescale to -zoomOut:zoomOut in the complex plane
            @inbounds data[i,j] = pixel(x+im*y, c)
        end
    end
end

c, zoomOut = 0.355 + 0.355im, 1.2
height = width = 1000
data = Array{Float32,2}(undef, height, width);

println("Computing Julia set ...")
@btime juliaSet(data, c, zoomOut)

# println("Very slow on-screen plotting ...")
# using Plots
# plot(heatmap(data, size=(width,height), color=:Spectral))

println("Writing NetCDF ...")
filename = "test.nc"
isfile(filename) && rm(filename)   # compact if statement
nccreate(filename, "stability", "x", collect(1:height), "y", collect(1:width), t=NC_FLOAT, mode=NC_NETCDF4, compress=9);
ncwrite(data, filename, "stability");
```

Let's run this code with `julia juliaSetSerial.jl`. It'll produce the file `test.nc` that you can download to your
computer and visualize with ParaView or other visualization tool.

> ### Exercise "Fractal.1"
> 1. Compare the expected and actual file sizes.
> 1. Try other parameter values:
> ```julia
> c, zoomOut = 0.355 + 0.355im, 1.2   # the default one: spirals
> c, zoomOut = 1.2exp(1.1π*im), 1     # original textbook example
> c, zoomOut = -0.4 - 0.59im, 1.5     # denser spirals
> c, zoomOut = 1.34 - 0.45im, 1.8     # beans
> c, zoomOut = 0.34 -0.05im, 1.2      # connected spiral boots
> ```
> 3. You can also try increasing problem sizes up from $1000^2$. Will you have enough physical memory for $8000^2$?
>    How does this affect the runtime?

### Parallelizing

How would we parallelize this problem? We have a large array, so we can use DistributedArrays and compute it in
parallel. Here are the steps:

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
