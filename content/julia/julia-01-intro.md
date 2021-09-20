+++
title = "Introduction to parallel Julia"
slug = "julia-01-intro"
weight = 1
+++

## Julia language

- High-performance, dynamically typed programming language for scientific computing
- Uses just-in-time (JIT) compiler to compile all code, includes an interactive command line (REPL = read–eval–print
  loop, and can also be run in Jupyter), i.e. tries to **combine the advantages of both compiled and interpreted
  languages**
- Built-in package manager
- Lots of interesting design decisions, e.g. macros, support for Unicode, etc -- covered in
  [our introductory Julia course](../../programming_julia)
- **Support for parallel and distributed computing** via its Standard Library and many 3rd party packages
  - being added along the way, e.g. @threads were first introduced in v0.5
  - currently under very active development, both in features and performance

## Processes vs. threads

In Unix a process is the smallest independent unit of processing, with its own memory space -- think of a running
application. A process can contain multiple threads, each running on its own CPU core (parallel execution), or sharing
CPU cores if there are too few CPU cores relative to the number of threads (parallel + concurrent execution). All
threads in a Unix process share the virtual memory address space of that process, e.g. several threads can update the
same variable, whether it is safe to do so or not (we'll talk about thread-safe programming in this course).

In Julia you can parallelize a code with multiple threads, or with multiple processes, or both (hybrid parallelization).

- Threads within a process communicate via shared memory, so multi-threading is always limited to shared memory within
  one node.
- Processes communicate via messages (over the cluster interconnect or shared memory); multi-processing can be in shared
  memory (one node, multiple CPU cores) or distributed memory (multiple cluster nodes). With multi-processing there is
  no scaling limitation, but traditionally it has been more difficult to write code for distributed-memory
  systems. Julia tries to simplify it with high-level abstractions.

## Parallel Julia

The main goal of this course is to teach you the basic tools for parallel programming in Julia, targeting both
multi-core PCs and distributed-memory clusters. We will cover the following topics:

- multi-threading with Base.Threads
- multi-processing with Distributed.jl
- ClusterManagers.jl (very briefly)
- DistributedArrays.jl
- SharedArrays.jl

We will **not** be covering the following topics today (although we hope to cover them in our future webinars!):

- Dagger.jl - a task graph scheduler heavily inspired by Python's Dask
- Concurrent function calls ("lightweight threads" for suspending/resuming computations)
- MPI.jl - a port of the standard MPI library to Julia
- MPIArrays.jl
- LoopVectorization.jl
- FLoops.jl
- ThreadsX.jl
- Transducers.jl
- GPU-related packages

## Running Julia in REPL

If you have Julia installed on your own computer, you can run it there. We have Julia on our training cluster
*cassiopeia.c3.ca*. In [our introductory Julia course](../../programming_julia) we were using Julia inside a Jupyter
notebook. Today we will be running multiple threads and processes, with the eventual goal of running our workflows on an
HPC cluster, so we'll be using Julia from the command line.

> **Pause**: We will now distribute accounts and passwords to connect to the cluster. We also have a backup cluster
>   *uu.c3.ca* with a similar setup.

Assuming we have all connected to *cassiopeia.c3.ca* via ssh, let's try to log in and start Julia REPL:

```sh
module load StdEnv/2020 julia/1.6.0
julia
```
