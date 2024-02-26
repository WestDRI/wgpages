+++
title = "Working with strings, variable scope, exceptions"
slug = "python-09-scope"
weight = 9
+++

## Working with strings

A `string` object in Python has a number of built-in methods:

```py
event = "HSS Winter Series"
event.<hit TAB once or twice>   # strings can access a number of methods = functions
event.capitalize()
event.count("S")
event.find("S")       # the first occurrence
event.find("hello")   # -1 = not found
event = event.replace("HSS", "Humanities and Social Sciences")
event += " 2024"
event.lower()
event.upper()
```

We can do all of this manipulation in one line:

```py
event = "HSS Winter Series"
(event.replace("HSS", "Humanities and Social Sciences")+" 2024").upper()
```

At this point you might ask about finding all occurrences of "S" inside `events`. One possible solution:

```py
import re   # regular expressions library
[m.start() for m in re.finditer("S", event)]   # [1, 2, 11]
```

Let's now split our string:

```py
words = event.split()   # split into words
'_'.join(words)         # join these words into a string with the `-` separator
```

This `.join()` syntax is useful for many purposes, e.g. you can use it to convert a list to a string:

```py
sentence = ["Good", "morning"]
str(sentence)        # this is not what we want ...
" ".join(sentence)   # this works!
```









## Variable scope

The scope of a variable is the part of a program that can see that variable.

```py
a = 5
def adjust(b):
	sum = a + b
    return sum
adjust(10)   # what will the outcome be?
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






## Handling exceptions

Putting some explicit logic into your code to deal with errors will make your code more robust. For example,
if the input data are missing, you can have some printout to show the instructions to get the data at runtime.

This error handling can be applied to calculations too. Let's say we want to write a code to calculate
mortgage payments. For a fixed interest rate in percent, we have two of the following three variables: (1) the
principal amount, (2) the term in years, or (3) a monthly payment. Our code will calculate the third variable,
based on the other two. There are three scenarios:

(1) If we have the **principal amount** and the **term in years**, here is how you would calculate the monthly
payment:

```py
r = rate / 1200
q = (1 + r)**(12*term)
payment = principal * r * q / (q - 1)
```

(2) If we have the **monthly payment** and the **principal amount**, here is how you would calculate the term
in years:

```py
r = rate / 1200
q =  payment / (payment - principal * r)
if q < 0.:
    print("you will never pay it off ...")
    exit(1)
term = log(q) / (log(1+r)*12)
```

(3) If we have the **term in years** and the **monthly payment**, here is how you would calculate the
principal amount:

```py
r = rate / 1200
q = (1 + r)**(12*term)
principal = payment * (q - 1) / (r * q)
```

How can we tell the code to decide on the fly which variable it needs to compute, based on the two existing ones?

We would like to do something like this (not actual Python code):

```py
if payment is not defined:
    use formula 1
if term is not defined:
    use formula 2
if principal is not defined:
    use formula 3
```

Consider this syntax:

```py
try:
    someUndefinedVariable       # here is what we try to do
except NameError:
    someUndefinedVariable = 1   # if that produces NameError, don't show it, but do this instead
    print(someUndefinedVariable)
```

And you can combine multiple error codes, e.g.

```py
...
except (RuntimeError, TypeError, NameError):
...
```

{{< question num=9.1 >}}
Write the rest of the mortgage calculation code.
{{< /question >}}

<!-- ```sh -->
<!-- try: -->
<!--     payment -->
<!-- except NameError: -->
<!--     r = rateInPercent / 1200 -->
<!--     q = (1 + r)**(12*termInYears) -->
<!--     payment = principal * r * q / (q - 1) -->
<!-- ``` -->

> Note: You can also implement this code setting `payment = None` for a missing variable, and then placing the
> code under `if payment == None` condition. Alternatively, you can put everything into a function with
> optional arguments that default to None unless assigned values. I personally like the implementation with
> the exception handling, as this way you don't have to assign the missing variable at all.









## Number crunching in Python: if we have time

(1) How would you [explain](./solau.md) the following:

```py
1 + 2 == 3         # returns True (makes sense!)
0.1 + 0.2 == 0.3   # returns False -- be aware of this when you use conditionals
abs(0.1+0.2 - 0.3) < 1.e-8   # compare floats for almost equality
import numpy as np
np.isclose(0.1+0.2, 0.3, atol=1e-8)
```

(2) More challening: write a code to solve $x^3+4x^2-10=0$ with a bisection method in the interval $[1.3,
    1.4]$ with tolerance $10^{-8}$.
