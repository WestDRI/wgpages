+++
title = "Ranges and arrays"
slug = "chapel-03-ranges-and-arrays"
weight = 3
katex = true
+++

A series of integers (1,2,3,4,5, for example), is called a **_range_** in Chapel. Ranges are generated
with the `..` operator, and are useful, among other things, to declare **_arrays_** of variables. For
example, the following variables

```chpl
var T: [0..rows+1,0..cols+1] real;      // current temperatures
var Tnew: [0..rows+1,0..cols+1] real;   // newly computed temperatures
```

are 2D arrays (matrices) with (`rows + 2`) rows and (`cols + 2`) columns of real numbers, all initialized
as 0.0. The ranges `0..rows+1` and `0..cols+1` used here, not only define the size and shape of the
array, they stand for the indices with which we could access particular elements of the array using the
`[ , ]` notation. For example, `T[0,0]` is the real variable located at the first row and first column of
the array `T`, while `T[3,7]` is the one at the 4th row and 8th column; `T[2,3..15]` access columns 4th
to 16th of the 3th row of `T`, and `T[0..3,4]` corresponds to the first 4 rows on the 5th column of
`T`. Similarly, with

```chpl
T[1..rows,1..cols] = 25;     // set the initial temperature
```

we assign an initial temperature of 25 degrees across all points of our metal plate.

We must now be ready to start coding our simulations ... here is what we are going to do:

- this simulation will consider a matrix of _rows_ by _cols_ elements
- it will run up to _niter_ iterations, or until the largest difference in temperature between iterations
  is less than _tolerance_
- at each iteration print out the temperature at the position (iout,jout)

### Using expressions to create arrays

In Chapel arrays can also be initialized with expressions (similarly to list comprehensions in Python):

```chpl
writeln([i in 1..10] i**2);   // prints 1 4 9 16 25 36 49 64 81 100
var x = [i in 1..10] if (i%2 == 0) then i else 0;
writeln(x);                   // prints 0 2 0 4 0 6 0 8 0 10
writeln(x.type:string);       // 1D array of type int(64)
```
