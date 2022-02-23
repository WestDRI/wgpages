+++
title = "Solutions for Chapel course"
slug = "solutions-chapel"
+++

## Part 1: basic language features
### Solution to Exercise 1

To see the evolution of the temperature at the top right corner of the plate, we just need to modify `iout` and
`jout`. This corner correspond to the first row (`iout=1`) and the last column (`jout=cols`) of the plate.

```sh
$ chpl baseSolver.chpl -o baseSolver
$ sbatch serial.sh
$ tail -f solution.out
```
```
Temperature at iteration 0: 25.0
Temperature at iteration 20: 1.48171
Temperature at iteration 40: 0.767179
...
Temperature at iteration 460: 0.068973
Temperature at iteration 480: 0.0661081
Temperature at iteration 500: 0.0634717
```

### Solution to Exercise 2

To get the linear distribution, the 80 degrees must be divided by the number of rows or columns in our
plate. So, the following couple of for loops at the start of time iteration will give us what we want:

```chpl
// boundary conditions
for i in 1..rows do
  T[i,cols+1] = i*80.0/rows;   // right side
for j in 1..cols do
  T[rows+1,j] = j*80.0/cols;   // bottom side
```
Note that 80 degrees is written as a real
number 80.0. The division of integers in Chapel returns an integer, then, as `rows` and `cols` are
integers, we must have 80 as real so that the result is not truncated.

```sh
$ chpl baseSolver.chpl -o baseSolver
$ sbatch serial.sh
$ tail -f solution.out
```
```
Temperature at iteration 0: 25.0
Temperature at iteration 20: 2.0859
Temperature at iteration 40: 1.42663
...
Temperature at iteration 460: 0.826941
Temperature at iteration 480: 0.824959
Temperature at iteration 500: 0.823152
```

### Solution to Exercise 3

The idea is simple: after each iteration of the while loop, we must compare all elements of `Tnew` and `T`, find the
greatest difference, and update `delta` with that value. The following nested `for` loops should do the job:

```chpl
// update delta, the greatest difference between Tnew and T
delta = 0;
for i in 1..rows do {
  for j in 1..cols do {
    tmp = abs(Tnew[i,j] - T[i,j]);
    if tmp > delta then delta = tmp;
  }
}
```
Clearly there is no need to keep the difference at every single position in the array, we just need to
update `delta` if we find a greater one.

```sh
$ chpl baseSolver.chpl -o baseSolver
$ sbatch serial.sh
$ tail -f solution.out
```
```
Temperature at iteration 0: 25.0
Temperature at iteration 20: 2.0859
Temperature at iteration 40: 1.42663
...
Temperature at iteration 460: 0.826941
Temperature at iteration 480: 0.824959
Temperature at iteration 500: 0.823152
```

### Solution to Exercise 4

For example, lets use a 650 x 650 grid and observe the evolution of the temperature at the position (200,300) for 10000
iterations or until the difference of temperature between iterations is less than 0.002; also, let's print the
temperature every 1000 iterations.

```sh
$ chpl --fast baseSolver.chpl -o baseSolver
$ ./baseSolver --rows=650 --cols=650 --iout=200 --jout=300 --niter=10000 --tolerance=0.002 --nout=1000
```
```
Temperature at iteration 0: 25.0
Temperature at iteration 1000: 25.0
Temperature at iteration 2000: 25.0
Temperature at iteration 3000: 25.0
Temperature at iteration 4000: 24.9998
Temperature at iteration 5000: 24.9984
Temperature at iteration 6000: 24.9935
Temperature at iteration 7000: 24.9819
Final temperature at the desired position after 7750 iterations is: 24.9671
The greatest difference in temperatures between the last two iterations was: 0.00199985
```

### Solution to Exercise 5

Without `--fast` the calculation will become slower by ~95X.

## Part 2: task parallelism

### Solution to Exercise 6

The following code is a possible solution:

```chpl
var x = 1;
config var numthreads = 2;
var messages: [1..numthreads] string;
writeln('This is the main thread: x = ', x);
coforall threadid in 1..numthreads do {
  var c = threadid**2;
  messages[threadid] = 'this is thread ' + threadid:string + ': my value of c is ' + c:string + ' and x is ' + x:string;  // add to a string
}
writeln('This message will not appear until all threads are done ...');
for i in 1..numthreads do  // serial loop, will be printed in sequential order
  writeln(messages[i]);
```
```sh
$ chpl exercise1.chpl -o exercise1
$ sed -i -e 's|coforall --numthreads=5|exercise1 --numthreads=5|' shared.sh
$ sbatch shared.sh
$ cat solution.out
```
```
This is the main thread: x = 10
This message will not appear until all threads are done ...
this is thread 1: my value of c is 1 and x is 10
this is thread 2: my value of c is 4 and x is 10
this is thread 3: my value of c is 9 and x is 10
this is thread 4: my value of c is 16 and x is 10
this is thread 5: my value of c is 25 and x is 10
```

### Solution to Exercise 7

```chpl
config const numthreads = 12;     // let's pretend we have 12 cores
const n = nelem / numthreads;     // number of elements per thread
const r = nelem - n*numthreads;   // these did not fit into the last thread
var lmax: [1..numthreads] real;   // local maximum for each thread

coforall threadid in 1..numthreads do {   // each iteration processed by a separate thread
  var start, finish: int;
  start  = (threadid-1)*n + 1;
  finish = (threadid-1)*n + n;
  if threadid == numthreads then finish += r;    // add r elements to the last thread
  for i in start..finish do
    if x[i] > lmax[threadid] then lmax[threadid] = x[i];
 }

for threadid in 1..numthreads do     // no need for a parallel loop here
  if lmax[threadid] > gmax then gmax = lmax[threadid];

```
```sh
$ chpl --fast exercise2.chpl -o exercise2
$ sed -i -e 's|coforall --numthreads=5|exercise2|' shared.sh
$ sbatch shared.sh
$ cat solution.out
```
```
the maximum value in x is: 1.0
```

We use `coforall` to spawn threads that work concurrently in a fraction of the array. The trick here is to determine,
based on the _threadid_, the initial and final indices that the thread will use. Each thread obtains the maximum in its
fraction of the array, and finally, after the coforall is done, the main thread obtains the maximum of the array from
the maximums of all threads.

### Solution to Exercise 8

```chpl
var x = 0;
writeln('This is the main thread, my value of x is ', x);

sync {
  begin {
     var x = 5;
     writeln('this is thread 1, my value of x is ', x);
  }
  begin writeln('this is thread 2, my value of x is ', x);
}

writeln('this message will not appear until all threads are done...');
```

### Solution to Exercise 9

The code most likely will lock (although sometimes it might not), as we'll be hitting a race
condition. Refer to the diagram for explanation.

### Solution to Exercise 10

You need two separate locks, and for simplicity increment them both:

```chpl
var lock1, lock2: atomic int;
const numthreads = 5;
lock1.write(0);   // the main thread set lock to zero
lock2.write(0);   // the main thread set lock to zero
coforall id in 1..numthreads {
  writeln('greetings form thread ', id, '... I am waiting for all threads to say hello');
  lock1.add(1);              // thread id says hello and atomically adds 1 to lock
  lock1.waitFor(numthreads);   // then it waits for lock=numthreads (which will happen when all threads say hello)
  writeln('thread ', id, ' is done ...');
  lock2.add(1);
  lock2.waitFor(numthreads);
  writeln('thread ', id, ' is really done ...');
}
```

## Part 3: data parallelism

### Solution to Exercise 11

Change the line

```chpl
for i in 1..n {
```

to

```chpl
forall i in 1..n with (+ reduce total) {
```

### Solution to Exercise 12

Run the code with

```sh
$ ./test -nl 4 --n=3
$ ./test -nl 4 --n=20
```

For n=3 we get fewer threads (7 in my case), for n=20 we still get 12 threads (the maximum available number of cores
inside our job).

### Solution to Exercise 13

Something along the lines of `m = here.id:string + '-' + m.locale.id:string;` should work.

In most cases `m.locale.id` should be the same as `here.id` (computation follows data distribution).

### Solution to Exercise 14

It should be `forall (i,j) in largerMesh[1..rows,1..cols] do` (run on multiple locales in parallel) instead of
`forall (i,j) in mesh do` (run in parallel on locale 0 only).

Another possible solution is `forall (i,j) in Tnew.domain[1..rows,1..cols] do` (run on multiple locales in parallel).

Also, we cannot have `forall (i,j) in largerMesh do` (run in parallel on multiple locales) as this would overwrite the
boundaries.

### Solution to Exercise 15

Just before temperature output (if count%nout == 0), insert the following:

```chpl
  var total = 0.0;
  forall (i,j) in largerMesh[1..rows,1..cols] with (+ reduce total) do
    total += T[i,j];
```

and add total to the temperature output. It is decreasing as energy is leaving the system:

```sh
$ chpl --fast parallel3.chpl -o parallel3
$ ./parallel3 -nl 1 --rows=30 --cols=30 --niter=2000   # run this from inside distributed.sh
Temperature at iteration 0: 25.0
Temperature at iteration 20: 3.49566   21496.5
Temperature at iteration 40: 2.96535   21052.6
...
Temperature at iteration 1100: 2.5809   18609.5
Temperature at iteration 1120: 2.58087   18608.6
Temperature at iteration 1140: 2.58085   18607.7
Final temperature at the desired position [1,30] after 1148 iterations is: 2.58084
The largest temperature difference was 9.9534e-05
The simulation took 0.114942 seconds
```

### Solution to Exercise 16

Here is one possible solution examining the locality of the finite-difference stencil:

```chpl
var message: [largerMesh] string = 'empty';
```

and in the next line after computing Tnew[i,j] put

```chpl
    message[i,j] = "%i".format(here.id) + message[i,j].locale.id + message[i-1,j].locale.id +
      message[i+1,j].locale.id + message[i,j-1].locale.id + message[i,j+1].locale.id + '  ';
```

and before the end of the `while` loop

```chpl
  writeln(message);
  assert(1>2);
```

Then run it

```sh
$ chpl --fast parallel3.chpl -o parallel3
$ ./parallel3 -nl 4 --rows=8 --cols=8   # run this from inside distributed.sh
```
