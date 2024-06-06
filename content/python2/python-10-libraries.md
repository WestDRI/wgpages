+++
title = "Libraries"
slug = "python-10-libraries"
weight = 1
+++

<!-- <u>For Day 2</u>, we will switch to running inside Jupyter Notebook -- please see option 2 in -->
<!-- [the Setup section](../python-01-setup#starting-python). -->




> There are many ways to run Python: in the shell, via scripts, in a Jupyter notebook. In this session we'll
> be running Python in the terminal inside an interactive job. We have preinstalled all libraries for today
> into a virtual environment `/project/def-sponsor00/shared/scientificpython-env` accessible to all users on
> the training cluster, so our workflow will be:
> ```sh
> module load StdEnv/2023 python/3.11.5 arrow/14.0.1 scipy-stack/2023b netcdf/4.9.2
> source /project/def-sponsor00/shared/scientificpython-env/bin/activate
> salloc --time=2:00:0 --mem-per-cpu=3600
> python
> ...
> ```




<!-- > Today we'll be running Python via JupyterHub on our training cluster. Point your browser to -->
<!-- > https://oc.c3.ca, log in with your guest username and password, then launch a JupyterHub server with time = -->
<!-- > ***3 hours***, **1 CPU core**, memory = ***3600 MB***, GPU configuration = ***None***, user interface = -->
<!-- > ***JupyterLab***. Finally, start a new Python 3 notebook. -->
<!-- {{< figure src="/img/jupyterlab.png" height=550 >}} -->








Most of the power of a programming language is in its libraries. This is especially true for Python which is
an interpreted language and is therefore very slow (compared to compiled languages). However, libraries are
often compiled, as they were written in compiled languages such as C/C++, and therefore offer much faster
performance than native Python code.

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
You want to select a random character from the string `bases='ACTTGCTTGAC'`. What standard library would you
most expect to help? Which function would you select from that library? Are there alternatives?
{{< /question >}}

{{< question num=10.3 >}}
A colleague of yours types `help(math)` and gets an error: `NameError: name 'math' is not defined`. What has
your colleague forgotten to do?
{{< /question >}}

{{< question num=10.4 >}}
Convert the angle 0.3 rad to degrees using the math library.
{{< /question >}}

## Virtual environments and packaging

<!-- Something that comes up often when trying to get people to use python is virtual environments and packaging - -->
<!-- it would be nice if there could be a discussion on this as well. -->

<!-- To install a package into the current Python environment from inside a Jupyter notebook, simply do (you will -->
<!-- probably need to restart the kernel before you can use the package): -->
<!-- ```sh -->
<!-- %pip install packageName   # e.g. try bson -->
<!-- ``` -->

In Python you can create an isolated environment for each project, into which all of its dependencies will be
installed. This could be useful if your several projects have very different sets of dependencies. On the computer
running your Jupyter notebooks, open the terminal and type:

(**Important**: on a cluster you must do this on the login node, not inside the JupyterLab terminal.)

```sh
module load python/3.10.2          # specific to HPC clusters
pip install virtualenv
virtualenv --no-download climate   # create a new virtual environment in your current directory
source climate/bin/activate
which python && which pip
pip install --no-index numpy netcdf4 ...
pip install --no-index ipykernel   # install ipykernel (IPython kernel for Jupyter) into this environment
python -m ipykernel install --user --name=climate --display-name "My climate project"   # add your environment to Jupyter
...
deactivate
```

Quit all your currently running Jupyter notebooks and the Jupyter dashboard. Reopen the notebook dashboard,
and one of the options in `New` below `Python 3` should be `climate`.

<!-- If running on syzygy.ca, logout from your -->
<!-- session and then log back in. -->

To delete the environment, in the terminal type:

```sh
jupyter kernelspec list                  # `climate` should be one of them
jupyter kernelspec uninstall climate     # remove your environment from Jupyter
/bin/rm -rf climate
```









##  Quick overview of some of the libraries

- `Pandas` (and its more efficient replacemet `Polars`) is a library for working with 2D tables / spreadsheets.
- `NumPy` is a library for working with large, multi-dimensional arrays, along with a large collection of
  linear algebra functions.
  - provides missing uniform collections (arrays) in Python, along with a large number of ways to quickly
    process these collections ⮕ great for speeding up calculations in Python
- `Matplotlib` and `Plotly` are two plotting packages for Python.
- `Scikit-image` is a collection of algorithms for image processing.
- `Xarray` is a library for working with labelled multi-dimensional arrays and datasets in Python.
  - been called "`pandas` for multi-dimensional arrays"
  - great for large scientific datasets; writes into NetCDF files
