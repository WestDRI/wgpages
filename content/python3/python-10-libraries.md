+++
title = "Libraries"
slug = "python-10-libraries"
weight = 10
+++

<!-- <u>For Day 2</u>, we will switch to running inside Jupyter Notebook -- please see option 2 in -->
<!-- [the Setup section](../python-01-setup#starting-python). -->

Most of the power of a programming language is in its libraries. This is especially true for Python which is an
interpreted language and is therefore very slow (compared to compiled languages). However, the libraries are often
compiled (can be written in compiled languages such as C/C++) and therefore offer much faster performance than native
Python code.

A library is a collection of functions that can be used by other programs. Python's *standard library* includes many
functions we worked with before (print, int, round, ...) and is included with Python. There are many other additional
modules in the standard library such as math:

```py
print('pi is', pi)
import math
print('pi is', math.pi)
```

You can also import math's items directly:

```py
from math import pi, sin
print('pi is', pi)
sin(pi/6)
cos(pi)
help(math)   # help for libraries works just like help for functions
from math import *
```

You can also create an alias from the library:

```py
import math as m
print m.pi
```

{{< question num=10.1 >}}
What function from the math library can you use to calculate a square root without using `sqrt`?
{{< /question >}}

{{< question num=10.2 >}}
You want to select a random character from the string `bases='ACTTGCTTGAC'`. What standard library would you most expect
to help? Which function would you select from that library? Are there alternatives?
{{< /question >}}

{{< question num=10.3 >}}
A colleague of yours types `help(math)` and gets an error: `NameError: name 'math' is not defined`. What has your
colleague forgotten to do?
{{< /question >}}

{{< question num=10.4 >}}
Convert the angle 0.3 rad to degrees using the math library.
{{< /question >}}







## Virtual environments and packaging

<!-- Something that comes up often when trying to get people to use python is virtual environments and packaging - -->
<!-- it would be nice if there could be a discussion on this as well. -->

To install a 3rd-party library into the current Python environment from inside a Jupyter notebook, simply do (you will
probably need to restart the kernel before you can use the package):

```sh
%pip install <packageName>   # e.g. try bson
```

In Python you can create an isolated environment for each project, into which all of its dependencies will be
installed. This could be useful if your several projects have very different sets of dependencies. On the computer
running your Jupyter notebooks, open the terminal and type:

(**Important**: on a cluster you must do this on the login node, not inside the JupyterLab terminal.)

```sh
module load python/3.9.6    # specific to HPC clusters
pip install virtualenv
virtualenv --no-download climate   # create a new virtual environment in your current directory
source climate/bin/activate
which python && which pip
pip install --no-index netcdf4 ...
...
deactivate
```

To use this environment in the terminal, you would do:

```py
source climate/bin/activate
...
deactivate
```

Optionally, you can add your environment to Jupyter:

```sh
pip install --no-index ipykernel    # install ipykernel (IPython kernel for Jupyter) into this environment
python -m ipykernel install --user --name=climate --display-name "My climate project" # add your env to Jupyter
...
deactivate
```

Quit all your currently running Jupyter notebooks and the Jupyter dashboard, and then restart. One of the
options in `New` below `Python 3` should be `climate`.

To delete the environment, in the terminal type:

```sh
jupyter kernelspec list                  # `climate` should be one of them
jupyter kernelspec uninstall climate     # remove your environment from Jupyter
/bin/rm -rf climate
```

##  Quick overview of some of the libraries

<!-- - `NumPy` is a library for working with large, multi-dimensional arrays, along with a large collection of -->
<!--   linear algebra functions -->
<!--   - provides missing uniform collections (arrays) in Python, along with a large number of ways to quickly -->
<!--     process these collections ⮕ great for speeding up calculations in Python -->
<!--   - we won't study it in detail this workshop -->

Python lists are very general and flexible, which is great for high-level programming, but it comes at a
cost. The Python interpreter can't make any assumptions about what will come next in a list, so it treats
everything as a generic object with its own type and size. As lists get longer, eventually performance takes a
hit.

Python does not have any mechanism for a uniform/homogeneous list, where -- to jump to element #1000 -- you
just take the memory address of the very first element and then increment it by (element size in bytes)
x 999. **NumPy** library fills this gap by adding the concept of homogenous collections to python --
`numpy.ndarray`s -- which are multidimensional, homogeneous arrays of fixed-size items (most commonly numbers,
but could be strings too). This brings huge performance benefits!

To speed up calculations with NumPy, typically you perform operations on entire arrays, and this by extension
applies the same operation to each array element. Since NumPy was written in C, it is much faster for
processing multiple data elements than manually looping over these elements in Python.

Learning NumPy is outside the scope of this introductory workshop, but there are many packages built on top of
NumPy that could be used in HSS:

- `pandas` is a library for working with 2D tables / spreadsheets, built on top of numpy
- `scikit-image` is a collection of algorithms for image processing, built on top of numpy
- `Matplotlib` and `Plotly` are two plotting packages for Python
- `xarray` is a library for working with labelled multi-dimensional arrays and datasets in Python
  - "`pandas` for multi-dimensional arrays"
  - great for large scientific datasets; writes into NetCDF files
  - we won't study it in this workshop
  
We'll also take a look at these two libraries (not based on NumPy):
- `requests` is an HTTP library to download HTML data from the web
- `Beautiful Soup` is a library to parse these HTML data
