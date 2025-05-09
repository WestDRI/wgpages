+++
title = "Julia set on distributed domains"
slug = "chapel-15-distributed-julia-set"
weight = 15
katex = true
+++




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
