+++
title = "Introduction to Julia language"
slug = "julia-01-intro-language"
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

## Julia packages on the training cluster

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

<a name="production"></a>
## Installing Julia packages on a production cluster (Alex)

By default, all Julia packages you install from REPL will go into `$HOME/.julia`. If you want to put packages into
another location, you will need to (1) install inside your Julia session with:

```jl
empty!(DEPOT_PATH)
push!(DEPOT_PATH,"/scratch/path/to/julia/packages") 
] add BenchmarkTools
```

and (2) before running Julia modify two variables:

```sh
module load julia
export JULIA_DEPOT_PATH=/home/\$USER/.julia:/scratch/path/to/julia/packages
export JULIA_LOAD_PATH=@:@v#.#:@stdlib:/scratch/path/to/julia/packages
```

Don't do this on the training cluster! We already have everything installed in a central location for all guest
accounts.

**Note**: Some Julia packages rely on precompiled bits that developers think would work on all architectures, but they
  don't. For example, `Plots` package comes with several precompiled libraries, it installs without problem on Compute
  Canada clusters, but then at runtime you will see an error about "GLIBC_2.18 not found". The proper solution would be
  to recompile the package on the cluster, but it is not done correctly in Julia packaging, and the error persists even
  after "recompilation". There is a solution for this, and you can always contact us at support@computecanada.ca and ask
  for help. Another example if Julia's `NetCDF` package: it installs fine on Apple Silicon Macs, but it actually comes
  with a precompiled C package that was compiled only for Intel Macs and does not work on M1.

## Serial Julia features worth noting in 10 mins

```sh
source /project/def-sponsor00/shared/julia/config/loadJulia.sh
salloc --mem-per-cpu=3600M --time=01:00:00
```
