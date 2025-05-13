+++
title = "Heat transfer solver on distributed domains"
slug = "chapel-16-distributed-heat-transfer"
weight = 16
katex = true
+++

## Case study 2: solving the **_Heat transfer_** problem

For a tightly coupled parallel calculation, consider a heat diffusion problem:

- we have a square metallic plate initially at 25 degrees (**_initial condition_**)
- we want to simulate the evolution of the temperature across the plate; governed by the 2D heat (diffusion)
  equation:
  {{< figure src="/img/heatEquation.png" width=400px >}}
- discretize the solution $T(x,y,t)\approx T^{(n)}_{i,j}$ with $i=1,...,{\rm rows}$ and $j=1,...,{\rm cols}$
  - the upper left corner is (1,1) and the lower right corner is (rows,cols)
- the plate's border is in contact with a different temperature distribution (**_boundary condition_**):
  - upper side $T^{(n)}_{0,1..{\rm cols}}\equiv 0$
  - left side $T^{(n)}_{1..{\rm rows},0}\equiv 0$
  - bottom side $T^{(n)}_{{\rm rows}+1,1..{\rm cols}} = {80\cdot j/\rm cols}$ (linearly increasing from 0 to
    80 degrees)
  - right side $T^{(n)}_{1..{\rm rows},{\rm cols}+1} = 80\cdot i/{\rm rows}$ (linearly increasing from 0 to 80
    degrees)

We discretize the equation with forward Euler time stepping:

{{< figure src="/img/discretizedHeatEquation1.png" width=800px >}}

If for simplicity we assume $\Delta x=\Delta y=1$ and $\Delta t=1/4$, our finite difference equation becomes:

{{< figure src="/img/discretizedHeatEquation2.png" width=600px >}}

At each time iteration, at each point we'll be computing the new temperature `Tnew` according to:

```chpl
Tnew[i,j] = 0.25 * (T[i-1,j] + T[i+1,j] + T[i,j-1] + T[i,j+1])
```

- `Tnew` = new temperature computed at the current iteration
- `T` = temperature calculated at the past iteration (or the initial conditions at the first iteration)
- the indices (i,j) indicate the grid point located at the i-th row and the j-th column

<!-- So, our objective is to: -->
<!-- 1. Write a code to implement the difference equation above. The code should: -->
<!--    - work for any given number of rows and columns in the grid, -->
<!--    - run for a given number of iterations, or until the difference between `Tnew` and `T` is smaller than a -->
<!--      given tolerance value, and -->
<!--    - output the temperature at a desired position on the grid every given number of iterations. -->
<!-- 1. Use task parallelism to improve the performance of the code and run it on a single cluster node. -->
<!-- 1. Use data parallelism to improve the performance of the code and run it on multiple cluster nodes using -->
<!--    hybrid parallelism. -->

Here is a serial implementation of this solver `baseSolver.chpl`:

```chpl
use Time;
config const rows, cols = 100;   // number of rows and columns in our matrix
config const niter = 500;        // max number of iterations
config const tolerance = 1e-4: real;   // temperature difference tolerance
var count = 0: int;                    // the iteration counter
var delta: real;   // the greatest temperature difference between Tnew and T
var tmp: real;     // for temporary results

var T: [0..rows+1,0..cols+1] real;
var Tnew: [0..rows+1,0..cols+1] real;
T[1..rows,1..cols] = 25;

delta = tolerance*10;    // some safe initial large value
var watch: stopwatch;
watch.start();
while (count < niter && delta >= tolerance) {
  for i in 1..rows do T[i,cols+1] = 80.0*i/rows;   // right side boundary condition
  for j in 1..cols do T[rows+1,j] = 80.0*j/cols;   // bottom side boundary condition
  count += 1;    // update the iteration counter
  for i in 1..rows {
    for j in 1..cols {
      Tnew[i,j] = 0.25 * (T[i-1,j] + T[i+1,j] + T[i,j-1] + T[i,j+1]);
    }
  }
  delta = 0;
  for i in 1..rows {
    for j in 1..cols {
      tmp = abs(Tnew[i,j]-T[i,j]);
      if tmp > delta then delta = tmp;
    }
  }
  if count%100 == 0 then writeln("delta = ", delta);
  T = Tnew;
}
watch.stop();

writeln('Largest temperature difference was ', delta);
writeln('Converged after ', count, ' iterations');
writeln('Simulation took ', watch.elapsed(), ' seconds');
```

```sh
chpl --fast baseSolver.chpl
./baseSolver --rows=650 --cols=650 --niter=9500 --tolerance=0.002
```
```output
Largest temperature difference was 0.00199985
Simulation took 17.3374 seconds
```




## Distributed version

Now let us use distributed domains to write a parallel version of our original heat transfer solver
code. We'll start by copying `baseSolver.chpl` into `parallelSolver.chpl` and making the following
modifications to the latter:

(1) Add

```chpl
use BlockDist;
const mesh: domain(2) = {1..rows, 1..cols};   // local 2D domain
```

(2) Add a larger $(rows+2)\times (cols+2)$ block-distributed domain `largerMesh` with a layer of *ghost points* on
*perimeter locales*, and define a temperature array T on top of it, by adding the following to our code:

```chpl
const largerMesh: domain(2) dmapped new blockDist(boundingBox=mesh) = {0..rows+1, 0..cols+1};
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

(4) Move the linearly increasing boundary conditions (right/bottom sides) before the `while` loop.

(5) Replace the loop for computing *inner* `Tnew`:

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

{{< question num="Data.4" >}}
Can anyone spot a mistake in this loop?
{{< /question >}}

(6) Replace

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

(7) Replace

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
$ source /project/def-sponsor00/shared/syncHPC/startMultiLocale.sh
$ chpl --fast baseSolver.chpl -o baseSolver
$ chpl --fast parallelSolver.chpl -o parallelSolver
```

First, let's try this on a smaller problem. Let's write a job submission script `distributed.sh`:

```sh
#!/bin/bash
# this is distributed.sh
#SBATCH --time=0:15:0         # walltime in d-hh:mm or hh:mm:ss format
#SBATCH --nodes=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=3600   # in MB
#SBATCH --output=solution.out
echo Running on $SLURM_NNODES nodes
./baseSolver --rows=30 --cols=30 --niter=2000 -nl $SLURM_NNODES
# ./parallelSolver --rows=30 --cols=30 --niter=2000 -nl $SLURM_NNODES
```

<!-- ./baseSolver --rows=650 --cols=650 --niter=9500 --tolerance=0.002 -nl $SLURM_NNODES -->
<!-- # ./parallelSolver --rows=650 --cols=650 --niter=9500 --tolerance=0.002 -nl $SLURM_NNODES -->

Let's run both codes, (un)commenting the relevant lines in `distributed.sh`:

```sh
$ sbatch distributed.sh
```
```output
Largest temperature difference was 9.9534e-05
Converged after 1148 iterations
Simulation took ... seconds
```

Wait for the jobs to finish and then check the results:

|   |   |   |
|---|---|---|
| -\-nodes | 1 | 4 |
| -\-cpus-per-task | 1 | 2 |
| baseSolver (sec) | 0.00725 | |
| parallelSolver (sec) | | 67.5 |

As you can see, on the training cluster the parallel code on 4 nodes (with 2 cores each) ran ~9,300 times
slower than a serial code on a single node ... What is going on here!? Shouldn't the parallel code run ~8X
faster, since we have 8X as many processors?

This is a **_fine-grained_** parallel code that needs a lot of communication between tasks, and relatively
little computing. So, we are seeing the **communication overhead**. The training cluster has a very slow
interconnect, so the problem is even worse there than on a production cluster!

If we increase our 2D problem size, there will be more computation (scaling as $O(n^2)$) in between
communications (scaling as $O(n)$), and at some point the parallel code should catch up to the serial code and
eventually run faster. Let's try these problem sizes:

```output
--rows=650 --cols=650 --niter=9500 --tolerance=0.002
Largest temperature difference was 0.0019989
Converged after 7766 iterations

--rows=2000 --cols=2000 --niter=9500 --tolerance=0.002
Largest temperature difference was 0.0019989
Converged after 9158 iterations

--rows=8000 --cols=8000 --niter=9800 --tolerance=0.002
Largest temperature difference was 0.0019989
Converged after 9725 iterations

--rows=16000 --cols=16000 --niter=9900 --tolerance=0.002
Largest temperature difference was 0.0019989
Converged after 9847 iterations
```

#### On the training cluster (slower interconnect)

I switched both codes to single precision (change `real` to `real(32)` and use `(80.0*i/rows):real(32)` when
assigning to `real(32)` variables), to be able to accommodate larger arrays. The table below shows the
**slowdown** factor when going from serial to parallel:

| | 30^2 | 650^2 | 2,000^2 | 8,000^2 | 16,000^2 |
| ----- | ----- | ----- | ----- | ----- | ----- |
| -\-nodes=4 -\-cpus-per-task=8 | 5104  | 14.78 | 2.29 | 1/1.95 | 1/3.31 |

<!-- #### On Graham (faster interconnect): -->

<!-- | | 30^2 | 650^2 | 2,000^2 | 8,000^2 | -->
<!-- | ----- | ----- | ----- | ----- | ----- | -->
<!-- | --nodes=4 --cpus-per-task=2 | 5,170 | 14 | 2.9 | 1.25 | -->
<!-- | --nodes=4 --cpus-per-task=4 | | | | 1/1.56 | -->
<!-- | --nodes=8 --cpus-per-task=4 | | | | 1/2.72 | -->

<!-- 16,000^2 on Graham: baseSolver 41,482s; parallel --nodes=4 --cpus-per-task=2 61,052s -->

<!-- on Cedar at 650^2 we have ~60X slowdown: 27.5408 seconds and 1658.34 seconds, respectively (bad Chapel build over OmniPath?) -->

<!-- with Chapel 1.17.0 on Graham 650^2 took 21.1198 seconds and 907.352 seconds, respectively -->

<!-- on Cedar 2000^2 baseSolver: The simulation took 469.298 seconds -->

<!-- on Graham 5000^2 took 3697.65 seconds and 6015.98 seconds, respectively -->

## Final parallel code

Here is the final single-precision parallel version of the code, minus the comments:

```chpl
use Time, BlockDist;
config const rows, cols = 100;
config const niter = 500;
config const tolerance = 1e-4: real(32);
var count = 0: int;
var delta: real(32);
var tmp: real(32);

const mesh: domain(2) = {1..rows, 1..cols};
const largerMesh: domain(2) dmapped new blockDist(boundingBox=mesh) = {0..rows+1, 0..cols+1};
var T, Tnew: [largerMesh] real(32);
T[1..rows,1..cols] = 25;

delta = tolerance*10;
var watch: stopwatch;
watch.start();
for i in 1..rows do T[i,cols+1] = (80.0*i/rows):real(32);   // right side boundary condition
for j in 1..cols do T[rows+1,j] = (80.0*j/cols):real(32);   // bottom side boundary condition
while (count < niter && delta >= tolerance) {
  count += 1;
  forall (i,j) in largerMesh[1..rows,1..cols] do
    Tnew[i,j] = 0.25 * (T[i-1,j] + T[i+1,j] + T[i,j-1] + T[i,j+1]);
  delta = max reduce abs(Tnew[1..rows,1..cols]-T[1..rows,1..cols]);
  if count%100 == 0 then writeln("delta = ", delta);
  T[1..rows,1..cols] = Tnew[1..rows,1..cols];   // uses parallel `forall` underneath
}
watch.stop();

writeln('Largest temperature difference was ', delta);
writeln('Converged after ', count, ' iterations');
writeln('Simulation took ', watch.elapsed(), ' seconds');
```

This is the entire multi-locale, data-parallel, hybrid shared-/distributed-memory solver!




<!-- > ### <font style="color:blue">Exercise "Data.5"</font> -->
<!-- > Add printout to the code to show the total energy on the inner mesh [1..row,1..cols] at each -->
<!-- > iteration. Consider the temperature sum over all mesh points to be the total energy of the system. Is -->
<!-- > the total energy on the mesh conserved? -->

<!-- > ### <font style="color:blue">Exercise "Data.6"</font> -->
<!-- > Write a code to print how the finite-difference stencil [i,j], [i-1,j], [i+1,j], [i,j-1], [i,j+1] is -->
<!-- > distributed among nodes, and compare that to the ID of the node where T[i,i] is computed. Use problem -->
<!-- > size 8x8. -->

<!-- This produced the following output clearly showing the *ghost points* and the stencil distribution for -->
<!-- each mesh point: -->

<!-- ``` -->
<!-- empty empty empty empty empty empty empty empty empty empty -->
<!-- empty 000000   000000   000000   000001   111101   111111   111111   111111   empty -->
<!-- empty 000000   000000   000000   000001   111101   111111   111111   111111   empty -->
<!-- empty 000000   000000   000000   000001   111101   111111   111111   111111   empty -->
<!-- empty 000200   000200   000200   000201   111301   111311   111311   111311   empty -->
<!-- empty 220222   220222   220222   220223   331323   331333   331333   331333   empty -->
<!-- empty 222222   222222   222222   222223   333323   333333   333333   333333   empty -->
<!-- empty 222222   222222   222222   222223   333323   333333   333333   333333   empty -->
<!-- empty 222222   222222   222222   222223   333323   333333   333333   333333   empty -->
<!-- empty empty empty empty empty empty empty empty empty empty -->
<!-- ``` -->

<!-- * note that Tnew[i,j] is always computed on the same node where that element is stored -->
<!-- * note remote stencil points at the block boundaries -->

<!-- <\!-- ## Periodic boundary conditions -\-> -->
<!-- <\!-- Now let us modify the previous parallel solver to include periodic BCs. At the beginning of each time -\-> -->
<!-- <\!-- step we need to set elements on the *ghost points* to their respective values on the *opposite ends*, by -\-> -->
<!-- <\!-- adding the following to our code: -\-> -->
<!-- <\!-- ``` -\-> -->
<!-- <\!--   T[0,1..n] = T[n,1..n]; // periodic boundaries on all four sides; these will run via parallel forall -\-> -->
<!-- <\!--   T[n+1,1..n] = T[1,1..n]; -\-> -->
<!-- <\!--   T[1..n,0] = T[1..n,n]; -\-> -->
<!-- <\!--   T[1..n,n+1] = T[1..n,1]; -\-> -->
<!-- <\!-- ``` -\-> -->
<!-- <\!-- Now total energy should be conserved, as nothing leaves the domain. -\-> -->

<!-- ## I/O -->

<!-- Let us write the final solution to disk. Please note: -->

<!-- - here we'll write in ASCII (raw binary output is slightly more difficult to make portable) <\!-- Chapel can also write -->
<!--   binary data but nothing can read it (checked: not the endians problem!) -\-> -->
<!-- - a much better choice would be writing in NetCDF or HDF5 -- covered in our webinar -->
<!-- ["Working with data files and external C libraries in Chapel"](https://westgrid.github.io/trainingMaterials/programming#working-with-data-files-and-external-c-libraries-in-chapel) -->
<!--   - portable binary encoding (little vs. big endian byte order) -->
<!--   - compression -->
<!--   - random access -->
<!--   - parallel I/O (partially implemented) -- see the HDF5 example in the webinar -->

<!-- Let's comment out all lines with `message` and `assert()`, and add the following at the end of our code to write ASCII: -->

<!-- ```chpl -->
<!-- use IO; -->
<!-- var myFile = open('output.dat', iomode.cw);   // open the file for writing -->
<!-- var myWritingChannel = myFile.writer();   // create a writing channel starting at file offset 0 -->
<!-- myWritingChannel.write(T);   // write the array -->
<!-- myWritingChannel.close();   // close the channel -->
<!-- ``` -->
<!-- ```sh -->
<!-- $ chpl --fast parallel.chpl -o parallel -->
<!-- $ ./parallel -nl 3 --rows=8 --cols=8   # run this from inside distributed.sh -->
<!-- $ ls -l *dat -->
<!-- -rw-rw-r-- 1 razoumov razoumov 659 Mar  9 18:04 output.dat -->
<!-- ``` -->

<!-- The file *output.dat* should contain the 8x8 temperature array after convergence. -->

<!-- ### Other I/O topics -->

<!-- * for binary I/O check https://chapel-lang.org/publications/ParCo-Larrosa.pdf -->
<!-- * writing arrays to NetCDF and HDF5 files from Chapel is covered in our -->
<!--   [March 2020 webinar](https://bit.ly/3QnP1Pd) -->
<!-- <\!-- * advanced take-home exercise: take a simple 2D or 3D non-linear problem, linearize it, implement a parallel -\-> -->
<!-- <\!--   multi-locale linear solver entirely in Chapel -\-> -->
