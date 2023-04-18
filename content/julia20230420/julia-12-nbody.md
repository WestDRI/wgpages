+++
title = "Parallelizing N-body"
slug = "julia-12-nbody"
weight = 12
katex = true
+++

In this section I will describe a project that you can work at home: the **direct N-body solver**.

Imagine that you place $N$ identical particles randomly into a unit cube, with zero initial velocities. Then
you turn on gravity, so that the particles start attracting each other. There are no boundary conditions:
these are the only particles in the Universe, and they can fly to $\infty$.

> ## Question
> What do you expect these particles will do?

We will adopt the following numerical method:

- force evaluation via direct summation
- single variable (adaptive) time step: smaller $\Delta t$ when any two particles are close
- time integration: more accurate than simple forward Euler + one force evaluation per time step
- two parameters: softening length and Courant number (I will explain these when we study the code)

In a real simulation, you would replace:

- direct summation *with* a tree- or mesh-based $O(N\log N)$ code
- current integrator *with* a higher-order scheme, e.g. Runge-Kutta
- current timestepping *with* hierarchical particle updates
- for long-term stable evolution with a small number of particles, use a symplectic orbit integrator

Expected solutions:

- 2 particles: should pass through each other, infinite oscillations
- 3 particles: likely form a close binary + distant 3$^{\rm rd}$ particle (hierarchical triple system)
- many particles: likely form a gravitationally bound system, with occasional ejection

In these clips below the time arrow is not physical time but the time step number. Consequently, the animations slow
down when any two particles come close to each other.

{{< youtube zB-NaYGT5bM >}}

&nbsp;

{{< youtube yZVMrwKtiPE >}}

Below you will find the serial code `nbodySerial.jl`. I removed all parts related to plotting the results, as it's slow
in Julia, and you would need to install `Plots` package (takes a while with many dependencies!).

```julia
using ProgressMeter

npart = 20
niter = Int(1e5)
courant = 1e-3
softeningLength = 0.01

x = rand(npart, 3);   # uniform [0,1]
v = zeros(npart, 3);

soft = softeningLength^2;

println("Computing ...");
force = zeros(Float32, npart, 3);
oldforce = zeros(Float32, npart, 3);
@showprogress for iter = 1:niter
    tmin = 1.e10
    for i = 1:npart
        force[i,:] .= 0.
        for j = 1:npart
            if i != j
                distSquared = sum((x[i,:] .- x[j,:]).^2) + soft;
                force[i,:] -= (x[i, :] .- x[j,:]) / distSquared^1.5;
                tmin = min(tmin, sqrt(distSquared / sum((v[i,:] .- v[j,:]).^2)));
            end
        end
    end
    dt = min(tmin*courant, 0.001);   # limit the initial step
    for i = 1:npart
        x[i,:] .+= v[i,:] .* dt .+ 0.5 .* oldforce[i,:] .* dt^2;
        v[i,:] .+= 0.5 .* (oldforce[i,:] .+ force[i,:]) .* dt;
        oldforce[i,:] .= force[i,:];
    end
end
```

Tring running this code with `julia nbodySerial.jl`; the main loop takes ~6m on the training
cluster. Obviously, the most CPU-intensive part is force evaluation -- this is what you want to accelerate.

There are many small arrays in the code -- let's use SharedArrays and fill them in parallel, e.g. you would replace

```julia
force = zeros(Float32, npart, 3);
```
with
```julia
force = SharedArray{Float32}(npart,3);
```

When updating shared arrays, you have a choice: either update `array[localindices(array)]` on each worker, or use a
parallel `for` loop with reduction. I suggest the latter. What do you want to reduce? **Hint:** what else do you compute
besides the force in that loop? For code syntax, check `parallelFor.jl` code in
[this earlier section](../../julia202202/julia-06-distributed2).


<!-- <     for i = 1:npart -->
<!-- --- -->
<!-- >     tmin = @distributed (min) for i = 1:npart -->

### Results

With default **20 particles and $10^5$ steps** the code runs slower in parallel on the training cluster:

| Code | Time  |
| ------------- | ----- |
| `julia nbodySerial.jl` (serial runtime) | 340s |
| `julia -p 1 nbodyDistributedShared.jl` (2 processes) | 358s |

This is the same problem we discussed in the Chapel course: with a fine-grained parallel code the communication overhead
dominates the problem. As we increase the problem size, we should see the benefit from parallelization. E.g. with **1000
particles and 10 steps**:

| Code | Time  |
| ------------- | ----- |
| `julia nbodySerial.jl` (serial runtime) | 83.7s |
| `julia -p 1 nbodyDistributedShared.jl` (2 processes) | 47.9s |

Here is what I got on Cedar with **100 particles and $10^3$ steps**:

| Run | Time  |
| ------------- | ----- |
| serial | 1m23s |
| 2 cores | 46s |
| 4 cores | 29s |
| 8 cores | 22s |
| 16 cores | 18s |
| 32 cores | 19s  |
