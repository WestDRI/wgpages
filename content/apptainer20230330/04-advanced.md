+++
title = "Advanced Apptainer usage"
slug = "04-advanced"
weight = 4
+++

{{< toc >}}




## Running GPU programs: using CUDA

Apptainer supports Nvidia GPUs through bind-mounting the GPU drivers and the base CUDA libraries. The `--nv`
flag does it transparently to the user, e.g.

```sh
apptainer pull tensorflow.sif docker://tensorflow/tensorflow
ls -l tensorflow.sif   # 415M
salloc --gres=gpu:p100:1 --cpus-per-task=8 --mem=40Gb --time=2:0:0 --account=...
apptainer exec --nv -B /scratch/${USER}:/scratch tensorflow.sif python my-tf.py
```

> ### Key point
> 1. Use `--nv` to expose the NVIDIA hardware devices to the container.

In addition, [NVidia NGC](https://catalog.ngc.nvidia.com) (host of GPU-optimized software) provides prebuilt
containers for a large number of HPC apps. Try searching for TensorFlow, GAMESS (quantum chemistry), GROMACS
and NAMD (molecular dynamics), VMD, ParaView, NVIDIA IndeX (visualization). Their GPU-accelerated containers
are quite large, so it might take a while to build one of them:

```sh
apptainer pull tensorflow-22.06-tf1-py3.sif docker://nvcr.io/nvidia/tensorflow:22.06-tf1-py3
ls -l tensorflow-22.06-tf1-py3.sif   # 5.9G (very large!)
```

<!-- Grigory's slides 23, 24 -->
<!-- Paul's slide 19 -->

<!-- https://developer.nvidia.com/blog/how-to-run-ngc-deep-learning-containers-with-apptainer -->
<!-- https://catalog.ngc.nvidia.com/orgs/hpc/collections/nvidia_hpc -->

<!-- NAMD - A parallel molecular dynamics code designed for high-performance simulation of large biomolecular systems. -->
<!-- GROMACS - A molecular dynamics application designed to simulate Newtonian equations of motion for systems with hundreds to millions of particles. -->
<!-- GAMESS – Application to simulate molecular quantum chemistry, allowing users to calculate various molecular properties and dynamics. -->
<!-- VMD – Software designed for modeling, visualization, and analysis of biomolecular systems. -->
<!-- ParaView – One of the most popular visualization software for analyzing HPC datasets. -->
<!-- NVIDIA IndeX – High performance volumetric visualization software. -->
<!-- NVIDIA HPC SDK – A comprehensive suite of compilers, math and communications libraries, and developer tools including Nsight Systems and Nsight Compute profilers, to maximize performance and portability of HPC applications. -->





## Running MPI programs from within a container

MPI (message passing interface) is the industry standard for distributed-memory parallel programming. There
are several implementations: OpenMPI, MPICH, and few others.

MPI libraries on HPC systems usually depend on various lower-level -- interconnect, RDMA (Remote Direct Memory
Access), PMI (process management interface) and others -- libraries, so they are hard to containerize. Thus no
generic `--mpi` flag could be implemented for containers that would work across the network on different HPC
clusters.

The official Apptainer documentation provides a [good
overview](https://apptainer.org/docs/user/latest/mpi.html) of running MPI codes inside containers. There
are 3 possible modes of running MPI programs with Apptainer:

1. Rely on **MPI inside the container**:
<!-- least interesting, won't work across multiple nodes. -->
```sh
apptainer exec -B ... --pwd ... container.sif mpirun -np $SLURM_NTASKS ./mpicode
```
- you start a single Apptainer process on the host
- `cgroup` limitations from the Slurm job are passed into the container &nbsp;⇒&nbsp; sets the number of
  available CPU cores &nbsp;⇒&nbsp; `mpirun` uses all available (to this job) CPU cores
- **con**: limited to a single node ...
- **pro**: no need to adapt container's MPI to the host; just install SSH into the container
- **pro**: can build a generic container that will work across multiple HPC clusters (each with a different setup)

2. **Hybrid mode**: use host's MPI to spawn MPI processes, and MPI inside the container to compile
   the code and provide runtime MPI libraries:
   <!-- Call the parallel launcher (`srun`) on the container itself, e.g. -->
```sh
mpirun -np $SLURM_NTASKS apptainer exec -B ... --pwd ... container.sif ./mpicode
```
- separate Apptainer process per each MPI rank
- **pro**: can span multiple nodes
- **con**: container's MPI should be configured to support the same process management mechanism and version
  (e.g. PMI2 / PMIx) as the host - not that difficult

<!-- Install MPI (similar that of the host) inside the container, use it to compile the code `mpitest` when -->
<!-- building the container, and also use it at runtime. MPI inside the container should also be configured to -->
<!-- support the same process management mechanism and version, e.g. PMI2 / PMIx, as on the host. -->

3. **Bind mode**: bind-mount host's MPI libraries and drivers into the container and use exclusively them,
   i.e. there is no MPI inside the container. The MPI code will need to be compiled (when building the
   container) with a version of MPI similar to that of the host -- typically that MPI will reside on the build
   node used to build the container, but will not be installed inside the container.
- I have zero experience with this mode, so I won't talk about it more

<!-- {{<note>}} -->
<!-- Always use `srun` to run MPI code with Apptainer. Do not use `mpirun` or `mpiexec` with containers: they -->
<!-- may or may not work. -->
<!-- {{</note>}} -->

#### Example: hybrid-mode MPI

For this course I have already built an MPI container that can talk to MPI on the training cluster. For those
interested, you can find the detailed instructions
[here](https://github.com/razoumov/sharedSnippets/blob/main/mpiContainer.md), but in nutshell I created a
definition file that:

1. bootstraps from docker://ubuntu:22.04
1. installs the necessary fabric and PMI packages, Slurm client, few others requirements

and then used it to build `mpi.sif` which I copied over to the training cluster into
`/project/def-sponsor00/shared`.

<!-- scp mpi.sif user01@container.c3.ca:/project/def-sponsor00/shared -->

```sh
cd ~/tmp
module load openmpi apptainer/1.1.6
unzip /project/def-sponsor00/shared/introHPC.zip codes/distributedPi.c
cd codes
mkdir -p ~/.openmpi
echo "btl_vader_single_copy_mechanism=none" >> ~/.openmpi/mca-params.conf
export PMIX_MCA_psec=native   # allow mpirun to use host's PMI
export CONTAINER=/project/def-sponsor00/shared/mpi.sif
apptainer exec $CONTAINER mpicc -O2 distributedPi.c -o distributedPi
salloc --ntasks=4 --time=0:5:0 --mem-per-cpu=1200
mpirun -np $SLURM_NTASKS apptainer exec $CONTAINER ./distributedPi
```








<!-- > ### <font style="color:blue">Exercise 3</font> -->
<!-- > Compare the following two commands. What do they do differently? -->
<!-- > ```sh -->
<!-- > $ srun apptainer exec mpi.sif ./distributedPi -->
<!-- > $ apptainer exec mpi.sif mpirun -np 4 ./distributedPi   # seems Ok -->
<!-- > ``` -->
<!-- > **Hint**: replace `./distributedPi` with `hostname` to check where these processes run. -->








<!-- > ### <font style="color:blue">Exercise 4</font> -->
<!-- > We installed many packages into our Debian container. How do we know which packages to install (apart from -->
<!-- > googling them), i.e. is there a way to search for packages from the command line? And how would you do this -->
<!-- > when we created the image from a definition file? -->
<!-- > **Hint**: use `--sandbox` along with `--writable`. -->

<!-- <\!-- ```sh -\-> -->
<!-- <\!-- centos -\-> -->
<!-- <\!-- cd tmp -\-> -->
<!-- <\!-- sudo apptainer build --sandbox debian.dir docker://debian -\-> -->
<!-- <\!-- sudo apptainer shell --writable debian.dir -\-> -->
<!-- <\!-- apt update -\-> -->
<!-- <\!-- apt upgrade -y -\-> -->
<!-- <\!-- apt-cache search pmi2 -\-> -->
<!-- <\!-- ``` -\-> -->






## Overlays

In the container world, an overlay image is a file formatted as a filesystem. To the host filesystem it is a
single file. When you mount it into a container, the container will see a filesystem with many files.

An overlay mounted into an immutable SIF image lets you store files without rebuilding the image. For example,
you can store your computation results, or compile/install software into an overlay.

An overlay can be:

- a standalone writable ext3 filesystem image (most useful),
- a sandbox directory,
- a writable ext3 image embedded into the SIF file.

{{<note>}}
If you write millions of files, do not store them on a cluster filesystem -- instead, use an Apptainer
overlay file for that. Everything inside the overlay will appear as a single file to the cluster filesystem.
{{</note>}}

{{<note>}}
The direct `apptainer overlay` command requires Singularity 3.8 / Apptainer 1.0 or later and a relatively
recent set of filesystem tools, e.g. it won't work in a CentOS7 VM. It should work on a VM or a cluster
running Rocky Linux 8.5 or later.
{{</note>}}

<!-- Narval's compute nodes don't have Internet access, but we can copy a usable SIF image from elsewhere. -->

```sh
cd ~/tmp
apptainer pull ubuntu.sif docker://ubuntu:latest
module load apptainer/1.1.6
salloc --time=0:30:0 --mem-per-cpu=3600
apptainer overlay create --size 512 small.img   # create a 0.5GB overlay image file
apptainer shell --overlay small.img ubuntu.sif
```

<!-- Alternatively, we could add a writable overlay partition directly to an existing SIF image: -->
<!-- ```sh -->
<!-- apptainer overlay create --size 512 --create-dir /data ubuntu.sif -->
<!-- apptainer shell -C -B /home,/scratch ubuntu.sif -->
<!-- ``` -->
<!-- but this comes with a number of limitations, so we won't use this option. -->

Inside the container any newly-created top-level directory will go into the overlay filesystem:

```sh
Apptainer> df -kh             # the overlay should be mounted inside the container
Apptainer> mkdir -p /data     # by default this will go into the overlay image
Apptainer> cd /data
Apptainer> df -kh .           # using overlay; check for available space
Apptainer> for num in $(seq -w 00 19); do
             echo $num
             # generate a binary file (1-33)MB in size
             dd if=/dev/urandom of=test"$num" bs=1024 count=$(( RANDOM + 1024 ))
           done
Apptainer> df -kh .     # should take ~300-400 MB
```

If you exit the container and then mount the overlay again, your files will be there:

```sh
apptainer shell --overlay small.img ubuntu.sif

Apptainer> ls /data     # here is your data
```

You can also create a new overlay image with a directory inside with something like:

```sh
apptainer overlay create --create-dir /data --size 512 overlay.img   # create an overlay with a directory
```

If you want to mount the overlay in the read-only mode:

```sh
apptainer shell --overlay small.img:ro ubuntu.sif
Apptainer>  touch /data/test.txt    # error: read-only file system
```

{{<note>}}
Into the same container at the same time, you can mount many read-only overlays, but only one writable overlay.
{{</note>}}

To see the help page on overlays (these two commands are equivalent):

```sh
apptainer help overlay create
apptainer overlay create --help
```

#### Sparse overlay images

Sparse images use disk more efficiently when blocks allocated to them are mostly empty. Let's create a sparse
overlay image:

```sh
apptainer overlay create --size 512 --sparse sparse.img
ls -l sparse.img                   # its apparent size is 512MB
du -h --apparent-size sparse.img   # same
du -h sparse.img                   # its actual size is much smaller (17MB)
```

Let's mount it and fill with some data, now creating fewer files:

```
apptainer shell --overlay sparse.img ubuntu.sif

Apptainer> mkdir -p /data && cd /data
Apptainer> for num in $(seq -w 0 4); do
             echo $num
             # generate a binary file (1-33)MB in size
             dd if=/dev/urandom of=test"$num" bs=1024 count=$(( RANDOM + 1024 ))
           done
Apptainer> df -kh .     # should take ~75-100 MB, pay attention to "Used"

du -h sparse.img        # shows actual usage
```
{{<note>}}
Be careful using sparse images: not all tools (e.g. backup/restore, scp, sftp, gunzip) recognize sparsefiles
⇒ this can potentially lead to very bad things ...
{{</note>}}

#### Example: installing Conda into an overlay

- native Anaconda on HPC clusters is a [bad idea](https://docs.alliancecan.ca/wiki/Anaconda/en) for a number
  of reasons
- installing Conda into an overlay image takes a couple of minutes, results in >17,000 files
- no need for root, as you don't modify the container
- still might not be the most efficient use of resources (non-optimized binaries)

Here is how you would install Conda into an overlay image:

```sh
cd ~/tmp
apptainer pull ubuntu.sif docker://ubuntu:latest
apptainer overlay create --size 550 conda.img   # create a 550MB overlay image
wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.12.0-Linux-x86_64.sh

apptainer shell --overlay conda.img -B /home ubuntu.sif

Apptainer> mkdir /conda && cd /conda
Apptainer> df -kh .
Apptainer> bash /home/user001/tmp/Miniconda3-py39_4.12.0-Linux-x86_64.sh
  agree to the license
  use /conda/miniconda3 for the installation path
  no to initialize Miniconda3
Apptainer> find /conda/miniconda3/ -type f | wc -l        # 17,722 files

du -h conda.img   # uses ~470M
```

These 17k+ files appear as a single file to the Lustre metadata server (which is great!).

```sh
apptainer shell ubuntu.sif
Apptainer> ls /conda                            # no such file or directory

apptainer shell --overlay conda.img ubuntu.sif
Apptainer> source /conda/miniconda3/bin/activate
Apptainer> python         # works
```

If you want to install large Python packages, you probably want to resize the image:

```sh
e2fsck -f conda.img         # check your overlay's filesystem first (required step)
resize2fs -p conda.img 2G   # resize your overlay
ls -l conda.img             # should be 2GB
```

Next mount the resized overlay into the container, and make sure to pass the `-C` flag to force writing config
files locally (and not to the host):

```sh
apptainer shell -C --overlay conda.img ubuntu.sif

Apptainer> cd /conda/miniconda3
Apptainer> source bin/activate
Apptainer> conda install numpy
Apptainer> du -skh .    # used 1.6G
Apptainer> python
>>> import numpy as np
>>> np.pi
```











## The importance of temp space when running large workflows

By default, for its internal use Apptainer allocates some temporary space in `/tmp` which is often in RAM
and is very limited. When it becomes full, Apptainer will stop working, so it is important to give it
another, larger temporary space via the `-W` flag. In practice, this would mean doing something like:

- on a personal machine or a login node
```sh
apptainer shell/exce/run ... -W /localscratch <image.sif>
apptainer shell/exce/run ... -W /localscratch/tmp <image.sif>
```
- inside a Slurm job
```sh
apptainer shell/exce/run ... -W $SLURM_TMPDIR <image.sif>
```

{{<note>}}
Regard `/tmp` inside the container as temporary space. Any files you put there will disappear the next time
you start the container.
{{</note>}}








## Running container instances

You can also run backgrounded processes within your container. You can start/terminate these with
`instance start`/`instance stop`. All these processes will terminate once your job ends.

```sh
module load apptainer/1.1.6
salloc --cpus-per-task=1 --time=0:30:0 --mem-per-cpu=3600
apptainer instance start ubuntu.sif test01     # start a container instance test01
apptainer shell instance://test01   # start an interactive shell in that instance
bash -c 'for i in {1..60}; do sleep 1; echo $i; done' > dump.txt &   # start a 60-sec background process
exit        # and then exit; the instance and the process are still running
apptainer exec instance://test01 tail -3 dump.txt   # check on the process in that instance
apptainer exec instance://test01 tail -3 dump.txt   # and again
apptainer shell instance://test01                   # poke around the instance
apptainer instance list
apptainer instance stop test01
```







## Placeholder: running multi-locale Chapel from a container

- Useful if Chapel is not installed natively at your HPC centre.
- Somewhat tricky for multi-locale Chapel due to its dependence on the cluster's parallel launcher and interconnect.
- Piece of cake for single-locale Chapel and for *simulated* multi-locale Chapel.










<!-- ## Placeholder: R containers -->

<!-- Grigory's slides 15, 21 -->





<!-- ## Transitioning from Singularity to Apptainer -->

<!-- In November 2021 the guidance of parts of Singularity was transferred to the -->
<!-- [Linux Foundation](https://www.linuxfoundation.org), and that fully open-source component has been renamed -->
<!-- *Apptainer*. The transition from Singularity to Apptainer should be seamless: -->

<!-- 1. rename the `singularity` command to `apptainer` -->
<!-- 1. rename all `SINGULARITY_*` environment variables to `APPTAINER_*` -->
<!-- 1. rename all `SINGULARITYENV_*` environment variables to `APPTAINERENV_*` (prefix to pass variables to your container) -->
