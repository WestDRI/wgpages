+++
title = "Intro to high-performance computing (HPC)"
slug = "hpc-in-summer"
+++

{{<cor>}}Monday, May 1st{{</cor>}}\
{{<cgr>}}2:00pm–5:00pm Pacific Time{{</cgr>}}

<!-- Course materials will be added here shortly before the start of the course. -->

---

This course is an introduction to High-Performance Computing on the Alliance clusters.

**Instructor**: Alex Razoumov (SFU)

**Prerequisites:** Working knowledge of the Linux Bash shell. We will provide guest accounts to one of our Linux systems.

**Software**: All attendees will need a remote secure shell (SSH) client installed on their computer in order to
participate in the course exercises. On Windows we recommend
[the free Home Edition of MobaXterm](https://mobaxterm.mobatek.net/download.html). On Mac and Linux computers SSH is
usually pre-installed (try typing `ssh` in a terminal to make sure it is there).

<!-- {{<cor>}}Part 1{{</cor>}} -->

1. Please download a [ZIP file](http://bit.ly/introhpc2) with all slides (single PDF combining all chapters)
   and sample codes.
1. We'll be using the same training cluster as in the morning -- let's try to log in now.

{{<cor>}}Part 1{{</cor>}} \
Click on a triangle to expand a question:

{{< question num="1: cluster filesystems" >}}
Let's log in to the training cluster. Try to access `/home`, `/scratch`, `/project` on the training cluster. Note that
these only emulate the real production filesystems and have no speed benefits on the training cluster.
{{< /question >}}

{{< question num="2: edit a remote file" >}}
Edit a remote file in `nano` or `vi` or `emacs`. Use `cat` or `more` to view its content in the terminal.
{{< /question >}}

{{< question num="3: gcc compiler" >}}
Load the default GNU compiler with `module` command. Which version is it? Try to understand what the module does: run
`module show` on it, `echo $PATH`, `which gcc`.
{{< /question >}}

{{< question num="4: Intel compiler" >}}
Load the default Intel compiler. Which version is it? Does it work on the training cluster?
{{< /question >}}

{{< question num="5: third compiler?" >}}
Can you spot the third compiler family when you do `module avail`?
{{< /question >}}

{{< question num="6: scipy-stack" >}}
What other modules does `scipy-stack/2022a` load?
{{< /question >}}

{{< question num="7: python3" >}}
How many versions of python3 do we have? What about python2?
{{< /question >}}

{{< question num="8: research software" >}}
Think of a software package that you use. Check if it is installed on the cluster, and share your findings.
{{< /question >}}

{{< question num="9: file transfer" >}}
Transfer a file to/from the cluster (we did this already in bash class) using either command line or GUI. Type "done"
into the chat when done.
{{< /question >}}

{{< question num="10: why HPC?" >}}
Can you explain (1-2 sentences) how HPC can help us solve problems? Why a desktop/workstation not sufficient? Maybe, you
can give an example from your field?
{{< /question >}}

{{< question num="11: tmux" >}}
Try left+right or upper+lower split panes in `tmux`. Edit a file in one and run bash commands in the
other. Try disconnecting temporarily and then reconnecting to the same session.
{{< /question >}}

{{< question num="12: compiling" >}}
In `introHPC/codes`, compile `{pi,sharedPi,distributedPi}.c` files. Try running a short serial code on the login node
(not longer than a few seconds: modify the number of terms in the summation).
{{< /question >}}

{{< question num="13a: make" >}}
Write a makefile to replace these compilations commands with `make {serial,openmp,mpi}`.
{{< /question >}}

{{< question num="13b: make (cont.)" >}}
Add target `all`.

Add target `clean`. Try implementing `clean` for *all* executable files in the current directory, no matter what they
are called.
{{< /question >}}

{{< question num="14: Julia" >}}
Julia parallelism was not mentioned in the videos. Let's quickly talk about it (slide 29).
{{< /question >}}

{{< question num="14b: parallelization" >}}
Suggest a computational problem to parallelize. Which of the parallel tools mentioned in the videos would you use, and
why?

If you are not sure about the right tool, suggest a problem, and we can brainstorm the approach together.
{{< /question >}}


{{< question num="15: Python and R" >}}
If you use Python or R in your work, try running a Python or R script in the terminal.

If this script depends on packages, try installing them in your own directory with `virtualenv`. Probably, only a few of
you should do this on the training cluster at the same time.
{{< /question >}}

{{< question num="16: other" >}}
Any remaining questions? Type your question into the chat, ask via audio (unmute), or raise your hand in Zoom.
{{< /question >}}







<!-- {{< solution >}} -->
<!-- ```sh -->
<!-- function countfiles() { -->
<!--     if [ $# -eq 0 ]; then -->
<!--         echo "No arguments given. Usage: countfiles dir1 dir2 ..." -->
<!--         return 1 -->
<!--     fi -->
<!--     for dir in $@; do -->
<!--         echo in $dir we found $(find $dir -type f | wc -l) files -->
<!--     done -->
<!-- } -->
<!-- ``` -->
<!-- {{< /solution >}} -->




{{<cor>}}Part 2{{</cor>}} \
Click on a triangle to expand a question:

{{< question num="17: serial job" >}}
Submit a serial job that runs `hostname` command.

Try playing with `sq`, `squeue`, `scancel` commands.
{{< /question >}}

{{< question num="18: serial job (cont.)" >}}
Submit a serial job based on `pi.c`.

Try `sstat` on a currently running job. Try `seff` and `sacct` on a completed job.
{{< /question >}}

{{< question num="19: optimization timing" >}}
Using a serial job, time optimized (`-O2`) vs. unoptimized code. Type your findings into the chat.
{{< /question >}}

{{< question num="20: Python vs. C timing" >}}
Using a serial job, time `pi.c` vs. `pi.py` for the same number of terms (cannot be too large or too small -- why?).

Python pros -- can you speed up `pi.py`?
{{< /question >}}

{{< question num="21: array job" >}}
Submit an array job for different values of `n` (number of terms) with `pi.c`. How can you have different executable for
each job inside the array?
{{< /question >}}

{{< question num="22: OpenMP job" >}}
Submit a shared-memory job based on `sharedPi.c`. Did you get any speedup? Type your answer into the chat.
{{< /question >}}

{{< question num="23: MPI job" >}}
Submit an MPI job based on `distributedPi.c`.

Try scaling 1 → 2 → 4 → 8 cores. Did you get any speedup? Type your answer into the chat.
{{< /question >}}

{{< question num="24: serial interactive job" >}}
Test the serial code inside an interactive job. Please quit the job when done, as we have very few compute cores on the
training cluster.

Note: we have seen the training cluster become unstable when using too many interactive resources. Strictly speaking,
this should not happen, however there is a small chance it might. We do have a backup.
{{< /question >}}

{{< question num="25: shared-memory interactive job" >}}
Test the shared-memory code inside an interactive job. Please quit when done, as we have very few compute cores on the training cluster.
{{< /question >}}

{{< question num="26: MPI interactive job" >}}
Test the MPI code inside an interactive job. Please quit when done, as we have very few compute cores on the training cluster.
{{< /question >}}

{{< question num="27: debugging and optimization" >}}
Let's talk about debugging, profiling and code optimization.
{{< /question >}}

{{< question num="28: permissions and file sharing" >}}
Let's talk about file permissions and file sharing.

Share a file in your `~/projects` directory (make it readable) with all other users in `def-sponsor00` group.
{{< /question >}}

{{< question num="29: other" >}}
Are there questions on any of the topics that we covered today? You can type your question into the chat, ask via audio
(unmute), or raise your hand in Zoom.
{{< /question >}}











<!-- - Edit a remote file in nano or vi or emacs. -->
<!-- - Try to understand what the default GNU compiler module does: run `module show` on it, print `PATH` -->
<!--   variable, locate the GNU C compiler. -->
<!-- - Check if your favourite research software is installed on the cluster. -->
<!-- - Write a makefile from scratch. -->
<!-- - Try left+right or upper+lower split panes in tmux on the cluster. -->






## Videos: introduction

- [Introduction](https://www.youtube.com/watch?v=dVMNSp98yRA) (3 min)
- [Cluster hardware overview](https://www.youtube.com/watch?v=pLy3m9Nq4rM) (17 min)
- [Basic tools on HPC clusters](https://www.youtube.com/watch?v=9StaWaE4KRw) (18 min)
- [File transfer](https://www.youtube.com/watch?v=SjANgOLA4lc) (10 min)
- [Programming languages and tools](https://www.youtube.com/watch?v=dhV0Jg8VLoU) (16 min)

**Updates**:
1. WestGrid ceased its operations on March 31, 2022. Since April 1st, your instructors in this course are
   based at Simon Fraser University.
1. Some of the slides and links in the video have changed -- please make sure to download
   the [latest version of the slides](http://bit.ly/introhpc2) (ZIP file).
1. Compute Canada has been replaced by the Digital Research Alliance of Canada (the Alliance). All Compute
  Canada hardware and services are now provided to researchers by the Alliance and its regional
  partners. However, you will still see many references to Compute Canada in
  [our documentation](https://docs.alliancecan.ca) and support system.
1. New systems were added (e.g. Narval in Calcul Québec), and some older systems were upgraded.

## Videos: overview of parallel programming frameworks

Here we give you a brief overview of various parallel programming tools. Our goal here is not to learn how to
use these tools, but rather tell you at a high level what these tools do, so that you understand the
difference between shared- and distributed-memory parallel programming models and know which tools you can use
for each. Later, in the scheduler session, you will use this knowledge to submit parallel jobs to the queue.

Feel free to skip some of these videos if you are not interested in parallel programming.

- [OpenMP](https://www.youtube.com/watch?v=hrN8hYYI-GA) (3 min)
- [MPI (message passing interface)](https://www.youtube.com/watch?v=0jTuecDVPYI) (9 min)
- [Chapel parallel programming language](https://www.youtube.com/watch?v=ptR9Wa-Saek) (7 min)
- [Python Dask](https://www.youtube.com/watch?v=-kYclNmUuX0) (6 min)
- [Make build automation tool](https://www.youtube.com/watch?v=m_60GzGJn6E) (9 min)
- [Other essential tools](https://www.youtube.com/watch?v=Ncwmx80zlGE) (5 min)
- [Python and R on clusters](https://www.youtube.com/watch?v=hqdvNMAaegI) (6 min)

## Videos: Slurm job scheduler

- [Slurm intro](https://www.youtube.com/watch?v=Qd39UkdajwQ) (8 min)
- [Job billing with core equivalents](https://www.youtube.com/watch?v=GjI8Fmzo20A) (2 min)
- [Submitting serial jobs](https://www.youtube.com/watch?v=sv5lUnoBV30) (12 min)
- [Submitting shared-memory jobs](https://www.youtube.com/watch?v=rIxTP8d8PaM) (9 min)
- [Submitting MPI jobs](https://www.youtube.com/watch?v=7RWpRtCCPz8) (8 min)
- [Slurm jobs and memory](https://www.youtube.com/watch?v=zaYUIjsuKoU) (8 min)
- [Hybrid and GPU jobs](https://www.youtube.com/watch?v=-1g2WM9kG88) (5 min)
- [Interactive jobs](https://www.youtube.com/watch?v=Ye7IrSxaN2k) (8 min)
- [Getting information and other Slurm commands](https://www.youtube.com/watch?v=I_U5u9F-_no) (6 min)
- [Best computing / storage practices and summary](https://www.youtube.com/watch?v=G4dcMri-gDM) (9 min)


<!-- An interactive job will give you a bash shell on one the nodes that was allocated to your job. There you -->
<!-- can start a test run, debug your code, start a VNC/ParaView/VisIt/etc server and connect to it from a -->
<!-- client on your computer, etc. Note that interactive jobs typically have a short maximum runtime, usually -->
<!-- 3 hours. -->

<!-- One of the main takeaways from this course is to learn how to transition between `sbatch` and `salloc` -->
<!-- commands. You may debug your workflow with `salloc`, transition to production jobs with `sbatch`, and -->
<!-- then find that you need to use `salloc` again to debug problems and to analyze your large datasets. -->
