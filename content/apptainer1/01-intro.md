+++
title = "What is Apptainer (formerly Singularity)"
slug = "01-intro"
weight = 1
+++

{{< toc >}}

<!-- Paul Preney on 2022-Dec-19: For a course, describe how to use Apptainer v1.0. In January I will be -->
<!-- teaching an Apptainer course. I will focus on v1.0 features and methodology. As you've seen Apptainer v1.1 has -->
<!-- issues with "fakeroot" related things and IMHO such is not completely ready for normal users. -->

<!-- What would I recommend on how to best build a container? I strongly recommend using one's own computer where -->
<!-- one has root access, a virtual machine where one has root access, one's own cloud instance where one has root -->
<!-- access, etc. and avoid using directly or indirectly any non-local disk space (i.e., avoid NFS and lustre and -->
<!-- the Apptainer docs say this too). Yes I know this isn't ideal or what everyone wants to hear. Building on -->
<!-- networked disk space is unwise because of two reasons: stuff like this -->
<!-- https://apptainer.org/docs/admin/1.1/installation.html#lustre-gpfs (NFS isn't much better -->
<!-- https://apptainer.org/docs/admin/1.1/installation.html#nfs ) and Apptainer reads and writes a LOT of space -->
<!-- which all much be transferred over the network in order to build images. Building without root is unwise -->
<!-- (IMHO) because --fakeroot can work but in my experience it won't always work whereas using sudo -->
<!-- will. Guaranteed results are way better than flaky results. -->

<!-- Can some images be built as a user? Sure -- but the larger these images are, it seems the greater the chances -->
<!-- things won't work out especially on our clusters (as one is typically using NFS or Lustre -- and it is at -->
<!-- least very slow-to-build even if it does work, or, fails after a waiting a long time). Worse users have no -->
<!-- idea how big the images will be that they are building really. Small images will typically build. Increasingly -->
<!-- larger images increasingly encounter issues. Sigh. (edited) -->

Until recently Apptainer was called Singularity. In November 2021 the guidance of parts of Singularity was
transferred to the [Linux Foundation](https://www.linuxfoundation.org), and that fully open-source component
has been renamed *Apptainer*, while the commercial fork is still called *Singularity*.

- Apptainer is an open-source project developed within the research community since 2015, started at the
  Lawrence Berkeley National Lab
- Its goal: create a portable system to run Linux applications on HPC clusters independently of the specific
  host Linux version and distro, i.e. distribute software and **its compute environment**
- Apptainer creates a custom, secure virtual Linux environment (a **container**) that is different from the
  host Linux system
  - e.g., on a CentOS/Rocky Linux machine you can create a virtual Ubuntu system where you can install any
    precompiled packaged software from the Ubuntu repositories
  - in a sense, gives you control of your software environment without being `root` on the host system (with a
    catch: creating containers from scratch usually requires `root`)
  - you can install any system packages and all dependencies for your software as packages inside the container
- Apptainer quickly became a way to package and deploy scientific software and its dependencies to different
  HPC systems
- Apptainer is different from Docker, as it does not require `root` access on the host system to *run* it
  - specifically designed for running containers on multi-user HPC clusters
- On a Linux host Apptainer is very lightweight compared to a full virtual machine (**VM**)
- On MacOS or Windows hosts Apptainer can be deployed inside a VM (still requires a Linux host layer
  &nbsp;➜&nbsp; a VM)
- From the technical standpoint, Apptainer uses:
  - <u>kernel namespaces</u> to virtualize and isolate OS resources (CPU, memory access, disk I/O, network
    access, user/group namespaces), so that processes inside the container see only a specific, virtualized
    set of resources
  - Linux control groups (<u>cgroups</u>) to control and limit the use of these resources
  - <u>overlay images</u> to enable writable filesystems in otherwise read-only containers

## Why use a container

Idea: package and distribute the software environment along with the application, i.e. create a **portable
software environment**.

Why:
1. avoid compiling complex software chains from scratch for the host's Linux OS
1. run software in the environment where it might not be available as a package, or run older software
1. use a familiar software environment everywhere where you can run Apptainer, e.g. across different HPC centres
   - create a consistent testing environment independently of the underlying system
   - transfer pipelines from a test environment to a production environment
1. popular, but somewhat dubious reason: data reproducibility (use the same software environment as the
   authors &nbsp;➜&nbsp; same result)

## Installing/running Apptainer on your own computer

Apptainer was really developed for use on HPC cluster, but there are ways to run it on your own computer:

1. on a Linux system (when running a longer version of this course after a Cloud course, we install Apptainer
   as a package inside our VM)
1. in a VM running Linux (on any host OS)
1. within Vagrant for Windows (WSL) or MacOS
1. inside Docker (download a Docker image with Apptainer installed)

## Glossary

An **image** is a bundle of files including an operating system, software and potentially data and other
application-related files. Apptainer uses the Singularity Image Format (SIF), and images are provided as
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

**Apptainer**: run containers entirely in user space, as a user, can use existing Docker containers (Apptainer
will convert them to proper SIF images for you), works seamlessly with the schedulers.

There are few other container engines focusing on specific features.






## Apptainer on HPC systems

{{<note>}}
We will now distribute usernames and passwords for our training cluster.
{{</note>}}

Let's log in to the training cluster `lecarre.c3.ca` and try loading Apptainer:

```sh
module load apptainer/1.1.8
apptainer --version
apptainer             # see the list of available commands
```
