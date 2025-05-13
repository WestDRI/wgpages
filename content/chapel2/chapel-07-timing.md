+++
title = "Measuring code performance"
slug = "chapel-07-timing"
weight = 7
katex = true
+++

## Timing the execution of your Chapel code

The code generated after Exercise "Basic.4" is the full implementation of our calculation. We will be using it
as a benchmark, to see how much we can improve the performance with Chapel's parallel programming features in
the following lessons.

But first, we need a quantitative way to measure the performance of our code. Perhaps the easiest way to do
this is to use the UNIX command `time`:

```sh
$ time ./juliaSetSerial --n=500
```
```chpl
real ...
user ...
sys	 ...
```

The real time is what interest us. Our code is taking ... seconds from the moment it is called at the command
line until it returns. Sometimes, however, it could be useful to take the execution time of specific parts of
the code. This can be achieved by modifying the code to output the information that we need. This process is
called **_instrumentation of the code_**.

An easy way to instrument our code with Chapel is by using the module `Time`. **_Modules_** in Chapel are
libraries of useful functions and methods that can be used in our code once the module is loaded. To load
a module we use the keyword `use` followed by the name of the module. Once the Time module is loaded we
can create a variable of the type `stopwatch`, and use the methods `start`, `stop`and `elapsed` to instrument
our code.

```chpl
use Time;
var watch: stopwatch;
watch.start();
for i in 1..n do {
  y = 2*(i-0.5)/n - 1;
  for j in 1..n do {
    point = 2*(j-0.5)/n - 1 + y*1i;   // rescale to -1:1 in the complex plane
    stability[i,j] = pixel(point);
  }
}
watch.stop();
writeln('It took ', watch.elapsed(), ' seconds');
```
```sh
$ chpl --fast juliaSetSerial.chpl
$ ./juliaSetSerial --n=500
```
```chpl
```

{{< question num="Basic.5" >}}
Try recompiling without `--fast` and see how it affects the execution time. If it becomes too slow, try
reducing the problem size. What is the speedup factor with `--fast`?
{{< /question >}}

Here is our complete serial code `juliaSetSerial.chpl`:

```chpl
use Time;

config const c = 0.355 + 0.355i;

proc pixel(z0) {
  var z = z0*1.2;   // zoom out
  for i in 1..255 do {
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
for i in 1..n do {
  y = 2*(i-0.5)/n - 1;
  for j in 1..n do {
    point = 2*(j-0.5)/n - 1 + y*1i;   // rescale to -1:1 in the complex plane
    stability[i,j] = pixel(point);
  }
}
watch.stop();
writeln('It took ', watch.elapsed(), ' seconds');
```
