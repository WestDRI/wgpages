+++
title = "Parallel Julia set"
slug = "chapel-15-distributed-julia-set"
weight = 15
katex = true
+++

## Shared-memory Julia set

Recall the serial code `juliaSetSerial.chpl` (without output):

```chpl
use Time;

config const c = 0.355 + 0.355i;

proc pixel(z0) {
  var z = z0*1.2;   // zoom out
  for i in 1..255 {
    z = z*z + c;
    if abs(z) >= 4 then
      return i;
  }
  return 255;
}

config const n = 2_000;   // vertical and horizontal size of our image
var y: real;
var point: complex;
var watch: stopwatch;

writeln("Computing ", n, "x", n, " Julia set ...");
var stability: [1..n,1..n] int;
watch.start();
for i in 1..n {
  y = 2*(i-0.5)/n - 1;
  for j in 1..n {
    point = 2*(j-0.5)/n - 1 + y*1i;   // rescale to -1:1 in the complex plane
    stability[i,j] = pixel(point);
  }
}
watch.stop();
writeln('It took ', watch.elapsed(), ' seconds');
```

Now let's parallelize this code with `forall` in shared memory (single locale). Copy `juliaSetSerial.chpl`
into `juliaSetParallel.chpl` and start modifying it:

1. For the outer loop, replace `for` with `forall`. This will produce an error about the scope of variables
   `y` and `point`:

```output
error: cannot assign to const variable
note: The shadow variable 'y' is constant due to task intents in this loop
error: cannot assign to const variable
note: The shadow variable 'point' is constant due to task intents in this loop
```

> ### Discussion
> Why do you think this message was produced? How do we solve this problem?

2. What do we do next?

Compile and run the code on several CPU cores on 1 node:

```sh
#!/bin/bash
# this is shared.sh
#SBATCH --time=0:5:0         # walltime in d-hh:mm or hh:mm:ss format
#SBATCH --mem-per-cpu=3600   # in MB
#SBATCH --cpus-per-task=4
#SBATCH --output=solution.out
./juliaSetParallel
```
```sh
module load chapel-multicore/2.4.0
chpl --fast juliaSetParallel.chpl
sbatch shared.sh
```

Once you have the working shared-memory parallel code, study its performance.

Here are my timings on the training cluster:

|   |   |   |   |   |
|---|---|---|---|---|
| ncores | 1 | 2 | 4 | 8 |
| wallclock runtime (sec) | 1.181 | 0.568 | 0.307 | 0.197 |

> ### Discussion
> Why do you think the code's speed does not scale linearly (~6X on 8 cores) with the number of cores?

## Julia set on distributed domains

Copy `juliaSetParallel.chpl` into `juliaSetDistributed.chpl` and start modifying it:

1. Load `BlockDist`
2. Replace
```chpl
var stability: [1..n,1..n] int;
```
with
```chpl
const mesh: domain(2) = {1..n, 1..n};
const distributedMesh: domain(2) dmapped new blockDist(boundingBox=mesh) = mesh;
var stability: [distributedMesh] int;
```
3. Look into the loop variables: currently we have

```chpl
forall i in 1..n {
  var y = 2*(i-0.5)/n - 1;
  for j in 1..n {
    var point = 2*(j-0.5)/n - 1 + y*1i;   // rescale to -1:1 in the complex plane
    stability[i,j] = pixel(point);
  }
}
```

-- in the previous, shared-memory version of the code this fragment gave you a parallel loop running on
multiple cores on the same node. If you run this loop now, it'll run entirely on the first node!

In the distributed version of the code you want to loop in parallel over all elements of the distributed mesh
`distributedMesh` (or, equivalently, over all elements of the distributed array `stability`) -- this will send
the computation to the locales holding these blocks:

```chpl
forall (i,j) in distributedMesh {
  var y = 2*(i-0.5)/n - 1;
  var point = 2*(j-0.5)/n - 1 + y*1i;
  stability[i,j] = pixel(point);
}
```

or (equivalent):

```chpl
forall (i,j) in stability.domain {
  var y = 2*(i-0.5)/n - 1;
  var point = 2*(j-0.5)/n - 1 + y*1i;
  stability[i,j] = pixel(point);
}
```

Compile and run a larger problem ($8000^2$) across several nodes:

```sh
#!/bin/bash
# this is distributed.sh
#SBATCH --time=0:5:0         # walltime in d-hh:mm or hh:mm:ss format
#SBATCH --nodes=4
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=3600   # in MB
#SBATCH --output=solution.out
echo Running on $SLURM_NNODES nodes
./juliaSetDistributed --n=8000 -nl $SLURM_NNODES
```
```sh
source /project/def-sponsor00/shared/syncHPC/startMultiLocale.sh
chpl --fast juliaSetDistributed.chpl
sbatch distributed.sh
```

Here are my timings on the training cluster (even over a slow interconnect!):

|   |   |   |   |   |
|---|---|---|---|---|
| -\-nodes | 1 | 2 | 4 | 4 |
| -\-cpus-per-task | 1 | 1 | 1 | 8 |
| wallclock runtime (sec) | 36.56 | 17.91 | 9.51 | 0.985 |

They don't call it *"embarrassing parallel"* for nothing! There is some overhead at the start and at the end
of computing each block, but this overhead is much smaller than the computing part itself, hence leading to
almost perfect speedup.

> Here we have an example of a hybrid parallel code, utilizing multiples processes (one per locale) and
> multiple threads (on each locale) when available.
{.note}
