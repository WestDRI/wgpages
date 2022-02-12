+++
title = "Parallelizing the Julia set with Base.Threads"
slug = "julia-05-threads-julia-set"
weight = 5
+++

<!-- In this section I will describe one of the two projects you can work on this afternoon.  -->

The project is the mathematical problem to compute a **Julia set** -- no relation to Julia language! A
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

**Note**: you might want to try these values too:
- $c = 1.2e^{1.1πi}$ $~\Rightarrow~$ original textbook example
- $c = -0.4-0.59i$ and 1.5X zoom-out $~\Rightarrow~$ denser spirals
- $c = 1.34-0.45i$ and 1.8X zoom-out $~\Rightarrow~$ beans
- $c = 0.34-0.05i$ and 1.2X zoom-out $~\Rightarrow~$ connected spiral boots

Below is the serial code `juliaSetSerial.jl`. If you are running Julia on your own computer, make sure you have the required packages:

```julia
] add BenchmarkTools
] add Plots
```

Let's study the code:

```julia
using BenchmarkTools, Plots

function pixel(z)
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

height, width = repeat([2_000],2)   # 2000^2 image

println("Computing Julia set ...")
stability = zeros(Int32, height, width);
@btime for i in 1:height, j in 1:width
    point = (2*(j-0.5)/width-1) + (2*(i-0.5)/height-1)im # rescale to -1:1 in the complex plane
    stability[i,j] = pixel(point)
end

println("Plotting to PNG ...")
gr()                       # initialize the gr backend
ENV["GKSwstype"] = "100"   # operate in headless mode
fname = "$(height)x$(width)"
png(heatmap(stability, size=(width,height), color=:gist_ncar), fname)
```

Let's run this code with `julia juliaSetSerial.jl`. On my laptop it reports 1.160 s.

**Note**: Built-in plotting in Julia is fairly slow and will take forever for drawing much larger fractals
  (e.g. $8000^2$). A faster alternative is to save your plot as compressed NetCDF and visualize it with something
  faster, e.g. ParaView. The code for this is below. Note that as of February 2022 Julia's NetCDF library does not yet
  work on Apple's M1 processors.

```jl
using NetCDF
println("Writing NetCDF ...")
filename = "test.nc"
isfile(filename) && rm(filename)
nccreate(filename, "stability", "x", collect(1:height), "y", collect(1:width), t=NC_FLOAT, mode=NC_NETCDF4, compress=9);
ncwrite(stability, filename, "stability");
```

This code will produce the file `test.nc` that you can download to your computer and render with ParaView or other
visualization tool.

> ### Exercise "Fractal.1"
> Try one of these:
> 1. With NetCDF output, compare the expected and actual file sizes.
> 1. Try other values of the parameter $c$ (see above).
> 1. Increase the problem size from the default $2000^2$. Will you have enough physical memory for $8000^2$?
>    How does this affect the runtime?
>
> If computing takes forever, recall that `@btime` runs the code multiple times, while `@time` does it only once. Also,
> you might like a progress bar inside the terminal:
> ```jl
> using ProgressMeter
> @showprogress <for loop>
> ```

## Parallelizing

1. Load Base.Threads.
1. Add `@threads` before the outer loop, and time this parallel loop.

On my laptop with 8 threads the timing is 249.924 ms (4.6X speedup) which is good but not great ... In terms of
row-major vs. column-major loop order, we are doing the faster one here. The likely culprit here is the false sharing
effect (cache issues with multiple threads writing into adjacent array elements), but since we are writing into a large
array, it is more difficult to fix it with spacing (like we did before).

> ### (Longer) Exercise "Fractal.2"
> How would you fix this issue?
