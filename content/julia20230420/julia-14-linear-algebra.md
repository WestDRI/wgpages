+++
title = "Distributed linear algebra in Julia"
slug = "julia-14-linear-algebra"
weight = 14
katex = true
+++

In the previous session there was a question about parallel linear algebra with DistributedArrays.jl,
i.e. whether it was possible to solve linear systems defined with distributed arrays, without having to code
your own solver. Let's start with serial solvers which can scale well to surprisingly large linear systems.







### Serial solvers

<!-- https://juliahub.com/ui/Packages/LinearSolve/WR6RC/1.42.0 -->

{{<a "https://docs.sciml.ai/LinearSolve/stable" "LinearSolve.jl">}} provides serial dense matrix solvers with
a focus on performance.

```jl
using LinearSolve
n = 100;
A = rand(n,n);                     # uniform numbers from [0, 1)
b = rand(n);
@time prob = LinearProblem(A, b)   # define a linear system problem
@time sol = solve(prob)            # solve this problem
*(A,sol) - b                       # check the result
```

Let's check performance on progressively larger systems:

```jl
k = 1000
for n in (10, 100, 1k, 10k, 20k, 30k)
    A = rand(n,n);
    b = rand(n);
    prob = LinearProblem(A, b);
    @time sol = solve(prob);
end
```

For these cases I receive:

```txt
  0.000026 seconds (14 allocations: 2.375 KiB)
  0.000115 seconds (17 allocations: 81.984 KiB)
  0.010350 seconds (15 allocations: 7.654 MiB)
  2.819498 seconds (18 allocations: 763.170 MiB, 0.07% gc time)
 23.127729 seconds (18 allocations: 2.981 GiB, 0.55% gc time)
123.673966 seconds (18 allocations: 6.706 GiB, 0.28% gc time)
```







### Distributed solvers

There seem to have been several projects that use Distributed.jl to implement parallel dense and/or sparse
linear solvers:

{{<emph_big>}}ParallelLinalg.jl{{</emph_big>}}
{{<a "https://juliapackages.com/p/parallellinalg" "ParallelLinalg.jl">}} implements distributed dense linear
algebra but was last updated 7 years ago ...

{{<emph_big>}}Pardiso.jl{{</emph_big>}}
{{<a "https://github.com/JuliaSparse/Pardiso.jl" "Pardiso.jl">}} provides an interface to the Intel's MKL
PARDISO library, which is a highly optimized direct solver for sparse linear systems. It supports
distributed computation through MPI.jl.

<!-- https://juliapackages.com/c/numerical-linear-algebra provides a list of various linear algebra packages in Julia -->

{{<emph_big>}}PartitionedArrays.jl{{</emph_big>}}
{{<a "https://github.com/fverdugo/PartitionedArrays.jl" "PartitionedArrays.jl">}} provides HPC sparse linear
algebra solvers and relies on MPI.jl. I played with it, but launching it was kind of tricky ...

<!-- HPC sparse linear algebra in Julia with PartitionedArrays.jl https://www.youtube.com/watch?v=jqwqFi9Um2M -->
<!-- PVector, PSparseMatrix - partitioned among processes -->
<!-- PDEs  ->  Ax = b -->
<!-- good parallel scaling shown to 1e4 cores -->
<!-- relies on MPI, so need to launch with Julia's own mpiexec ... kind of tricky -->
<!-- many examples https://www.francescverdugo.com/PartitionedArrays.jl/stable/examples/#Examples -->
<!-- ```jl -->
<!-- # hello_mpi.jl -->
<!-- using PartitionedArrays -->
<!-- np = 4 -->
<!-- ranks = distribute_with_mpi(LinearIndices((np,))) -->
<!-- map(ranks) do rank -->
<!--    println("I am proc $rank of $np.") -->
<!-- end -->
<!-- ``` -->

{{<emph_big>}}IterativeSolvers.jl{{</emph_big>}}
{{<a "https://iterativesolvers.julialinearalgebra.org/stable" "IterativeSolvers.jl">}} provides iterative
solvers for linear systems and eigenvalue problems. It supports distributed computation through
DistributedArrays.jl and ParallelStencil.jl. I played with it, but ran into errors while following their
examples ...

<!-- ```jl -->
<!-- using LinearAlgebra, IterativeSolvers, DistributedArrays -->
<!-- n = 100 -->
<!-- c = drand(n,n); -->
<!-- # A = Diagonal(drand(n) .^ 2 .+ √eps()) -->
<!-- b = drand(n); -->
<!-- cg(c, b) -->


<!-- using IterativeSolvers -->
<!-- n = 100 -->
<!-- A = rand(n,n); -->
<!-- b = rand(n); -->
<!-- sol = cg(A, b) -->
<!-- *(A,sol) - b   # check the result -->

<!-- LinearAlgebra.axpby!(alpha::Float64, x::DArray{Float64, 1, Vector{Float64}}, beta::Float64, y::DArray{Float64, 1, Vector{Float64}}) = axpby!(alpha, x.localpart, beta, y.localpart) -->

<!-- ERROR: MethodError: -->
<!-- copyto!(::DArray{Float64, 1, Vector{Float64}}, ::Base.Broadcast.Broadcasted{Base.Broadcast.DefaultArrayStyle{0}, Tuple{Base.OneTo{Int64}}, typeof(identity), Tuple{Float64}}) -->

<!-- copyto!(dest::AbstractArray, bc::Base.Broadcast.Broadcasted{<:Base.Broadcast.AbstractArrayStyle{0}}) in Base.Broadcast at broadcast.jl:916 -->

<!-- copyto!(dest::DArray, bc::Base.Broadcast.Broadcasted) in DistributedArrays at /project/def-sponsor00/shared/julia/packages/DistributedArrays/fEM6l/src/broadcast.jl:66 -->

{{<emph_big>}}PETSc.jl{{</emph_big>}}
{{<a "https://github.com/JuliaParallel/PETSc.jl" "PETSc.jl">}} provides a low-level interface to PETSc
(Portable, Extensible Toolkit for Scientific Computation), a parallel library for linear algebra, PDEs, and
optimization. It supports distributed computation through MPI.jl. I have not tried it in Julia.

{{<emph_big>}}Elemental.jl{{</emph_big>}}
{{<a "https://juliapackages.com/p/elemental" "Elemental.jl">}} provides a distributed-memory library of linear
algebra routines, including solvers for linear systems, eigenvalue problems, and singular value problems. It
supports a wide range of parallel architectures, including multicore CPUs, GPUs, and clusters. This one seems
to work quite nicely, although you cannot use DistributedArrays out of the box.

<!-- ```jl -->
<!-- using Distributed -->
<!-- addprocs(4) -->
<!-- using DistributedArrays, Elemental -->
<!-- A = drandn(1000, 800); -->
<!-- Elemental.svdvals(A)[1:5]   # compute the singular values of A in descending order -->

<!-- Elemental.solve! -->

<!-- # solve!(A::Elemental.DistMatrix{Float32}, B::Elemental.DistMatrix{Float32}) -->
<!-- # solve!(A::Elemental.DistSparseMatrix{Float32}, B::Elemental.DistSparseMatrix{Float32}) -->
<!-- # Elemental.DistSparseMatrix{T} <: Elemental.ElementalMatrix{T} <: AbstractArray{T, 2} <: Any -->

<!-- using Distributed -->
<!-- addprocs(4) -->
<!-- using DistributedArrays, Elemental -->

<!-- n = 20_000 -->
<!-- A = Elemental.DistMatrix(Float64); -->
<!-- Elemental.gaussian!(A,n,n); -->
<!-- b = Elemental.DistMatrix(Float64); -->
<!-- Elemental.gaussian!(b,n); -->
<!-- x = copy(b); -->
<!-- @time Elemental.solve!(A,x)   # 25.1s 28.5s -->
<!-- *(A,x)-b   # check the solution -->

<!-- It seems in these previous examples A and the workspace was still stored on the control process, and the
work was --> <!-- done by multiple threads on the control process. -->

You have to use `Elemental.DistMatrix` type which gets distributed only when you run it on top of Julia's MPI:

```jl
using MPI, MPIClusterManagers, Distributed
man = MPIWorkerManager(4)
addprocs(man);
@everywhere using DistributedArrays, Elemental
@everywhere n = 100
@mpi_do man A = Elemental.DistMatrix(Float64);
@mpi_do man Elemental.gaussian!(A,n,n);
@mpi_do man b = Elemental.DistMatrix(Float64);
@mpi_do man Elemental.gaussian!(b,n);
@time @mpi_do man Elemental.solve!(A,b)
@mpi_do man println(size(b))   # each worker prints global size
@mpi_do man println(b)         # each worker prints the (same) solution
```

In this example storage and computation happen on all worker processes. You can monitor all Julia processes
with:

```sh
htop -p $(echo $(pgrep julia) | sed 's/ /,/g')
```

I had trouble printing this array from a single process or printing its subsections from all processes, but I
probably just used the wrong syntax. I have not tried scaling to bigger problems and more CPU cores.

<!-- DimensionMismatch: output array is the wrong size; expected (Base.OneTo(10),), got (10, 1) -->














<!-- <\!-- Dagger.jl talk at JuliaCon2021 https://www.youtube.com/watch?v=t3S8W6A4Ago -\-> -->


<!-- {{<a "link" "text">}} -->
