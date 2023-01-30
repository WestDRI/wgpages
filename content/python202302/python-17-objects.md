+++
title = "Basics of object-oriented programming"
slug = "python-17-objects"
weight = 17
+++

<!-- Most notably, climate scientists have a very good handle on structured/procedural programming concepts, but generally -->
<!-- have little to no knowledge of the object-oriented programming concepts that underpin Python. For example, classes, -->
<!-- class methods, inheritance, etc. will likely be foreign to most people at CCCma. -->

Object-oriented programming is a way of programming in which you bundle related variables and functions into objects,
and then manipulate and use these objects as a whole. We already saw many examples of objects on Python, e.g. lists,
dictionaries, numpy arrays, that have both variables and methods inside them. In this section we will learn how to
create our own objects.

You can think of:

- **variables** as *properties* / *attributes* of an object
- **functions** as some *operations* / *methods* you can perform on this object

Let's define out first class:

```py
class Planet:
    # internally we store all numbers in cgs units
    hostObject = "Sun"     # class attribute (the same value for every class instance)
    def __init__(self, radius, mass):   # "constructor" sets the initial state of a newly created object
        self.radius = radius*1e5   # instance attribute, convert km -> cm
        self.mass = mass*1.e3      # instance attribute, convert kg->g
```

Let's define some instances of this class:

```py
mercury = Planet(radius=2439.7, mass=3.285e23) # enter km and kg
venus = Planet(6051.8, 4.867e24)               # enter km and kg
venus.radius, venus.mass, venus.hostObject
```

Instances are guaranteed to have the attributes that we expect.

{{< question num=23 >}}
How can we define an instance without passing the values? E.g., I would like to say `earth = Planet()` and then pass the
attribute values separately like this:
```py
earth = Planet()
earth.radius = 6371         # these are dynamic variables that we can redefine
earth.mass = 5.972e24
```
{{< /question >}}

<!-- Planet().radius      # prints 'nan' -->

Let's add *inside our class* an instance method (with proper indentation):

```py
    def density(self):   # it acts on the class instance
        return self.mass/(4./3.*math.pi*self.radius**3) # [g/cm^3]
```

Redefine the class, and now:

```py
earth = Planet()
earth.radius = 6371*1e5      # here we need to convert manually
earth.mass = 5.972e24*1e3
import math
earth.density()    # 5.51 g/cm^3
```

Let's add another method (remember the indentation!):

```py
    def g(self):   # free fall acceleration
        return 6.67259e-8*self.mass/self.radius**2    # G in [cm^3/g/s^2]
```

and now

```py
earth = Planet(6371,5.972e24)
mars = Planet(3389.5,6.39e23)
earth.g()              # 981.7 cm/s^2
mars.g() / earth.g()   # 0.378
```

Let's add another method (remember the indentation!):

```py
    def describe(self):
        print('density =', self.density(), 'g/cm^3')
        print('free fall =', self.g(), 'cm/s^2')
```

Redefine the class, and now:

```py
jupyter = Planet(radius=69911, mass=1.898e27)
jupyter.describe()       # should print 1.32 g/cm^3 and 2591 cm/s^2
print(jupyter)           # says it is an object at this memory location (not very descriptive)
```

Let's add our last method (remember the indentation!):

```py
    def __str__(self):    # special method to redefine the output of print(self)
        return f"My radius is {self.radius/1e5}km and my mass is {self.mass/1e3}kg"
```

Redefine the class, and now:

```py
jupyter = Planet(radius=69911, mass=1.898e27)
print(jupyter)        # prints the full sentence
```

**Important**: As with any complex object in Python, assigning an instance to a new variable will simply create a
pointer, i.e. if you modify one in place, you'll see the change through the other one too:

```py
new = jupyter
jupyter.mass = -1
new.mass     # also -1
```

If you want a separate copy:

```py
import copy
new = copy.deepcopy(jupyter)
jupyter.mass = -2
new.mass     # still -1
```

## Inherit from parent classes

Let's create a child class `Moon` that would inherit the attributes and methods of `Planet` class:

```py
class Moon(Planet):    # it inherits all the attributes and methods of the parent process
    pass

phobos = Moon(radius=22.2, mass=1.08e16)
deimos = Moon(radius=12.6, mass=2.0e15)
phobos.g() / earth.g()        # 0.0001489
isinstance(phobos, Moon)         # True
isinstance(phobos, Planet)       # True - all objects of a child class are instances of the parent class
isinstance(jupyter, Planet)      # True
isinstance(jupyter, Moon)        # False
issubclass(Moon,Planet)      # True
```

Child classes can have their own attributes and methods that are distinct from (i.e. override) the parent class:

```py
class Moon(Planet):
    hostObject = 'Mars'
    def g(self):
        return 'too small to compute accurately'
    
phobos = Moon(radius=22.2, mass=1.08e16)
deimos = Moon(radius=12.6, mass=2.0e15)
mars = Planet(3389.5,6.39e23)
phobos.hostObject, mars.hostObject     # ('Mars', 'Sun')
phobos.g(), mars.g()                   # ('too small to compute accurately', 371.1282569773226)
```

One thing to keep in mind about class inheritance is that changes to the parent class automatically propagate to child
classes (when you follow the sequence of definitions), unless overridden in the child class:

```py
class Parent:
	...
    def __str__(self):
        return "Changed in the parent class"
	...

class Moon(Planet):
    hostObject = 'Mars'
    def g(self):
        return 'too small to compute accurately'

deimos = Moon(radius=12.6, mass=2.0e15)
print(deimos)            # prints "Changed in the parent class"
```

You can access the parent class namespace from inside a *method* of a child class by using super():

```py
class Moon(Planet):
    hostObject = 'Mars'
    def parentHost(self):
        return super().hostObject       # will return hostObject of the parent class

deimos = Moon(radius=12.6, mass=2.0e15)
deimos.hostObject, deimos.parentHost()     # ('Mars', 'Sun')
```

## Generators

We already saw that in Python you can loop over a collection using `for`:

```py
for i in 'weather':
    print(i)
for j in [5,6,7]:
    print(j)
```

Behind the scenes Python creates an iterator out of a collection. This iterator has a `__next__()` method, i.e. it does
something like:

```py
a = iter('weather')
a.__next__()    # 'w'
a.__next__()    # 'e'
a.__next__()    # 'a'
```

You can build your own iterator as if you were defining a function. Such function is called a *generator* in Python:

```py
def cycle():
    yield 1
    yield 'hello'
    yield [1,2,3]

[i for i in cycle()]               # [1, 'hello', [1, 2, 3]]

def square(x):   # `x` is an input string in this generator
    for letter in x:
        yield int(letter)**2       # yields a sequence of numbers that you can cycle through

[i for i in square('12345')]       # [1, 4, 9, 16, 25]

a = square('12345')
[a.__next__() for i in range(3)]   # [1, 4, 9]
```











# Programming Style and Wrap-Up

* comment your code as much as possible
* use meaningful variable names
* very good idea to break complex programs into blocks using functions
* change one thing at a time, then test
* use revision control
* use docstrings to provide online help

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

* very good idea to add assertions to your code to check things

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

* Python 3 documentation https://docs.python.org/3
* Matplotlib gallery http://matplotlib.org/gallery.html
* NumPy is a scientific computing package http://www.numpy.org
* SciPy is a rich collection of scientific utilities http://www.scipy.org/scipylib
* Python Data Analysis Library http://pandas.pydata.org













<!-- # Other advanced Python topics -->

<!-- - list.sort() and list.index(value); heterogeneous lists -->
<!-- - to/from matplotlib, to/from numpy -->

<!-- <\!-- https://www.w3resource.com/python-exercises/list -\-> -->
<!-- <\!-- https://www.google.ca/amp/s/zwischenzugs.com/2018/01/06/ten-things-i-wish-id-known-about-bash/amp/#ampshare=https://zwischenzugs.com/2018/01/06/ten-things-i-wish-id-known-about-bash -\-> -->
<!-- <\!-- https://github.com/ComputeCanada/DC-shell_automation -\-> -->
