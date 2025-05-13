+++
title = "Intro to parallel computing"
slug = "chapel-10-intro-parallel"
weight = 10
katex = true
+++

<!-- ## Quick review of the previous sessions -->

<!-- - we wrote the serial version of the 2D heat transfer solver in Chapel `baseSolver.chpl`: initial T=25, zero -->
<!--   boundary conditions on the left/upper sides, and linearly increasing temperature on the boundary for the -->
<!--   right/bottom sides; the temperature should converge to a steady state -->
<!-- - it optionally took the following `config` variables from the command line: _rows_, _cols_, _niter_, _iout_, -->
<!--   _jout_, _tolerance_, _nout_ -->
<!-- - we ran the benchmark solution to convergence after 7750 iterations -->

<!-- ```sh -->
<!-- $ ./baseSolver --rows=650 --iout=200 --niter=10_000 --tolerance=0.002 --nout=1000 -->
<!-- ``` -->

<!-- - we learned how to time individual sections of the code -->
<!-- - we saw that `--fast` flag sped up calculation by ~100X -->

## Parallel programming in Chapel

Chapel provides high-level abstractions for parallel programming no matter the grain size of your tasks,
whether they run in a shared memory or a distributed memory environment, or whether they are executed
"concurrently" (frequently switching between tasks) or truly in parallel. As a programmer you can focus
on the algorithm: how to divide the problem into tasks that make sense in the context of the problem, and
be sure that the high-level implementation will run on any hardware configuration. Then you could
consider the specificities of the particular system you are going to use (whether is shared or
distributed, the number of cores, etc.) and tune your code/algorithm to obtain a better performance.

To this effect, **_concurrency_** (the creation and execution of multiple tasks), and **_locality_** (on which
set of resources these tasks are executed) are orthogonal (separate) concepts in Chapel. For example, we could
have a set of several tasks that would be running as shown below:

{{< figure src="/img/orthogonal.png" width="800px" >}}

<!-- ``` -->
<!-- a. concurrently by the same processor in a single compute node (**serial local** code), -->
<!-- b. in parallel by several processors in a single compute node (**parallel local** code), -->
<!-- c. in parallel by several processors distributed in different compute nodes (**parallel distributed** -->
<!--    code), or -->
<!-- d. serially (one by one) by several processors distributed in different compute nodes (**serial -->
<!--    distributed** code -- yes, this is possible in Chapel) -->
<!-- ``` -->
<!-- Similarly, each of these tasks could be using variables located in: -->
<!-- ``` -->
<!-- a. the local memory on the compute node where it is running, or -->
<!-- b. on distributed memory located in other compute nodes. -->
<!-- ``` -->

And again, Chapel could take care of all the stuff required to run our algorithm in most of the
scenarios, but we can always add more specific detail to gain performance when targeting a particular
scenario.

> **Task parallelism** is a style of parallel programming in which parallelism is driven by
> *programmer-specified tasks*. This is in contrast with **data parallelism** which is a style of
> parallel programming in which parallelism is driven by *computations over collections of data elements
> or their indices*.
{.note}

Chapel provides functionality for both task- and data-parallel programming. Since task parallelism is lower
level (*you* tell the computer how to divide your computation into tasks) than data parallelism, it is
considerably more difficult. In this course we will focus mostly on data parallelism, but we will briefly
cover task parallelism towards the end of the course.







## Running single-local parallel Chapel

Make sure you have loaded the single-locale Chapel environment:

```sh
$ module load chapel-multicore/2.4.0
```

<!-- ```sh -->
<!-- source /project/def-sponsor00/shared/syncHPC/startSingleLocale.sh -->
<!-- ``` -->

In this lesson, we'll be running on several cores on one node with a script `shared.sh`:

```sh
#!/bin/bash
#SBATCH --time=0:5:0         # walltime in d-hh:mm or hh:mm:ss format
#SBATCH --mem-per-cpu=3600   # in MB
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --output=solution.out
./test
```
