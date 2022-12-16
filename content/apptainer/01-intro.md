+++
title = "What is Singularity / Apptainer"
slug = "01-intro"
weight = 1
+++

Apptainer (until recently called Singularity):

- is an open-source project developed within the research community since 2015, first by the Lawrence Berkeley
  National Lab
- goal: create a portable system to run Linux applications on HPC clusters independently of the specific host
  Linux version and distro, i.e. distribute software and **its compute environment**
- creates a custom, secure virtual Linux environment (a **container**) that is different from the host Linux
  system
  - e.g., on a CentOS/Rocky Linux machine you can create a virtual Ubuntu system where you can install any
    packaged software from the Ubuntu repositories
  - in a sense, gives you control of your software environment without being `root` on the host system (with a
    catch: creating containers from scratch usually requires `root`)
  - you can install any system packages and all dependencies for your software as packages inside the container
- quickly became a way to package and deploy scientific software and its dependencies to different HPC systems
- is different from Docker, as it does not require `root` access on the host system to *run* it
  - specifically designed for running containers on multi-user HPC cluster s
- on a Linux host is very lightweight compared to a full virtual machine (**VM**)
- on Mac or Windows can be deployed inside a VM (still requires a Linux host layer &nbsp;➜&nbsp; a VM)
- from the technical standpoint, uses:
  - <u>kernel namespaces</u> to virtualize and isolate OS resources (CPU, memory access, disk I/O, network
    access, user/group namespaces), so that processes inside the container see only a specific, virtualized
    set of resources
  - Linux control groups (<u>cgroups</u>) to control and limit the use of these resources
  - <u>overlay filesystems</u> to enable the appearance of writing to otherwise read-only filesystems

## Why use a container

Idea: package and distribute the software environment along with the application, i.e. create a **portable
software environment**.

Why:
1. avoid compiling complex software chains from scratch for the host's Linux OS
1. run software in the environment where it might not be available as a package, or run older software
1. use a familiar software environment everywhere where you can run Singularity, e.g. across different HPC centres
   - create a consistent testing environment independently of the underlying system
   - transfer pipelines from a test environment to a production environment
1. popular, but somewhat dubious reason: data reproducibility (use the same software environment as the
   authors &nbsp;➜&nbsp; same result)

## Installing/running Singularity on your own computer

1. on a Linux system (we will install Singularity as a package inside our VM from Tuesday)
1. in a VM running Linux (on any host OS)
1. within Vagrant for Windows (WSL) or MacOS
1. inside Docker (download a Docker image with Singularity installed)

## Glossary

An **image** is a bundle of files including an operating system, software and potentially data and other
application-related files. Singularity uses the Singularity Image Format (SIF), and images are provided as
single `.sif` files.

A **container** is a virtual environment that is based on an image. You can start multiple container instances
from an image.

An **operating system** (OS) is all the software that let you interact with a computer, run applications, UI,
etc, consists of the "kernel" and "userland" parts.

A **kernel** is the central piece of software that manages hardware and provides resources (CPU, I/O, memory,
devices, filesystems) to the processes it is running.

A **filesystem** is an organized collection of files. Under UNIX/Linux, there is a single hierarchy under `/`,
and additional filesystems are "mounted" somewhere under that hierarchy.

## Containers vs virtual machines

- **Container** = the OS-level mechanism to isolate some parts of the OS along with a given application.
  - virtualizes an operating system
  - lets you run an application compiled for a specific Linux OS on another Linux OS
  - almost no performance overhead
- **Virtual machine** (VM) = complete isolation from the host OS via virtualized hardware
  - virtualizes hardware
  - maximum flexibility, can mix any combination of host and guest OS's
  - significant performance overhead, as you run on simulated hardware

**Docker**: container platform for services, runs as root on the host system, uses cgroups for resource
management between different VMs on a given node, very popular with software developers, can't really use it
on HPC systems (no `root` or `sudo` possible for users on clusters + cgroups resource management will conflict
with HPC resource managers).

**Singularity**: run containers entirely in user space, as a user, can use existing Docker containers
(Singularity will convert them to proper Singularity containers for you), works seamlessly with the
schedulers.

There are few other container engines focusing on specific features.






## Singularity on HPC systems

```sh
module load singularity
singularity --version   # singularity version 3.7.4 on the training cluster
singularity             # see the list of available commands
```

```sh
module load apptainer
apptainer --version   # apptainer version 1.0.2 on production clusters
apptainer             # see the list of available commands
```
