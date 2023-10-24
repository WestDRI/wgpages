+++
title = "Measuring code performance"
slug = "chapel-07-timing"
weight = 7
katex = true
+++

## Timing the execution of your code in Chapel

The code generated after Exercise "Basic.4" is the full implementation of our simulation. We will be using it
as a benchmark, to see how much we can improve the performance with Chapel's parallel programming features in
the following lessons.

But first, we need a quantitative way to measure the performance of our code. Maybe the easiest way to do it,
is to see how much it takes to finish a simulation. The UNIX command `time` could be used to this effect

```sh
$ time ./baseSolver --rows=650 --iout=200 --niter=10_000 --tolerance=0.002 --nout=1000
```
```chpl
Temperature at iteration 0: 25.0
Temperature at iteration 1000: 25.0
Temperature at iteration 2000: 25.0
Temperature at iteration 3000: 25.0
Temperature at iteration 4000: 24.9996
Temperature at iteration 5000: 24.9968
Temperature at iteration 6000: 24.987
Temperature at iteration 7000: 24.9639
Final temperature at the desired position [200,200] after 7750 iterations is: 24.9343
The largest temperature difference was 0.00199985
real	0m3.931s
user	0m7.354s
sys	0m9.952s
```

The real time is what interest us. Our code is taking around 9.2 seconds from the moment it is called at
the command line until it returns. Sometimes, however, it could be useful to take the execution time of
specific parts of the code. This can be achieved by modifying the code to output the information that we
need. This process is called **_instrumentation of the code_**.

An easy way to instrument our code with Chapel is by using the module `Time`. **_Modules_** in Chapel are
libraries of useful functions and methods that can be used in our code once the module is loaded. To load
a module we use the keyword `use` followed by the name of the module. Once the Time module is loaded we
can create a variable of the type `Timer`, and use the methods `start`, `stop`and `elapsed` to instrument
our code.

```chpl
use Time;
var watch: Timer;
watch.start();
while (count < niter && delta >= tolerance) do {
  ...
}
watch.stop();
writeln('The simulation took ', watch.elapsed(), ' seconds');
```
```sh
$ chpl --fast baseSolver.chpl -o baseSolver
$ ./baseSolver --rows=650 --iout=200 --niter=10_000 --tolerance=0.002 --nout=1000
```
```chpl
Temperature at iteration 0: 25.0
Temperature at iteration 1000: 25.0
Temperature at iteration 2000: 25.0
Temperature at iteration 3000: 25.0
Temperature at iteration 4000: 24.9996
Temperature at iteration 5000: 24.9968
Temperature at iteration 6000: 24.987
Temperature at iteration 7000: 24.9639
Final temperature at the desired position [200,200] after 7750 iterations is: 24.9343
The largest temperature difference was 0.00199985
The simulation took 3.9187 seconds
```

> ### <font style="color:blue">Exercise "Basic.5"</font>
> Try recompiling without `--fast` and see how it affects the execution time. If it becomes too slow, try
> reducing the problem size. What is the speedup factor with `--fast`?
