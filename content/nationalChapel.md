+++
title = "Parallel programming in Chapel"
slug = "national_chapel_workshop"
+++

{{<cor>}}March 7, 9, 11 (Mon, Wed, Fri), 2022{{</cor>}}\
{{<cgr>}}Each day starting at 9:30am Pacific / 12:30pm Eastern / 1:30pm Atlantic{{</cgr>}}

This course is a general introduction to the main principles of parallel coding using the Chapel programming language to
illustrate the basic concepts and ideas.

Chapel is a relatively new language for both shared and distributed memory programming, with easy-to-use, high-level
abstractions for both task and data parallelism, making it ideal for a novice HPC user to learn parallel
programming. Chapel is incredibly intuitive, striving to merge the ease-of-use of Python and the performance of
traditional compiled languages such as C and Fortran. Parallel constructs that typically take tens of lines of MPI code
can be expressed in only a few lines of Chapel code. Chapel is open source and can run on any Unix-like operating
system, with hardware support from laptops to large HPC systems.

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

**Instructors**: Alex Razoumov (WestGrid), Marie-Hélène Burle (WestGrid)

**Prerequisites:** basic understanding of HPC at the introductory level (how to submit jobs with Slurm scheduler) and
  basic knowledge of the Linux command line.

**Software**: For the hands-on, we will use Chapel on our training cluster. To access the training cluster, you will
need a remote secure shell (SSH) client installed on your computer. On Windows we recommend
[the free Home Edition of MobaXterm](https://mobaxterm.mobatek.net/download.html). On Mac and Linux computers SSH is
usually pre-installed (try typing `ssh` in a terminal to make sure it is there). We will provide guest accounts to all
participants. No need to install Chapel on your computer.

{{<cor>}}Zoom{{</cor>}} {{<s>}} {{<cgr>}}Day 1: March-07 9:30am-12:30pm Pacific time{{</cgr>}}\
{{<linktitle url="../chapel202203/chapel-01-base" text="Basic language features">}}

{{<cor>}}Zoom{{</cor>}} {{<s>}} {{<cgr>}}Day 2: March-09 9:30am-12:30pm Pacific time{{</cgr>}}\
{{<linktitle url="../chapel202203/chapel-02-task-parallelism" text="Task parallelism">}}

{{<cor>}}Zoom{{</cor>}} {{<s>}} {{<cgr>}}Day 3: March-11 9:30am-12:30pm Pacific time{{</cgr>}}\
{{<linktitle url="../chapel202203/chapel-03-domain-parallelism" text="Data parallelism">}}
<!-- {{<nolinktitle>}}Cover challenges, do some exercises, and wrap up the course.{{</nolinktitle>}} -->

<!-- {{<nolinktitle>}}Basic language features{{</nolinktitle>}} -->
<!-- {{<nolinktitle>}}Task parallelism{{</nolinktitle>}} -->
<!-- {{<nolinktitle>}}Data parallelism{{</nolinktitle>}} -->

&nbsp;
{{< figure src="/img/solveMulti.gif" >}}
