+++
title = "Introduction to Julia language"
slug = "../summer/julia-01-intro-language"
weight = 1
+++

## The Julia programming language

- High-performance, dynamically typed programming language for scientific computing
- Uses just-in-time (JIT) compiler to compile all code, includes an interactive command line (REPL =
  read–eval–print loop, and can also be run in Jupyter), i.e. tries to **combine the advantages of both
  compiled and interpreted languages**
- Built-in package manager
- Lots of interesting design decisions, e.g. macros, support for Unicode, etc
- **Support for parallel and distributed computing** via its Standard Library and many 3rd party packages
  - being added along the way, e.g. @threads were first introduced in v0.5
  - currently under active development, both in features and performance

## Running Julia locally

If you have Julia installed on your own computer, you can run it there: on a multi-core laptop/desktop you can launch multiple threads and processes and run them in parallel.

If you want to install Julia after this workshop, you can find it {{<a "https://julialang.org/downloads" "here">}}.

## Using Julia on supercomputers

### Julia on the Alliance production clusters

Julia is among hundreds of software packages installed on the CC clusters. To use Julia on one of them, you would load the following module:

```bash
$ module spider julia   # show the available versions
$ module load julia     # load the default version
```

#### Installing Julia packages on a production cluster

{{<note>}}
Don't do this on the training cluster! We already have everything installed in a central location for all guest
accounts.
{{</note>}}

By default, all Julia packages you install from REPL will go into `$HOME/.julia`, and that we will count
against your `/home` quota. If you want to put packages into another location, you will need to (1) install
inside your Julia session with (from within Julia):

```jl
empty!(DEPOT_PATH)
push!(DEPOT_PATH,"/scratch/path/to/julia/packages") 
] add BenchmarkTools
```

and (2) before running Julia modify two variables (from the command line):

```sh
$ module load julia
$ export JULIA_DEPOT_PATH=/home/\$USER/.julia:/scratch/path/to/julia/packages
$ export JULIA_LOAD_PATH=@:@v#.#:@stdlib:/scratch/path/to/julia/packages
```

**Note**: Some Julia packages rely on precompiled bits that developers think would work on all architectures,
  but they don't. For example, `Plots` package comes with several precompiled libraries, it installs without
  problem on the Alliance clusters, but then at runtime you might see an error about "GLIBC_2.18 not
  found". The proper solution would be to recompile the package on the cluster, but it is not done correctly
  in Julia packaging, and the error persists even after "recompilation". There is a solution for this, and you
  can always contact us at support@tech.alliancecan.ca and ask for help. Another example is Julia's `NetCDF`
  package: as of February 2022, it was installing fine on Apple Silicon Macs, but it came with a precompiled C
  package that had been compiled only for Intel Macs and did not work on M1. This issue has been resolved
  since then, but the point remains: successful installation of a Julia package does not mean it'll work on
  your architecture.

### Julia on the training cluster for this workshop

We have Julia on our training cluster *julia.vastcloud.org*.

{{<note>}}
Our training cluster has:
<ul>
<li> one fairly small login node,</li>
<li> 6 compute nodes with 8 cores and 30GB of memory on each &nbsp;⟹&nbsp; 3.75GB/core, 48 cores in total</li>
</ul>
{{</note>}}

Normally in our introductory Julia course we would use Julia inside a Jupyter notebook. Today we will be
starting multiple threads and processes, with the eventual goal of running our workflows as batch jobs on an
HPC cluster, so we'll be using Julia from the command line.

> **Pause**: We will now distribute accounts and passwords to connect to the cluster.

Normally, you would install Julia packages yourself. A typical package installation however takes several
hundred MBs of RAM, a fairly long time, and creates many small files. Our training cluster runs on top of
virtualized hardware with a shared filesystem. If several dozen workshop participants start installing
packages at the same time, this will hammer the filesystem and will make it slow for all participants for
quite a while.

Instead, for this workshop, you will run:

```sh
$ source /project/def-sponsor00/shared/julia/config/loadJulia.sh
```

This script loads the Julia module and sets environment variables to point to a central environment in which
we have pre-installed all the packages for this workshop.

{{<note>}}
Note that you can still install additional packages if you want. These will install in your own environment at ~/.julia.
{{</note>}}


## Running Julia in the REPL

### Where to run the REPL

You could now technically launch a Julia REPL (Read-Eval-Print-Loop). However, this would launch it on the
login node and if everybody does this at the same time, we would probably crash our training cluster.

Instead, you will first launch an interactive job by running the Slurm command `salloc`:

```sh
$ salloc --mem-per-cpu=3600M --cpus-per-task=2 --time=2:0:0
```

This puts you on a compute node and gives you 2 CPU cores for up to 2 hours.

Now you can launch the Julia REPL and try to run a couple of commands:

```sh
$ julia
               _
   _       _ _(_)_     |  Documentation: https://docs.julialang.org
  (_)     | (_) (_)    |
   _ _   _| |_  __ _   |  Type "?" for help, "]?" for Pkg help.
  | | | | | | |/ _` |  |
  | | |_| | | | (_| |  |  Version 1.8.5 (2023-01-08)
 _/ |\__'_|_|_|\__'_|  |
|__/                   |

julia> using BenchmarkTools

 julia> @btime sqrt(2)
  1.310 ns (0 allocations: 0 bytes)
1.4142135623730951
```

### REPL modes

The Julia REPL has 4 modes:

```sh
julia>       Julian mode to run code. Default mode. Go back to it from other modes with Backspace
help?>       Help mode to access documentation. Enter it with ?
shell>       Shell mode to run Bash commands. Enter it with ;
(env) pkg>   Package manager mode to manage external packages. Enter it with ]
```

(`env` is the name of your current project environment.)

### REPL keybindings

In the REPL, you can use standard command-line (Emacs-like) keybindings:

```
C-c		cancel
C-d		quit
C-l		clear console

C-u		kill from the start of line
C-k		kill until the end of line

C-a		go to start of line
C-e		go to end of line

C-f		move forward one character
C-b		move backward one character

M-f		move forward one word
M-b		move backward one word

C-d		delete forward one character
C-h		delete backward one character

M-d		delete forward one word
M-Backspace	delete backward one word

C-p		previous command
C-n		next command

C-r		backward search
C-s		forward search
```

### REPL for parallel work

Remember our workflow to launch a Julia REPL:

```sh
# Step 0: start tmux (optional), gives you left-right panes, persistent terminal session
$ tmux

# Step 1: run the script to load our Julia environment with pre-installed packages
$ source /project/def-sponsor00/shared/julia/config/loadJulia.sh

# Step 2: launch an interactive job on a compute node
$ salloc --mem-per-cpu=3600M --cpus-per-task=2 --time=2:0:0

# Step 3: launch the Julia REPL
$ julia
```

This will launch Julia in serial. To use multiple threads, you want to pass the `-t` flag when starting Julia:

```sh
# Launch Julia on 2 threads
$ julia -t 2
```

## Running scripts as  batch jobs

Now, if we want to get an even bigger speedup, we could use even more CPUs per task. The problem is that our
training cluster only has ~60 compute cores, so if we use `--cpus-per-task=4` some of us could be left waiting
for Slurm while the others play with several CPUs for two hours. This is not an efficient approach. This is
equally true on production clusters: if you want to run an interactive job using a lot of resources, you might
have to wait for a long time.

On production clusters, a much better approach is to put our Julia code in a Julia script and run it through a
batch job by using the Slurm command `sbatch`.

<!-- You can run a Julia script with `julia julia_script.jl`. -->

<!-- So all we need to do is to submit a shell script to `sbatch` that contains information for Slurm and the code to run (`julia julia_script.jl`). -->

<!-- {{<note>}} -->
<!-- Example: -->
<!-- {{</note>}} -->

Let's save the following into a file `job_script.sh`:

```sh
#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=3600M
#SBATCH --time=00:10:00
julia -t 4 julia_script.jl
```

Then we submit our job script:

```sh
$ sbatch job_script.sh
```

In this session, we continue using `salloc --cpus-per-task=2 ...`

## Serial Julia features worth noting in 10 mins

### JIT compilation

Programming languages are either interpreted or compiled.

Interpreted languages use interpreters: programs that execute your code directly (Python, for instance, uses the interpreter CPython, written in C). Interpreted languages are very convenient since you can run sections of your code as soon as you write them. However, they are slow.

Compiled languages use compilers: programs that translate your code into machine code. Machine code is extremely efficient, but of course, having to compile your code before being able to run it makes for less convenient workflows when it comes to writing or debugging code.

Julia uses {{<a "https://en.wikipedia.org/wiki/Just-in-time_compilation" "just-in-time compilation">}} or JIT based on {{<a "https://en.wikipedia.org/wiki/LLVM" "LLVM">}}: the source code is compiled at run time. This combines the flexibility of interpretation with the speed of compilation, bringing speed to an interactive language. It also allows for dynamic recompilation, continuous weighing of gains and costs of the compilation of parts of the code, and other on the fly optimizations.

{{<a "https://kipp.ly/blog/jits-intro" "Here">}} is a great blog post covering this topic if you want to dive deeper into the functioning of JIT compilers.

### Macros

In the tradition of Lisp, Julia has {{<a "https://en.wikibooks.org/wiki/Introducing_Julia/Metaprogramming#Macros" "strong metaprogramming capabilities">}}, in particular in the form of macros.

Macros are parsed and evaluated first, then their output gets evaluated like a classic expression. This allows the language to modify itself in a {{<a "https://en.wikipedia.org/wiki/Reflective_programming" "reflective">}} manner.

Macros have a `@` prefix and are defined with a syntax similar to that of functions.

`@time` for instance is a macro that executes an expression and prints the execution time and other information.

### Fun fact

{{<a "https://docs.julialang.org/en/v1/manual/unicode-input/" "Julia supports unicode">}}. In a Julia REPL,
type `\:snail:` followed by the TAB key, and you get 🐌.

While assigning values to a "snail variable" might not be all that useful, a wide access to -- for instance --
Greek letters, would make Julia's code look nicely similar to the equations it represents. For instance, if
you type TAB after each variable name, the following:

```jl
\pgamma = ((\alpha \pi + \beta) / \delta) + \upepsilon
```

looks like:

```jl
ɣ = ((α π + β) / δ) + ε
```

In Julia you can omit the multiplication sign in some cases, e.g.

```jl
julia> 2π
6.283185307179586
```

### Additional basic information

Our beginner's {{<a "https://rcmodules22.netlify.app/programming_julia" "introduction to Julia course">}} has,
amongst others, sections on:

- {{<a "https://westgrid-julia.netlify.app/2022_modules/06_jl_pkg" "working with packages">}}
- {{<a "https://westgrid-julia.netlify.app/2022_modules/08_jl_functions" "working with functions">}}
- {{<a "https://westgrid-julia.netlify.app/2022_modules/09_jl_control_flow" "control flow">}}
- {{<a "https://westgrid-julia.netlify.app/2022_modules/13_jl_arrays" "arrays">}}
