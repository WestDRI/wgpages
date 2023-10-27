+++
title = "Parallel programming in Chapel"
slug = "chapel"
+++

{{<cor>}}November 9th and 16th, 2023{{</cor>}}\
{{<cgr>}}10:00am - noon Pacific Time{{</cgr>}}

This course is a general introduction to the main principles of parallel coding using the Chapel programming
language to illustrate the basic concepts and ideas. Chapel is a relatively new language for both shared and
distributed memory programming, with easy-to-use, high-level abstractions for both task and data parallelism,
making it ideal for a novice HPC user to learn parallel programming. Chapel is incredibly intuitive, striving
to merge the ease-of-use of Python and the performance of traditional compiled languages such as C and
Fortran. Parallel constructs that typically take tens of lines of MPI code can be expressed in only a few
lines of Chapel code. Chapel is open source and can run on any Unix-like operating system, with hardware
support from laptops to large HPC systems.

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

**Instructors**: Alex Razoumov (SFU)

**Prerequisites:** basic understanding of HPC at the introductory level (how to submit jobs with Slurm scheduler) and
  basic knowledge of the Linux command line.

**Software**: For the hands-on, we will use Chapel on our training cluster. To access the training cluster, you will
need a remote secure shell (SSH) client installed on your computer. On Windows we recommend
[the free Home Edition of MobaXterm](https://mobaxterm.mobatek.net/download.html). On Mac and Linux computers SSH is
usually pre-installed (try typing `ssh` in a terminal to make sure it is there). We will provide guest accounts to all
participants. No need to install Chapel on your computer.






<!-- {{<nolinktitle>}}Introduction to Chapel{{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}Basic syntax and variables{{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}Ranges and arrays{{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}Conditional statements{{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}Getting started with loops{{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}Using command-line arguments{{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}Measuring code performance{{</nolinktitle>}} \ -->

{{<cor>}}Part 1: basic language features{{</cor>}} {{<s>}} {{<cgr>}}{{</cgr>}} \
{{<linktitle url="../chapel1/chapel-01-intro" text="Introduction to Chapel">}} \
{{<linktitle url="../chapel1/chapel-02-variables" text="Basic syntax and variables">}} \
{{<linktitle url="../chapel1/chapel-03-ranges-and-arrays" text="Ranges and arrays">}} \
{{<linktitle url="../chapel1/chapel-04-conditions" text="Conditional statements">}} \
{{<linktitle url="../chapel1/chapel-05-loops" text="Getting started with loops">}} \
{{<linktitle url="../chapel1/chapel-06-command-line-arguments" text="Using command-line arguments">}} \
{{<linktitle url="../chapel1/chapel-07-timing" text="Measuring code performance">}}

<!-- {{<nolinktitle>}}Intro to parallel computing{{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}Fire-and-forget tasks{{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}Synchronization of threads{{</nolinktitle>}} -->
<!-- {{<nolinktitle>}}Task-parallelizing the heat transfer solver{{</nolinktitle>}} \ -->

{{<cor>}}Part 2: task parallelism{{</cor>}} {{<s>}} {{<cgr>}}{{</cgr>}} \
{{<linktitle url="../chapel1/chapel-08-intro-parallel" text="Intro to parallel computing">}} \
{{<linktitle url="../chapel1/chapel-09-fire-and-forget-tasks" text="Fire-and-forget tasks">}} \
{{<linktitle url="../chapel1/chapel-10-synchronising-threads" text="Synchronization of threads">}} \
{{<linktitle url="../chapel1/chapel-11-task-parallel-heat-transfer" text="Task-parallelizing the heat transfer solver">}}

<!-- {{<nolinktitle>}}Single-locale data parallelism{{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}Parallelizing the Julia set problem{{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}Multi-locale Chapel{{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}Domains and data parallelism{{</nolinktitle>}} -->
<!-- {{<nolinktitle>}}Heat transfer solver on distributed domains{{</nolinktitle>}} -->

{{<cor>}}Part 3: data parallelism{{</cor>}} {{<s>}} {{<cgr>}}{{</cgr>}} \
{{<linktitle url="../chapel1/chapel-12-single-locale-data-parallel" text="Single-locale data parallelism">}} \
{{<linktitle url="../chapel1/chapel-13-julia-set" text="Parallelizing the Julia set problem">}} \
{{<linktitle url="../chapel1/chapel-14-multi-locale-chapel" text="Multi-locale Chapel">}} \
{{<linktitle url="../chapel1/chapel-15-domains-and-data-parallel" text="Domains and data parallelism">}} \
{{<linktitle url="../chapel1/chapel-16-distributed-heat-transfer" text="Heat transfer solver on distributed domains">}}





### Solutions

You can find the solutions [here](../../solutions-chapel).




### Links

- {{<a "https://chapel-lang.org" "Chapel homepage">}}
- {{<a "https://developer.hpe.com/platform/chapel/home" "What is Chapel?">}} (HPE Developer Portal)
- [2023 Introducing Chapel slides](https://chapel-lang.org/presentations/ChapelForLinuxCon-presented.pdf) (PDF)
- {{<a "https://chapel-for-python-programmers.readthedocs.io/basics.html" "Getting started guide for Python programmers">}}
- {{<a "https://learnxinyminutes.com/docs/chapel" "Learn X=Chapel in Y minutes">}}
- {{<a "https://stackoverflow.com/questions/tagged/chapel" "Chapel on StackOverflow">}}
- Watch {{<a "https://youtu.be/0DjIdRJIqRY" "Chapel: Productive, Multiresolution Parallel Programming talk">}} by Brad Chamberlain
- WestGrid's April 2019 webinar {{<a "https://bit.ly/39iRSbx" "Working with distributed unstructured data in Chapel">}}
- WestGrid's March 2020 webinar {{<a "https://bit.ly/3QnP1Pd" "Working with data files and external C libraries in Chapel">}} discusses writing arrays to NetCDF and HDF5 files from Chapel

&nbsp;





<!-- * Binary I/O: check https://chapel-lang.org/publications/ParCo-Larrosa.pdf -->

<!-- * advanced: take a simple 2D or 3D non-linear problem, linearize it, implement a parallel multi-locale -->
<!--   linear solver entirely in Chapel -->






&nbsp;
{{< figure src="/img/solveMulti.gif" >}}
