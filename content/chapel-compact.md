+++
title = "Parallel programming in Chapel"
slug = "chapel-compact"
aliases = ["chapel"]
+++

{{<cor>}}June 12<sup>th</sup>{{</cor>}}\
{{<cgr>}}1:30pm-4:30pm Pacific Time{{</cgr>}}

Chapel is a modern programming language designed for both shared and distributed memory systems, offering
high-level, easy-to-use abstractions for task and data parallelism. Its intuitive syntax makes it an excellent
choice for novice HPC users learning parallel programming. Chapel supports a wide range of parallel hardware
-- from multicore processors and multi-node clusters to GPUs -- using consistent syntax and concepts across
all levels of hardware parallelism.

Chapel dramatically reduces the complexity of parallel coding by combining the simplicity of Python-style
programming with the performance of compiled languages like C and Fortran. Parallel operations that might
require dozens of lines in MPI can often be written in just a few lines of Chapel. As an open-source language,
it runs on most Unix-like operating systems and scales from laptops to large HPC systems.

This course begins with Chapel fundamentals, then focuses on data parallelism through two numerical examples:
one embarrassingly parallel and one tightly coupled. We'll also briefly explore task parallelism (a more
complex topic, and not the primary focus in this course). Finally, we'll introduce GPU programming with
Chapel.

<!-- 1. Instructor / helpers / course introduction -->
<!-- 1. Introduction to Chapel (download the [PDF slides](http://bit.ly/chapeltop)) -->
<!-- 1. Distribute usernames and passwords -->
<!-- 1. Hands-on on the cluster:   -->
<!--   4.1 let's try to log in to the training cluster   -->
<!--   4.2 let's try loading single-locale Chapel and compiling a simple code   -->
<!--   4.3 let's write a makefile for compiling Chapel codes   -->
<!--   4.4 let's submit a serial job script to run Chapel on a compute node -->
<!-- 1. Review the program for self-study:   -->
<!--   5.1 build step-by-step a serial heat diffusion solver   -->
<!--   5.2 task parallelism in shared-memory -->
<!-- Start with the **Basic language features** page. Next go to **Task parallelism** and try to go as far as you can in that -->
<!-- page before the mid-day session. I suggest skipping *"Parallelizing the heat transfer equation"* subsection at the end -->
<!-- to save time. -->
<!-- Try to do all exercises in the lessons. The solutions are posted at the end of each page: please try not to look at them -->
<!-- while working on the problems. -->

<!-- 1. Answer any questions + go through the main points from the morning   -->
<!--     1.1 serial heat diffusion solver   -->
<!--     1.1 task parallelism in shared-memory -->
<!-- 1. Review the program for the afternoon: data parallelism -->
<!-- 1. Let's try loading multi-locale Chapel and compiling a simple multi-locale code -->

**Instructor**: Alex Razoumov (SFU)

**Prerequisites:** basic understanding of HPC at the introductory level (how to submit jobs with Slurm scheduler) and
  basic knowledge of the Linux command line.

**Software**: For the hands-on, we will use Chapel on our training cluster. To access the training cluster, you will
need a remote secure shell (SSH) client installed on your computer. On Windows we recommend
[the free Home Edition of MobaXterm](https://mobaxterm.mobatek.net/download.html). On Mac and Linux computers SSH is
usually pre-installed (try typing `ssh` in a terminal to make sure it is there). We will provide guest accounts to all
participants. No need to install Chapel on your computer.






{{<cor>}}Part 1: basic language features{{</cor>}} {{<s>}} {{<cgr>}}{{</cgr>}} \
{{<linktitle url="../chapel2/chapel-01-intro" text="Introduction to Chapel">}} \
{{<linktitle url="../chapel2/chapel-02-variables" text="Basic syntax and variables">}} -- Julia set description \
{{<linktitle url="../chapel2/chapel-03-ranges-and-arrays" text="Ranges and arrays">}} \
{{<linktitle url="../chapel2/chapel-04-control-flow" text="Control flow">}} \
{{<linktitle url="../chapel2/chapel-06-command-line-arguments" text="Using command-line arguments">}} \
{{<linktitle url="../chapel2/chapel-07-timing" text="Measuring code performance">}} \
{{<linktitle url="../chapel2/chapel-08-output" text="Writing output">}}

{{<cor>}}Part 2: data parallelism{{</cor>}} {{<s>}} {{<cgr>}}{{</cgr>}} \
{{<linktitle url="../chapel2/chapel-10-intro-parallel" text="Intro to parallel computing">}} \
{{<linktitle url="../chapel2/chapel-11-single-locale-data-parallel" text="Single-locale data parallelism">}} \
{{<linktitle url="../chapel2/chapel-13-multi-locale-chapel" text="Multi-locale Chapel">}} \
{{<linktitle url="../chapel2/chapel-14-domains-and-data-parallel" text="Domains and data parallelism">}} \
{{<linktitle url="../chapel2/chapel-15-distributed-julia-set" text="Parallel Julia set">}} \
{{<linktitle url="../chapel2/chapel-16-distributed-heat-transfer" text="Heat transfer solver on distributed domains">}} -- heat transfer description

{{<cor>}}Part 3: task parallelism (briefly){{</cor>}} {{<s>}} {{<cgr>}}{{</cgr>}} \
{{<linktitle url="../chapel2/chapel-20-fire-and-forget-tasks" text="Fire-and-forget tasks">}} \
{{<linktitle url="../chapel2/chapel-21-synchronising-tasks" text="Synchronization of tasks">}} \
{{<linktitle url="../chapel2/chapel-22-task-parallel-heat-transfer" text="Task-parallelizing the heat transfer solver">}}

{{<cor>}}Part 4: GPU computing with Chapel{{</cor>}} {{<s>}} {{<cgr>}}{{</cgr>}}
<!-- ACTION: add and shorten material from chapel-gpu.md -->




### Solutions

You can find the solutions [here](../../solutions-chapel).




### Links

- {{<a "https://chapel-lang.org" "Chapel homepage">}}
- {{<a "https://developer.hpe.com/platform/chapel/home" "What is Chapel?">}} (HPE Developer Portal)
- LinuxCon 2023 [Introducing Chapel slides](https://chapel-lang.org/presentations/ChapelForLinuxCon-presented.pdf) (PDF)
- {{<a "https://chapel-for-python-programmers.readthedocs.io/basics.html" "Getting started guide for Python programmers">}}
- {{<a "https://learnxinyminutes.com/docs/chapel" "Learn X=Chapel in Y minutes">}}
- {{<a "https://stackoverflow.com/questions/tagged/chapel" "Chapel on StackOverflow">}}
- Watch {{<a "https://youtu.be/0DjIdRJIqRY" "Chapel: Productive, Multiresolution Parallel Programming talk">}} by Brad Chamberlain
- WestGrid's April 2019 webinar {{<a "https://training.westdri.ca/programming#chapel" "Working with distributed unstructured data in Chapel">}}
- WestGrid's March 2020 webinar {{<a "https://training.westdri.ca/programming#chapel" "Working with data files and external C libraries in Chapel">}} discusses writing arrays to NetCDF and HDF5 files from Chapel




<!-- * Binary I/O: check https://chapel-lang.org/publications/ParCo-Larrosa.pdf -->

<!-- * advanced: take a simple 2D or 3D non-linear problem, linearize it, implement a parallel multi-locale -->
<!--   linear solver entirely in Chapel -->






&nbsp;
{{< figure src="/img/solveMulti.gif" >}}
