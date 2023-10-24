+++
title = "Multi-locale Chapel"
slug = "chapel-14-multi-locale-chapel"
weight = 14
katex = true
+++

## Setup

So far we have been working with single-locale Chapel codes that may run on one or many cores on a single
compute node, making use of the shared memory space and accelerating computations by launching parallel
threads on individual cores. Chapel codes can also run on multiple nodes on a compute cluster. In Chapel this
is referred to as **multi-locale** execution.

> ## Docker side note
>
> If you work inside a Chapel Docker container, e.g., chapel/chapel-gasnet, the container environment
> simulates a multi-locale cluster, so you would compile and launch multi-locale Chapel codes directly by
> specifying the number of locales with `-nl` flag:
>
> ```sh
> $ chpl --fast mycode.chpl -o mybinary
> $ ./mybinary -nl 3
> ```
>
> Inside the Docker container on multiple locales your code will not run any faster than on a single
> locale, since you are emulating a virtual cluster, and all tasks run on the same physical node. To
> achieve actual speedup, you need to run your parallel multi-locale Chapel code on a real HPC cluster.

On an HPC cluster you would need to submit either an interactive or a batch job asking for several nodes
and then run a multi-locale Chapel code inside that job. In practice, the exact commands to run
multi-locale Chapel codes depend on how Chapel was built on the cluster.

When you compile a Chapel code with the multi-locale Chapel compiler, two binaries will be produced. One
is called `mybinary` and is a launcher binary used to submit the real executable `mybinary_real`. If the
Chapel environment is configured properly with the launcher for the cluster's physical interconnect, then
you would simply compile the code and use the launcher binary `mybinary` to run a multi-locale code.

For the rest of this class we assume that you have a working multi-locale Chapel environment, whether
provided by a Docker container or by multi-locale Chapel on a physical HPC cluster. We will run all
examples on four nodes with two cores per node.

<!-- ```sh -->
<!-- $ chpl mycode.chpl -o mybinary -->
<!-- $ ./mybinary -nl 2 -->
<!-- ``` -->
<!-- The exact parameters of the job such as the maximum runtime and the requested memory can be specified -->
<!-- with Chapel environment variables. One drawback of this launching method is that Chapel will have access -->
<!-- to all physical cores on each node participating in the run -- this will present problems if you are -->
<!-- scheduling jobs by-core and not by-node, since part of a node should be allocated to someone else's job. -->
<!-- The Compute Canada clusters Cedar and Graham employ two different physical interconnects, and since we -->
<!-- use exactly the same multi-locale Chapel module on both clusters -->
<!-- ```sh -->
<!-- $ module load gcc chapel-slurm-gasnetrun_ibv/1.15.0 -->
<!-- $ export GASNET_PHYSMEM_MAX=1G      # needed for faster job launch -->
<!-- $ export GASNET_PHYSMEM_NOPROBE=1   # needed for faster job launch -->
<!-- ``` -->
<!-- we cannot configure the same single launcher for both. Therefore, we launch multi-locale Chapel codes -->
<!-- using the real executable `mybinary_real`. For example, for an interactive job you would type: -->
<!-- ```sh -->
<!-- $ salloc --time=0:30:0 --nodes=4 --cpus-per-task=2 --mem-per-cpu=1000 --account=def-razoumov-ac -->
<!-- $ echo $SLURM_NODELIST          # print the list of four nodes -->
<!-- $ echo $SLURM_CPUS_PER_TASK     # print the number of cores per node (3) -->
<!-- $ chpl mycode.chpl -o mybinary -->
<!-- $ srun ./mybinary_real -nl 4   # will run on four locales with max 3 cores per locale -->
<!-- ``` -->
<!-- Production jobs would be launched with `sbatch` command and a Slurm launch script as usual. -->
<!-- Alternatively, instead of loading the system-wide module, you can configure multi-locale Chapel in your -->
<!-- own directory. Send me an email later, and I'll share the instructions. Here is how you would use it: -->

<!-- On Cedar let's exit our single-node job (Ctrl-D if you are still running it), and then back on the login -->
<!-- node unload `chapel-single` and load `chapel-multi-cedar`, and then start a **4-node** interactive job -->
<!-- with **3 cores per MPI task** (12 cores per job): -->

<!-- ```sh -->
<!-- $ module unload chapel-single -->
<!-- $ module load chapel-multi-cedar/1.16.0 -->
<!-- $ salloc --time=2:00:0 --nodes=4 --cpus-per-task=3 --mem-per-cpu=1000 \ -->
<!--          --account=def-razoumov-ws_cpu --reservation=arazoumov-may17 -->
<!-- $ echo $SLURM_NODELIST          # print the list of nodes (should be four) -->
<!-- $ echo $SLURM_CPUS_PER_TASK     # print the number of cores per node (3) -->
<!-- $ export HFI_NO_CPUAFFINITY=1   # to enable parallelism on each locale with OmniPath drivers -->
<!-- $ export CHPL_RT_NUM_THREADS_PER_LOCALE=$SLURM_CPUS_PER_TASK   # to limit the number of tasks -->
<!-- ``` -->

Let's write a job submission script `distributed.sh`:

```sh
#!/bin/bash
#SBATCH --time=0:5:0         # walltime in d-hh:mm or hh:mm:ss format
#SBATCH --mem-per-cpu=1000   # in MB
#SBATCH --nodes=3
#SBATCH --cpus-per-task=2
#SBATCH --output=solution.out
./test -nl 3   # in this case the 'srun' launcher is already configured for our interconnect
```

<!-- Check: without `CHPL_RT_NUM_THREADS_PER_LOCALE`, will 32 threads run on separate 32 cores -->
<!-- or will they run on the 3 cores inside our Slurm job? -->

## Simple multi-locale codes

Let us test our multi-locale Chapel environment by launching the following code:

```chpl
writeln(Locales);
```
```sh
$ source /home/razoumov/shared/syncHPC/startMultiLocale.sh   # on the training cluster
$ chpl test.chpl -o test
$ sbatch distributed.sh
$ cat solution.out
```

This code will print the built-in global array `Locales`. Running it on four locales will produce

```
LOCALE0 LOCALE1 LOCALE2
```

We want to run some code on each locale (node). For that, we can cycle through locales:

```chpl
for loc in Locales do   // this is still a serial program
  on loc do             // run the next line on locale `loc`
	writeln("this locale is named ", here.name[0..4]);   // `here` is the locale on which the code is running
```

This will produce

```
this locale is named node1
this locale is named node2
this locale is named node3
```

Here the built-in variable class `here` refers to the locale on which the code is running, and `here.name` is
its hostname. We started a serial `for` loop cycling through all locales, and on each locale we printed its
name, i.e., the hostname of each node. This program ran in serial starting a task on each locale only after
completing the same task on the previous locale. Note the order in which locales were listed.

To run this code in parallel, starting four simultaneous tasks, one per locale, we simply need to replace
`for` with `forall`:

```chpl
forall loc in Locales do   // now this is a parallel loop
  on loc do
	writeln("this locale is named ", here.name[0..4]);
```

This starts four tasks in parallel, and the order in which the print statement is executed depends on the
runtime conditions and can change from run to run:

```
this locale is named node1
this locale is named node3
this locale is named node2
```

We can print few other attributes of each locale. Here it is actually useful to revert to the serial loop
`for` so that the print statements appear in order:

```chpl
use Memory.Diagnostics;
for loc in Locales do
  on loc {
	writeln("locale #", here.id, "...");
	writeln("  ...is named: ", here.name);
	writeln("  ...has ", here.numPUs(), " processor cores");
	writeln("  ...has ", here.physicalMemory(unit=MemUnits.GB, retType=real), " GB of memory");
	writeln("  ...has ", here.maxTaskPar, " maximum parallelism");
  }
```
```sh
$ chpl test.chpl -o test
$ sbatch distributed.sh
$ cat solution.out
```
```
locale #0...
  ...is named: node1
  ...has 2 processor cores
  ...has 2.77974 GB of memory
  ...has 2 maximum parallelism
locale #1...
  ...is named: node2
  ...has 2 processor cores
  ...has 2.77974 GB of memory
  ...has 2 maximum parallelism
locale #2...
  ...is named: node3
  ...has 2 processor cores
  ...has 2.77974 GB of memory
  ...has 2 maximum parallelism
```

Note that while Chapel correctly determines the number of physical cores on each node and the number of cores
available inside our job on each node (maximum parallelism), it lists the total physical memory on each node
available to all running jobs which is not the same as the total memory per node allocated to our job.
