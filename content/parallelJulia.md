+++
title = "Parallel computing in Julia"
slug = "parallel_julia"
+++

{{<cor>}}October 18-19, 2021{{</cor>}}
<!-- {{<cgr>}}9 am–5 pm Pacific Time{{</cgr>}} -->

<!-- This course will start at 9am Pacific Time and will run until 5pm Pacific Time. Its format will be a combination of -->
<!-- several interactive Zoom sessions and the reading materials in-between the Zoom sessions. Course materials will be added -->
<!-- here shortly before the start of the course. -->
<!-- --- -->

Julia is a high-level programming language well suited for scientific computing and data science. Just-in-time
compilation, among other things, makes Julia really fast yet interactive. For heavy computations, Julia supports
multi-threaded and multi-process parallelism, both natively and via a number of external packages. It also supports
memory arrays distributed across multiple processes either on the same or different nodes. In this hands-on workshop, we
will start with a quick review of Julia's multi-threading features but will focus primarily on Distributed standard
library and its large array of tools. We will demo parallelization using three problems: a slowly converging series, a
Julia set, and an N-body solver. We will run examples on a multi-core laptop and an HPC cluster.

**Instructor**: Alex Razoumov (WestGrid)

**Prerequisites:** working knowledge of serial Julia.

<!-- **Prerequisites:** working knowledge of serial Julia (covered in [our Julia course](../programming_julia)) and -->
<!-- familiarity with Compute Canada's HPC cluster environment, in particular, with the Slurm scheduler (covered in -->
<!-- [our HPC course](../basics_hpc)). -->

**Software**: If you have Julia on your computer, you are all set. If you want to access our training cluster and run
Julia there, you will need a remote secure shell (SSH) client installed on your computer. On Windows we recommend [the
free Home Edition of MobaXterm](https://mobaxterm.mobatek.net/download.html). On Mac and Linux computers SSH is usually
pre-installed (try typing `ssh` in a terminal to make sure it is there).

{{<cor>}}Zoom{{</cor>}} {{<s>}} {{<cgr>}}Day 1: Oct-18 4:00pm-7:00pm Paris time{{</cgr>}} \
{{<linktitle url="../julia202110/julia-01-intro" text="Introduction to parallel Julia">}} \
{{<linktitle url="../julia202110/julia-02-threads1" text="Base.Threads (part 1)">}} \
{{<linktitle url="../julia202110/julia-03-slow-series" text="Slow series">}} \
{{<linktitle url="../julia202110/julia-04-threads2" text="Base.Threads (part 2)">}} \
{{<linktitle url="../julia202110/julia-05-distributed1" text="Distributed.jl (part 1: basics)">}} \
{{<linktitle url="../julia202110/julia-06-distributed2" text="Distributed.jl (part 2: three scalable versions of parallel slow series)">}}

<!-- In the afternoon Zoom session you'll be working on one of two projects: parallelizing Julia set (I recommend to do this -->
<!-- with distributed arrays) and parallelizing the N-body code (I recommend to do this with shared arrays). **Note:** we -->
<!-- will guide you through the process and answer questions, but we will not share the final solutions with you today; the -->
<!-- goal is to build your own! -->

{{<cor>}}Zoom{{</cor>}} {{<s>}} {{<cgr>}}Day 2: Oct-19 4:00pm-7:00pm Paris time{{</cgr>}} \
{{<linktitle url="../julia202110/julia-07-distributed-arrays" text="DistributedArrays.jl">}} \
{{<linktitle url="../julia202110/julia-08-julia-set" text="Parallelizing Julia set">}} \
{{<linktitle url="../julia202110/julia-09-asm" text="Parallelizing additive Schwarz method">}} \
{{<linktitle url="../julia202110/julia-10-shared-arrays" text="SharedArrays.jl">}} \
{{<linktitle url="../julia202110/julia-11-nbody" text="Parallelizing N-body">}}
