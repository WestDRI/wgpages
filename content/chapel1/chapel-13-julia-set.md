+++
title = "Parallelizing the Julia set problem"
slug = "chapel-13-julia-set"
weight = 13
katex = true
+++

This project is a mathematical problem to compute a [Julia set](https://en.wikipedia.org/wiki/Julia_set),
defined as a set of points on the complex plane that remain bound under infinite recursive transformation
$f(z)$. We will use the traditional form $f(z)=z^2+c$, where $c$ is a complex constant. Here is our algorithm:

1. pick a point $z_0\in\mathbb{C}$
1. compute iterations $z_{i+1}=z_i^2+c$ until $|z_i|>4$ (arbitrary fixed radius; here $c$ is a complex
   constant)
1. store the iteration number $\xi(z_0)$ at which $z_i$ reaches the circle $|z|=4$
1. limit max iterations at 255  
    4.1 if $\xi(z_0)=255$, then $z_0$ is a stable point  
    4.2 the quicker a point diverges, the lower its $\xi(z_0)$ is
1. plot $\xi(z_0)$ for all $z_0$ in a rectangular region $-1<=\mathfrak{Re}(z_0)<=1$,
   $-1<=\mathfrak{Im}(z_0)<=1$

We should get something conceptually similar to this figure (here $c = 0.355 + 0.355i$; we'll get drastically
different fractals for different values of $c$):

{{< figure src="/img/2000a.png" >}}

**Note**: you might want to try these values too:
- $c = 1.2e^{1.1πi}$ $~\Rightarrow~$ original textbook example
- $c = -0.4-0.59i$ and 1.5X zoom-out $~\Rightarrow~$ denser spirals
- $c = 1.34-0.45i$ and 1.8X zoom-out $~\Rightarrow~$ beans
- $c = 0.34-0.05i$ and 1.2X zoom-out $~\Rightarrow~$ connected spiral boots

Below is the serial code `juliaSetSerial.chpl`:

```chpl
use Time;
use NetCDF.C_NetCDF;

proc pixel(z0) {
  const c = 0.355 + 0.355i;
  var z = z0*1.2;   // zoom out
  for i in 1..255 do {
    z = z*z + c;
    if abs(z) >= 4 then
      return i:c_int;
  }
  return 255:c_int;
}

const height, width = 2_000;   // 2000^2 image
var point: complex, y: real, watch: Timer;

writeln("Computing Julia set ...");
var stability: [1..height,1..width] c_int;
watch.start();
for i in 1..height do {
  y = 2*(i-0.5)/height - 1;
  for j in 1..width do {
    point = 2*(j-0.5)/width - 1 + y*1i;   // rescale to -1:1 in the complex plane
    stability[i,j] = pixel(point);
  }
}
watch.stop();
writeln('It took ', watch.elapsed(), ' seconds');
```

The reason we are using C types (`c_int`) here -- and not Chapel's own int(32) or int(64) -- is that we can
save the resulting array `stability` into a compressed netCDF file. To the best of my knowledge, this can only
be done using `NetCDF.C_NetCDF` library that relies on C types. You can add this to your code:

```chpl
writeln("Writing NetCDF ...");
use NetCDF.C_NetCDF;
proc cdfError(e) {
  if e != NC_NOERR {
    writeln("Error: ", nc_strerror(e): string);
    exit(2);
  }
}
var ncid, xDimID, yDimID, varID: c_int;
var dimIDs: [0..1] c_int;   // two elements
cdfError(nc_create("test.nc", NC_NETCDF4, ncid));       // const NC_NETCDF4 => file in netCDF-4 standard
cdfError(nc_def_dim(ncid, "x", width: size_t, xDimID)); // define the dimensions
cdfError(nc_def_dim(ncid, "y", height: size_t, yDimID));
dimIDs = [xDimID, yDimID];                              // set up dimension IDs array
cdfError(nc_def_var(ncid, "stability", NC_INT, 2, dimIDs[0], varID));   // define the 2D data variable
cdfError(nc_def_var_deflate(ncid, varID, NC_SHUFFLE, deflate=1, deflate_level=9)); // compress 0=no 9=max
cdfError(nc_enddef(ncid));                              // done defining metadata
cdfError(nc_put_var_int(ncid, varID, stability[1,1]));  // write data to file
cdfError(nc_close(ncid));
```

Testing on my laptop, it took the code 0.471 seconds to compute a $2000^2$ fractal.

Try running it yourself! It will produce a file `test.nc` that you can download to your computer and render
with ParaView or other visualization tool. Does the size of `test.nc` make sense?

Now let's parallelize this code with `forall`. Copy `juliaSetSerial.chpl` into `juliaSetParallel.chpl` and
start modifying it:

1. For the outer loop, replace `for` with `forall`. This will produce an error about the scope of variables
   `y` and `point`:

```sh
error: cannot assign to const variable
note: The shadow variable '...' is constant due to forall intents in this loop
```

> ### Discussion
> Why do you think this message was produced? How do we solve this problem?

2. What do we do next?

Once you have the working shared-memory parallel code, study its performance.

> ### Discussion
> Why do you think the code's speed does not scale linearly with the number of cores?
