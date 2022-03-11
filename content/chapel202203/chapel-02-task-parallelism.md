+++
title = "Task parallelism"
slug = "chapel-02-task-parallelism"
weight = 2
+++

## Quick review of the previous session

* we wrote the serial version of the 2D heat transfer solver in Chapel `baseSolver.chpl`: initial T=25,
  zero boundary conditions on the left/upper sides, and linearly increasing temperature on the boundary
  for the right/bottom sides; the temperature should converge to a steady state
* it optionally took the following `config` variables from the command line: _rows_, _cols_, _niter_, _iout_,
  _jout_, _tolerance_, _nout_
* we ran the benchmark solution to convergence after 7750 iterations
```sh
./baseSolver --rows=650 --iout=200 --niter=10_000 --tolerance=0.002 --nout=1000
```
* we learned how to time individual sections of the code
* we saw that `--fast` flag sped up calculation by ~100X

## Task Parallelism with Chapel

The basic concept of parallel computing is simple to understand: we **divide our job into tasks that can
be executed at the same time**, so that we finish the job in a fraction of the time that it would have
taken if the tasks are executed one by one.

> ## Key idea
> **Task** is a unit of computation that can run in parallel with other tasks.

Implementing parallel computations, however, is not always easy. How easy it is to parallelize a code
really depends on the underlying problem you are trying to solve. This can result in:

- a **_fine-grained_** parallel code that needs lots of communication/synchronization between tasks, or
- a **_coarse-grained_** code that requires little communication between tasks.
- in this sense **_grain size_** refers to the amount of independent computing in between communication
- an **_embarrassing parallel_** problem is one where all tasks can be executed completely independent
  from each other (no communications required)

## Parallel programming in Chapel

Chapel provides high-level abstractions for parallel programming no matter the grain size of your tasks,
whether they run in a shared memory or a distributed memory environment, or whether they are executed
"concurrently" (frequently switching between tasks) or truly in parallel. As a programmer you can focus
on the algorithm: how to divide the problem into tasks that make sense in the context of the problem, and
be sure that the high-level implementation will run on any hardware configuration. Then you could
consider the specificities of the particular system you are going to use (whether is shared or
distributed, the number of cores, etc.) and tune your code/algorithm to obtain a better performance.

To this effect, **_concurrency_** (the creation and execution of multiple tasks), and **_locality_** (on
which set of resources these tasks are executed) are orthogonal (separate) concepts in Chapel. For
example, we can have a set of several tasks; these tasks could be running, e.g.,

```
a. concurrently by the same processor in a single compute node (**serial local** code),
b. in parallel by several processors in a single compute node (**parallel local** code),
c. in parallel by several processors distributed in different compute nodes (**parallel distributed**
   code), or
d. serially (one by one) by several processors distributed in different compute nodes (**serial
   distributed** code -- yes, this is possible in Chapel)
```
Similarly, each of these tasks could be using variables located in:
```
a. the local memory on the compute node where it is running, or
b. on distributed memory located in other compute nodes.
```

And again, Chapel could take care of all the stuff required to run our algorithm in most of the
scenarios, but we can always add more specific detail to gain performance when targeting a particular
scenario.

> ## Key idea
> **Task parallelism** is a style of parallel programming in which parallelism is driven by
> *programmer-specified tasks*. This is in contrast with **Data Parallelism** which is a style of
> parallel programming in which parallelism is driven by *computations over collections of data elements
> or their indices*.

## Running single-local parallel Chapel

<!-- ```sh -->
<!-- module load gcc chapel-single/1.15.0 -->
<!-- salloc --time=2:00:0 --ntasks=1 --cpus-per-task=3 --mem-per-cpu=1000 \ -->
<!--          --account=def-razoumov-ws_cpu --reservation=arazoumov-may17 -->
<!-- echo $SLURM_NODELIST          # print the list of nodes (should be one) -->
<!-- echo $SLURM_CPUS_PER_TASK     # print the number of cores per node (3) -->
<!-- ``` -->

Make sure you have loaded the official single-locale Chapel module:

```sh
module load gcc/9.3.0 chapel-multicore/1.25.0
```

In this lesson, we'll be running on several cores on one node with a script `shared.sh`:

```sh
#!/bin/bash
#SBATCH --time=00:05:00      # walltime in d-hh:mm or hh:mm:ss format
#SBATCH --mem-per-cpu=3200   # in MB
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --output=solution.out
./begin
```

## Fire-and-forget tasks

A Chapel program always starts as a single main thread. You can then start concurrent threads with the `begin`
statement. A thread spawned by the `begin` statement will run in a different thread while the main thread continues its
normal execution. Let's start a new code `begin.chpl` with the following lines:

```chpl
var x = 100;
writeln('This is the main thread starting first thread');
begin {
  var count = 0;
  while count < 10 {
	count += 1;
	writeln('thread 1: ', x + count);
  }
}
writeln('This is the main thread starting second thread');
begin {
  var count = 0;
  while count < 10 {
	count += 1;
	writeln('thread 2: ', x + count);
  }
}
writeln('This is the main thread, I am done ...');
```
```sh
chpl begin.chpl -o begin
sbatch shared.sh
cat solution.out
```
```
This is the main thread starting first thread
This is the main thread starting second thread
This is the main thread, I am done ...
thread 2: 101
thread 1: 101
thread 2: 102
thread 1: 102
thread 2: 103
thread 1: 103
thread 2: 104
...
thread 1: 109
thread 2: 109
thread 1: 110
thread 2: 110
```

As you can see the order of the output is not what we would expected, and actually it is somewhat
unpredictable. This is a well known effect of concurrent threads accessing the same shared resource at the
same time (in this case the screen); the system decides in which order the threads could write to the
screen.

> ## Discussion
> 1. What would happen if in the last code we move the definition of `count` into the main thread, but try to assign it
>    from threads 1 and 2?
>
>> _Answer_: we'll get an error at compilation ("cannot assign to const variable"), since then `count` would belong to the
>> main thread (would be defined within the scope of the main thread), and we could modify its value only in the main
>> thread.

> 2. What would happen if we try to insert a second definition `var x = 10;` inside the first `begin` statement?
>
>> _Answer_: that will actually work, as we'll simply create another, local instance of `x` with its own value.

> ## Key idea
> All variables have a **_scope_** in which they can be used. Variables declared inside a concurrent
> thread are accessible only by that thread. Variables declared in the main thread can be read everywhere,
> but Chapel won't allow other concurrent threads to modify them.

> ## Discussion
> Are the concurrent threads, spawned by the last code, running truly in parallel?
>
> _Answer_: it depends on the number of cores available to your job. If you have a single core, they'll
> run concurrently, with the CPU switching between the threads. If you have two cores, thread1 and thread2
> will likely run in parallel using the two cores.

> ## Key idea
> To maximize performance, start as many threads as the number of available cores.

A slightly more structured way to start concurrent threads in Chapel is by using the `cobegin` statement. Here you can
start a block of concurrent threads, **one for each statement** inside the curly brackets. Another difference between
the `begin` and `cobegin` statements is that with the `cobegin`, all the spawned threads are synchronized at the end of
the statement, i.e. the main thread won't continue its execution until all threads are done. Let's start `cobegin.chpl`:

```chpl
var x = 0;
writeln('This is the main thread, my value of x is ', x);
cobegin {
  {
	var x = 5;
	writeln('This is thread 1, my value of x is ', x);
  }
  writeln('This is thread 2, my value of x is ', x);
}
writeln('This message will not appear until all threads are done ...');
```
```sh
chpl cobegin.chpl -o cobegin
sed -i -e 's|begin|cobegin|' shared.sh
sbatch shared.sh
cat solution.out
```
```
This is the main thread, my value of x is 0
This is thread 2, my value of x is 0
This is thread 1, my value of x is 5
This message will not appear until all threads are done...
```

As you may have concluded from the Discussion exercise above, the variables declared inside a thread are accessible only
by the thread, while those variables declared in the main thread are accessible to all threads.

Another, and one of the most useful ways to start concurrent/parallel threads in Chapel, is the `coforall` loop. This is
a combination of the for-loop and the `cobegin`statements. The general syntax is:

```chpl
coforall index in iterand
{instructions}
```

This will start **a new thread for each iteration**. Each thread will then perform all the instructions inside the curly
brackets. Each thread will have a copy of the loop variable **_index_** with the corresponding value yielded by the
iterand. This index allows us to _customize_ the set of instructions for each particular thread. Let's write
`coforall.chpl`:

```chpl
var x = 10;
config var numthreads = 2;
writeln('This is the main thread: x = ', x);
coforall threadid in 1..numthreads do {
  var count = threadid**2;
  writeln('this is thread ', threadid, ': my value of count is ', count, ' and x is ', x);
}
writeln('This message will not appear until all threads are done ...');
```
```sh
chpl coforall.chpl -o coforall
sed -i -e 's|cobegin|coforall --numthreads=5|' shared.sh
sbatch shared.sh
cat solution.out
```
```
This is the main thread: x = 10
this is thread 1: my value of c is 1 and x is 10
this is thread 2: my value of c is 4 and x is 10
this is thread 4: my value of c is 16 and x is 10
this is thread 3: my value of c is 9 and x is 10
this is thread 5: my value of c is 25 and x is 10
This message will not appear until all threads are done ...
```

Notice the random order of the print statements. And notice how, once again, the variables declared
outside the `coforall` can be read by all threads, while the variables declared inside, are available
only to the particular thread.

> ### Exercise "Task.1"
> Would it be possible to print all the messages in the right order? Modify the code in the last example as required and
> save it as `consecutive.chpl`.
>
> Hint: you can use an array of strings declared in the main thread, into which all the concurrent threads could write
> their messages in the right order. Then, at the end, have the main thread print all elements of the array.

> ### Exercise "Task.2"
> Consider the following code `gmax.chpl` to find the maximum array element. Complete this code, and also time the
> `coforall` loop.
> ```chpl
> use Random, Time;
> config const nelem = 1e8: int;
> var x: [1..nelem] real;
> fillRandom(x);	                   // fill array with random numbers
> var gmax = 0.0;
>
> config const numthreads = 2;       // let's pretend we have 2 cores
> const n = nelem / numthreads;      // number of elements per thread
> const r = nelem - n*numthreads;    // these elements did not fit into the last thread
> var lmax: [1..numthreads] real;    // local maxima for each thread
> coforall threadid in 1..numthreads do {
>   var start, finish: int;
>   start = ...
>   finish = ...
>   ... compute lmax for this thread ...
> }
>
> // put largest lmax into gmax
> for threadid in 1..numthreads do                        // a serial loop
>   if lmax[threadid] > gmax then gmax = lmax[threadid];
>
> writef('The maximum value in x is %14.12dr\n', gmax);   // formatted output
> writeln('It took ', watch.elapsed(), ' seconds');
> ```
> Write a parallel code to find the maximum value in the array `x`. Be careful: the number of threads should not be
> excessive. Best to use `numthreads` to organize parallel loops. For each thread compute the `start` and `finish`
> indices of its array elements and cycle through them to find the local maximum. Then in the main thread cycle through
> all local maxima to find the global maximum.

> ## Discussion
> Run the code of last Exercise using different number of threads, and different sizes of the array `x` to
> see how the execution time changes. For example:
> ```sh
> ./gmax --nelem=100_000_000 --numthreads=1
> ```
>
> Discuss your observations. Is there a limit on how fast the code could run?
>
>> Answer: (1) consider a small problem, increasing the number of threads => no speedup
>>         (2) consider a large problem, increasing the number of threads => speedup up to the physical
>>             number of cores

> ## Try this...
> Substitute your addition to the code to find _gmax_ in the last exercise with:
> ```chpl
> gmax = max reduce x;   // 'max' is one of the reduce operators (data parallelism example)
> ```
> Time the execution of the original code and this new one. How do they compare?
>
>> Answer: the built-in reduction operation runs in parallel utilizing all cores.

> ## Key idea
> It is always a good idea to check whether there is _built-in_ functions or methods in the used
> language, that can do what we want as efficiently (or better) than our house-made code. In this case,
> the _reduce_ statement reduces the given array to a single number using the operation `max`, and it is
> parallelized. Here is the full list of reduce operations: + &nbsp; * &nbsp; && &nbsp; || &nbsp; &
> &nbsp; | &nbsp; ^ &nbsp; min &nbsp; max.

## Synchronization of threads
### `sync` block

The keyword `sync` provides all sorts of mechanisms to synchronize threads in Chapel. We can simply use
`sync` to force the _parent thread_ to stop and wait until its _spawned child-thread_ ends. Consider this
`sync1.chpl`:

```chpl
var x = 0;
writeln('This is the main thread starting a synchronous thread');
sync {
  begin {
	var count = 0;
	while count < 10 {
	  count += 1;
	  writeln('thread 1: ', x + count);
	}
  }
}
writeln('The first thread is done ...');
writeln('This is the main thread starting an asynchronous thread');
begin {
  var count = 0;
  while count < 10 {
	count += 1;
	writeln('thread 2: ', x + count);
  }
}
writeln('This is the main thread, I am done ...');
```
```sh
chpl sync1.chpl -o sync1
sed -i -e 's|gmax|sync1|' shared.sh
sbatch shared.sh
cat solution.out
```
```
This is the main thread starting a synchronous thread
thread 1: 1
thread 1: 2
thread 1: 3
thread 1: 4
thread 1: 5
thread 1: 6
thread 1: 7
thread 1: 8
thread 1: 9
thread 1: 10
The first thread is done ...
This is the main thread starting an asynchronous thread
This is the main thread, I am done ...
thread 2: 1
thread 2: 2
thread 2: 3
thread 2: 4
thread 2: 5
thread 2: 6
thread 2: 7
thread 2: 8
thread 2: 9
thread 2: 10
```

> ## Discussion
> What would happen if we swap `sync` and `begin` in the first thread:
> ```chpl
> begin {
>   sync {
>     var c = 0;
>     while c < 10 {
>       c += 1;
>       writeln('thread 1: ', x + c);
>     }
>   }
> }
> writeln('The first thread is done ...');
> ```
> Discuss your observations.
>
> Answer: `sync` would have no effect on the rest of the program. We only pause the execution of the first thread, until
> all statements inside sync {} are completed -- but this does not affect the main and the second threads: they keep on
> running.

> ### Exercise "Task.3"
> Use `begin` and `sync` statements to reproduce the functionality of `cobegin` in cobegin.chpl, i.e., the main thread
> should not continue until both threads 1 and 2 are completed.

### `sync` variables

A more elaborated and powerful use of `sync` is as a type qualifier for variables. When a variable is
declared as _sync_, a state that can be **_full_** or **_empty_** is associated with it.

To assign a new value to a _sync_ variable,  its state must be _empty_ (after the assignment operation is
completed, the state will be set as _full_). On the contrary, to read a value from a _sync_ variable, its
state must be _full_ (after the read operation is completed, the state will be set as _empty_ again).

```chpl
var x: sync int;
writeln('this is the main thread launching a new thread');
begin {
  for i in 1..10 do
	writeln('this is the new thread working: ', i);
	x.writeEF(2);   // write the value, state changes from Empty to Full
  writeln('New thread finished');
}
writeln('this is the main thread after launching new thread ... I will wait until x is full');
x.readFE();         // read the value, state changes from Full to Empty
writeln('and now it is done');
```
```sh
chpl sync2.chpl -o sync2
sed -i -e 's|sync1|sync2|' shared.sh
sbatch shared.sh
cat solution.out
```
```
this is main thread launching a new thread
this is main thread after launching new thread ... I will wait until x is full
this is new thread working: 1
this is new thread working: 2
this is new thread working: 3
this is new thread working: 4
this is new thread working: 5
this is new thread working: 6
this is new thread working: 7
this is new thread working: 8
this is new thread working: 9
this is new thread working: 10
New thread finished
and now it is done
```

Here the main thread does not continue until the variable is full and can be read.

* Let's add another line `x.readFE();` -- now it is stuck since we cannot read `x` while it's empty!
* Let's add `x.writeEF(5);` right before the last `x.readFE();` -- now we set is to full again (and assigned 5),
  and it can be read again.

There are a number of methods defined for _sync_ variables. Suppose _x_ is a sync variable of a given type:

```chpl
// general methods
x.reset() - set the state as empty and the value as the default of x's type
x.isfull() - return true is the state of x is full, false if it is empty

// blocking read and write methods
x.writeEF(value) - block until the state of x is empty, then assign the value and
                   set the state to full
x.writeFF(value) - block until the state of x is full, then assign the value and
                   leave the state as full
x.readFE() - block until the state of x is full, then return x's value and set
             the state to empty
x.readFF() - block until the state of x is full, then return x's value and
             leave the state as full

// non-blocking read and write methods
x.writeXF(value) - assign the value no matter the state of x, then set the state as full
x.readXX() - return the value of x regardless its state; the state will remain unchanged
```

### Atomic variables

Chapel also implements **_atomic_** operations with variables declared as `atomic`, and this provides
another option to synchronize threads. Atomic operations run *completely independently of any other thread
or process*. This means that when several threads try to write an atomic variable, only one will succeed at
a given moment, providing implicit synchronization between them. There is a number of methods defined for
atomic variables, among them `sub()`, `add()`, `write()`, `read()`, and `waitfor()` are very useful to
establish explicit synchronization between threads, as shown in the next code `atomic.chpl`:

```chpl
var lock: atomic int;
const numthreads = 5;

lock.write(0);               // the main thread set lock to zero

coforall id in 1..numthreads {
  writeln('greetings form thread ', id, '... I am waiting for all threads to say hello');
  lock.add(1);               // thread id says hello and atomically adds 1 to lock
  lock.waitFor(numthreads);  // then it waits for lock to be equal numthreads (which will happen when all threads say hello)
  writeln('thread ', id, ' is done ...');
}
```
```sh
chpl atomic.chpl -o atomic
sed -i -e 's|sync2|atomic|' shared.sh
sbatch shared.sh
cat solution.out
```
```
greetings form thread 4... I am waiting for all threads to say hello
greetings form thread 5... I am waiting for all threads to say hello
greetings form thread 2... I am waiting for all threads to say hello
greetings form thread 3... I am waiting for all threads to say hello
greetings form thread 1... I am waiting for all threads to say hello
thread 1 is done...
thread 5 is done...
thread 2 is done...
thread 3 is done...
thread 4 is done...
```

> ## Try this...
> Comment out the line `lock.waitfor(numthreads)` in the code above to clearly observe the effect of the
> thread synchronization.

Finally, with all the material studied so far, we should be ready to parallelize our code for the
simulation of the heat transfer equation.

## Parallelizing the heat transfer equation

**Important:** In a one-day Chapel course, we suggest skipping to [data parallelism](../chapel-03-domain-parallelism)
(next session) and coming back here only if/when you have time.

Here is our plan to task-parallelize the heat transfer equation:

1. divide the entire grid of points into blocks and assign blocks to individual threads,
1. each thread should compute the new temperature of its assigned points,
1. perform a **_reduction_** over the whole grid, to update the greatest temperature difference between
   `Tnew` and `T`.

For the reduction of the grid we can simply use the `max reduce` statement, which is already parallelized. Now, let's
divide the grid into `rowthreads` * `colthreads` subgrids, and assign each subgrid to a thread using the `coforall` loop
(we will have `rowthreads * colthreads` threads in total).

Recall out code `gmax.chpl` in which we broke the 1D array with 1e8 elements into `numthreads=2` blocks, and each thread
was processing elements `start..finish`. Now we'll do exactly the same in 2D. First, let's write a quick serial code
`test.chpl` to test the indices:

```chpl
config const rows, cols = 100;               // number of rows and columns in our matrix

config const rowthreads = 3, colthreads = 4; // number of blocks in x- and y-dimensions
// each block processed by a separate thread
// let's pretend we have 12 cores

const nr = rows / rowthreads;   // number of rows per thread
const rr = rows % rowthreads;   // remainder rows (did not fit into the last row of threads)
const nc = cols / colthreads;   // number of columns per thread
const rc = cols % colthreads;   // remainder columns (did not fit into the last column of threads)

coforall threadid in 0..colthreads*rowthreads-1 do {
  var row1, row2, col1, col2: int;
  row1 = threadid/colthreads*nr + 1;
  row2 = threadid/colthreads*nr + nr;
  if row2 == rowthreads*nr then row2 += rr; // add rr rows to the last row of threads
  col1 = threadid%colthreads*nc + 1;
  col2 = threadid%colthreads*nc + nc;
  if col2 == colthreads*nc then col2 += rc; // add rc columns to the last column of threads
  writeln('thread ', threadid, ': rows ', row1, '-', row2, ' and columns ', col1, '-', col2);
}
```
```sh
chpl test.chpl -o test
sed -i -e 's|atomic|test|' shared.sh
sbatch shared.sh
cat solution.out
```
```
thread 0: rows 1-33 and columns 1-25
thread 1: rows 1-33 and columns 26-50
thread 2: rows 1-33 and columns 51-75
thread 3: rows 1-33 and columns 76-100
thread 4: rows 34-66 and columns 1-25
thread 5: rows 34-66 and columns 26-50
thread 6: rows 34-66 and columns 51-75
thread 7: rows 34-66 and columns 76-100
thread 8: rows 67-100 and columns 1-25
thread 9: rows 67-100 and columns 26-50
thread 10: rows 67-100 and columns 51-75
thread 11: rows 67-100 and columns 76-100
```

As you can see, dividing `Tnew` computation between concurrent threads could be cumbersome. Chapel provides
high-level abstractions for data parallelism that take care of all the data distribution for us. We will
study data parallelism in the following lessons, but for now let's compare the benchmark solution
(`baseSolver.chpl`) with our `coforall` parallelization to see how the performance improved.

Now we'll parallelize our heat transfer solver. Let's copy `baseSolver.chpl` into `parallel1.chpl` and
then start editing the latter. We'll make the following changes in `parallel1.chpl`:

```sh
diff baseSolver.chpl parallel1.chpl
18a19,24
> config const rowthreads = 3, colthreads = 4;   // let's pretend we have 12 cores
> const nr = rows / rowthreads;    // number of rows per thread
> const rr = rows - nr*rowthreads; // remainder rows (did not fit into the last thread)
> const nc = cols / colthreads;    // number of columns per thread
> const rc = cols - nc*colthreads; // remainder columns (did not fit into the last thread)
>
31,32c37,46
<   for i in 1..rows do {    // do smth for row i
<     for j in 1..cols do {  // do smth for row i and column j
<       Tnew[i,j] = 0.25 * (T[i-1,j] + T[i+1,j] + T[i,j-1] + T[i,j+1]);
<     }
<   }
---
>   coforall threadid in 0..colthreads*rowthreads-1 do { // each iteration processed by a separate thread
>     var row1, row2, col1, col2: int;
>     row1 = threadid/colthreads*nr + 1;
>     row2 = threadid/colthreads*nr + nr;
>     if row2 == rowthreads*nr then row2 += rr; // add rr rows to the last row of threads
>     col1 = threadid%colthreads*nc + 1;
>     col2 = threadid%colthreads*nc + nc;
>     if col2 == colthreads*nc then col2 += rc; // add rc columns to the last column of threads
>     for i in row1..row2 do {
>       for j in col1..col2 do {
>         Tnew[i,j] = 0.25 * (T[i-1,j] + T[i+1,j] + T[i,j-1] + T[i,j+1]);
>       }
>     }
>   }
>
36,42d49
<   delta = 0;
<   for i in 1..rows do {
<     for j in 1..cols do {
<       tmp = abs(Tnew[i,j]-T[i,j]);
<       if tmp > delta then delta = tmp;
<     }
<   }
43a51,52
>   delta = max reduce abs(Tnew[1..rows,1..cols]-T[1..rows,1..cols]);
```

Let's compile and run both codes on the same large problem:

```sh
chpl --fast baseSolver.chpl -o baseSolver
sed -i -e 's|test|baseSolver --rows=650 --iout=200 --niter=10_000 --tolerance=0.002 --nout=1000|' shared.sh
sbatch shared.sh
cat solution.out
Working with a matrix 650x650 to 10000 iterations or dT below 0.002
Temperature at iteration 0: 25.0
Temperature at iteration 1000: 25.0
Temperature at iteration 2000: 25.0
Temperature at iteration 3000: 25.0
Temperature at iteration 4000: 24.9998
Temperature at iteration 5000: 24.9984
Temperature at iteration 6000: 24.9935
Temperature at iteration 7000: 24.9819
Final temperature at the desired position [200,300] after 7750 iterations is: 24.9671
The largest temperature difference was 0.00199985
The simulation took 8.96548 seconds

chpl --fast parallel1.chpl -o parallel1
sed -i -e 's|baseSolver|parallel1|' shared.sh
sbatch shared.sh
cat solution.out
Working with a matrix 650x650 to 10000 iterations or dT below 0.002
Temperature at iteration 0: 25.0
Temperature at iteration 1000: 25.0
Temperature at iteration 2000: 25.0
Temperature at iteration 3000: 25.0
Temperature at iteration 4000: 24.9998
Temperature at iteration 5000: 24.9984
Temperature at iteration 6000: 24.9935
Temperature at iteration 7000: 24.9819
Final temperature at the desired position [200,300] after 7750 iterations is: 24.9671
The largest temperature difference was 0.00199985
The simulation took 25.106 seconds
```

Both ran to 7750 iterations, with the same numerical results, but the parallel code is nearly 3X slower
-- that's terrible!

> ## Discussion
> What happened!?...

To understand the reason, let's analyze the code. When the program starts, the main thread does all the declarations and
initializations, and then, it enters the main loop of the simulation (the **_while_** loop). Inside this loop, the
parallel threads are launched for the first time. When these threads finish their computations, the main thread resumes
its execution, it updates `delta` and T, and everything is repeated again. So, in essence, parallel threads are launched
and terminated 7750 times, which introduces a significant amount of overhead (the time the system needs to effectively
start and destroy threads in the specific hardware, at each iteration of the while loop).

Clearly, a better approach would be to launch the parallel threads just once, and have them execute all the
time steps, before resuming the main thread to print the final results.

Let's copy `parallel1.chpl` into `parallel2.chpl` and then start editing the latter. We'll make the
following changes:

(1) Move the rows

```chpl
  coforall threadid in 0..colthreads*rowthreads-1 do { // each iteration processed by a separate thread
	var row1, row2, col1, col2: int;
	row1 = threadid/colthreads*nr + 1;
	row2 = threadid/colthreads*nr + nr;
	if row2 == rowthreads*nr then row2 += rr; // add rr rows to the last row of threads
	col1 = threadid%colthreads*nc + 1;
	col2 = threadid%colthreads*nc + nc;
	if col2 == colthreads*nc then col2 += rc; // add rc columns to the last column of threads
```

and the corresponding closing bracket `}` of this `coforall` loop outside the `while` loop, so that
`while` is now nested inside `coforall`.

(2) Since now copying Tnew into T is a local operation for each thread, i.e. we should replace `T = Tnew;`
with

```chpl
T[row1..row2,col1..col2] = Tnew[row1..row2,col1..col2];
```

But this is not sufficient! We need to make sure we finish computing all elements of Tnew in all threads
before computing the greatest temperature difference `delta`. For that we need to synchronize all threads,
right after computing Tnew. We'll also need to synchronize threads after computing `delta` and T from Tnew,
as none of the threads should jump into the new iteration without having `delta` and T! So, we need two
synchronization points inside the `coforall` loop.

<!-- The synchronization must happen at two points:  -->
<!-- 1. We need to be sure that all threads have finished with the computations of their part of the grid `temp`, before updating `delta` and `past_temp` safely. -->
<!-- 2. We need to be sure that all threads use the updated value of `delta` to evaluate the condition of the while loop for the next iteration. -->

> ### Exercise "Task.4"
> Recall our earlier code `atomic.chpl`:
> ```chpl
> var lock: atomic int;
> const numthreads = 5;
> lock.write(0);                // the main thread set lock to zero
> coforall id in 1..numthreads {
>   writeln('greetings form thread ', id, '... I am waiting for all threads to say hello');
>   lock.add(1);               // thread id says hello and atomically adds 1 to lock
>   lock.waitFor(numthreads);  // then it waits for lock to be equal numthreads (which will happen when all threads say hello)
>   writeln('thread ', id, ' is done ...');
> }
> ```
> Suppose we want to add another synchronization point right after the last `writeln()` command. What is
> wrong with adding the following at the end of the `coforall` loop?
> ```chpl
>   lock.sub(1);      // thread id says hello and atomically subtracts 1 from lock
>   lock.waitFor(0);  // then it waits for lock to be equal 0 (which will happen when all threads say hello)
>   writeln('thread ', id, ' is really done ...');
> ```

> ### Exercise "Task.5"
> Ok, then what is the solution if we want two synchronization points?

(3) Define two atomic variables that we'll use for synchronization

```chpl
var lock1, lock2: atomic int;
```

and add after the (i,j)-loops to compute Tnew the following:

```chpl
lock1.add(1);   // each thread atomically adds 1 to lock
lock1.waitFor(colthreads*rowthreads*count);   // then it waits for lock to be equal colthreads*rowthreads
```

and after `T[row1..row2,col1..col2] = Tnew[row1..row2,col1..col2];` the following:

```chpl
lock2.add(1);   // each thread atomically subtracts 1 from lock
lock2.waitFor(colthreads*rowthreads*count);   // then it waits for lock to be equal 0
```

Notice that we have a product `colthreads*rowthreads*count`, since lock1/lock2 will be incremented by all
threads at all iterations.

(4) Move `var count = 0: int;` into `coforall` so that it becomes a local variable for each thread. Also,
remove `count` instance (in `writeln()`) after `coforall` ends.

(5) Make `delta` atomic:

```chpl
var delta: atomic real;    // the greatest temperature difference between Tnew and T
...
delta.write(tolerance*10); // some safe initial large value
...
while (count < niter && delta.read() >= tolerance) do {
```

(6) Define an array of local delta's for each thread and use it to compute delta:

```chpl
var arrayDelta: [0..colthreads*rowthreads-1] real;
...
var tmp: real;  // inside coforall
...
tmp = 0;        // inside while
...
tmp = max(abs(Tnew[i,j]-T[i,j]),tmp);    // next line after Tnew[i,j] = ...
...
arrayDelta[threadid] = tmp;   // right after (i,j)-loop to compute Tnew[i,j]
...
if threadid == 0 then {       // compute delta right after lock1.waitFor()
	delta.write(max reduce arrayDelta);
	if count%nout == 0 then writeln('Temperature at iteration ', count, ': ', Tnew[iout,jout]);
}
```

(7) Remove the original T[iout,jout] output line.

(8) Finally, move the boundary conditions (right+bottom edges) before the `while` loop. Why can we do it now?

Now let's compare the performance of `parallel2.chpl` to the benchmark serial solution `baseSolver.chpl`:

```sh
sed -i -e 's|parallel1|baseSolver|' shared.sh
sbatch shared.sh
cat solution.out
Working with a matrix 650x650 to 10000 iterations or dT below 0.002
Temperature at iteration 0: 25.0
Temperature at iteration 1000: 25.0
Temperature at iteration 2000: 25.0
Temperature at iteration 3000: 25.0
Temperature at iteration 4000: 24.9998
Temperature at iteration 5000: 24.9984
Temperature at iteration 6000: 24.9935
Temperature at iteration 7000: 24.9819
Final temperature at the desired position [200,300] after 7750 iterations is: 24.9671
The largest temperature difference was 0.00199985
The simulation took 9.40637 seconds

chpl --fast parallel2.chpl -o parallel2
sed -i -e 's|baseSolver|parallel2|' shared.sh
sbatch shared.sh
cat solution.out
Working with a matrix 650x650 to 10000 iterations or dT below 0.002
Temperature at iteration 0: 25.0
Temperature at iteration 1000: 25.0
Temperature at iteration 2000: 25.0
Temperature at iteration 3000: 25.0
Temperature at iteration 4000: 24.9998
Temperature at iteration 5000: 24.9984
Temperature at iteration 6000: 24.9935
Temperature at iteration 7000: 24.9819
Final temperature at the desired position [200,300] is: 24.9671
The largest temperature difference was 0.00199985
The simulation took 4.74536 seconds
```

We get a speedup of 2X on two cores, as we should.

Finally, here is a parallel scaling test on Cedar inside a 32-core interactive job:

```sh
./parallel2 ... --rowthreads=1 --colthreads=1
The simulation took 32.2201 seconds

./parallel2 ... --rowthreads=2 --colthreads=2
The simulation took 10.197 seconds

./parallel2 ... --rowthreads=4 --colthreads=4
The simulation took 3.79577 seconds

./parallel2 ... --rowthreads=4 --colthreads=8
The simulation took 2.4874 seconds
```

## Solutions

You can find the solutions [here](../../solutions-chapel).
