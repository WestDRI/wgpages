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

{{<cor>}}March 20<sup>th</sup> (Part 1) and 27<sup>th</sup> (Part 2){{</cor>}}\
{{<cgr>}}10:00am - noon Pacific Time{{</cgr>}}

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

1. You can run Julia on our training cluster, in which case you will need a remote secure shell (SSH) client
installed on your computer. On Mac and Linux computers, SSH is usually pre-installed -- try typing `ssh` in a
terminal to make sure it is there. Many versions of Windows also provide an OpenSSH client by default –- try
opening PowerShell and typing `ssh` to see if it is available. If not, then we recommend installing the free
Home Edition of MobaXterm from https://mobaxterm.mobatek.net/download.html. We will provide guest accounts on
our training cluster, and you would not need to install Julia on your computer in this setup.

2. You can run Julia on your own computer, in which case you can install it from
   https://julialang.org/downloads -- this may take a while so please do this before the class.

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
{{<linktitle url="../summer/julia-09-persistent-arrays" text="Persistent storage on workers">}} &nbsp;&nbsp;(new) \
{{<linktitle url="../summer/julia-10-distributed-arrays" text="DistributedArrays.jl">}} \
{{<linktitle url="../summer/julia-11-distributed-julia-set" text="Parallelizing the Julia set with DistributedArrays">}} \
{{<linktitle url="../summer/julia-12-shared-arrays" text="SharedArrays.jl">}} \
{{<linkoptional url="../summer/julia-13-nbody" text="Parallelizing the N-body problem">}} &nbsp;&nbsp;(supplemental material) \
{{<linkoptional url="../summer/julia-14-asm" text="Parallelizing the additive Schwarz method">}} &nbsp;&nbsp;(supplemental material)\
{{<linkoptional url="../summer/julia-15-linear-algebra" text="Distributed linear algebra in Julia">}} &nbsp;&nbsp;(supplemental material)

### Our Julia webinars

Since 2020, we've been teaching occasional webinars on parallel programming in Julia -- watch the recordings
{{<a "https://training.westdri.ca/programming/#julia" "here">}}.

### External links

- {{<a "https://benlauwens.github.io/ThinkJulia.jl/latest/book.html" "Think Julia: How to Think Like a Computer Scientist">}} by Ben Lauwens and Allen Downey is a very thorough introduction to non-parallel Julia for beginners
- {{<a "https://discourse.julialang.org/c/domain/parallel" "Julia at Scale">}} forum
- Baolai Ge's (SHARCNET) November 2020 webinar {{<a "https://youtu.be/xTLFz-5a5Ec" "Julia: Parallel computing revisited">}}
- {{<a "https://docs.julialang.org/en/v1/manual/performance-tips" "Julia performance tips">}}
- {{<a "https://viralinstruction.com/posts/optimise" "How to optimise Julia code: A practical guide">}}
- {{<a "https://kipp.ly/blog/jits-intro" "A Deep Introduction to JIT Compilers">}}
