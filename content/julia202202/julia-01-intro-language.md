+++
title = "Introduction to Julia language"
slug = "julia-01-intro-language"
weight = 1
+++

## The Julia programming language

- High-performance, dynamically typed programming language for scientific computing
- Uses just-in-time (JIT) compiler to compile all code, includes an interactive command line (REPL = read–eval–print
  loop, and can also be run in Jupyter), i.e. tries to **combine the advantages of both compiled and interpreted
  languages**
- Built-in package manager
- Lots of interesting design decisions, e.g. macros, support for Unicode, etc -- covered in
  {{<a "https://wgtm21.netlify.app/programming_julia/" "our introductory Julia course">}}
- **Support for parallel and distributed computing** via its Standard Library and many 3rd party packages
  - being added along the way, e.g. @threads were first introduced in v0.5
  - currently under active development, both in features and performance

## Running Julia

If you have Julia installed on your own computer, you can run it there: on a multi-core laptop/desktop you can launch multiple threads and processes and run them in parallel.

If you would like to install Julia later on, you can find some information {{<a "/julia-installation" "here">}}.

## Using Julia on supercomputers

### Julia on Compute Canada production clusters

Julia is among hundreds of software packages installed on the CC clusters. To use Julia on one of them, you would load the following module:

```bash
module load julia
```

#### Installing Julia packages on a production cluster

By default, all Julia packages you install from REPL will go into `$HOME/.julia`. If you want to put packages into
another location, you will need to (1) install inside your Julia session with:

Our training cluster has:
```jl
empty!(DEPOT_PATH)
push!(DEPOT_PATH,"/scratch/path/to/julia/packages") 
] add BenchmarkTools
```

1. one login node with 16 *"persistent"* cores and 32GB of memory,
1. 17 compute nodes with 16 *"compute"* cores and 60GB of memory, and
1. one GPU node with 4 *"compute"* cores, 1 vGPU (8GB) and 22GB of memory.
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

### Julia on the training cluster for this workshop

We have Julia on our training cluster *uu.c3.ca*.



In our introductory Julia course we use Julia inside a Jupyter notebook. Today we will be starting multiple threads and processes, with the eventual goal of running our
workflows as batch jobs on an HPC cluster, so we'll be using Julia from the command line.

> **Pause**: We will now distribute accounts and passwords to connect to the cluster.

Normally, you would install Julia packages yourself. A typical package installation however takes several hundred MBs of RAM, a fairly long time, and creates many small files. Our training cluster runs on top of virtualized hardware with a shared filesystem. If several dozen workshop
participants start installing packages at the same time, this will hammer the filesystem and will make it slow for all
participants for quite a while.

Instead, for this workshop, you will run:

```sh
source /project/def-sponsor00/shared/julia/config/loadJulia.sh
```

This script loads the Julia module and sets environment variables to point to a central environment in which we have pre-installed all the packages for this workshop.

{{<note>}}
Note that you can still install additional packages if you want. These will install in your own environment at ~/.julia.
{{</note>}}


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







```



## Serial Julia features worth noting in 10 mins

describe the training cluster specs, and how this will translate in our usage this week
- do not run on the login node

for serial work
```sh
source /project/def-sponsor00/shared/julia/config/loadJulia.sh
salloc --mem-per-cpu=3600M --time=01:00:00
julia
```

- JIT
- running in REPL vs. running scripts
- diff REPL modes
- macros
- unicode?

for multi-threaded work
```sh
source /project/def-sponsor00/shared/julia/config/loadJulia.sh
salloc --mem-per-cpu=3600M --cpus-per-task=4 --time=01:00:00
julia -t 4
```

if we don't have enough resources, we should switch to sbatch

this should go into an earlier session?
