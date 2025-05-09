+++
title = "Writing output"
slug = "chapel-08-output"
weight = 8
katex = true
+++

## Write to a NetCDF file

Here is a modified serial code `juliaSetSerial.chpl` with NetCDF output:

```chpl
use Time;
use NetCDF.C_NetCDF;

proc pixel(z0) {
  config const c = 0.355 + 0.355i;
  var z = z0*1.2;   // zoom out
  for i in 1..255 do {
    z = z*z + c;
    if abs(z) >= 4 then
      return i:c_int;
  }
  return 255:c_int;
}

config const n = 2_000;   // vertical and horizontal size of our image
var y: real;
var point: complex;
var watch: stopwatch;

writeln("Computing Julia set ...");
var stability: [1..n,1..n] c_int;
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
cdfError(nc_def_dim(ncid, "x", n, xDimID)); // define the dimensions
cdfError(nc_def_dim(ncid, "y", n, yDimID));
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










## Write to a PNG image

To be updated.
