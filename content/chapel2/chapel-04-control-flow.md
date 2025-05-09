+++
title = "Control flow"
slug = "chapel-04-control-flow"
weight = 4
katex = true
+++

Chapel, as most *high-level programming languages*, has different staments to control the flow of the program
or code. The conditional statements are the `if` statement and the `while` statement.

The general syntax of a `while` statement is one of the two:

```chpl
while condition do 
  instruction;
  
while condition {
  instruction1;
  ...
  instructionN;
}
```

With multiple instructions inside the curly brackets, all of them are executed one by one if the condition
evaluates to `True`. This block will be repeated over and over again until the condition does not hold
anymore.

In our Julia set code we don't use the `while` construct, however, we need to check if our iteration goes
beyond the $|z|=4$ circle -- this is the type of control that an **_if statement_** gives us. The general
syntax is:

```chpl
if condition then
  instruction1;
else
  instruction2;
```

and you can group multiple instructions into a block by using the curly brackets `{}`.

Let's package our calculation into a function: for each complex number we want to iterate until either we
reach the maximum number of iterations, or we cross the $|z|=4$ circle:

```chpl
proc pixel(z0) {
  const c: complex = 0.355 + 0.355i;   // Julia set constant
  var z = z0*1.2;   // zoom out
  for i in 1..255 {
    z = z*z + c;
    if abs(z) >= 4 then
      return i;
  }
  return 255;
}
```



<!-- The main loop in our simulation can be programmed using a while statement like this -->

<!-- ```chpl -->
<!-- delta = tolerance;   // safe initial bet; could also be a large number -->
<!-- while (count < niter && delta >= tolerance) do { -->
<!--   // specify boundary conditions for T -->
<!--   count += 1;        // increase the iteration counter by one -->
<!--   Tnew = T;          // will be replaced: calculate Tnew from T -->
<!--   // update delta, the greatest difference between Tnew and T -->
<!--   T = Tnew;          // update T once all elements of Tnew are calculated -->
<!--   // print the temperature at [iout,jout] if the iteration is multiple of nout -->
<!-- } -->
<!-- ``` -->

<!-- <\!-- Essentially, what we want is to repeat all the code inside the curly brackets until the number of -\-> -->
<!-- <\!-- iterations is gerater than or equal to `niter`, and then submitting it:
or the difference of temperature between iterations is -\-> -->
<!-- <\!-- less than `tolerance`. (Note that in our case, as `delta` was not initialized when declared -and thus -\-> -->
<!-- <\!-- Chapel assigned it the default real value 0.0-, we need to assign it a value greater than or equal -\-> -->
<!-- <\!-- to 0.001, or otherwise the condition of the while statemnt will never be satisfied. A good starting point -\-> -->
<!-- <\!-- is to simple say that `delta` is equal to `tolerance`). -\-> -->

<!-- Let's focus, first, on printing the temperature every 20 interations. To achieve this, we only need to -->
<!-- check whether `count` is a multiple of 20, and in that case, to print the temperature at the desired -->
<!-- position. -->

<!-- In our case we print the temperature at the desired position if the iteration is multiple of niter: -->

<!-- ```chpl -->
<!-- if count%nout == 0 then writeln('Temperature at iteration ', count, ': ', T[iout,jout]); -->
<!-- ``` -->

<!-- To print 0th iteration, we can insert just before the time loop -->

<!-- ```chpl -->
<!-- writeln('Temperature at iteration ', count, ': ', T[iout,jout]); -->
<!-- ``` -->

<!-- Note that when only one instruction will be executed, there is no need to use the curly brackets. `%` -->
<!-- returns the remainder after the division (i.e. it returns zero when `count` is multiple of 20). -->





Let's compile and run our code using the job script `serial.sh`:

```sh
#!/bin/bash
#SBATCH --time=00:05:00      # walltime in d-hh:mm or hh:mm:ss format
#SBATCH --mem-per-cpu=3600   # in MB
#SBATCH --output=solution.out
./juliaSetSerial
```
```sh
$ chpl juliaSetSerial.chpl
$ sbatch serial.sh
$ tail -f solution.out
```
```chpl
```
