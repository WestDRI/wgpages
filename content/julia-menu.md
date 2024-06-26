+++
title = "Parallel computing in Julia"
slug = "julia"
aliases = ["julia-in-summer", "parallel_julia", "parallel_julia_oct21"]
+++

<!-- {{<cor>}}Wednesday, June 21st{{</cor>}}\ -->
<!-- {{<cgr>}}9:00am-noon and 2pm-5pm Pacific Time{{</cgr>}} -->

<!-- {{<cor>}}Friday, July 14th{{</cor>}}\ -->
<!-- {{<cgr>}}9:00am-noon Mountain Time{{</cgr>}} -->

<!-- {{<cor>}}February 1st (Part 1) and February 8th (Part 2){{</cor>}}\ -->
<!-- {{<cgr>}}Both days 10:00am - noon Pacific Time{{</cgr>}} -->

{{<cor>}}June 10<sup>th</sup>{{</cor>}}\
{{<cgr>}}10:00am - 1:00pm Mountain Time{{</cgr>}}

<!-- Course materials will be added here shortly before the start of the course. -->

---

Julia is a high-level programming language well suited for scientific computing and data science. Just-in-time
compilation, among other things, makes Julia really fast yet interactive. For heavy computations, Julia
supports multi-threaded and multi-process parallelism, both natively and via a number of external packages. It
also supports memory arrays distributed across multiple processes either on the same or different nodes. In
this hands-on workshop, we will start with Julia's multi-threading features and then focus on Distributed
multi-processing standard library and its large array of tools. We will demo parallelization using two
problems: a slowly converging series and a Julia set. We will run examples on a multi-core laptop and an HPC
cluster.

**Instructor**: Alex Razoumov (SFU)

**Prerequisites:** Ideally, some familiarity with the Alliance's HPC cluster environment, in particular, with
the Slurm scheduler. Having some previous serial Julia programming experience would help, but we will start
slowly so you will be able to follow up even if you are new to Julia.

**Software**: There are a couple of options:

1. You can work on our remote training cluster through an SSH client. You will need a remote secure shell
(SSH) client installed on your computer in order to participate in course exercises. On Windows we recommend
[the free Home Edition of MobaXterm](https://mobaxterm.mobatek.net/download.html). On Mac and Linux computers
SSH is usually pre-installed (try typing `ssh` in a terminal to make sure it is there). We will provide guest
accounts on our training cluster. No need to install Julia on your computer.

2. You can use Julia on your own computer (if already installed).

<!-- 3. You can work on our remote training cluster via JupyterHub | Terminal. In this case you will want to ask -->
<!--    for 2-4 CPU cores and 3 hours. This is the easiest option (nothing to install on your computer), as you -->
<!--    will work entirely through a browser. -->



<!-- {{<nolinktitle>}}Introduction to Julia language{{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}Intro to parallelism{{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}Multi-threading with Base.Threads (slow series){{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}Multi-threading with ThreadsX (slow series){{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}Parallelizing the Julia set with Base.Threads{{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}Parallelizing the Julia set with ThreadsX{{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}Distributed.jl: basics{{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}Distributed.jl: three scalable versions of the slow series{{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}DistributedArrays.jl{{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}Parallelizing the Julia set with DistributedArrays{{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}SharedArrays.jl{{</nolinktitle>}} \ -->
<!-- {{<nolinktitle>}}Parallelizing the N-body problem{{</nolinktitle>}} (supplemental material)\ -->
<!-- {{<nolinktitle>}}Parallelizing the additive Schwarz method{{</nolinktitle>}} (supplemental material)\ -->
<!-- {{<nolinktitle>}}Distributed linear algebra in Julia{{</nolinktitle>}} (supplemental material) -->




{{<cor>}}Part 1{{</cor>}} \
{{<linktitle url="../summer/julia-01-intro-language" text="Introduction to Julia language">}}\
{{<linktitle url="../summer/julia-02-intro-parallel" text="Intro to parallelism">}}\
{{<linktitle url="../summer/julia-03-threads-slow-series" text="Multi-threading with Base.Threads (slow series)">}} \
{{<linktitle url="../summer/julia-04-threadsx-slow-series" text="Multi-threading with ThreadsX (slow series)">}} \
{{<linktitle url="../summer/julia-05-threads-julia-set" text="Parallelizing the Julia set with Base.Threads">}} \
{{<linktitle url="../summer/julia-06-threadsx-julia-set" text="Parallelizing the Julia set with ThreadsX">}}

{{<cor>}}Part 2{{</cor>}} \
{{<linktitle url="../summer/julia-07-distributed1" text="Distributed.jl: basics">}} \
{{<linktitle url="../summer/julia-08-distributed2" text="Distributed.jl: three scalable versions of the slow series">}} \
{{<linktitle url="../summer/julia-09-distributed-arrays" text="DistributedArrays.jl">}} \
{{<linktitle url="../summer/julia-10-distributed-julia-set" text="Parallelizing the Julia set with DistributedArrays">}} \
{{<linktitle url="../summer/julia-11-shared-arrays" text="SharedArrays.jl">}} \
{{<linkoptional url="../summer/julia-12-nbody" text="Parallelizing the N-body problem">}} (supplemental material) \
{{<linkoptional url="../summer/julia-13-asm" text="Parallelizing the additive Schwarz method">}} (supplemental material)\
{{<linkoptional url="../summer/julia-14-linear-algebra" text="Distributed linear algebra in Julia">}} (supplemental material)



### External links

- {{<a "https://discourse.julialang.org/c/domain/parallel" "Julia at Scale">}} forum
- {{<a "https://benlauwens.github.io/ThinkJulia.jl/latest/book.html" "Think Julia: How to Think Like a Computer Scientist">}} by Ben Lauwens and Allen Downey is a good introduction to basic Julia for beginners
- Baolai Ge's (SHARCNET) November 2020 webinar {{<a "https://youtu.be/xTLFz-5a5Ec" "Julia: Parallel computing revisited">}}
- WestGrid's March 2021 webinar {{<a "https://youtu.be/2SafLn0xJKY" "Parallel programming in Julia">}}
- WestGrid's February 2022 webinar {{<a "https://bit.ly/3MSNL3J" "ThreadsX.jl: easier multithreading in Julia">}}
- {{<a "https://docs.julialang.org/en/v1/manual/performance-tips" "Julia performance tips">}}
- {{<a "https://viralinstruction.com/posts/optimise" "How to optimise Julia code: A practical guide">}}
- {{<a "https://kipp.ly/blog/jits-intro" "A Deep Introduction to JIT Compilers">}}
