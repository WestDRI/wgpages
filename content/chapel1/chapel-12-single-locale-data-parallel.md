+++
title = "Single-locale data parallelism"
slug = "chapel-12-single-locale-data-parallel"
weight = 12
katex = true
+++

As we mentioned in the previous section, **Data Parallelism** is a style of parallel programming in which
parallelism is driven by *computations over collections of data elements or their indices*. The main tool for
this in Chapel is a `forall` loop -- it'll create an *appropriate* number of threads to execute a loop,
dividing the loop's iterations between them.

```chpl
forall index in iterand   \\ iterating over all elements of an array or over a range of indices
{instructions}
```

What is the *appropriate* number of tasks?
* on a single core: single task
* on multiple cores on the same nodes: all cores, up to the number of elements or iterations
* on multiple cores on multiple nodes: all cores, up to the problem size, given the data distribution

Consider a simple code `test.chpl`:

```chpl
const n = 1e6: int;
var A: [1..n] real;
forall a in A do
  a += 1;
```

In this code we update all elements of the array `A`. The code will run on a single node, lauching as many
threads as the number of available cores. It is thread-safe, meaning that no two threads are writing into the
same variable at the same time.

* if we replace `forall` with `for`, we'll get a serial loop on a sigle core
* if we replace `forall` with `coforall`, we'll create 1e6 threads (likely an overkill!)

Consider a simple code `forall.chpl` that we'll run inside a 3-core interactive job. We have a range of
indices 1..1000, and they get broken into groups that are processed by different threads:

```chpl
var count = 0;
forall i in 1..1000 with (+ reduce count) {   // parallel loop
  count += i;
}
writeln('count = ', count);
```

If we have not done so, let's write a script `shared.sh` for submitting single-locale, two-core Chapel jobs:

```sh
#!/bin/bash
#SBATCH --time=0:5:0         # walltime in d-hh:mm or hh:mm:ss format
#SBATCH --mem-per-cpu=1000   # in MB
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --output=solution.out
./forall
```

```sh
$ source /home/razoumov/shared/syncHPC/startMultiLocale.sh   # on the training cluster
$ chpl forall.chpl -o forall
$ sbatch shared.sh
$ cat solution.out
```
```
count = 500500
```

We computed the sum of integers from 1 to 1000 in parallel. How many cores did the code run on? Looking at the
code or its output, **we don't know**. Most likely, on two cores available to us inside the job. But we can
actually check that! Do this:

1. replace `count += i;` with `count = 1;`
1. change the last line to `writeln('actual number of threads = ', count);`

```sh
$ chpl forall.chpl -o forall
$ sbatch shared.sh
$ cat solution.out
```
```
actual number of threads = 2
```

If you see one thread, try running this code as a batch multi-core job.

> ### <font style="color:blue">Exercise "Data.1"</font>
> Using the first version of `forall.chpl` (where we computed the sum of integers 1..1000) as a template,
> write a Chapel code to compute `pi` by calculating the integral (see slides) numerically through
> summation using `forall` parallelism. Implement the number of intervals as `config` variable.
>
> Hint: to get you started, here is a serial version of this code:
> ```chpl
> config const n = 1000;
> var h, total: real;
> h = 1.0 / n;                          // interval width
> for i in 1..n {
>   var x = h * ( i - 0.5 );
>   total += 4.0 / ( 1.0 + x**2);
> }
> writef('pi is %3.10r\n', total*h);    // C-style formatted write, r stands for real
> ```

We finish this section by providing an example of how you can organize a data-parallel, shared-memory
`forall` loop for the 2D heat transfer solver (without writing the full code):

```chpl
config const rows = 100, cols = 100;
const rowStride = 34, colStride = 25;    // each block has 34 rows and 25 columns => 3x4 blocks
forall (r,c) in {1..rows,1..cols} by (rowStride,colStride) do {   // nested c-loop inside r-loop
																  // 12 iterations, up to 12 threads
  for i in r..min(r+rowStride-1,rows) do {     // serial i-loop inside each block
	for j in c..min(c+colStride-1,cols) do {   // serial j-loop inside each block
	  Tnew[i,j] = 0.25 * (T[i-1,j] + T[i+1,j] + T[i,j-1] + T[i,j+1]);
	}
  }
}
```
