+++
title = "Using command-line arguments"
slug = "chapel-06-command-line-arguments"
weight = 6
katex = true
+++

If we want to resize our image, we would need to edit the line `const n = 2_000;` in the code and then
recompile it. Wouldn't it be great if we could pass this number to the binary when it is called at the command
line, without having to recompile it?

The Chapel mechanism for this is **_config_** variables. When a variable is declared with the `config`
keyword, in addition to `var` or `const`, like this:

```chpl
config const n = 2_000;   // vertical and horizontal size of our image
```

you can its new value from the command line:

```sh
```
```sh
$ chpl juliaSetSerial.chpl   # using the default value 2_000
$ ./juliaSetSerial --n=500   # passing another value from the command line
```



{{< question num="Basic.4" >}}
> Make `c` a config variable, and test passing different values.
{{< /question >}}





<!-- From the last run of our code, we can see that 500 iterations is not enough to get to a _steady state_ (a -->
<!-- state where the difference in temperature does not vary too much, i.e. `delta`<`tolerance`). Now, if we want -->
<!-- to change the number of iterations we would need to modify `niter` in the code, and compile it again. What if -->
<!-- we want to change the number of rows and columns in our grid to have more precision, or if we want to see the -->
<!-- evolution of the temperature at a different point (iout,jout)? The answer would be the same, modify the code -->
<!-- and compile it again! -->

<!-- No need to say that this would be very tedious and inefficient. 

<!-- ```chpl -->
<!-- Temperature at iteration 0: 25.0 -->
<!-- Temperature at iteration 20: 2.0859 -->
<!-- ... -->
<!-- Temperature at iteration 2980: 0.793969 -->
<!-- Temperature at iteration 3000: 0.793947 -->
<!-- Final temperature at the desired position after 3000 iterations is: 0.793947 -->
<!-- The greatest difference in temperatures between the last two iterations was: 0.00142546 -->
<!-- ``` -->
