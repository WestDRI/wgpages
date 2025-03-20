+++
title = "Parallel Julia"
slug = "../summer/julia-02-intro-parallel"
weight = 2
katex = true
+++

## Threads vs. processes

In Unix a **process** is the smallest independent unit of processing, with its own memory space -- think of an
instance of a running application. The operating system tries its best to isolate processes so that a problem
with one process doesn't corrupt or cause havoc with another process. Context switching between processes is
relatively expensive.

A process can contain multiple **threads**, each running on its own CPU core (parallel execution), or sharing
CPU cores if there are too few CPU cores relative to the number of threads (parallel + concurrent
execution). All threads in a Unix process share the virtual memory address space of that process, e.g. several
threads can update the same variable, whether it is safe to do so or not (we'll talk about thread-safe
programming in this course). Context switching between threads of the same process is less expensive.

{{< figure src="/img/threads.png" title="">}}
<!-- "Image copied from https://www.backblaze.com/blog/whats-the-diff-programs-processes-and-threads"  -->

- Threads within a process communicate via shared memory, so **multi-threading** is always limited to shared
  memory within one node.
- Processes communicate via messages (over the cluster interconnect or via shared
  memory). **Multi-processing** can be in shared memory (one node, multiple CPU cores) or distributed memory
  (multiple cluster nodes). With multi-processing there is no scaling limitation, but traditionally it has
  been more difficult to write code for distributed-memory systems. Julia tries to simplify it with high-level
  abstractions.

In Julia you can parallelize your code with multiple threads, or with multiple processes, or both (hybrid
parallelization) -- see an example below:

{{< figure src="/img/hybridParallelism.png" title="">}}

> ### Discussion
> What are the benefits of each type of parallelism: multi-threading vs. multi-processing?
> Consider:
> 1. context switching, e.g. starting and terminating or concurrent execution on the same CPU core,
> 1. communication,
> 1. scaling up.

## Parallelism in Julia

The main goal of this course is to teach you the basic tools for parallel programming in Julia, targeting both
multi-core PCs and distributed-memory clusters. We will cover the following topics:

- multi-threading with **Base.Threads** and **ThreadsX.jl**
- multi-processing with **Distributed.jl**
- **ClusterManagers.jl** (very briefly)
- **DistributedArrays.jl** -- distributing large arrays across multiple processes
- **SharedArrays.jl** -- shared-memory access to large arrays from multiple processes

We will *not* be covering the following topics today (we have covered some of these in our past webinars):

- **MPI.jl** -- a port of the standard MPI library to Julia
- **MPIArrays.jl**
- **ParallelStencil.jl** -- high-level library for fast parallel stencil computations on **CPUs**
  (Base.Threads, can also interoperate with ImplicitGlobalGrid.jl built upon MPI.jl) and **GPUs** (NVIDIA,
  AMD, Apple Silicon)
- **Dagger.jl** -- a task graph scheduler heavily inspired by Python's Dask
- Concurrent function calls ("lightweight threads" for suspending/resuming computations)
- **LoopVectorization.jl**
- **FLoops.jl**
- **Transducers.jl**
- **DistributedData.jl**
- other GPU-related packages
