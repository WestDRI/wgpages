+++
title = "Task-parallelizing the heat transfer solver"
slug = "chapel-22-task-parallel-heat-transfer"
weight = 22
katex = true
+++

**Important:** In a shorter Chapel course, we suggest skipping this section and focus mostly on *data
parallelism*, coming back here only when you have time.

Here is our plan to task-parallelize the heat transfer equation:

1. divide the entire grid of points into blocks and assign blocks to individual tasks,
1. each task should compute the new temperature of its assigned points,
1. perform a **_reduction_** over the whole grid, to update the greatest temperature difference between `Tnew`
   and `T`.

For the reduction of the grid we can simply use the `max reduce` statement, which is already
parallelized. Now, let's divide the grid into `rowtasks` * `coltasks` subgrids, and assign each subgrid to a
task using the `coforall` loop (we will have `rowtasks * coltasks` tasks in total).

Recall out code `gmax.chpl` in which we broke the 1D array with 1e8 elements into `numtasks=2` blocks, and
each task was processing elements `start..finish`. Now we'll do exactly the same in 2D. First, let's write a
quick serial code `test.chpl` to test the indices:

```chpl
config const rows, cols = 100;               // number of rows and columns in our matrix

config const rowtasks = 3, coltasks = 4; // number of blocks in x- and y-dimensions
// each block processed by a separate task
// let's pretend we have 12 cores

const nr = rows / rowtasks;   // number of rows per task
const rr = rows % rowtasks;   // remainder rows (did not fit into the last row of tasks)
const nc = cols / coltasks;   // number of columns per task
const rc = cols % coltasks;   // remainder columns (did not fit into the last column of tasks)

coforall taskid in 0..coltasks*rowtasks-1 do {
  var row1, row2, col1, col2: int;
  row1 = taskid/coltasks*nr + 1;
  row2 = taskid/coltasks*nr + nr;
  if row2 == rowtasks*nr then row2 += rr; // add rr rows to the last row of tasks
  col1 = taskid%coltasks*nc + 1;
  col2 = taskid%coltasks*nc + nc;
  if col2 == coltasks*nc then col2 += rc; // add rc columns to the last column of tasks
  writeln('task ', taskid, ': rows ', row1, '-', row2, ' and columns ', col1, '-', col2);
}
```
```sh
$ chpl test.chpl -o test
$ sed -i -e 's|atomic|test|' shared.sh
$ sbatch shared.sh
$ cat solution.out
```
```output
task 0: rows 1-33 and columns 1-25
task 1: rows 1-33 and columns 26-50
task 2: rows 1-33 and columns 51-75
task 3: rows 1-33 and columns 76-100
task 4: rows 34-66 and columns 1-25
task 5: rows 34-66 and columns 26-50
task 6: rows 34-66 and columns 51-75
task 7: rows 34-66 and columns 76-100
task 8: rows 67-100 and columns 1-25
task 9: rows 67-100 and columns 26-50
task 10: rows 67-100 and columns 51-75
task 11: rows 67-100 and columns 76-100
```

As you can see, dividing `Tnew` computation between concurrent tasks could be cumbersome. Chapel provides
high-level abstractions for data parallelism that take care of all the data distribution for us. We will study
data parallelism in the following lessons, but for now let's compare the benchmark solution
(`baseSolver.chpl`) with our `coforall` parallelization to see how the performance improved.

Now we'll parallelize our heat transfer solver. Let's copy `baseSolver.chpl` into `parallel1.chpl` and then
start editing the latter. We'll make the following changes in `parallel1.chpl`:

```
diff baseSolver.chpl parallel1.chpl
18a19,24
> config const rowtasks = 3, coltasks = 4;   // let's pretend we have 12 cores
> const nr = rows / rowtasks;    // number of rows per task
> const rr = rows - nr*rowtasks; // remainder rows (did not fit into the last task)
> const nc = cols / coltasks;    // number of columns per task
> const rc = cols - nc*coltasks; // remainder columns (did not fit into the last task)
>
31,32c37,46
<   for i in 1..rows do {    // do smth for row i
<     for j in 1..cols do {  // do smth for row i and column j
<       Tnew[i,j] = 0.25 * (T[i-1,j] + T[i+1,j] + T[i,j-1] + T[i,j+1]);
<     }
<   }
---
>   coforall taskid in 0..coltasks*rowtasks-1 do { // each iteration processed by a separate task
>     var row1, row2, col1, col2: int;
>     row1 = taskid/coltasks*nr + 1;
>     row2 = taskid/coltasks*nr + nr;
>     if row2 == rowtasks*nr then row2 += rr; // add rr rows to the last row of tasks
>     col1 = taskid%coltasks*nc + 1;
>     col2 = taskid%coltasks*nc + nc;
>     if col2 == coltasks*nc then col2 += rc; // add rc columns to the last column of tasks
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
$ chpl --fast baseSolver.chpl -o baseSolver
$ sed -i -e 's|test|baseSolver --rows=650 --iout=200 --niter=10_000 --tolerance=0.002 --nout=1000|' shared.sh
$ sbatch shared.sh
$ cat solution.out
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

$ chpl --fast parallel1.chpl -o parallel1
$ sed -i -e 's|baseSolver|parallel1|' shared.sh
$ sbatch shared.sh
$ cat solution.out
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

> ### <font style="color:blue">Discussion</font>
> What happened!?...

To understand the reason, let's analyze the code. When the program starts, the main task does all the
declarations and initializations, and then, it enters the main loop of the simulation (the **_while_**
loop). Inside this loop, the parallel tasks are launched for the first time. When these tasks finish their
computations, the main task resumes its execution, it updates `delta` and T, and everything is repeated
again. So, in essence, parallel tasks are launched and terminated 7750 times, which introduces a significant
amount of overhead (the time the system needs to effectively start and destroy tasks in the specific hardware,
at each iteration of the while loop).

Clearly, a better approach would be to launch the parallel tasks just once, and have them execute all the time
steps, before resuming the main task to print the final results.

Let's copy `parallel1.chpl` into `parallel2.chpl` and then start editing the latter. We'll make the
following changes:

(1) Move the rows

```chpl
  coforall taskid in 0..coltasks*rowtasks-1 do { // each iteration processed by a separate task
	var row1, row2, col1, col2: int;
	row1 = taskid/coltasks*nr + 1;
	row2 = taskid/coltasks*nr + nr;
	if row2 == rowtasks*nr then row2 += rr; // add rr rows to the last row of tasks
	col1 = taskid%coltasks*nc + 1;
	col2 = taskid%coltasks*nc + nc;
	if col2 == coltasks*nc then col2 += rc; // add rc columns to the last column of tasks
```

and the corresponding closing bracket `}` of this `coforall` loop outside the `while` loop, so that
`while` is now nested inside `coforall`.

(2) Since now copying Tnew into T is a local operation for each task, i.e. we should replace `T = Tnew;` with

```chpl
T[row1..row2,col1..col2] = Tnew[row1..row2,col1..col2];
```

But this is not sufficient! We need to make sure we finish computing all elements of Tnew in all tasks before
computing the greatest temperature difference `delta`. For that we need to synchronize all tasks, right after
computing Tnew. We'll also need to synchronize tasks after computing `delta` and T from Tnew, as none of the
tasks should jump into the new iteration without having `delta` and T! So, we need two synchronization points
inside the `coforall` loop.

<!-- The synchronization must happen at two points:  -->
<!-- 1. We need to be sure that all tasks have finished with the computations of their part of the grid `temp`, before updating `delta` and `past_temp` safely. -->
<!-- 2. We need to be sure that all tasks use the updated value of `delta` to evaluate the condition of the while loop for the next iteration. -->

(3) Define two atomic variables that we'll use for synchronization

```chpl
var lock1, lock2: atomic int;
```

and add after the (i,j)-loops to compute Tnew the following:

```chpl
lock1.add(1);   // each task atomically adds 1 to lock
lock1.waitFor(coltasks*rowtasks*count);   // then it waits for lock to be equal coltasks*rowtasks
```

and after `T[row1..row2,col1..col2] = Tnew[row1..row2,col1..col2];` the following:

```chpl
lock2.add(1);   // each task atomically subtracts 1 from lock
lock2.waitFor(coltasks*rowtasks*count);   // then it waits for lock to be equal 0
```

Notice that we have a product `coltasks*rowtasks*count`, since lock1/lock2 will be incremented by all tasks at
all iterations.

(4) Move `var count = 0: int;` into `coforall` so that it becomes a local variable for each task. Also, remove
`count` instance (in `writeln()`) after `coforall` ends.

(5) Make `delta` atomic:

```chpl
var delta: atomic real;    // the greatest temperature difference between Tnew and T
...
delta.write(tolerance*10); // some safe initial large value
...
while (count < niter && delta.read() >= tolerance) do {
```

(6) Define an array of local delta's for each task and use it to compute delta:

```chpl
var arrayDelta: [0..coltasks*rowtasks-1] real;
...
var tmp: real;  // inside coforall
...
tmp = 0;        // inside while
...
tmp = max(abs(Tnew[i,j]-T[i,j]),tmp);    // next line after Tnew[i,j] = ...
...
arrayDelta[taskid] = tmp;   // right after (i,j)-loop to compute Tnew[i,j]
...
if taskid == 0 then {       // compute delta right after lock1.waitFor()
	delta.write(max reduce arrayDelta);
	if count%nout == 0 then writeln('Temperature at iteration ', count, ': ', Tnew[iout,jout]);
}
```

(7) Remove the original T[iout,jout] output line.

(8) Finally, move the boundary conditions (right+bottom edges) before the `while` loop. Why can we do it now?

Now let's compare the performance of `parallel2.chpl` to the benchmark serial solution `baseSolver.chpl`:

```sh
$ sed -i -e 's|parallel1|baseSolver|' shared.sh
$ sbatch shared.sh
$ cat solution.out
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

$ chpl --fast parallel2.chpl -o parallel2
$ sed -i -e 's|baseSolver|parallel2|' shared.sh
$ sbatch shared.sh
$ cat solution.out
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
$ ./parallel2 ... --rowtasks=1 --coltasks=1
The simulation took 32.2201 seconds

$ ./parallel2 ... --rowtasks=2 --coltasks=2
The simulation took 10.197 seconds

$ ./parallel2 ... --rowtasks=4 --coltasks=4
The simulation took 3.79577 seconds

$ ./parallel2 ... --rowtasks=4 --coltasks=8
The simulation took 2.4874 seconds
```
