+++
title = "Variables and data types"
slug = "python-02-variables"
weight = 2
+++

## Variables and Assignment

- Python is a dynamically typed language: all variables have types, but types can change on the fly
- possible names for variables
  - don't use built-in function names for variables, e.g. setting a `sum` variable will prevent you from using
    the built-in `sum()` function
- Python is case-sensitive

```py
age = 100
firstName = 'Jason'
print(firstName, 'is', age, 'years old')
a = 1; b = 2    # can use ; to separate multiple commands in one line
a, b = 1, 2   # assign variables in a tuple notation; same as last line
a = b = 10    #  assign a value to multiple variables at the same time
b = "now I am a string"    # variables can change their type on the fly
```

* variables persist between cells
* variables must be defined before use
* variables can be used in calculations

```py
age = age + 3   # another syntax: age += 3
print('age in three years:', age)
```

{{< question num=2.1 >}}
What is the final value of `position` in the program below? (Try to predict the value without running the program, then
check your prediction.)
```py
initial = "left"
position = initial
initial = "right"
```
{{< /question >}}

With simple variables in Python, assigning `var2 = var1` will create a new object in memory `var2`. Here we have two
distinct objects in memory: `initial` and `position`.

> Note: With more complex (mutable) objects, its name could be a pointer. E.g. when we study lists, we'll see
> that `initial` and
> `new` below really point to the same list in memory:
> ```
> initial = [1,2,3]
> new = initial        # create a pointer to the same object
> initial.append(4)    # change the original list to [1, 2, 3, 4]
> print(new)           # [1, 2, 3, 4]
> new = initial[:]     # one way to create a new object in memory
> import copy
> new = copy.deepcopy(initial)   # another way to create a new object in memory
> ```

Use square brackets to get a substring:
```py
element = 'helium'
print(element[0])     # single character
print(element[0:3])   # a substring
```

* Python is case-sensitive
* use meaningful variable names

## Data Types and Type Conversion

```py
print(type(52))
print(type(52.))
print(type('52'))
```

```py
print(name+' Smith')   # can add strings
print(name*10)         # can replicate strings by mutliplying by a number
print(len(name))       # strings have lengths
```

```py
print(1+'a')        # cannot add strings and numbers
print(str(1)+'a')   # this works
print(1+int('2'))   # this works
```

{{< question num=2.2 >}} If you assign some arbitrary integer value to `a`, e.g. `a=123` or `a=87236`, write a
code to get the second digit of `a`.  {{< /question >}}
