+++
title = "Heat transfer solver on distributed domains"
slug = "chapel-16-distributed-heat-transfer"
weight = 16
katex = true
+++

Now let us use distributed domains to write a parallel version of our original heat transfer solver
code. We'll start by copying `baseSolver.chpl` into `parallel.chpl` and making the following
modifications to the latter:

(1) Add

```chpl
use BlockDist;
const mesh: domain(2) = {1..rows, 1..cols};   // local 2D domain
```

(2) Add a larger (n+2)^2 block-distributed domain `largerMesh` with a layer of *ghost points* on
*perimeter locales*, and define a temperature array T on top of it, by adding the following to our code:

```chpl
const largerMesh: domain(2) dmapped Block(boundingBox=mesh) = {0..rows+1, 0..cols+1};
```

(3) Change the definitions of T and Tnew (delete those two lines) to

```chpl
var T, Tnew: [largerMesh] real;   // block-distributed arrays of temperatures
```

<!-- Here we initialized an initial Gaussian temperature peak in the middle of the mesh. As we evolve our -->
<!-- solution in time, this peak should diffuse slowly over the rest of the domain. -->

<!-- > ## Question -->
<!-- > Why do we have   -->
<!-- > forall (i,j) in T.domain[1..n,1..n] {   -->
<!-- > and not   -->
<!-- > forall (i,j) in mesh -->
<!-- >> ## Answer -->
<!-- >> The first one will run on multiple locales in parallel, whereas the -->
<!-- >> second will run in parallel via multiple threads on locale 0 only, since -->
<!-- >> "mesh" is defined on locale 0. -->

<!-- The code above will print the initial temperature distribution: -->

<!-- ``` -->
<!-- 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0   -->
<!-- 0.0 2.36954e-17 2.79367e-13 1.44716e-10 3.29371e-09 3.29371e-09 1.44716e-10 2.79367e-13 2.36954e-17 0.0   -->
<!-- 0.0 2.79367e-13 3.29371e-09 1.70619e-06 3.88326e-05 3.88326e-05 1.70619e-06 3.29371e-09 2.79367e-13 0.0   -->
<!-- 0.0 1.44716e-10 1.70619e-06 0.000883826 0.0201158 0.0201158 0.000883826 1.70619e-06 1.44716e-10 0.0   -->
<!-- 0.0 3.29371e-09 3.88326e-05 0.0201158 0.457833 0.457833 0.0201158 3.88326e-05 3.29371e-09 0.0   -->
<!-- 0.0 3.29371e-09 3.88326e-05 0.0201158 0.457833 0.457833 0.0201158 3.88326e-05 3.29371e-09 0.0   -->
<!-- 0.0 1.44716e-10 1.70619e-06 0.000883826 0.0201158 0.0201158 0.000883826 1.70619e-06 1.44716e-10 0.0   -->
<!-- 0.0 2.79367e-13 3.29371e-09 1.70619e-06 3.88326e-05 3.88326e-05 1.70619e-06 3.29371e-09 2.79367e-13 0.0   -->
<!-- 0.0 2.36954e-17 2.79367e-13 1.44716e-10 3.29371e-09 3.29371e-09 1.44716e-10 2.79367e-13 2.36954e-17 0.0   -->
<!-- 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0   -->
<!-- ``` -->

Let us define an array of strings `message` with the same distribution over locales as T, by adding the
following to our code:

```chpl
var message: [largerMesh] string;
forall m in message do
  m = here.id:string;   // store ID of the locale on which the code is running
writeln(message);
halt();
```
```sh
$ chpl -o parallel parallel.chpl
$ ./parallel -nl 3 --rows=8 --cols=8   # run this from inside distributed.sh
```

The outer perimeter in the partition below are the *ghost points*, with the inner 8x8 array:

```txt
0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0
0 0 0 0 0 0 0 0 0 0
1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1
1 1 1 1 1 1 1 1 1 1
2 2 2 2 2 2 2 2 2 2
2 2 2 2 2 2 2 2 2 2
2 2 2 2 2 2 2 2 2 2
```

> With 4 locales, we might see something like this:
> ```txt
> 0 0 0 0 0 1 1 1 1 1
> 0 0 0 0 0 1 1 1 1 1
> 0 0 0 0 0 1 1 1 1 1
> 0 0 0 0 0 1 1 1 1 1
> 0 0 0 0 0 1 1 1 1 1
> 2 2 2 2 2 3 3 3 3 3
> 2 2 2 2 2 3 3 3 3 3
> 2 2 2 2 2 3 3 3 3 3
> 2 2 2 2 2 3 3 3 3 3
> 2 2 2 2 2 3 3 3 3 3
> ```

> ### <font style="color:blue">Exercise "Data.3"</font>
> In addition to here.id, also print the ID of the locale holding that value. Is it the same or different
> from `here.id`?

(4) Let's comment out this `message` part, and start working on the parallel solver.

(5) Move the linearly increasing boundary conditions (right/bottom sides) before the `while` loop.

(6) Replace the loop for computing *inner* `Tnew`:

```chpl
for i in 1..rows do {  // do smth for row i
  for j in 1..cols do {   // do smth for row i and column j
	Tnew[i,j] = 0.25 * (T[i-1,j] + T[i+1,j] + T[i,j-1] + T[i,j+1]);
  }
}
```

with a parallel `forall` loop (**contains a mistake on purpose!**):

```chpl
forall (i,j) in mesh do
  Tnew[i,j] = 0.25 * (T[i-1,j] + T[i+1,j] + T[i,j-1] + T[i,j+1]);
```

> ### <font style="color:blue">Exercise "Data.4"</font>
> Can anyone spot a mistake in this loop?

(7) Replace

```chpl
delta = 0;
for i in 1..rows do {
  for j in 1..cols do {
	tmp = abs(Tnew[i,j]-T[i,j]);
	if tmp > delta then delta = tmp;
  }
}
```

with

```chpl
delta = max reduce abs(Tnew[1..rows,1..cols]-T[1..rows,1..cols]);
```

(8) Replace

```chpl
T = Tnew;
```

with the **inner-only** update

```chpl
T[1..rows,1..cols] = Tnew[1..rows,1..cols];   // uses parallel `forall` underneath
```

## Benchmarking

Let's compile both serial and data-parallel versions using the same multi-locale compiler (and we will
need `-nl` flag when running both):

```sh
$ which chpl
/project/60303/shared/c3/chapel-1.24.1/bin/linux64-x86_64/chpl
$ chpl --fast baseSolver.chpl -o baseSolver
$ chpl --fast parallel.chpl -o parallel
```

First, let's try this on a smaller problem. Let's write two job submission scripts:

```sh
#!/bin/bash
# this is baseSolver.sh
#SBATCH --time=0:5:0         # walltime in d-hh:mm or hh:mm:ss format
#SBATCH --mem-per-cpu=1000   # in MB
#SBATCH --output=baseSolver.out
./baseSolver -nl 1 --rows=30 --cols=30 --niter=2000
```

```sh
#!/bin/bash
# this is parallel.sh
#SBATCH --time=0:5:0         # walltime in d-hh:mm or hh:mm:ss format
#SBATCH --mem-per-cpu=1000   # in MB
#SBATCH --nodes=3
#SBATCH --cpus-per-task=2
#SBATCH --output=parallel.out
./parallel -nl 3 --rows=30 --cols=30 --niter=2000
```

Let's run them both:

```sh
$ sbatch baseSolver.sh
$ sbatch parallel.sh
```

Wait for the jobs to finish and then check the results:

```sh
$ tail -3 baseSolver.out
Final temperature at the desired position [1,30] after 1148 iterations is: 2.58084
The largest temperature difference was 9.9534e-05
The simulation took 0.008524 seconds

$ tail -3 parallel.out
Final temperature at the desired position [1,30] after 1148 iterations is: 2.58084
The largest temperature difference was 9.9534e-05
The simulation took 193.279 seconds
```

As you can see, on the training VM cluster the parallel code on 4 nodes (with 2 cores each) ran ~22,675
times slower than a serial code on a single node ... What is going on here!? Shouldn't the parallel code
run ~8X faster, since we have 8X as many processors?

This is a **_fine-grained_** parallel code that needs lots of communication between tasks, and relatively
little computing. So, we are seeing the **communication overhead**. The training cluster has a very slow
network, so the problem is exponentially worse there ...

If we increase the problem size, there will be more computation (scaling O(n^2)) in between
communications (scaling O(n)), and at some point parallel code should catch up to the serial code and
eventually run faster. Let's try these problem sizes:

```
--rows=650 --cols=650 --niter=9500 --tolerance=0.002
Final temperature at the desired position [1,650] after 7750 iterations is: 0.125606
The largest temperature difference was 0.00199985

--rows=2000 --cols=2000 --niter=9500 --tolerance=0.002
Final temperature at the desired position [1,2000] after 9140 iterations is: 0.04301
The largest temperature difference was 0.00199989

--rows=8000 --cols=8000 --niter=9800 --tolerance=0.002
Final temperature at the desired position [1,8000] after 9708 iterations is: 0.0131638
The largest temperature difference was 0.00199974

./baseSolver -nl 1 --rows=16000 --cols=16000 --niter=9900 --tolerance=0.002
Final temperature at the desired position [1,16000] after 9806 iterations is: 0.00818861
The largest temperature difference was 0.00199975
```

#### On the training cluster

I switched both codes to single precision, to be able to accommodate larger arrays. The table below shows the
**slowdown** factor when going from serial to parallel. For each row correspondingly, I was running the
following:

```sh
$ ./baseSolver --rows=2000 --niter=200 --tolerance=0.002
$ ./parallel -nl 4 --rows=2000 --niter=200 --tolerance=0.002
$ ./parallel -nl 6 --rows=2000 --niter=200 --tolerance=0.002
```

| | 30^2 | 650^2 | 2,000^2 | 16,000^2 |
| ----- | ----- | ----- | ----- | ----- |
| --nodes=4 --cpus-per-task=2 | 32,324 | 176 | 27.78 | 4.13 |
| --nodes=6 --cpus-per-task=16 | | | 15.3 | 1/5.7 |

#### On Graham (faster interconnect):

| | 30^2 | 650^2 | 2,000^2 | 8,000^2 |
| ----- | ----- | ----- | ----- | ----- |
| --nodes=4 --cpus-per-task=2 | 5,170 | 14 | 2.9 | 1.25 |
| --nodes=4 --cpus-per-task=4 | | | | 1/1.56 |
| --nodes=8 --cpus-per-task=4 | | | | 1/2.72 |

<!-- 16,000^2 on Graham: baseSolver 41,482s; parallel --nodes=4 --cpus-per-task=2 61,052s -->

<!-- on Cedar at 650^2 we have ~60X slowdown: 27.5408 seconds and 1658.34 seconds, respectively (bad Chapel build over OmniPath?) -->

<!-- with Chapel 1.17.0 on Graham 650^2 took 21.1198 seconds and 907.352 seconds, respectively -->

<!-- on Cedar 2000^2 baseSolver: The simulation took 469.298 seconds -->

<!-- on Graham 5000^2 took 3697.65 seconds and 6015.98 seconds, respectively -->

## Final parallel code

Here is the final version of the entire code, minus the comments:

```chpl
use Time, BlockDist;
config const rows = 100, cols = 100;
config const niter = 500;
config const iout = 1, jout = cols, nout = 20;
config const tolerance = 1e-4: real;
var count = 0: int;
const mesh: domain(2) = {1..rows, 1..cols};
const largerMesh: domain(2) dmapped Block(boundingBox=mesh) = {0..rows+1, 0..cols+1};
var delta: real;
var T, Tnew: [largerMesh] real;   // a block-distributed array of temperatures
T[1..rows,1..cols] = 25;   // the initial temperature
writeln('Working with a matrix ', rows, 'x', cols, ' to ', niter, ' iterations or dT below ', tolerance);
for i in 1..rows do T[i,cols+1] = 80.0*i/rows;   // right-side boundary
for j in 1..cols do T[rows+1,j] = 80.0*j/cols;   // bottom-side boundary
writeln('Temperature at iteration ', 0, ': ', T[iout,jout]);
delta = tolerance*10;   // some safe initial large value
var watch: stopwatch;
watch.start();
while (count < niter && delta >= tolerance) do {
  count += 1;
  forall (i,j) in largerMesh[1..rows,1..cols] do
	Tnew[i,j] = 0.25 * (T[i-1,j] + T[i+1,j] + T[i,j-1] + T[i,j+1]);
  delta = max reduce abs(Tnew[1..rows,1..cols]-T[1..rows,1..cols]);
  T[1..rows,1..cols] = Tnew[1..rows,1..cols];
  if count%nout == 0 then writeln('Temperature at iteration ', count, ': ', T[iout,jout]);
 }
watch.stop();
writeln('Final temperature at the desired position [', iout,',', jout, '] after ', count, ' iterations is: ', T[iout,jout]);
writeln('The largest temperature difference was ', delta);
writeln('The simulation took ', watch.elapsed(), ' seconds');
```

This is the entire multi-locale, data-parallel, hybrid shared-/distributed-memory solver!

> ### <font style="color:blue">Exercise "Data.5"</font>
> Add printout to the code to show the total energy on the inner mesh [1..row,1..cols] at each
> iteration. Consider the temperature sum over all mesh points to be the total energy of the system. Is
> the total energy on the mesh conserved?

> ### <font style="color:blue">Exercise "Data.6"</font>
> Write a code to print how the finite-difference stencil [i,j], [i-1,j], [i+1,j], [i,j-1], [i,j+1] is
> distributed among nodes, and compare that to the ID of the node where T[i,i] is computed. Use problem
> size 8x8.

This produced the following output clearly showing the *ghost points* and the stencil distribution for
each mesh point:

```
empty empty empty empty empty empty empty empty empty empty
empty 000000   000000   000000   000001   111101   111111   111111   111111   empty
empty 000000   000000   000000   000001   111101   111111   111111   111111   empty
empty 000000   000000   000000   000001   111101   111111   111111   111111   empty
empty 000200   000200   000200   000201   111301   111311   111311   111311   empty
empty 220222   220222   220222   220223   331323   331333   331333   331333   empty
empty 222222   222222   222222   222223   333323   333333   333333   333333   empty
empty 222222   222222   222222   222223   333323   333333   333333   333333   empty
empty 222222   222222   222222   222223   333323   333333   333333   333333   empty
empty empty empty empty empty empty empty empty empty empty
```

* note that Tnew[i,j] is always computed on the same node where that element is stored
* note remote stencil points at the block boundaries

<!-- ## Periodic boundary conditions -->
<!-- Now let us modify the previous parallel solver to include periodic BCs. At the beginning of each time -->
<!-- step we need to set elements on the *ghost points* to their respective values on the *opposite ends*, by -->
<!-- adding the following to our code: -->
<!-- ``` -->
<!--   T[0,1..n] = T[n,1..n]; // periodic boundaries on all four sides; these will run via parallel forall -->
<!--   T[n+1,1..n] = T[1,1..n]; -->
<!--   T[1..n,0] = T[1..n,n]; -->
<!--   T[1..n,n+1] = T[1..n,1]; -->
<!-- ``` -->
<!-- Now total energy should be conserved, as nothing leaves the domain. -->

## I/O

Let us write the final solution to disk. Please note:

- here we'll write in ASCII (raw binary output is slightly more difficult to make portable) <!-- Chapel can also write
  binary data but nothing can read it (checked: not the endians problem!) -->
- a much better choice would be writing in NetCDF or HDF5 -- covered in our webinar
["Working with data files and external C libraries in Chapel"](https://westgrid.github.io/trainingMaterials/programming#working-with-data-files-and-external-c-libraries-in-chapel)
  - portable binary encoding (little vs. big endian byte order)
  - compression
  - random access
  - parallel I/O (partially implemented) -- see the HDF5 example in the webinar

Let's comment out all lines with `message` and `assert()`, and add the following at the end of our code to write ASCII:

```chpl
use IO;
var myFile = open('output.dat', iomode.cw);   // open the file for writing
var myWritingChannel = myFile.writer();   // create a writing channel starting at file offset 0
myWritingChannel.write(T);   // write the array
myWritingChannel.close();   // close the channel
```
```sh
$ chpl --fast parallel.chpl -o parallel
$ ./parallel -nl 3 --rows=8 --cols=8   # run this from inside distributed.sh
$ ls -l *dat
-rw-rw-r-- 1 razoumov razoumov 659 Mar  9 18:04 output.dat
```

The file *output.dat* should contain the 8x8 temperature array after convergence.

### Other I/O topics

* for binary I/O check https://chapel-lang.org/publications/ParCo-Larrosa.pdf
* writing arrays to NetCDF and HDF5 files from Chapel is covered in our
  [March 2020 webinar](https://bit.ly/3QnP1Pd)
<!-- * advanced take-home exercise: take a simple 2D or 3D non-linear problem, linearize it, implement a parallel -->
<!--   multi-locale linear solver entirely in Chapel -->
