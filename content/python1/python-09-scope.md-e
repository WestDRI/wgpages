+++
title = "Variable scope"
slug = "python-09-scope"
weight = 9
+++

The scope of a variable is the part of a program that can see that variable.

```py
a = 5
def adjust(b):
	sum = a + b
    return sum
adjust(10)   # what will be the outcome?
```

* `a` is the global variable &nbsp;⇨&nbsp; visible everywhere
* `b` and `sum` are local variables &nbsp;⇨&nbsp; visible only inside the function

Inside a function we can access methods of global variables:

```py
a = []
def add():
    a.append(5)   # modify global `a`
add()
print(a)          # [5]
```

However, from a local scope we cannot assign to a global variable directly:

```py
a = []
def add():
    a = [1,2,3]   # this will create a local copy of `a` inside the function
    print(a)      # [1,2,3]
add()
print(a)          # []
```

## If we have time

(1) How would you [explain](./solau.md) the following:

```py
1 + 2 == 3              # returns True (makes sense!)
0.1 + 0.2 == 0.3        # returns False -- be aware of this when you use conditionals
abs(0.1+0.2 - 0.3) < 1.e-8   # compare floats for almost equality
import numpy as np
np.isclose(0.1+0.2, 0.3, atol=1e-8)
```

(2) More challening: write a code to solve x^3+4x^2-10=0 with a bisection method in the interval
    [1.3, 1.4] with tolerance 1e-8.
