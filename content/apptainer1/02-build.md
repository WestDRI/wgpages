+++
title = "Creating container images"
slug = "02-build"
weight = 2
katex = true
+++

{{< toc >}}

{{< figure src="/img/apptainer.png" width=1000px caption="Blue lines show workflows without modifying a container, whereas grey-line workflows modify system files in your container and typically require root, although there are non-root workarounds in dotted boxes.">}}

## Build command

The `apptainer build <imagePath> <buildSpec>` command is a versatile tool that lets you:

1. download and assemble existing containers from external hubs like [Docker Hub](https://hub.docker.com)
   (`docker://`), [Singularity Hub](https://singularityhub.github.io) (`shub://`), and the [Container
   Library](https://cloud.sylabs.io) (`library://` - no longer supported by default),
1. create a container from scratch using an Apptainer definition file customized to your needs,
1. convert containers between different formats supported by Apptainer, e.g. create a container from a sandbox.

<!-- You can create an image from: -->
<!-- - a recipe/definition file (similar to Dockerfile for Docker images) -->
<!-- - from Singularity Hub -->
<!-- - from Docker Hub -->
<!-- - few other options -->

```sh
apptainer build --help
```

- {{<a "https://apptainer.org/docs/user/latest/build_a_container.html" "Build a Container">}} page in the
  Apptainer documentation

In <u>most cases</u>, you would download an existing Docker/Apptainer container image and build/run a
container from it, without having to modify the image. Or maybe, the image is already provided by your lab, a
research collaborator, or the Alliance. For example, right now we are testing a set of Apptainer images with
GPU development tools for different GPU architectures, such as NVIDIA's CUDA and AMD's ROCm, as it is often
difficult to compile these from source -- and we are planning to make these images available to all users in
the near future.

{{<note>}}
In most cases `apptainer build ...` will need root access, so for simple downloading of an online image as a
regular user you might prefer `apptainer pull ...` command.
{{</note>}}

### Build consideration 1: modifying system files inside the container (root vs. regular user)

In <u>other cases</u> you might want to modify the image or build your own container image from scratch. To
create a container image, you need a machine that:

1. runs Linux,
1. has Apptainer installed,
1. has Internet access, and
1. ideally where you have `root` (or `sudo`) permissions, otherwise all permissions inside the image will be
   messed up, and you won't have `root` or `sudo` access
    &nbsp;➜&nbsp; you won't be able to install or upgrade packages (this requires `root`)

It is possible to install packages and modify system (root-owned) files inside the container without being
root, either:

1. by using `--fakeroot` to modify system files inside the container as if you were root (covered in this
   section; this option might be prone to errors, depending on the complexity of your container), or
1. by using a `--remote` build option (covered in this section).

If installing packages is not important to you, i.e. you are planning to use the container as is for
production purposes, you can create an image on an HPC cluster; for more details see
{{<a "https://docs.alliancecan.ca/wiki/Singularity#Creating_images_on_Alliance_clusters" "Creating images on Alliance clusters">}}.


{{<note>}}
In Apptainer the user always remains the same inside and outside of the container. In other
words, if you enter a container without root privileges, you won't be able to obtain root privileges within
the container.
{{</note>}}

{{<note>}}
If you have access to your own Linux computer, it is best to build your images there (root access and
performance from a local drive). Alternatively, you can use a VM where you have root access.
{{</note>}}

{{<note>}}
If you have problems building an image for our HPC clusters, ask for help at <i>support@tech.alliancecan.ca</i>.
{{</note>}}

### Build consideration 2: host's filesystem limitations

Another limitation to keep in mind is the type and bandwitdth of the host's filesystem in which you are
building the container. Parallel filesystems such as Lustre and GPFS (used on our clusters for `/home`,
`/scratch`, `/project`) have some limitations that might lead to errors when creating a container -- for
technical details on one of the issues see {{<a
"https://apptainer.org/docs/admin/latest/installation.html#lustre-gpfs" "this page">}}.

In addition, building containers involves a large number of small file operations slowing down parallel
filesystems which were not optimized for this type of I/O. For this reason, when building containers on our
clusters, we highly recommend doing this inside Slurm jobs in `$SLURM_TMPDIR` (SSD local to a compute node).








## Running pre-packaged containers (without modifying them)

Run the "Lolcow" container by Apptainer developers:

```sh
mkdir tmp && cd tmp
module load apptainer
salloc --time=1:0:0 --mem-per-cpu=3600
apptainer pull hello-world.sif shub://vsoch/hello-world   # store it into the file hello-world.sif
apptainer run hello-world.sif   # run its default script
```

Where is this script? What did running the container actually do to result in the displayed output?

```sh
apptainer inspect -r hello-world.sif          # it runs the script /rawr.sh
apptainer exec hello-world.sif cat /rawr.sh   # here is what's inside
```

We can also run an image on the fly without putting it into the current directory:

```sh
rm hello-world.sif                        # clear old image
apptainer run shub://vsoch/hello-world    # use the cached image	
```

Alternatively, we can run a container directly off Docker Hub. However, it will first convert a Docker image
into an Apptainer image, and then run this Apptainer image:

```sh
apptainer run docker://godlovedc/lolcow   # random cow message
```

Let's try something more basic:

```sh
apptainer run docker://ubuntu   # press Ctrl-D to exit
```

What happened here in the last example? Well, there was no default script, so it just presented the container
shell to type commands.





### Apptainer’s image cache

In the last two examples we did not store SIF images in the current directory. Where were they stored?

```sh
apptainer cache list
apptainer cache list -v
apptainer cache clean          # clean all; will ask to confirm
apptainer cache clean --help   # more granular control
```

By default, Apptainer cache is stored in `$HOME/.apptainer/cache`. We can control the cache location with
APPTAINER_CACHE environment variable.




### Inspecting image metadata

```sh
apptainer inspect /path/to/SIF/file
apptainer inspect -r /path/to/SIF/file   # short for --runscript
apptainer inspect -d /path/to/SIF/file   # short for --deffile
```



## Modifying containers

### Demo: building a development container in a sandbox as root

{{<note>}}
You need to be root in this section. For this reason, in this section I will run a demo on a machine with root
access, and you can simply watch.
{{</note>}}

1. Pull a existing Docker image from Docker Hub.
1. Create a modifiable sandbox directory into which you can install packages.
1. Add packages and perhaps your application and data.
1. Convert the sandbox into a regular SIF image.

{{<note>}}
By default, Apptainer containers are read-only, i.e. while you can write into bind-mounted directories,
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
<!-- sudo apptainer build --sandbox ubuntu.dir docker-archive://ubuntu.tar -->
<!-- /bin/rm -rf build ubuntu.tar download-frozen-image-v2.sh -->
<!-- sudo apptainer shell --writable ubuntu.dir -->
<!-- apt-get update            # hit return twice -->
<!-- apt-get -y install wget   # will fail here if run as regular user -->
<!-- exit -->
<!-- ``` -->

<!-- New, single-step method: -->

<!-- Log in to your VM from Tuesday and install a text editor and Apptainer there: -->

<!-- ```sh -->
<!-- ssh -i <privateKey> centos@<your.floating.IP>   # or use MobaXTerm -->
<!-- sudo yum install nano -y          # or emacs, to edit files -->
<!-- sudo yum install apptainer -y     # install Apptainer -->
<!-- ``` -->

I will log in as user `centos` (with sudo privileges) to my own cloud machine and there run `apptainer` with
the full path (as `apptainer` from CVMFS will not be accessible to `sudo`):

<!-- APPTNR=/cvmfs/soft.computecanada.ca/easybuild/software/2020/Core/apptainer/1.1.8/bin/apptainer -->

```sh
ssh centos@cass
mkdir -p tmp && cd tmp
alias apptainer=/cvmfs/soft.computecanada.ca/easybuild/software/2020/Core/apptainer/1.1.8/bin/apptainer
apptainer build --sandbox ubuntu.dir docker://ubuntu   # sudo not yet required
du -sh ubuntu.dir                              # 82M, before installing packages
sudo apptainer shell --writable ubuntu.dir     # start the sandbox in writable mode;
                                               # sudo needed to install packages as root
Apptainer> apt-get update            # update the package index files
Apptainer> wget                      # not available
Apptainer> whoami                    # I am root, so can install software system-wide
Apptainer> apt-get -y install wget   # will fail here if Apptainer run without root

sudo du -sh ubuntu.dir               # 130M; sudo necessary to scan root directories
```

> Above you might see a warning when running `... apptainer shell --writable ...`
> ```txt
> WARNING: Skipping mount /etc/localtime [binds]: /etc/localtime doesn't exist in container
> ```
> occurs when you try to mount a file/directory into the container without that file/directory already
> inside the container. You can simply ignore this message.

To convert the sandbox to a regular non-writable SIF container image, use

```sh
sudo apptainer build ubuntu.sif ubuntu.dir
sudo rm -rf ubuntu.dir
ls -lh ubuntu.sif            # 62M (compressed)
apptainer shell ubuntu.sif   # can now start it as non-root

Apptainer> wget
Apptainer> ...

scp ubuntu.sif user149@lecarre.c3.ca:shared
```

As a regular user on the training cluster, I should be able to use this image now:

```sh
chmod -R og+rX ~user149/shared   # give read access to all users
module load apptainer
apptainer shell ~user149/shared/ubuntu.sif
```







### Fakeroot in a sandbox: no need for root!

{{<note>}}
You need an Apptainer 1.1 or later in this section, as well as `fakeroot-sysv` utility on the host preceding
`fakeroot` in the path. Our CVMFS modules have been patched to include this utility inside the
module's private bindir, and on standalone Linux systems `fakeroot-sysv` is typically installed when you
install the Apptainer package. This is to say that the approach outlined in this section most likely works
both on our production clusters and on most standalone Linux systems with Apptainer 1.1 (or higher). However,
it is always preferable to modify system files in the containers as root, and with
`--fakeroot` you might still run into problems with more complex Apptainer images, so always monitor your
output for errors.
{{</note>}}

We will follow the same recipe:

1. Pull a existing Docker image from Docker Hub.
1. Create a modifiable sandbox directory into which you can install packages.
1. Add packages and perhaps your application and data.
1. Convert the sandbox into a regular SIF image.

However, this time we will start the sandbox shell with the `--fakeroot` flag that will let us write system
files inside the container as a regular (non-root) user. As a reminder, we need the sandbox to be able to
modify files inside the container, i.e. we cannot do this inside an immutable SIF image.

```sh
mkdir -p tmp && cd tmp
apptainer build --sandbox ubuntu.dir docker://ubuntu   # create the sandbox in ubuntu.dir/
du -sh ubuntu.dir                                      # 81M, before installing packages
apptainer shell --fakeroot --writable ubuntu.dir   # with Apptainer 1.1 fakeroot works even
                                                   # without /etc/subuid mapping
Apptainer> apt-get update
Apptainer> apt-get -y install wget

du -sh ubuntu.dir                     # ~126M
```

> Above you might see a warning when running `... apptainer shell --writable ...`
> ```txt
> WARNING: Skipping mount /etc/localtime [binds]: /etc/localtime doesn't exist in container
> ```
> occurs when you try to mount a file/directory into the container without that file/directory already
> inside the container. You can simply ignore this message.

To convert the sandbox to a regular non-writable SIF container image, use

```sh
apptainer build ubuntu.sif ubuntu.dir
rm -rf ubuntu.dir
apptainer shell ubuntu.sif

Apptainer> wget
Apptainer> ...
```










### Building a development container from a definition file: root or not

{{<note>}}
Depending on your Apptainer installation, you may or may no need to be root in this section. Try to follow
along, if you want, or alternatively simply watch this demo.
{{</note>}}

Inside the VM, create a new file `test.def`:

```sh
cd ~/tmp
nano test.def
```
```txt
Bootstrap: docker
From: ubuntu:20.04

%post
    apt-get -y update && apt-get install -y python

%runscript
    python -c 'print("Hello World! Hello from our custom Apptainer image!")'
```

We will bootstrap our image from a minimal Ubuntu 20.04 Linux Docker image as then run it as a regular user:

```sh
apptainer build test.sif test.def   # in Apptainer 1.0 important to run this as root; it can run
                                    # without sudo but will use /etc/subuid mappings;
                                    # running this as regular user will result in errors;
                                    # in properly configured Apptainer 1.1 can run this as regular user
ls -l test.sif           # ~65M
apptainer run test.sif   # Hello World! Hello from our custom Apptainer image!
```

<!-- > On the training cluster, if you try to do the same as non-root with Apptainer 1.1, you will receive an error, as it will try to use non-existing /etc/subuid permissions from the host: -->
<!-- > ```sh -->
<!-- > $ apptainer build test.sif test.def -->
<!-- > FATAL:   container creation failed: mount hook function failure: mount /.singularity.d/libs/faked->/cvmfs/soft.computecanada.ca/easybuild/software/2020/Core/apptainer/1.1.8/var/apptainer/mnt/session/libs/faked error: while mounting /.singularity.d/libs/faked: mount source /.singularity.d/libs/faked doesn't exist -->
<!-- > FATAL:   While performing build: while running engine: exit status 255 -->
<!-- > ``` -->

<!-- Answer: we would need to either (1) replace `test.sif` with `--sandbox test.dir` to make it a sandbox: -->
<!-- ```sh -->
<!-- sudo apptainer build --sandbox test.dir test.def -->
<!-- sudo apptainer shell --writable ubuntu.dir -->
<!-- apt-get update            # hit return twice -->
<!-- apt-get -y install wget   # will fail here if run as regular user -->
<!-- ``` -->
<!-- or (2) modify the definition file. -->
<!-- or (3) use contaner overlays. -->

More advanced definition files may have these sections:

    %setup - commands in this section are first executed on the host system outside of the container
    %files - copy files into the container with greater safety
    %environment - define environment variables that will be set at runtime
    %startscript - executed when the `instance start` command is issued
    %test - runs at the very end of the build process to validate the container using a method of your choice
    %labels - add metadata to `/.apptainer.d/labels.json` within your container
    %help - this text can then be displayed with `apptainer run-help ...` in the host

as described in {{<a "https://apptainer.org/docs/user/latest/definition_files.html#sections" "the user guide">}}.

> #### Key point
> Apptainer definition files are used to define the build process and configuration for an image.

> #### <font style="color:blue">Discussion</font>
> At this point, how do we install additional packages into this new container? There are several options.






### Remote builder: no need for root!

If you have access to a platform with Apptainer installed but you don't have root access to create
containers, you may be able to use the Remote Builder functionality to offload the process of building an
image to remote cloud resources. One popular cloud service for this is the {{<a
"https://cloud.sylabs.io/builder" "Remote Builder">}} from SyLabs, the developers of Apptainer. If you want
to use their service, you will need to register for a cloud token via the link on the
[their page](https://cloud.sylabs.io/builder). Here is one possible workflow:

1. Log in at https://cloud.sylabs.io/builder (can sign in with an existing GitHub account).
1. Generate an access token at https://cloud.sylabs.io/auth/tokens and copy it into your clipboard.
1. On the training cluster create a new local file `test.def`:

```txt
Bootstrap: docker
From: ubuntu:20.04

%post
    apt-get -y update && apt-get install -y python

%runscript
    python -c 'print("Hello World! Hello from our custom Apptainer image!")'
```

4. Build the image remotely and then run it locally:

```sh
module load apptainer/1.1.8
apptainer remote login    # enter the token
apptainer remote status   # check that you are able to connect to the services
apptainer build --remote test.sif test.def
ls -l test.sif   # 62M
apptainer run test.sif   # Hello World! Hello from our custom Apptainer image!
```

You can find more information on remote endpoints in the
[official documentation](https://sylabs.io/guides/3.8/user-guide/endpoint.html).









## Running more useful Docker images via Apptainer as regular user
### Running client-server ParaView from a container

You can pull a Docker image from [Docker Hub](https://hub.docker.com) and convert it to an Apptainer
image. For this you typically do not need `sudo` access. Please build containers only on compute nodes, as
this process is CPU-intensive.

The following commands require online access and will work only on Cedar (and the training cluster!)  where
compute nodes can access Internet. Let's search [Docker Hub](https://hub.docker.com) for
*"topologytoolkit"*. Click on the result and then on Tags -- you should see the suggested Docker command
*"docker pull topologytoolkit/ttk:5.10.1-stable"*. From Apptainer, the address will be
*"docker://topologytoolkit/ttk:5.10.1-stable"*.

```sh
cd ~/tmp
module load apptainer/1.1.8
salloc --cpus-per-task=1 --time=0:30:0 --mem-per-cpu=3600
apptainer pull topologytoolkit.sif docker://topologytoolkit/ttk:5.10.1-stable
```

> Note: on other production clusters -- such as Béluga, Narval or Graham -- compute nodes do not have Internet access,
> so you will have to use the two-step approach there:
> ```sh
> cd ~/scratch
> wget https://raw.githubusercontent.com/moby/moby/master/contrib/download-frozen-image-v2.sh
> sh download-frozen-image-v2.sh build ttk:latest   # download an image
>                                                   # from Docker Hub into build/
> cd build && tar cvf ../ttk.tar * && cd ..
> module load apptainer/1.1.8
> salloc --cpus-per-task=1 --time=0:30:0 --mem-per-cpu=3600 --account=...
> apptainer build topologytoolkit.sif docker-archive://ttk.tar   # build the Apptainer image;
>                                                                # wait for `Build complete`
> /bin/rm -rf build topologytoolkit.tar
> ```

Let's use this image! While still inside the job (on a compute node):

```sh
unzip /project/def-sponsor00/shared/paraview.zip data/sineEnvelope.nc   # unpack some sample data
apptainer exec -B /home topologytoolkit.sif pvserver
```

If successful, it should say something like *"Accepting connection(s): node1.int.lecarre.c3.ca:11111"* --
write down the node and the port names as you will need them in the next step.

On your laptop, set up SSH port forwarding to this compute node and port:

```sh
ssh username@lecarre.c3.ca -L 11111:node1:11111
```

Next, start ParaView 5.10.x on your computer and connect to `localhost:11111`, and then load the dataset and
visualize it.

### Switching to another Linux distribution

... is super-easy:

```sh
apptainer pull centos.sif docker://centos:latest
apptainer pull debian.sif docker://debian:latest
apptainer pull ubuntu.sif docker://ubuntu:latest
apptainer pull ubuntu.sif docker://ubuntu:19.04   # specific older version
```




> ### <font style="color:blue">Exercise 1: latest Python image</font>
> Pull the latest Python image from Docker Hub into an Apptainer image. It should take few minutes to build it.
> 1. How large is the resulting image?
> 1. Run container's Python with the `exec` command. Which version of Python did it install?
> 1. Do some math, e.g. print $\pi$.
> 1. When you exit Python, you will be back to your host system's shell.
> 1. Which operating system does this container run?
> ```sh
> module load apptainer/1.1.8
> salloc --cpus-per-task=1 --time=3:00:0 --mem-per-cpu=3600
> apptainer pull python.sif docker://???
> ```
> <!-- docker://python -->

> ### <font style="color:blue">Exercise 2: CPU-based PyTorch image</font>
> Pull a recent <b>CPU-based</b> PyTorch image from Docker Hub into an Apptainer image.
> ```sh
> module load apptainer/1.1.8
> salloc --cpus-per-task=1 --time=3:00:0 --mem-per-cpu=3600
> apptainer pull pytorch.sif docker://???
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

<!-- {{<a "link" "text">}} -->
