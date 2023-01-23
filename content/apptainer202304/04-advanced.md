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

> ## Key point
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

MPI libraries on HPC systems usually use a high-performance interconnect / RDMA (Remote Direct Memory Access)
model / etc that rely on a variety of kernel device drivers and low-level libraries, so they are hard to
containerize. Thus no generic `--mpi` flag could be implemented for containers that would work across
different HPC clusters.

The official user guide provides a [good overview](https://docs.sylabs.io/guides/3.7/user-guide/mpi.html) of
running MPI codes inside containers. There are 3 possible modes of running MPI programs with Apptainer:

1. **MPI inside the container**: least interesting, won't work across multiple nodes.

2. **Hybrid mode**: use MPI on the host to spawn the MPI processes, and MPI inside the container to compile
   the code and provide runtime MPI libraries. Call the parallel launcher (`srun`) on the container itself, e.g.
```sh
srun apptainer exec mpi.sif /path/inside/the/container/to/your-mpi-program
```
Install MPI (similar that of the host) inside the container, use it to compile the code `mpitest` when
building the container, and also use it at runtime. MPI inside the container should also be configured to
support the same process management mechanism and version, e.g. PMI2 / PMIx, as on the host.

3. **Bind mode**: bind-mount host's MPI libraries and drivers into the container and use exclusively them,
   i.e. there is no MPI inside the container. The code `mpitest` will need to be compiled (when building the
   container) with a version of MPI similar to that of the host -- typically that MPI will reside on the build
   node used to build the container, but will not be installed inside the container.
```sh
srun apptainer exec -B /path/to/host/MPI/directory nompi.sif /path/inside/the/container/to/your-mpi-program
```

{{<note>}}
Always use `srun` to run MPI code with Apptainer. Do not use `mpirun` or `mpiexec` with containers: they
may or may not work.
{{</note>}}










### Example: OpenMPI hybrid container

{{<note>}}
This section provides an overview of the process, with a placeholder <i>"You will need to configure MPI for
the same process management mechanism and version as on the host"</i>. We will not build this container
now. However, if you want to run containers with MPI applications on the Alliance clusters, please contact us
at <i>"support@tech.alliancecan.ca"</i>, and we will help you to get started.
{{</note>}}

We have already seen that building Apptainer containers can be impractical without root access. Since we are
highly unlikely to have root access on a large HPC cluster, building a container directly on the target
platform is not normally an option. Instead, you will need to build on a local platform with root access (your
computer, a VM), install MPI into it, and then deploy it to a cluster with a *compatible* MPI implementation.

<!-- https://docs.alliancecan.ca/wiki/Apptainer#Running_MPI_programs_from_within_a_container -->
You will need:

- inside your container:
  - OpenMPI version 3 or later; it will talk to the MPI loaded outside the container
  - high-performance interconnect package (libpsm2 for OmniPath, UCX for Infiniband), along with any dependencies
  - `libfabric` low-level communication library and any dependencies
  - multithreading libraries, depending on your CPU architecture
  - `slurm-client` package inside the container to enable interaction with the host's Slurm scheduler
- on the cluster (outside your container):
  - OpenMPI version 4 or later
  - to compile your MPI program with the same version of OpenMPI as inside your container (easy inside the container!)
  - to use `srun` at runtime (and not `mpirun` or `mpiexec`)

{{<note>}}
You need to be root when creating the container here.
{{</note>}}

<!-- https://docs.sylabs.io/guides/3.5/user-guide/mpi.html#apptainer-and-mpi-applications -->
Start by logging in to your VM as `centos` and changing to the working directory:

```sh
cd ~/tmp
```

Create a file `parallelContainer.def`:

```txt
Bootstrap: debootstrap
MirrorURL: http://deb.debian.org/debian
OSVersion: stable
Stage: basis-debian-latest-current-stable

%post
    export DEBIAN_FRONTEND=noninteractive
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8
    export LANGUAGE=C:en
    apt update
    apt upgrade -y
    apt install -y --reinstall locales
    sed -i 's/^# C/C/' /etc/locale.gen || echo "C.UTF-8 UTF-8" >>/etc/locale.gen
    dpkg-reconfigure -fnoninteractive locales
    update-locale --reset LANG="$LANG" LC_ALL="$LC_ALL" LANGUAGE="$LANGUAGE"

    apt upgrade -y
    apt install -y tzdata
    ln -fs /usr/share/zoneinfo/UTC /etc/localtime
    dpkg-reconfigure -fnoninteractive tzdata

    apt install -y apt-utils
    apt install -y nano vim emacs
    apt install -y fakeroot fakechroot
    apt install -y ncdu htop
    apt autoremove -y
    apt clean -y

    apt install -y build-essential libboost-all-dev libtbb-dev libtbb2
    apt install -y openmpi-bin libpmix-bin libucx-dev libucx0 ucx-utils \
        libfabric-bin libfabric-dev libfabric1 hwloc-nox libpmi2-0 libpmi2-0-dev \
        rdma-core rdmacm-utils ibacm ibverbs-providers ibverbs-utils libibverbs-dev libibverbs1 \
        librdmacm-dev librdmacm1 srptools libmunge-dev libmunge2 munge
    apt install -y slurm-client
    apt install -y 
    apt autoremove -y
    apt clean -y
```







Next create an image (this step took me 16 mins on a VM):

```sh
sudo yum install debootstrap -y   # install Debian bootstrapper
sudo apptainer build mpi.sif parallelContainer.def
ls -lh mpi.sif   # 417M
scp mpi.sif <username>@kandinsky.c3.ca:tmp/
```

{{<note>}}
This image will work only on clusters with the Infiniband interconnect, such as Graham and Béluga.
{{</note>}}





> ### <font style="color:blue">Alternative build</font>
> We installed OpenMPI into the image and will compile the code inside the container on the training
> cluster. Alternatively, we could compile the code when building the image, by pre-copying `distributedPi.c`
> (see below) to the current directory and adding the following to the definition file:
> ```txt
> %files
>     distributedPi.c /home/
> %post
>     ...
>     cd /home
>     mpicc -O2 distributedPi.c -o distributedPi
> ```
> When using such container, you would have to run the executable from the correct path:
> ```sh
> srun apptainer exec -C mpi.sif bash -c "cd /home && ./distributedPi"
> ```



> ### <font style="color:blue">Alternative build</font>
> We installed all packages from the repository. In some cases, you might want to compile some of them from
> source. Consider this definition file:
> ```txt
> Bootstrap: debootstrap
> MirrorURL: http://deb.debian.org/debian
> OSVersion: stable
> Stage: basis-debian-latest-current-stable
> 
> %environment
>     export OMPI_DIR=/opt/ompi
>     export APPTAINER_OMPI_DIR=$OMPI_DIR
>     export APPTAINERENV_APPEND_PATH=$OMPI_DIR/bin
>     export SINGULAIRTYENV_APPEND_LD_LIBRARY_PATH=$OMPI_DIR/lib
> 
> %post
>     export DEBIAN_FRONTEND=noninteractive
>     export LC_ALL=C.UTF-8
>     export LANG=C.UTF-8
>     export LANGUAGE=C:en
>     apt update
>     apt upgrade -y
>     apt install -y --reinstall locales
>     sed -i 's/^# C/C/' /etc/locale.gen || echo "C.UTF-8 UTF-8" >>/etc/locale.gen
>     dpkg-reconfigure -fnoninteractive locales
>     update-locale --reset LANG="$LANG" LC_ALL="$LC_ALL" LANGUAGE="$LANGUAGE"
> 
>     apt upgrade -y
>     apt install -y tzdata
>     ln -fs /usr/share/zoneinfo/UTC /etc/localtime
>     dpkg-reconfigure -fnoninteractive tzdata
> 
>     apt install -y apt-utils
>     apt install -y nano vim emacs
>     apt install -y fakeroot fakechroot
>     apt install -y ncdu htop
>     apt autoremove -y
>     apt clean -y
> 
>     apt install -y build-essential libboost-all-dev libtbb-dev libtbb2
>     apt install -y libpmix-bin libucx-dev libucx0 ucx-utils \
>         libfabric-bin libfabric-dev libfabric1 hwloc-nox wget
>     apt install -y slurm-client
>     apt install -y 
>     apt autoremove -y
>     apt clean -y
> 
>     echo "Installing OpenMPI"
>     export OMPI_DIR=/opt/ompi
>     export OMPI_VERSION=4.1.1
>     export OMPI_URL="https://download.open-mpi.org/release/open-mpi/v4.1/openmpi-$OMPI_VERSION.tar.bz2"
>     mkdir -p /tmp/ompi
>     mkdir -p /opt
>     cd /tmp/ompi
>     wget -O openmpi-$OMPI_VERSION.tar.bz2 $OMPI_URL && tar -xjf openmpi-$OMPI_VERSION.tar.bz2
>     cd /tmp/ompi/openmpi-$OMPI_VERSION
>     ./configure --prefix=$OMPI_DIR && make -j4 && make install
>     export PATH=$OMPI_DIR/bin:$PATH
>     export LD_LIBRARY_PATH=$OMPI_DIR/lib:$LD_LIBRARY_PATH
> 	export MANPATH=$OMPI_DIR/share/man:$MANPATH
> ```









Next, on the training cluster create a file `~/tmp/distributedPi.c`:

```c
#include <stdio.h>
#include <math.h>
#include <mpi.h>
#define pi 3.14159265358979323846
int main(int argc, char *argv[])
{
  double total, h, sum, x;
  long long int i, n = 1e9;
  int rank, numprocs;
  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &numprocs);
  h = 1./n;
  sum = 0.;
  if (rank == 0)
    printf("Calculating PI with %d processes\n", numprocs);
  printf("process %d started\n", rank);
  for (i = rank+1; i <= n; i += numprocs) {
    x = h * ( i - 0.5 );    //calculate at center of interval
    sum += 4.0 / ( 1.0 + pow(x,2));
  }
  sum *= h;
  MPI_Reduce(&sum,&total,1,MPI_DOUBLE,MPI_SUM,0,MPI_COMM_WORLD);
  if (rank == 0)
    printf("%.17g  %.17g\n", total, fabs(total-pi));
  MPI_Finalize();
  return 0;
}
```

run the container on our training cluster:

```sh
cd ~/tmp
cat distributedPi.c
module load apptainer/1.1.3
module load openmpi   # version 4 or version 3, no need to match the MPI version inside the container
apptainer shell -C -B /home,/scratch --pwd ~/tmp mpi.sif

Apptainer> mpicc -O2 distributedPi.c -o distributedPi
Apptainer> ./distributedPi                # single process
Apptainer> mpirun -np 4 ./distributedPi   # running on the login node (bad idea!)
Apptainer> mpirun -np 4 hostname          # they all ran on the same node

salloc --nodes=4 --time=0:10:0 --mem-per-cpu=3600
srun apptainer exec -C -B /home,/scratch --pwd ~/tmp mpi.sif ./distributedPi
```



<!-- beluga -->
<!-- module load apptainer/1.1.3 openmpi -->
<!-- salloc --nodes=1 --ntasks=4 --time=0:20:0 --mem-per-cpu=3600 --account=def-razoumov-ac -->
<!-- srun apptainer exec -C -B /home,/scratch --pwd /scratch/razoumov/ mpi.sif ./distributedPi -->





> ### <font style="color:blue">Exercise 3</font>
> Compare the following two commands. What do they do differently?
> ```sh
> $ srun apptainer exec -C -B /home,/scratch --pwd /scratch/razoumov mpi.sif ./distributedPi
> $ apptainer exec -C -B /home,/scratch --pwd /scratch/razoumov mpi.sif mpirun -np 4 ./distributedPi   # seems Ok
> ```
> **Hint**: replace `./distributedPi` with `hostname` to check where these processes run.






<!-- The application appears to have been direct launched using "srun", -->
<!-- but OMPI was not built with SLURM's PMI support and therefore cannot -->
<!-- execute. There are several options for building PMI support under -->
<!-- SLURM, depending upon the SLURM version you are using: -->

<!--   version 16.05 or later: you can use SLURM's PMIx support. This -->
<!--   requires that you configure and build SLURM --with-pmix. -->






> ### <font style="color:blue">Exercise 4</font>
> We installed many packages into our Debian container. How do we know which packages to install (apart from
> googling them), i.e. is there a way to search for packages from the command line? And how would you do this
> when we created the image from a definition file?
> **Hint**: use `--sandbox` along with `--writable`.

<!-- ```sh -->
<!-- centos -->
<!-- cd tmp -->
<!-- sudo apptainer build --sandbox debian.dir docker://debian -->
<!-- sudo apptainer shell --writable debian.dir -->
<!-- apt update -->
<!-- apt upgrade -y -->
<!-- apt-cache search pmi2 -->
<!-- ``` -->









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






## Running multi-locale Chapel from a container

- Useful if Chapel is not installed natively at your HPC centre.
- Somewhat tricky for multi-locale Chapel due to its dependence on the cluster's parallel launcher and interconnect.
- Piece of cake for single-locale Chapel and for *simulated* multi-locale Chapel.







## Running container instances

You can also run backgrounded processes within your container. You can start/terminate these with
`instance start`/`instance stop`. All these processes will terminate once your job ends.

```sh
module load apptainer/1.1.3
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






## R containers

<!-- Grigory's slides 15, 21 -->





## Transitioning from Singularity to Apptainer

In November 2021 the guidance of parts of Singularity was transferred to the
[Linux Foundation](https://www.linuxfoundation.org), and that fully open-source component has been renamed
*Apptainer*. The transition from Singularity to Apptainer should be seamless:

1. rename the `singularity` command to `apptainer`
1. rename all `SINGULARITY_*` environment variables to `APPTAINER_*`
1. rename all `SINGULARITYENV_*` environment variables to `APPTAINERENV_*` (prefix to pass variables to your container)





## Overlays and ephemeral temporary directories

The overlay "layers" on top of an immutable SIF image allow for changes without rebuilding the image. The
overlay can be:

- a sandbox directory,
- a standalone writable ext3 filesystem image,
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
cd scratch/containers
apptainer pull ubuntu.sif docker://ubuntu:latest
module load apptainer/1.1.3
salloc --cpus-per-task=1 --time=0:30:0 --mem-per-cpu=3600 --account=...

apptainer overlay create --size 512 small.img   # create a 0.5GB overlay image file
apptainer shell -C --overlay ./small.img -B /home,/scratch ubuntu.sif
```



<!-- Alternatively, we could add a writable overlay partition directly to an existing SIF image: -->
<!-- ```sh -->
<!-- apptainer overlay create --size 512 --create-dir /data ubuntu.sif -->
<!-- apptainer shell -C -B /home,/scratch ubuntu.sif -->
<!-- ``` -->
<!-- but this comes with a number of limitations, so we won't use this option. -->




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

apptainer shell -C --overlay ./small.img -B /home,/scratch ubuntu.sif

Apptainer> ls /data     # here is your data
```

You can create an overlay image with a directory inside with something like:

```sh
apptainer overlay create --create-dir /data --size 512 overlay.img   # create an overlay with a directory
```

If you want to mount the overlay in the read-only mode:

```sh
apptainer shell -C --overlay ./small.img:ro -B /home,/scratch ubuntu.sif
Apptainer>  touch /data/test.txt    # error: read-only file system
```

To see the help page:

```sh
apptainer help overlay create
```



Sparse images use disk more efficiently when blocks allocated to them are mostly empty. Let's create a sparse
overlay image:

```sh
apptainer overlay create --size 512 --sparse sparse.img
ls -l sparse.img                   # its apparent size is 512MB
du -h --apparent-size sparse.img   # same
du -h sparse.img                   # its actual size is much smaller (17MB)
```

Let's mount it and fill with some data:

```
apptainer shell -C --overlay sparse.img -B /home,/scratch ubuntu.sif

Apptainer> mkdir -p /data && cd /data
Apptainer> for num in $(seq -w 00 19); do
             echo $num
             # generate a binary file (1-33)MB in size
             dd if=/dev/urandom of=test"$num" bs=1024 count=$(( RANDOM + 1024 ))
           done
Apptainer> df -kh .     # should take ~300-400 MB, pay attention to "Used"

du -h sparse.img        # actual usage is now 385MB
```




Here is how you would install Conda into an overlay image:

```sh
apptainer pull ubuntu.sif docker://ubuntu:latest
apptainer overlay create --size 1024 big.img   # create a 1GB overlay image file
wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.12.0-Linux-x86_64.sh

apptainer shell --overlay ./big.img -B /home,/scratch ubuntu.sif

Apptainer> mkdir /conda && cd /conda
Apptainer> df -kh .
Apptainer> bash /home/user01/tmp/Miniconda3-py39_4.12.0-Linux-x86_64.sh
  agree to the license
  use /conda/miniconda3 for the installation path
  no to initialize Miniconda3
Apptainer> find /conda/miniconda3/ -type f | wc -l        # 17,722 files

apptainer shell  -B /home,/scratch ubuntu.sif
Apptainer> /conda/miniconda3/bin/python         # it is missing
Apptainer> ls /conda                            # no such file or directory

apptainer shell --overlay ./big.img -B /home,/scratch ubuntu.sif
Apptainer> /conda/miniconda3/bin/python         # works
```

These 17k+ files appear as a single file to the Lustre metadata server.












Outside the container, when an overlay is *not* in use, you can easily resize it:

```sh
e2fsck -f small.img         # good idea to check your overlay's filesystem first
resize2fs -p small.img 1G   # resize your overlay
```
