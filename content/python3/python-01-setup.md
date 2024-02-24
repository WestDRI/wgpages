+++
title = "Setup and running Jupyter notebooks"
slug = "python-01-setup"
weight = 1
+++

**Disclaimer**: These notes started number of years ago from the [official SWC
lesson](https://software-carpentry.org/lessons) but then evolved quite a bit to include other topics.





## Why Python?

Python is a free, open-source programming language first developed in the late 1980s and 90s that became
really popular for scientific computing in the past 15 years. With Python in a few minutes you can:
- analyze thousands of texts,
- process tables with billions of records,
- manipulate thousands of images,
- restructure and process data any way you want.

#### Python vs. Excel

- Unlike Excel, Python can read any type of data, both structured and unstructured.
- Python is free and open-source, so no artificial limitations on where/how you run it.
- Python works on all platforms: Windows, Mac, Linux, Android, etc.
- Data manipulation is much easier in Python. There are hundreds of data processing, machine learning, and
  visualization libraries.
- Python can handle much larger amounts of data: limited not by Python, but by your available computing
  resources. In addition, Python can run at scale (in parallel) on larger systems.
- Python is more reproducible (rerun / modify the script).

<!-- Python code is easier to reproduce -->
<!-- Python is faster doing difficult calculations. -->
<!-- Python is easier than vba. -->
<!-- Python works better with big data. -->
<!-- Python is open source and has access to an enormous amount of libraries. -->
<!-- On the other hand. -->
<!-- Excel is known by more people. -->
<!-- Excel is faster for simple calculations, graphs etc. -->

#### Python vs. other programming languages

Python pros                                 | Python cons
--------------------------------------------|------------------------
elegant scripting language                  | slow (interpreted, dynamically typed)
easy to write and read code                 | uses indentation for code blocks
powerful, compact constructs for many tasks |
very popular across all fields              |
huge number of external libraries           |







## Installing Python locally

Today we'll be running Python in the cloud, so you can skip this section. I am listing these options in case
you want to install Python on your computer after the workshop.

**Option 1**: Install Python from https://www.python.org/downloads making sure to check the option "Add Python
to PATH" during the installation.

**Option 2**: Install Python and the packages via Anaconda from https://www.anaconda.com/download.

**Option 3**: Install Python via your favourite package manager, e.g. in MacOS -- assuming you have
[Homebrew](https://brew.sh) installed -- run the command `brew install python`.

**Post-installation**: Install 3rd-party Python packages in the Command Prompt / terminal via `pip install
<packageName>`, e.g. to be able to run Python inside a Jupyter Notebook run `pip install jupyter`.





## Starting Python

There are many ways to run Python commands:

* from a Unix shell you can start a Python shell and type commands there,
* you can launch Python scripts saved in plain text *.py files,
* you can execute Python cells inside Jupyter notebooks; the code is stored inside JSON files, displayed as HTML

<!-- Today we will be using a Jupyter notebook. -->






## Today's setup

Today we'll be using JupyterHub on our training cluster. Point your browser to https://hss.c3.ca and log in
with your username and password, then launch a JupyterHub server with time = ***2.5 hours***, **1 CPU core**,
memory = ***3712 MB***, GPU configuration = ***None***, user interface = ***JupyterLab***. Finally, start a
new Python 3 notebook.

{{< figure src="/img/jupyterlab.png" height=650 >}}

After you log in, in the dashboard start a new Python 3 notebook.

<!-- 4. **Community cloud option**: use syzygy.ca with one of the following accounts: -->
<!--     - if you have a university computer ID &nbsp;&rarr;&nbsp; go to <a href="https://syzygy.ca" -->
<!--       target="_blank">syzygy.ca</a>, under Launch select your institution, then log in with your university credentials -->
<!--     - if you have a Google account &nbsp;&rarr;&nbsp; go to <a href="https://syzygy.ca" target="_blank">syzygy.ca</a>, -->
<!--       under Launch select either Cybera or PIMS, then log in with your Google account -->
<!-- 	<\!-- - if you have a GitHub account &nbsp;&rarr;&nbsp; go to https://westgrid.syzygy.ca, sign in with your GitHub account -\-> -->
<!-- Note that syzygy.ca is a free community service run on the Alliance cloud and used heavily for undergraduate -->
<!-- teaching, with no uptime guarantees. In other words, it usually works, but it could be unstable or down. -->








<!-- ## Virtual Python environments -->

<!-- We talk about creating Virtual Python environments in the HPC course. These environment are very useful, as -->
<!-- not only can you install packages into your directories without being root, but they also let you create -->
<!-- sandbox Python environments with your custom set of packages -- perfect when you work on multiple projects, -->
<!-- each with a different list of dependencies. -->

<!-- To create a Python environment (you do this only once): -->

<!-- ```sh -->
<!-- module avail python               # several versions available -->
<!-- module load python/3.10.2 -->
<!-- virtualenv --no-download astro    # install Python tools in your $HOME/astro -->
<!-- source astro/bin/activate -->
<!-- pip install --no-index --upgrade pip -->
<!-- pip install --no-index numpy jupyter pandas            # all these will go into your $HOME/astro -->
<!-- avail_wheels --name "*tensorflow_gpu*" --all_versions   # check out the available packages -->
<!-- pip install --no-index tensorflow_gpu==2.2.0            # if needed, install a specific version -->
<!-- ... -->
<!-- deactivate -->
<!-- ``` -->

<!-- Once created, you would use it with: -->

<!-- ```sh -->
<!-- source ~/astro/bin/activate -->
<!-- python -->
<!-- ... -->
<!-- deactivate -->
<!-- ``` -->

<!-- We'll talk more about virtual Python environments in -->
<!-- [Section 10](../python-10-libraries#virtual-environments-and-packaging). -->







## Navigating Jupyter interface

- File | Save Notebook As - to rename your notebook
- File | Download - download the notebook to your computer
- File | New Launcher - to open a new launcher dashboard, e.g. to start a terminal
- File | Log Out - to terminate your job (everything is running inside a Slurm job!)

Explain: tab completion, annotating code, displaying figures inside the notebook.

- <font size="+2">Esc</font> - leave the cell (border changes colour) to the control mode
- <font size="+2">A</font> - insert a cell above the current cell
- <font size="+2">B</font> - insert a cell below the current cell
- <font size="+2">X</font> - delete the current cell
- <font size="+2">M</font> - turn the current cell into the markdown cell
- <font size="+2">H</font> - to display help
- <font size="+2">Enter</font> - re-enter the cell (border becomes green) from the control mode
- you can enter Latex expressions in a markdown cell, e.g. try typing `\int_0^\infty f(x)dx` inside two dollar
  signs

```py
print(1/2)   # to run all commands in the cell, either use the Run button, or press shift+return
```
