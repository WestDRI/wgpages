+++
title = "Ranges, arrays, and loops"
slug = "chapel-03-ranges-and-arrays"
weight = 3
katex = true
+++

A series of integers (1,2,3,4,5, for example), is called a **_range_** in Chapel. Ranges are generated with
the `..` operator, and are useful, among other things, to declare **_arrays_** of variables. For example, the
following variable

```chpl
var stability: [1..n,1..n] int;   // our target array to compute
```

is a 2D array (matrix) with `n` rows and `n` columns of integer numbers, all initialized as `0`. The two
ranges `1..n` not only define the size and shape of the array, they stand for the indices with which we could
access particular elements of the array using the `[X,X]` notation. For example, `stability[1,1]` is the
integer variable located at the first row and first column of the array `stability`, while `stability[3,7]`
sits at the 3rd row and 7th column; `stability[2,3..15]` access columns 3 to 15 of the 2nd row, and
`stability[1..4,4]` corresponds to the first 4 rows on the 4th column of `stability`.

<!-- Similarly, with -->
<!-- ```chpl -->
<!-- T[1..rows,1..cols] = 25;     // set the initial temperature -->
<!-- ``` -->
<!-- we assign an initial temperature of 25 degrees across all points of our metal plate. -->

We are now ready to start coding our computation ... here is what we are going to do:

<!-- - this simulation will consider a matrix of _rows_ by _cols_ elements -->
<!-- - it will run up to _niter_ iterations, or until the largest difference in temperature between iterations -->
<!--   is less than _tolerance_ -->
<!-- - at each iteration print out the temperature at the position (iout,jout) -->

1. write a function to compute a single pixel of the image: takes a complex point, returns its stability number
1. iterate over all points in the image, calling `pixel()` for each
1. time the computation
1. learn how to write the result to a NetCDF file
1. learn how to write the result to a PNG image
1. parallelize this code, first on a single node, and then across multiple nodes





### Using expressions to create arrays

In Chapel arrays can also be initialized with expressions (similarly to list comprehensions in Python):

```chpl
writeln([i in 1..10] i**2);   // prints 1 4 9 16 25 36 49 64 81 100
var x = [i in 1..10] if (i%2 == 0) then i else 0;
writeln(x);                   // prints 0 2 0 4 0 6 0 8 0 10
writeln(x.type:string);       // 1D array of type int(64)
```





## Structured iterations with for-loops

We want to iterate over all points in our image. When it comes to iterating over a given number of elements,
the **_for-loop_** is what we want to use. The for-loop has the following general syntax:

```chpl
for index in iterand do
  instruction;
  
for index in iterand {
  instruction1;
  instruction2;
  ...
  }
``` 

The *iterand* is a statement that expresses an iteration; it could be a range `1..15`, for example. *index* is
a variable that exists only in the context of the for-loop, and that will be taking the different values
yielded by the iterand. The code flows as follows: index takes the first value yielded by the iterand, and
keeps it until all the instructions inside the curly brackets are executed one by one; then, index takes the
second value yielded by the iterand, and keeps it until all the instructions are executed again. This pattern
is repeated until index takes all the different values exressed by the iterand.

In our case we iterate both over all rows and all columns in the image to compute every pixel. This can be
done with nested _for_ loops like this:

```chpl
for i in 1..n { // process row i
  y = 2*(i-0.5)/n - 1;
  for j in 1..n { // process column j, row i
    point = 2*(j-0.5)/n - 1 + y*1i;   // rescale to -1:1 in the complex plane
    stability[i,j] = pixel(point);
  }
}
```

To be able to compile the code, we also need a prototype `pixel()` function:

```chpl
proc pixel(z0) {
  return z0; // to be replaced with an actual calculation
}
```

Now let's compile and execute our code again:

```sh
$ chpl juliaSetSerial.chpl
$ sbatch serial.sh
$ tail -f solution.out
```

```output
```

<!-- As we can see, the temperature in the middle of the plate (position 50,50) is slowly decreasing as the -->
<!-- plate is cooling down. -->

<!-- > ### <font style="color:blue">Exercise "Basic.1"</font> -->
<!-- > What would be the temperature at the top right corner (row 1, column `cols`) of the plate? The border of the -->
<!-- > plate is in contact with the boundary conditions, which are set to zero (default boundary values for T), so -->
<!-- > we expect the temperature at these points to decrease faster. Modify the code to see the temperature at the -->
<!-- > top right corner. -->

<!-- > ### <font style="color:blue">Exercise "Basic.2"</font> -->
<!-- > Now let's have some more interesting boundary conditions. Suppose that the plate is heated by a source of 80 -->
<!-- > degrees located at the bottom right corner (row `rows`, column `cols`), and that the temperature on the rest -->
<!-- > of the border on adjacent sides (to this bottom right corner) decreases linearly to zero as one gets farther -->
<!-- > from that corner. Utilize `for` loops to setup the described boundary conditions. Compile and run your code -->
<!-- > to see how the temperature is changing now. -->

<!-- > ### <font style="color:blue">Exercise "Basic.3"</font> -->
<!-- > So far, `delta` has been always equal to `tolerance`, which means that our main while loop will always run -->
<!-- > the 500 iterations. So let's update `delta` after each iteration. Use what we have studied so far to write -->
<!-- > the required piece of code. -->

<!-- Now, after Exercise "Basic.3" we should have a working program to simulate our heat transfer equation. Let's -->
<!-- print some additional useful information: -->

<!-- ```chpl -->
<!-- writeln('Final temperature at the desired position [', iout, ',', jout, '] after ', count, ' iterations is: ', T[iout,jout]); -->
<!-- writeln('The largest temperature difference between the last two iterations was: ', delta); -->
<!-- ``` -->

<!-- and compile and execute our final code -->

<!-- ```sh -->
<!-- $ chpl baseSolver.chpl -o baseSolver -->
<!-- $ sbatch serial.sh -->
<!-- $ tail -f solution.out -->
<!-- ``` -->
<!-- ```chpl -->
<!-- Temperature at iteration 0: 25.0 -->
<!-- Temperature at iteration 20: 2.0859 -->
<!-- ... -->
<!-- Temperature at iteration 500: 0.823152 -->
<!-- Final temperature at the desired position [1,100] after 500 iterations is: 0.823152 -->
<!-- The largest temperature difference between the last two iterations was: 0.0258874 -->
<!-- ``` -->
