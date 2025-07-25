+++
title = "Introduction to Chapel"
slug = "chapel-01-intro"
weight = 1
katex = true
+++

<!-- as productive as Python -->
<!-- as fast as Fortran -->
<!-- as portable as C -->
<!-- as scalabale as MPI -->
<!-- as fun as your favourite programming language -->

<!-- - lower-level task parallelism: create one task to do this, another task to do this -->
<!-- - higher-level data parallelism: for all elements in my array, distribute them this way -->

<!-- - library of standard domain maps provided by chapel -->
<!-- - users can write their own domain maps -->

## Chapel: a language for parallel computing on large-scale systems

- Modern, **open-source parallel programming language** developed at _Cray Inc._ (acquired by Hewlett Packard
  Enterprise in 2019).
- Offers simplicity and readability of scripting languages such as Python or Matlab: "Python for parallel
  programming".
- Compiled language $\Rightarrow$ provides the **speed and performance** of Fortran and C.
- Supports high-level abstractions for data distribution and **data parallel processing**, and for **task
  parallelism**.
- Based on the **PGAS** (Partitioned Global Address space) programming model: can access variables in global
  address space from each node, a lot of behind-the-scenes work to reduce/buffer remote memory access.
- Provides **data-driven placement of computations**.
  <!-- - allow users to express parallel computations in a natural, almost intuitive, manner -->
- Designed around a **multi-resolution** philosophy: users can incrementally add more detail to their original
  code, to bring it as close to the machine as required, at the same time they can achieve anything you can
  normally do with MPI and OpenMP.




<!-- - has its source code stored in text files with the extension `.chpl` -->

The Chapel community is fairly small: relatively few people know/use Chapel &nbsp;⇄&nbsp; too few
libraries. However, you can use functions/libraries written in other languages:

<!-- 1. Direct calls will always be serial. -->
<!-- 1. High-level Chapel parallel libraries can use C/F90/etc libraries underneath. -->
<!-- 1. A slowly growing base of parallel Chapel libraries. -->

<!-- {{< figure src="/img/threeParts.png" width=800px >}} -->

<!-- You can find the slides [here](../../files/chapel.pdf). -->

<!-- {{<note>}} In "Task parallelism" we will try to go as far as we can today, and we will resume on Day 2 where -->
<!-- we left off. {{</note>}} -->

<!-- {{<note>}} Try to do all exercises in the lessons. The solutions are linked from the course's front page: -->
<!-- please try not to look at them while working on the problems. {{</note>}} -->

## Running Chapel codes on Cedar / Graham / Béluga / Narval

On Alliance's production clusters Cedar / Graham / Béluga / Narval we have three versions of Chapel:

1. single-locale (single-node) `chapel-multicore`
2. multi-locale `chapel-ucx` for InfiniBand clusters (all newer clusters)
3. older multi-locale `chapel-ofi` for OmniPath clusters (Cedar)

You can find the documentation on running Chapel
in {{<a "https://docs.alliancecan.ca/wiki/Chapel" "our wiki">}}.

If you want to start single-locale Chapel, you will need to load `chapel-multicore` module, e.g.

```sh
$ module spider chapel-multicore   # list all versions
$ module load chapel-multicore/2.4.0
```

<!-- Since multi-locale Chapel includes a parallel launcher for the right interconnect type, there is no single -->
<!-- Chapel module for all cluster architectures. -->

## Running Chapel codes inside a Docker container

If you are familiar with Docker and have it installed, you can run multi-locale Chapel inside a Docker
container (e.g., on your laptop, or inside an Ubuntu VM on Arbutus):

```sh
$ docker pull chapel/chapel  # will emulate a cluster with 4 cores/node
$ mkdir -p ~/tmp
$ docker run -v /home/ubuntu/tmp:/mnt -it -h chapel chapel/chapel  # map host's ~/tmp to container's /mnt
$ cd /mnt
$ apt-get update
$ apt-get install nano  # install nano inside the Docker container
$ nano test.chpl        # file is /mnt/test.chpl inside the container and ~ubuntu/tmp/test.chpl on the host VM
$ chpl test.chpl
$ ./test -nl 8
```

You can find more information at https://hub.docker.com/r/chapel/chapel

## Running single-locale Chapel in MacOS

You can compile and run Chapel codes in MacOS. Multi-locale codes (e.g. containing distributed arrays) will
compile but will run only as single-locale.

```sh
brew install chapel
```

## Running Chapel codes on the training cluster

> Now we will distribute the usernames and passwords. Once you have these, log in to the training
> cluster and do the following:
> 1. load single-locale Chapel and compile a simple code,
> 2. write a makefile for compiling Chapel codes, and
> 3. submit a serial job script to run Chapel on a compute node.
{.note}

<!-- Depending on where our training cluster is deployed, its Chapel setup might (or not) be different from the -->
<!-- production clusters. -->

On the training cluster, you can start single-locale Chapel with:

<!-- ```sh -->
<!-- $ module load arch/avx2 gcc/9.3.0 chapel-multicore -->
<!-- ``` -->

```sh
$ module load chapel-multicore/2.4.0
```

<!-- or -->
<!-- ```sh -->
<!-- source /project/def-sponsor00/shared/syncHPC/startSingleLocale.sh -->
<!-- ``` -->

Let's write a simple Chapel code, compile and run it:

```sh
$ cd ~/tmp
$ nano test.chpl
$     writeln('If you can see this, everything works!');
$ chpl test.chpl
$ ./test
```

You can optionally pass the flag `--fast` to the compiler to optimize the binary to run as fast as possible
for the given architecture.

<!-- Chapel was designed from scratch as a new programming language. It is an imperative language with its own
-->
<!-- syntax (with elements similar to C) that we must know before introducing the parallel programming -->
<!-- concepts. -->

<!-- In this lesson we will learn the basic elements and syntax of the language; then we will study **_task -->
<!-- parallelism_**, the first level of parallelism in Chapel, and finally we will use parallel data -->
<!-- structures and **_data parallelism_**, which is the higher level of abstraction, in parallel programming, -->
<!-- offered by Chapel. -->

Depending on the code, it might utilize one / several / all cores on the current node. The command above
implies that you are allowed to utilize all cores. This might not be the case on an HPC cluster, where a login
node is shared by many people at the same time, and where it might not be a good idea to occupy all cores on a
login node with CPU-intensive tasks. Therefore, we'll be running test Chapel codes inside submitted jobs on
compute nodes.

Let's write the job script `serial.sh`:

```sh
#!/bin/bash
#SBATCH --time=0:5:0         # walltime in d-hh:mm or hh:mm:ss format
#SBATCH --mem-per-cpu=3600   # in MB
#SBATCH --output=solution.out
./test
```

and then submit it:

```sh
$ chpl test.chpl
$ sbatch serial.sh
$ sq                         # same as `squeue -u $USER`
$ cat slurm-jobID.out
```

Alternatively, we could work inside a serial interactive job:

```sh
$ salloc --time=2:0:0 --mem-per-cpu=3600
```

<!-- Note that on the training cluster we have: -->

<!-- - the login node with 16 "p"-type cores and 32GB memory, -->
<!-- - 8 compute nodes with 16 "c"-type cores and 60GB memory each, for the total of 128 cores. -->

<!-- {{<note>}} -->
<!-- Even though each node effectively has 3GB of memory, we highly recommend to use `--mem-per-cpu=1000` (and -->
<!-- not more) throughout this workshop. Some memory is being used for the operating system, drivers, system -->
<!-- utilities, MPI buffers and the like. Unfortunately, unlike the production clusters, the training cluster does -->
<!-- not have safeguards when its nodes run out of memory, shutting down some system utilities and leading to -->
<!-- inability to run parallel jobs. The cluster will rebuild itself within few hours, but unfortunately asking for -->
<!-- too much memory might leave it unable to run parallel jobs during the workshop. -->
<!-- {{</note>}} -->

## Makefiles

In the rest of this workshop, we'll be compiling codes `test.chpl`, `baseSolver.chpl`, `begin.chpl`,
`cobegin.chpl` and many others. To simplify compilation, we suggest writing a file called `Makefile` in your
working directory:

```makefile
%: %.chpl
	chpl $^ -o $@
clean:
	@find . -maxdepth 1 -type f -executable -exec rm {} +
```

Note that the 2nd and the 4th lines start with TAB and not with multiple spaces -- this is **very important**!

With this makefile, to compile any Chapel code, e.g. `test.chpl`, you would type:

```sh
$ make test
```

Add `--fast` flag to the makefile to optimize your code. And you can type `make clean` to delete all
executables in the current directory.
