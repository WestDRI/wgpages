+++
title = "Introduction to parallel Julia"
slug = "../../julia202110/julia-01-intro"
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
  - currently under active development, both in features and performance

## Processes vs. threads

In Unix a **process** is the smallest independent unit of processing, with its own memory space -- think of an instance
of a running application. The operating system tries its best to isolate processes so that a problem with one process
doesn't corrupt or cause havoc with another process. Context switching between processes is relatively expensive.

A process can contain multiple **threads**, each running on its own CPU core (parallel execution), or sharing CPU cores
if there are too few CPU cores relative to the number of threads (parallel + concurrent execution). All threads in a
Unix process share the virtual memory address space of that process, e.g. several threads can update the same variable,
whether it is safe to do so or not (we'll talk about thread-safe programming in this course). Context switching between
threads of the same process is less expensive.

![Alt text here](/img/threads.png "Image copied from
https://www.backblaze.com/blog/whats-the-diff-programs-processes-and-threads")

- Threads within a process communicate via shared memory, so **multi-threading** is always limited to shared memory
  within one node.
- Processes communicate via messages (over the cluster interconnect or via shared memory). **Multi-processing** can be
  in shared memory (one node, multiple CPU cores) or distributed memory (multiple cluster nodes). With multi-processing
  there is no scaling limitation, but traditionally it has been more difficult to write code for distributed-memory
  systems. Julia tries to simplify it with high-level abstractions.

In Julia you can parallelize your code with multiple threads, or with multiple processes, or both (hybrid parallelization).

> ### Discussion
> What are the benefits of each: threads vs. processes? Consider (1) context switching, e.g. starting and terminating or
> concurrent execution, (2) communication, (3) scaling up.

## Parallel Julia

The main goal of this course is to teach you the basic tools for parallel programming in Julia, targeting both
multi-core PCs and distributed-memory clusters. We will cover the following topics:

- multi-threading with Base.Threads
- multi-processing with Distributed.jl
- ClusterManagers.jl (very briefly)
- DistributedArrays.jl - distributing large arrays across multiple processes
- SharedArrays.jl - shared-memory access to large arrays from multiple processes
- Dagger.jl (briefly) - a task graph scheduler heavily inspired by Python's Dask

We will **not** be covering the following topics today (although we hope to cover them in our future webinars!):

- Concurrent function calls ("lightweight threads" for suspending/resuming computations)
- MPI.jl - a port of the standard MPI library to Julia
- MPIArrays.jl
- LoopVectorization.jl
- FLoops.jl
- ThreadsX.jl - deterministic thread parallelism
- Transducers.jl
- DistributedData.jl
- GPU-related packages

## Running Julia in REPL

If you have Julia installed on your own computer, you can run it there. On a multi-core laptop/desktop you can launch
multiple threads and processes and run them in parallel.

We have Julia on our training cluster *uu.c3.ca*. Typically, in our introductory Julia course we would use Julia inside
a Jupyter notebook. Today we will be starting multiple threads and processes, with the eventual goal of running our
workflows as batch jobs on an HPC cluster, so we'll be using Julia from the command line.

> **Pause**: We will now distribute accounts and passwords to connect to the cluster.

Our training cluster has:

1. one login node with 16 *"persistent"* cores and 32GB memory,
1. 16 compute nodes with 2 *"compute"* cores and 7.5GB memory, and
1. one GPU node with 4 *"compute"* cores, 1 vGPU (8GB) and 22GB memory.

#### Julia packages on the training cluster

Normally, you would install a Julia package by typing `] add packageName` in REPL and then waiting for it to install. A
typical package installation takes few hundred MBs and a fraction of a minute and usually requires a lot of small file
writes. Our training cluster runs on top of virtualized hardware with a shared filesystem. If several dozen workshop
participants start installing packages at the same time, this will hammer the filesystem and will make it slow for all
participants for quite a while.

To avoid this, we created a special environment, with all packages installed into a shared directory
`/project/def-sponsor00/shared/julia`. To load this environment, run the command

```sh
source /project/def-sponsor00/shared/julia/config/loadJulia.sh
```

This script will load the Julia module and set a couple of environment variables, to point to our central environment
while keeping your setup and Julia history separate from other users. You can still install packages the usual way (`]
add packageName`), and they will go into your own `~/.julia` directory. Feel free to check the content of this script,
if you are interested.

Try opening the Julia REPL and running a couple of commands:

```sh
$ julia 
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.6.2 (2021-07-14)
 _/ |\__'_|_|_|\__'_|  |  
|__/                   |

julia> using BenchmarkTools

julia> @btime sqrt(2)
  1.825 ns (0 allocations: 0 bytes)
1.4142135623730951
```

<!-- Assuming we have all connected to *uu.c3.ca* via ssh, let's try to log in and start Julia REPL: -->

<!-- ```sh -->
<!-- module load StdEnv/2020 julia/1.6.2 -->
<!-- julia -->
<!-- ``` -->
