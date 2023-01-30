+++
title = "Built-in functions and help"
slug = "python-03-builtin"
weight = 3
+++

* Python comes with a number of built-in functions
* a function may take zero or more arguments

```py
print('hello')
print()
```

```py
print(max(1,2,3,10))
print(min(5,2,10))
print(min('a', 'A', '0'))   # works with characters, the order is (0-9, A-Z, a-z)
print(max(1, 'a'))    # can't compare these
round(3.712)      # to the nearest integer
round(3.712, 1)   # can specify the number of decimal places
help(round)
round?   # Jupyter Notebook's additional syntax
```

* every function returns something, whether it is a variable or None
```py
result = print('example')
print('result of print is', result)   # what happened here? Answer: print returns None
```
