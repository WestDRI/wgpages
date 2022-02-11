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

## Setup

### Linux for Windows Users

For Windows users, it is a huge advantage of having Windows Subsystem for Linux (WSL), provided by Microsoft. With a WSL running a flavour of Linux, one can access a full version of Linux on Windows.

Installing Linux with WSL is pretty straightforward. The following is a link to a complete instruction on how to enable WSL on Windows 10

&emsp;[https://docs.microsoft.com/en-us/windows/wsl/install-win10](https://docs.microsoft.com/en-us/windows/wsl/install-win10)

Or, one may just follow this 2 minute video on how to enable Windows Subsystem for Linux

&emsp;[https://www.youtube.com/watch?v=Ew_pYKGB810&t=21s](https://www.youtube.com/watch?v=Ew_pYKGB810&t=21s)

The following are the steps to enable WSL and install Linux on Windows 10.

In the Windows task bar __Type here to search__ box, type PowerShell to bring a Windows PowerShell

{{< figure src="/img//powershell.png" width=600px >}}

At the prompt. type the following command (one line)

```bash
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

Then restart the computer.

OR, in Windows search bar at the lower left corner, type keywords “Windows features”. When the __“Turn Windows features on or off”__ dialogue windows pops up, check the box for __Windows Subsystems for Linux__

{{< figure src="/img/win_features.png" width=500px >}}

Click OK, it will install changes and updates and ask you to reboot the computer.
After the reboot, the WSL is enabled. In Windows search bar, type “Microsoft store”. Search for Linux

{{< figure src="/img/ms_app_store.png" >}}

Select a Linux flavour, in the example below we choose Debian

{{< figure src="/img/ms_app_store_linux.png" >}}

And then click install to install Debian.

After it is installed, select launch. You may find it afterwards by searching Debian in Windows search bar. You may also want to make a shortcut on your Desktop or the task bar at bottom.

Now Debian will appear on your Desktop as a terminal as follows. Note the username will be your username for Windows.

{{< figure src="/img/wsl_term.png" width=600px >}}

Note, if you follow the link on Microsoft site, DO NOT proceed with “Update to WSL 2” if you are not an advanced Windows user developer. This will require you to install Windows updates and jump to the latest development build. It may take forever to finish.

### Accessing Windows File Systems from WSL

The Linux you just installed is “caged” inside Windows. In the newly installed Debian Linux terminal, if you type command ls to list files and folders, you will find nothing. You don’t have access to your files on Windows yet.

Before you proceed, make sure you have a user account for your Windows. If you don't have a user account but administrator account on Windows, it is strongly recommended that you create one. Do not use the Administrator account.

To access the Windows file systems, run the following commands

```bash
cd
sudo ln -s /mnt/c/Users/you/Documents/ Documents
sudo ln -s /mnt/c/Users/you/Downloads/ Downloads
```

replacing _you_ above with your user name for Windows’s account. 

Now you have the shortcuts Documents and Downloads created inside your Debina Linux, you can now access your Windows files.

### Installing Julia on Linux

The official Julia site strongly recommends that the official generic binaries from the downloads page be used to install Julia on Linux

&emsp;[https://julialang.org/downloads/](https://julialang.org/downloads/)

Select the build for your system, right click the link to copy the URL, e.g.

&emsp;[https://julialang-s3.julialang.org/bin/musl/x64/1.5/julia-1.5.4-musl-x86_64.tar.gz](https://julialang-s3.julialang.org/bin/musl/x64/1.5/julia-1.5.4-musl-x86_64.tar.gz)

To install the pre-built binary, proceed with the following

```bash
sudo apt update
sudo apt install wget
wget https://julialang-s3.julialang.org/bin/musl/x64/1.5/julia-1.5.4-musl-x86_64.tar.gz
sudo tar -xvf julia-1.5.0-musl-x86_64.tar.gz -C /opt
sudo ln -s /optjulia-1.5.0-musl-x86_64.tar.gz /usr/local/bin/julia
```

Note <tt>/opt</tt> should exist for most Linux distros. If not, do <tt>sudo mkdir /opt</tt> to create one.

Now you should be able to run Julia by typing <tt>julia</tt> inside a terminal.

### Advanced Installation of Packages and Julia on Linux

If you are an advanced Linux user and you want to use the Linux package manager to do a systematic installation, you can pursue the following.

On a Linux base system, before installing Julia, make sure the following are installed:

* GCC compiler (gcc and gfortran).

* OpenBLAS library, an optimized linear algebra library.

* OpenMPI library, an implementation of message passing interface (MPI) library for distributed and parallel computing.

The following refers to the commands pertaining to Ubuntu/Debian only. At the command line, do an update

```bash
sudo apt update
```

You may use the follow commands to find the packages and versions, e.g.

```
sudo apt list | grep -i gcc*
```

Then install the latest GCC, e.g. version 9 and libraries. 

```
sudo apt install gcc-9*
sudo apt install gfortran-9*
sudo apt install libopenmpi
sudo apt install libopenblas

sudo apt install julia
```

Now Julia should be ready to go. You may just type julia at the command line, you will get into the julia environment (called REPL).

### Using Julia on Mac OS X

For those using Mac OS X, if you can’t find julia installed, you might need to do the following to install or update Julia on MacOS

* Goto https://julialang.org/downloads/, double click 64-bit to download julia-1.5.0-mac64.dmg. Once download completes double click it. Drag Julia-1.5 icon into Applications folder, then execute the following commands

```bash
sudo rm -f /usr/local/bin/julia
sudo ln -s /Applications/Julia-1.5.app/Contents/Resources/julia/bin/julia /usr/local/bin/julia
julia -v

julia version 1.5.0
```

### Using Julia on Clusters

Julia is among hundreds of software packages installed on the systems. To use Julia, load the following modules first

```bash
module load gcc/9.3.0
module load julia/1.7.0
```

You may now type julia at the command line and enter the REPL environment.

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
