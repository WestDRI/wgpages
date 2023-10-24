+++
title = "Getting started with loops"
slug = "chapel-05-loops"
weight = 5
katex = true
+++

<!-- ## Structured iterations with for-loops -->

To compute the new temperature `Tnew` at any point, we need to add temperatures `T` at all the surronding
points, and divide the result by 4. And, esentially, we need to repeat this process for all the elements of
`Tnew`, or, in other words, we need to *iterate* over the elements of `Tnew`. When it comes to iterating over
a given number of elements, the **_for-loop_** is what we want to use. The for-loop has the following general
syntax:

```chpl
for index in iterand do
  {instructions}
``` 

The *iterand* is a statement that expresses an iteration; it could be the range 1..15, for example. *index* is
a variable that exists only in the context of the for-loop, and that will be taking the different values
yielded by the iterand. The code flows as follows: index takes the first value yielded by the iterand, and
keeps it until all the instructions inside the curly brackets are executed one by one; then, index takes the
second value yielded by the iterand, and keeps it until all the instructions are executed again. This pattern
is repeated until index takes all the different values exressed by the iterand.

We need to iterate both over all rows and all columns in order to access every single element of `Tnew`. This
can be done with nested _for_ loops like this

```chpl
for i in 1..rows do {     // process row i
  for j in 1..cols do {   // process column j, row i
    Tnew[i,j] = (T[i-1,j] + T[i+1,j] + T[i,j-1] + T[i,j+1])/4;
  }
}
```

Now let's compile and execute our code again:

```sh
$ chpl baseSolver.chpl -o baseSolver
$ sbatch serial.sh
$ tail -f solution.out
```

```chpl
Temperature at iteration 0: 25.0
...
Temperature at iteration 200: 25.0
Temperature at iteration 220: 24.9999
Temperature at iteration 240: 24.9996
...
Temperature at iteration 480: 24.8883
Temperature at iteration 500: 24.8595
```

As we can see, the temperature in the middle of the plate (position 50,50) is slowly decreasing as the
plate is cooling down.

> ### <font style="color:blue">Exercise "Basic.1"</font>
> What would be the temperature at the top right corner (row 1, column `cols`) of the plate? The border of the
> plate is in contact with the boundary conditions, which are set to zero (default boundary values for T), so
> we expect the temperature at these points to decrease faster. Modify the code to see the temperature at the
> top right corner.

> ### <font style="color:blue">Exercise "Basic.2"</font>
> Now let's have some more interesting boundary conditions. Suppose that the plate is heated by a source of 80
> degrees located at the bottom right corner (row `rows`, column `cols`), and that the temperature on the rest
> of the border on adjacent sides (to this bottom right corner) decreases linearly to zero as one gets farther
> from that corner. Utilize `for` loops to setup the described boundary conditions. Compile and run your code
> to see how the temperature is changing now.

> ### <font style="color:blue">Exercise "Basic.3"</font>
> So far, `delta` has been always equal to `tolerance`, which means that our main while loop will always run
> the 500 iterations. So let's update `delta` after each iteration. Use what we have studied so far to write
> the required piece of code.

Now, after Exercise "Basic.3" we should have a working program to simulate our heat transfer equation. Let's
print some additional useful information:

```chpl
writeln('Final temperature at the desired position [', iout, ',', jout, '] after ', count, ' iterations is: ', T[iout,jout]);
writeln('The largest temperature difference between the last two iterations was: ', delta);
```

and compile and execute our final code

```sh
$ chpl baseSolver.chpl -o baseSolver
$ sbatch serial.sh
$ tail -f solution.out
```
```chpl
Temperature at iteration 0: 25.0
Temperature at iteration 20: 2.0859
...
Temperature at iteration 500: 0.823152
Final temperature at the desired position [1,100] after 500 iterations is: 0.823152
The largest temperature difference between the last two iterations was: 0.0258874
```
