+++
title = "Introduction"
slug = "bash-01-intro"
weight = 1
+++

<!-- # Introduction -->

We use HPC systems (clusters) to do computing beyond the scale of a desktop. For example, we can:

* use many processors in parallel to speed up computation,
* solve large problems that do not fit on a desktop, by decomposing these problems onto multiple nodes
  and processing them in parallel,
* use parallel I/O to read very large datasets from many processors simultaneously, cutting the read time
  from hours to minutes.

The use of HPC in modeling complex physical phenomena such as astrophysical processes, weather, fluid
dynamics, molecular interactions, and engineering design is well known to researchers in those fields. More
recently, HPC is being used by researchers in other fields from genomics and medical imaging to social
sciences and humanities.

## Why the shell?

<!-- command interpreter -->

Using HPC systems usually involves the use of a shell. Unlike a GUI, the shell is a text-based interface
to the operating system that excels at two things:

1. launching other tools and scripts, and
1. connecting standard input/output of these tools through pipes to form more complex commands.

The shell design follows the classic UNIX philosophy of breaking complex projects into simpler subtasks
and chaining together components and utilities. The name "shell" comes from the coconut anallogy, as it
is a shell around the operating system kernel, surrounded itself by utilities and applications. Shell
commands are often very cryptic, and this is by design to avoid too much typing.

We use the Unix shell because it is very powerful, great for automation and for creating reproducible
workflows, and is necessary to work on larger Unix systems. *Bash* is one of many Unix shell implementations
out there. It is a default on the Alliance systems, but you can easily switch to a different shell such as
*tcsh*, *zsh*, etc. The main difference between these is a slight change in the command syntax.

For the hands-on work, we have set up a small training cluster *bobthewren.c3.ca* that features the same
software setup as our real production clusters. In the ["Introduction to HPC"](../../hpc-menu) course you will
learn the specifics of working on a cluster: its software environment, scheduler, compilers, parallel
programming models, and so on. In this course we will learn how to work with a remote Linux machine and its
filesystem, the basic Linux commands, how to transfer files to/from/between remote systems, how to automate
things, and similar introductory topics.

## Logging in to a remote system

You can connect to a remote HPC system via SSH (secure shell) using a terminal on your laptop. Linux and
Mac laptops have built-in terminals, whereas on Windows we suggest using a free version of MobaXterm
that comes with its own terminal emulator and a simple interface for remote SSH sessions.

Let's log in to *bobthewren.c3.ca* using a username userXXX (where XXX is three digits):

```sh
[local]$ ssh userXXX@bobthewren.c3.ca   # password supplied by the instructor
```

- those on Windows please use MobaXterm: click on Session | SSH, and then fill in the Remote host name
  and your username.

Please enter the password when prompted. Note that no characters will be shown when typing the
password. If you make a mistake, you will have to start your connection from scratch.

Once connected, compare the prompt on the local and remote systems -- do you notice any difference?

#### SSH connection problems

If you are trying to ssh into the training cluster and you get one of these errors

- *"Permission denied, please try again"*
- *"Network error: Connection timed out"*
- *"Connection refused"*

and you are 100% certain that you type the password correctly, we might need to check if your IP address is
blocked after too many attempts to log in. Please go to {{<a "https://whatismyipaddress.com"
"https://whatismyipaddress.com">}} and tell us your IPv4 address so that we could whitelist it.
