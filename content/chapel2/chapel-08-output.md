+++
title = "Writing output"
slug = "chapel-08-output"
weight = 8
katex = true
+++

## Write to a NetCDF file

From Chapel you can save data as binary (not recommended, for portability reasons), as HDF5 (serial or
parallel), or NetCDF. Here is a modified serial code `juliaSetSerial.chpl` with NetCDF output:

```chpl
use Time;
use NetCDF.C_NetCDF;

config const c = 0.355 + 0.355i;

proc pixel(z0) {
  var z = z0*1.2;   // zoom out
  for i in 1..255 {
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

writeln("Computing ", n, "x", n, " Julia set ...");
var stability: [1..n,1..n] c_int;
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

Chapel's [Image](https://chapel-lang.org/docs/main/modules/packages/Image.html) library lets you write arrays
of pixels to a PNG file. The following code -- when added to the non-GPU code `juliaSetSerial.chpl` -- writes
the array `stability` to a file `2000.png` assuming that in the current directory you

1. have downloaded the [colour map in CSV](/files/nipy_spectral.csv) and
2. have added the file `sciplot.chpl` (pasted below)

```chpl
writeln("Plotting ...");
use Image, Math, sciplot;
watch.clear();
watch.start();
const smin = min reduce(stability);
const smax = max reduce(stability);
var colour: [1..n, 1..n] 3*int;
var cmap = readColourmap('nipy_spectral.csv');   // cmap.domain is {1..256, 1..3}
for i in 1..n {
  for j in 1..n {
    var idx = ((stability[i,j]:real-smin)/(smax-smin)*255):int + 1; //scale to 1..256
    colour[i,j] = ((cmap[idx,1]*255):int, (cmap[idx,2]*255):int, (cmap[idx,3]*255):int);
  }
}
var pixels = colorToPixel(colour);               // array of pixels
writeImage(n:string+".png", imageType.png, pixels);
watch.stop();
writeln('It took ', watch.elapsed(), ' seconds');
```

```chpl
// save this as sciplot.chpl
use IO;
use List;

proc readColourmap(filename: string) {
  var reader = open(filename, ioMode.r).reader();
  var line: string;
  if (!reader.readLine(line)) then   // skip the header
    halt("ERROR: file appears to be empty");
  var dataRows : list(string); // a list of lines from the file
  while (reader.readLine(line)) do   // read all lines into the list
    dataRows.pushBack(line);
  var cmap: [1..dataRows.size, 1..3] real;
  for (i, row) in zip(1..dataRows.size, dataRows) {
    var c1 = row.find(','):int;    // position of the 1st comma in the line
    var c2 = row.rfind(','):int;   // position of the 2nd comma in the line
    cmap[i,1] = row[0..c1-1]:real;
    cmap[i,2] = row[c1+1..c2-1]:real;
    cmap[i,3] = row[c2+1..]:real;
  }
  reader.close();
  return cmap;
}
```

Here are the typical timings on a CPU:

```output
Computing 2000x2000 Julia set ...
It took 0.382409 seconds
Plotting ...
It took 0.192508 seconds
```
