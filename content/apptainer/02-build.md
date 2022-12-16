+++
title = "Creating container images"
slug = "02-build"
weight = 2
katex = true
+++

<!-- https://docs.sylabs.io/guides/3.0/user-guide/build_a_container.html -->

The `singularity build <imagePath> <buildSpec>` command is a versatile tool that lets you:

1. download and assemble existing containers from external hubs like the
   [Container Library](https://cloud.sylabs.io) (`library://`), [Docker Hub](https://hub.docker.com)
   (`docker://`), and [Singularity Hub](https://singularityhub.github.io) (`shub://`),
1. create a container from scratch using a Singularity definition file customized to your needs,
1. convert containers between different formats supported by Singularity,
1. create a container from a sandbox.

<!-- You can create an image from: -->
<!-- - a recipe/definition file (similar to Dockerfile for Docker images) -->
<!-- - from Singularity Hub -->
<!-- - from Docker Hub -->
<!-- - few other options -->

```sh
singularity build --help
```

In <u>many (99%?) cases</u>, you would download an existing Docker/Singularity container image and build/run a
container from it, without having to modify the image. Or maybe, the image is already provided by your lab, a
research collaborator, or the Alliance. For example, right now we are testing a set of Singularity images with
GPU development tools for different GPU architectures, such as NVIDIA's CUDA and AMD's ROCm, as it is often
difficult to compile these from source -- and we are planning to make these images available to all users
likely in the fall.

In <u>other cases</u> you might want to modify the image or build your own container image from scratch. To
create a container image, you need a machine that:

1. runs Linux,
1. has Singularity installed,
1. has Internet access, and
1. ideally where you have `root` (or `sudo`) permissions, otherwise:
  - all permissions inside the image will be messed up, and you won't have `root` or `sudo` access
    &nbsp;➜&nbsp; you won't be able to install or upgrade packages (this requires `root`)
  - if installing packages is not important to you, i.e. you are planning to use the container as is for
    production purposes, you can create an image on an HPC cluster; for more details see
    [Creating images on Compute Canada clusters](https://bit.ly/3xg29gK)
  - for developing/modifying the container you will need `root`

{{<note>}} In Singularity the user always remains the same inside and outside of the container. In other
words, if you enter a container without root privileges, you won't be able to obtain root privileges within
the container. {{</note>}}

{{<note>}}
If you have access to your own Linux computer, it is best to build your images there (root access and
performance from a local drive). Alternatively, you can use a VM.
{{</note>}}

{{<note>}}
If you have problems building an image for our HPC clusters, ask for help at <i>support@tech.alliancecan.ca</i>.
{{</note>}}





## Example: run a pre-packaged container

Run the "Lolcow" container by Singularity developers:

```sh
mkdir tmp && cd tmp
module load singularity
salloc --time=1:0:0 --mem-per-cpu=3600
singularity pull hello-world.sif shub://vsoch/hello-world   # store it into the file hello-world.sif
singularity run hello-world.sif   # run its default script
```

Where is this script? What did running the container actually do to result in the displayed output?

```sh
singularity inspect -r hello-world.sif          # it runs the script /rawr.sh
singularity exec hello-world.sif cat /rawr.sh   # here is what's inside
```

We can also run an image on the fly without putting it into the current directory:

```sh
rm hello-world.sif                          # clear old image
singularity run shub://vsoch/hello-world    # use the cached image	
```

We also run a container directly off Docker Hub. However, it will first convert a Docker image into a
Singularity image, and then run this Singularity image:

```sh
singularity run docker://godlovedc/lolcow   # random cow message
```

Let's try something more basic:

```sh
singularity run docker://ubuntu   # press Ctrl-D to exit
```

What happened here in the last example? Well, there was no default script, so it just presented the container
shell to type commands.





## Singularity’s image cache

In the last two examples we did not store SIF images in the current directory. Where were they stored?

```sh
singularity cache list
singularity cache list -v
singularity cache clean          # clean all; will ask to confirm
singularity cache clean --help   # more granular control
```

By default, Singularity cache is stored in `$HOME/.singularity/cache`. We can control the cache location with
SINGULARITY_CACHE environment variable.




## Inspecting image metadata

```sh
singularity inspect /path/to/SIF/file
singularity inspect -r /path/to/SIF/file   # short for --runscript
singularity inspect -d /path/to/SIF/file   # short for --deffile
```




## Building a development container in a sandbox as root

{{<note>}}
You need to be root in this section.
{{</note>}}

1. Pull a existing Docker image from Docker Hub.
1. Create a modifiable sandbox directory into which you can install packages.
1. Add packages and perhaps your application and data.
1. Convert the sandbox into a regular SIF image.

{{<note>}}
By default, Singularity containers are read-only, i.e. while you can write into bind-mounted directories,
normally you cannot modify files inside the container.
{{</note>}}

To build a writable container into which you can install packages, you need `root` access. The `--sandbox`
flag below builds a sandbox to which changes can be made, and the `--writable` flag launches a read-write
container. In this example `ubuntu.dir` is a directory on the host filesystem.

<!-- Old, two-step method: -->
<!-- ```sh -->
<!-- centos -->
<!-- cd tmp -->
<!-- wget https://raw.githubusercontent.com/moby/moby/master/contrib/download-frozen-image-v2.sh -->
<!-- sh download-frozen-image-v2.sh build ubuntu:latest   # download an image from Docker Hub into build/ -->
<!-- cd build && tar cvf ../ubuntu.tar * && cd .. -->
<!-- sudo singularity build --sandbox ubuntu.dir docker-archive://ubuntu.tar -->
<!-- /bin/rm -rf build ubuntu.tar download-frozen-image-v2.sh -->
<!-- sudo singularity shell --writable ubuntu.dir -->
<!-- apt-get update            # hit return twice -->
<!-- apt-get -y install wget   # will fail here if run as regular user -->
<!-- exit -->
<!-- ``` -->

<!-- New, single-step method: -->

Log in to your VM from Tuesday and install a text editor and Singularity there:

```sh
ssh -i <privateKey> centos@<your.floating.IP>   # or use MobaXTerm
sudo yum install nano -y          # or emacs, to edit files
sudo yum install singularity -y   # install Singularity 3.8
```

> ### <font style="color:blue">Note to self</font>
> The presenter can also log in as `centos` user to the training cluster and there run singularity with the
> full path (as `singularity` from CVMFS will not be accessible to `sudo`), e.g.
> ```sh
> sudo /opt/software/singularity-3.7/bin/singularity build --sandbox ubuntu.dir docker://ubuntu
> ```

```sh
mkdir -p tmp && cd tmp
sudo singularity build --sandbox ubuntu.dir docker://ubuntu
sudo du -skh ubuntu.dir   # 81M
sudo singularity shell --writable ubuntu.dir
apt-get update            # hit return twice
apt-get -y install wget   # will fail here if Singularity were run as regular user
exit
sudo du -skh ubuntu.dir   # 118M
```

> Above you might see a warning when running `... singularity shell --writable ...`
> ```txt
> WARNING: Skipping mount /etc/localtime [binds]: /etc/localtime doesn't exist in container
> ```
> occurs when you try to mount a file/directory into the container without that file/directory already
> inside the container. You can simply ignore this message.

To convert the sandbox to a regular non-writable SIF container image, use

```sh
sudo singularity build ubuntu.sif ubuntu.dir
sudo rm -rf ubuntu.dir
singularity shell ubuntu.sif   # can now start it as non-root
scp ubuntu.sif <username>@kandinsky.c3.ca:tmp
```







## Building a development container from a definition file as root

{{<note>}}
You need to be root in this section.
{{</note>}}

Inside the VM, create a new file `test.def` (this is where the text editor becomes useful!):

```txt
Bootstrap: docker
From: ubuntu:20.04

%post
    apt-get -y update && apt-get install -y python

%runscript
    python -c 'print("Hello World! Hello from our custom Singularity image!")'
```

We will bootstrap our image from a minimal Ubuntu 20.04 Linux Docker image as then run it as a regular user:

```sh
cd ~/tmp
sudo singularity build test.sif test.def
ls -l test.sif   # 62M
singularity run test.sif   # Hello World! Hello from our custom Singularity image!
```

> On the training cluster, if you try to do the same as non-root, you will receive an error:
> ```sh
> $ singularity build test.sif test.def
> FATAL:   You must be the root user, however you can use --remote or --fakeroot to build from a Singularity recipe file
> $ singularity build --fakeroot test.sif test.def
> FATAL:   could not use fakeroot: no mapping entry found in /etc/subuid for razoumov
> ```
> We will cover the `--remote` option in the last section.

> ### <font style="color:blue">Discussion</font>
>
> How do we install additional packages into this new container? (There are two options.)

<!-- Answer: we would need to either (1) replace `test.sif` with `--sandbox test.dir` to make it a sandbox: -->
<!-- ```sh -->
<!-- sudo singularity build --sandbox test.dir test.def -->
<!-- sudo singularity shell --writable ubuntu.dir -->
<!-- apt-get update            # hit return twice -->
<!-- apt-get -y install wget   # will fail here if run as regular user -->
<!-- ``` -->
<!-- or (2) modify the definition file. -->

More advanced definition files may have these sections:

    %setup - commands in this section are first executed on the host system outside of the container
    %files - copy files into the container with greater safety
    %environment - define environment variables that will be set at runtime
    %startscript - executed when the `instance start` command is issued
    %test - runs at the very end of the build process to validate the container using a method of your choice
    %labels - add metadata to `/.singularity.d/labels.json` within your container
    %help - this text can then be displayed with `singularity run-help ...` in the host

as described in {{<a "https://docs.sylabs.io/guides/3.7/user-guide/definition_files.html#sections" "the user guide">}}.

> ## Key points
> 1. Singularity definition files are used to define the build process and configuration for an image.







## Converting a Docker image to Singularity as regular user
### Running client-server ParaView from a container

You can pull a Docker image from [Docker Hub](https://hub.docker.com) and convert it to a Singularity
image. For this you typically do not need `sudo` access. Please build containers only on compute nodes, as
this process is CPU-intensive.

The following commands require online access and will work only on Cedar (and the training cluster!)  where
compute nodes can access Internet. Let's search [Docker Hub](https://hub.docker.com) for
*"topologytoolkit"*. Click on the result and then on Tags -- you should see the suggested Docker command *"docker
pull topologytoolkit/ttk:latest"*. From Singularity, the address will be *"docker://topologytoolkit/ttk:latest"*.

```sh
cd ~/scratch
module load singularity
salloc --cpus-per-task=1 --time=0:30:0 --mem-per-cpu=3600 --account=...
singularity pull topologytoolkit.sif docker://topologytoolkit/ttk:latest
```

> Note: on other production clusters -- such as Béluga, Narval or Graham -- compute nodes do not have Internet access,
> so you will have to use the two-step approach there:
> ```sh
> cd ~/scratch
> wget https://raw.githubusercontent.com/moby/moby/master/contrib/download-frozen-image-v2.sh
> sh download-frozen-image-v2.sh build ttk:latest   # download an image
>                                                   # from Docker Hub into build/
> cd build && tar cvf ../ttk.tar * && cd ..
> module load singularity
> salloc --cpus-per-task=1 --time=0:30:0 --mem-per-cpu=3600 --account=...
> singularity build topologytoolkit.sif docker-archive://ttk.tar   # build the Singularity image;
>                                                                  # wait for `Build complete`
> /bin/rm -rf build topologytoolkit.tar
> ```

Let's use this image! While still inside the job (on a compute node):

```sh
unzip /home/razoumov/shared/paraview.zip data/sineEnvelope.nc   # unpack some sample data
singularity run -B /home topologytoolkit.sif pvserver
```

If successful, it should say something like *"Accepting connection(s): node1.int.kandinsky.c3.ca:11111"* --
write down the node and the port names as you will need them in the next step.

On your laptop, set up SSH port forwarding to this compute node and port:

```sh
ssh username@kandinsky.c3.ca -L 11111:node1:11111
```

Next, start ParaView 5.10.x on your computer and connect to `localhost:11111`, and then load the dataset and
visualize it.

### Switching to another Linux distribution

... is super-easy:

```sh
singularity pull centos.sif docker://centos:latest
singularity pull debian.sif docker://debian:latest
singularity pull ubuntu.sif docker://ubuntu:latest
singularity pull ubuntu.sif docker://ubuntu:19.04   # specific older version
```




> ### <font style="color:blue">Exercise 1</font>
> Pull the latest Python image from Docker Hub into a Singularity image. It should take few minutes to build it.
> 1. How large is the resulting image?
> 1. Run container's Python with the `exec` command. Which version of Python did it install?
> 1. Do some math, e.g. print $\pi$.
> 1. When you exit Python, you will be back to your host system's shell.
> 1. Which operating system does this container run?
> ```sh
> module load singularity
> salloc --cpus-per-task=1 --time=3:00:0 --mem-per-cpu=3600
> singularity pull python.sif docker://???
> ```
> <!-- docker://python -->

> ### <font style="color:blue">Exercise 2</font>
> Pull a recent <b>CPU-based</b> PyTorch image from Docker Hub into a Singularity image.
> ```sh
> module load singularity
> salloc --cpus-per-task=1 --time=3:00:0 --mem-per-cpu=3600
> singularity pull pytorch.sif docker://???
> ```
> <!-- docker://intel/intel-optimized-pytorch:latest -->
> Try running some basic PyTorch commands inside this image:
> ```py
> import torch
> A = torch.tensor([[2., 3., -1.], [1., -2., 8.], [6., 1., -3.]])
> print(A)
> b = torch.tensor([5., 21., -1.])
> print(b)
> x = torch.linalg.solve(A, b)
> print(x)
> torch.allclose(A @ x, b)   # verify the result
> ```
> For more info on working with PyTorch tensors watch
> [our webinar](https://westgrid.github.io/trainingMaterials/tools/ml/#pytorch-tensors).
