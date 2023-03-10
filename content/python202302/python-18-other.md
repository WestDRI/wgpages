+++
title = "Other topics"
slug = "python-18-other"
weight = 18
+++

# Caching function calls ("memoization")

<!-- more on this at https://wiki.python.org/moin/PythonDecoratorLibrary#Memoize -->

### Simple example

Consider the following function:

```py
import time
def slow(x):
    time.sleep(1) # mimicking some heavy computation
    return x
```

Calling it 20 times will result in a 20-sec wait:

```py
%%time
for i in range(10):
    slow(2)
    slow(3)
```
Wall time: 20.1 s

In reality there are only 2 functions calls: `slow(2)` and `slow(3)`, and everything else is just a repeat.

Now let's cache our function calls with a *decorator*:

```py
import collections
import functools

class memoized(object):
   '''Decorator. Caches a function's return value each time it is called.
   If called later with the same arguments, the cached value is returned
   (not reevaluated).
   '''
   def __init__(self, func):
      self.func = func
      self.cache = {}
   def __call__(self, *args):
      if not isinstance(args, collections.abc.Hashable):
         # uncacheable. a list, for instance.
         # better to not cache than blow up.
         return self.func(*args)
      if args in self.cache:
         return self.cache[args]
      else:
         value = self.func(*args)
         self.cache[args] = value
         return value
   def __repr__(self):
      '''Return the function's docstring.'''
      return self.func.__doc__
   def __get__(self, obj, objtype):
      '''Support instance methods.'''
      return functools.partial(self.__call__, obj)

@memoized
def fast(x):
    time.sleep(1) # mimicking some heavy computation
    return x
```

The function will be called twice, and the other 18 times it'll reuse previously computed results:

```py
%%time
for i in range(10):
    fast(2)
    fast(3)
```
Wall time: 2.01 s

### Badly-coded Fibonacci problem

Consider a top-down (and thus terribly inefficient) Fibonacci number calculation:

```py
def fibonacci(n):
    if n == 0:
        return 0
    elif n == 1:
        return 1
    return fibonacci(n-1) + fibonacci(n-2)
```
```py
%%timeit
fibonacci(30)
```
181 ms ± 2.85 ms per loop (mean ± std. dev. of 7 runs, 1 loop each)

The total number of `fibonacci()` calls in this example is 2,692,537, and it scales exponentially towards
lower `n`, e.g. `f(1)` is evaluated 832,040 times. It turns out it is possible to store previous function
calls and only compute new ones using the following *decorator*.

```py
import collections
import functools

class memoized(object):
   '''Decorator. Caches a function's return value each time it is called.
   If called later with the same arguments, the cached value is returned
   (not reevaluated).
   '''
   def __init__(self, func):
      self.func = func
      self.cache = {}
   def __call__(self, *args):
      if not isinstance(args, collections.abc.Hashable):
         # uncacheable. a list, for instance.
         # better to not cache than blow up.
         return self.func(*args)
      if args in self.cache:
         return self.cache[args]
      else:
         value = self.func(*args)
         self.cache[args] = value
         return value
   def __repr__(self):
      '''Return the function's docstring.'''
      return self.func.__doc__
   def __get__(self, obj, objtype):
      '''Support instance methods.'''
      return functools.partial(self.__call__, obj)

@memoized
def fastFibonacci(n):
    if n == 0:
        return 0
    elif n == 1:
        return 1
    return fastFibonacci(n-1) + fastFibonacci(n-2)
```

```py
%%timeit
fastFibonacci(30)
```
268 ns ± 1.23 ns per loop (mean ± std. dev. of 7 runs, 1,000,000 loops each)

We have a speedup by a factor of 675,000! This is even better than the anticipated speedup of $2,692,537/30
\approx 89,751$ (from the reduction in the number of function calls) which probably tells us something about
the overhead of managing many thousands of simultaneous nested function calls in Python in the first place.











# Programming Style and Wrap-Up

* Comment your code as much as possible.
* Use meaningful variable names.
* Very good idea to break complex programs into blocks using functions.
* Change one thing at a time, then test.
* Use version control.
* Use docstrings to provide online help:

```py
def average(values):
    "Return average of values, or None if no values are supplied."
    if len(values) > 0:
        return(sum(values)/len(values))

print(average([1,2,3,4]))
print(average([]))
help(average)
```

```py
def moreComplexFunction(values):
    """This string spans
       multiple lines.

    Blank lines are allowed."""

help(moreComplexFunction)
```

* Very good idea to add assertions to your code to check input:

```py
assert n > 0., 'Data should only contain positive values'
```

is the same as

```py
import sys
if n <= 0.:
    print('Data should only contain positive values')
    sys.exit(1)
```

# Links

* {{<a "https://docs.python.org/3" "Python 3 documentation">}}
* {{<a "http://matplotlib.org/gallery.html" "Matplotlib gallery">}}
* {{<a "http://www.numpy.org" "NumPy">}} scientific computing package
* {{<a "http://www.scipy.org" "SciPy">}} collection of scientific utilities
* {{<a "http://pandas.pydata.org" "Pandas">}} library
* {{<a "https://docs.xarray.dev" "Xarray documentation">}}

<!-- {{<a "link" "text">}} -->







<!-- # Other advanced Python topics -->

<!-- - list.sort() and list.index(value); heterogeneous lists -->
<!-- - to/from matplotlib, to/from numpy -->

<!-- <\!-- https://www.w3resource.com/python-exercises/list -\-> -->
<!-- <\!-- https://www.google.ca/amp/s/zwischenzugs.com/2018/01/06/ten-things-i-wish-id-known-about-bash/amp/#ampshare=https://zwischenzugs.com/2018/01/06/ten-things-i-wish-id-known-about-bash -\-> -->
<!-- <\!-- https://github.com/ComputeCanada/DC-shell_automation -\-> -->
