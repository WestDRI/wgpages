+++
title = "Parallel programming in Julia"
slug = "national_julia_workshop"
+++

{{<cor>}}February 14, 16, 18 (Mon, Wed, Fri), 2022{{</cor>}}\
{{<cgr>}}Each day starting at 9:30am Pacific / 12:30pm Eastern / 1:30pm Atlantic{{</cgr>}}

<!-- This course will start at 9am Pacific Time and will run until 5pm Pacific Time. Its format will be a combination of -->
<!-- several interactive Zoom sessions and the reading materials in-between the Zoom sessions. Course materials will be added -->
<!-- here shortly before the start of the course. -->
<!-- --- -->

Julia is a high-level programming language well suited for scientific computing and data science. Just-in-time
compilation, among other things, makes Julia really fast, yet interactive. For heavy computations, Julia supports
multi-threaded and multi-process parallelism, both natively and via a number of external packages. It also supports
memory arrays distributed across multiple processes either on the same or different nodes. In this hands-on introductory
workshop, we will start with a detailed look at multi-threaded programming in Julia, with many hands-on examples. We
will next study multi-processing with the Distributed standard library and its large array of tools. Finally, we will
work with large data structures on multiple processes using DistributedArrays and SharedArrays libraries. We will demo
parallelization using several problem solvers: a slowly converging series, a Julia set, and -- if time allows -- a
linear algebra solver and an N-body solver. We will run examples on a multi-core laptop and an HPC cluster.

**Instructors**: Alex Razoumov (WestGrid), Marie-Hélène Burle (WestGrid), Baolai Ge (SHARCNET)

**Prerequisites:** basic understanding of HPC at the introductory level (how to submit jobs with Slurm scheduler), basic
  knowledge of Linux command line.

<!-- **Prerequisites:** working knowledge of serial Julia (covered in [our Julia course](../programming_julia)) and -->
<!-- familiarity with Compute Canada's HPC cluster environment, in particular, with the Slurm scheduler (covered in -->
<!-- [our HPC course](../basics_hpc)). -->

**Software**: For the hands-on, you can use Julia either on your computer or on our training cluster. If you have Julia
on your computer, you are all set. If you want to access our training cluster and run Julia there, you will need a
remote secure shell (SSH) client installed on your computer. On Windows we recommend
[the free Home Edition of MobaXterm](https://mobaxterm.mobatek.net/download.html). On Mac and Linux computers SSH is
usually pre-installed (try typing `ssh` in a terminal to make sure it is there). We will provide guest accounts to all
participants.

<!-- {{<nolinktitle>}}Introduction to Julia language{{</nolinktitle>}} - Marie\ -->
<!-- {{<nolinktitle>}}Intro to parallelism{{</nolinktitle>}} - Marie\ -->
<!-- {{<nolinktitle>}}Multi-threading with Base.Threads (slow series){{</nolinktitle>}} - Alex\ -->
<!-- {{<nolinktitle>}}Multi-threading with ThreadsX (slow series){{</nolinktitle>}} - Alex -->

{{<cor>}}Zoom{{</cor>}} {{<s>}} {{<cgr>}}Day 1: Feb-14 9:30am-12:30pm Pacific time{{</cgr>}}\
{{<linktitle url="../julia202202/julia-01-intro-language" text="Introduction to Julia language">}} - Marie\
{{<linktitle url="../julia202202/julia-02-intro-parallel" text="Intro to parallelism">}} - Marie\
{{<linktitle url="../julia202202/julia-03-threads-slow-series" text="Multi-threading with Base.Threads (slow series)">}} - Alex

{{<cor>}}Zoom{{</cor>}} {{<s>}} {{<cgr>}}Day 2: Feb-16 9:30am-12:30pm Pacific time{{</cgr>}}\
{{<linktitle url="../julia202202/julia-04-threadsx-slow-series" text="Multi-threading with ThreadsX (slow series)">}} - Alex \
{{<linktitle url="../julia202202/julia-05-threads-julia-set" text="Parallelizing the Julia set with Base.Threads">}} - Alex\
{{<linktitle url="../julia202202/julia-06-threadsx-julia-set" text="Parallelizing the Julia set with ThreadsX">}} - Alex\
{{<linktitle url="../julia202202/julia-07-distributed1" text="Distributed.jl: basics">}} - Alex\
{{<linktitle url="../julia202202/julia-08-distributed2" text="Distributed.jl: three scalable versions of the slow series">}} - Marie

{{<cor>}}Zoom{{</cor>}} {{<s>}} {{<cgr>}}Day 3: Feb-18 9:30am-12:30pm Pacific time{{</cgr>}} \
{{<nolinktitle>}}Finishing the last section from Wednesday{{</nolinktitle>}} - Marie\
{{<linktitle url="../julia202202/julia-09-distributed-arrays" text="DistributedArrays.jl: concepts, tridiagonal matrix, memory usage">}} - Baolai\
{{<linktitle url="../julia202202/julia-10-distributed-julia-set" text="Parallelizing the Julia set with DistributedArrays">}} - Alex\
{{<linktitle url="../julia202202/julia-11-shared-arrays" text="SharedArrays.jl: concepts, 1D heat equation">}} - Baolai\
{{<linktitle url="../julia202202/julia-12-nbody" text="Parallelizing the N-body problem">}} (supplemental material)\
{{<linktitle url="../julia202202/julia-13-asm" text="Parallelizing the additive Schwarz method">}} (supplemental material)

<!-- In the afternoon Zoom session you'll be working on one of two projects: parallelizing Julia set (I recommend to do this -->
<!-- with distributed arrays) and parallelizing the N-body code (I recommend to do this with shared arrays). **Note:** we -->
<!-- will guide you through the process and answer questions, but we will not share the final solutions with you today; the -->
<!-- goal is to build your own! -->
