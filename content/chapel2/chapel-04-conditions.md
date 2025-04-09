+++
title = "Conditional statements"
slug = "chapel-04-conditions"
weight = 4
katex = true
+++

Chapel, as most *high-level programming languages*, has different staments to control the flow of the program
or code.  The conditional statements are the `if` statement and the `while` statement.

The general syntax of a `while` statement is: 

```chpl
while condition do 
{instructions}
```

The code flows as follows: first, the condition is evaluated, and then, if it is satisfied, all the
instructions within the curly brackets are executed one by one. This will be repeated over and over again
until the condition does not hold anymore.

The main loop in our simulation can be programmed using a while statement like this

```chpl
delta = tolerance;   // safe initial bet; could also be a large number
while (count < niter && delta >= tolerance) do {
  // specify boundary conditions for T
  count += 1;        // increase the iteration counter by one
  Tnew = T;          // will be replaced: calculate Tnew from T
  // update delta, the greatest difference between Tnew and T
  T = Tnew;          // update T once all elements of Tnew are calculated
  // print the temperature at [iout,jout] if the iteration is multiple of nout
}
```

<!-- Essentially, what we want is to repeat all the code inside the curly brackets until the number of -->
<!-- iterations is gerater than or equal to `niter`, or the difference of temperature between iterations is -->
<!-- less than `tolerance`. (Note that in our case, as `delta` was not initialized when declared -and thus -->
<!-- Chapel assigned it the default real value 0.0-, we need to assign it a value greater than or equal -->
<!-- to 0.001, or otherwise the condition of the while statemnt will never be satisfied. A good starting point -->
<!-- is to simple say that `delta` is equal to `tolerance`). -->

Let's focus, first, on printing the temperature every 20 interations. To achieve this, we only need to
check whether `count` is a multiple of 20, and in that case, to print the temperature at the desired
position. This is the type of control that an **_if statement_** give us. The general syntax is:

```chpl
if condition then 
  {instructions A} 
else 
  {instructions B}
```

In our case we print the temperature at the desired position if the iteration is multiple of niter:

```chpl
if count%nout == 0 then writeln('Temperature at iteration ', count, ': ', T[iout,jout]);
```

To print 0th iteration, we can insert just before the time loop

```chpl
writeln('Temperature at iteration ', count, ': ', T[iout,jout]);
```

Note that when only one instruction will be executed, there is no need to use the curly brackets. `%`
returns the remainder after the division (i.e. it returns zero when `count` is multiple of 20).

Let's compile and execute our code to see what we get until now, using the job script `serial.sh`:

```sh
#!/bin/bash
#SBATCH --time=00:05:00      # walltime in d-hh:mm or hh:mm:ss format
#SBATCH --mem-per-cpu=1000   # in MB
#SBATCH --output=solution.out
./baseSolver
```

and then submitting it:

```sh
$ chpl baseSolver.chpl -o baseSolver
$ sbatch serial.sh
$ tail -f solution.out
```

```chpl
Temperature at iteration 0: 25.0
Temperature at iteration 20: 25.0
Temperature at iteration 40: 25.0
...
Temperature at iteration 500: 25.0
```

Of course the temperature is always 25.0, as we haven't done any computation yet.
