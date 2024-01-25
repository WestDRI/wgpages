+++
title = "More on running containers"
slug = "03-run"
weight = 3
+++

{{< toc >}}

## Different ways to run a container

If you have not done so already, let's pull the latest Ubuntu container from Docker:

```sh
# cd ~/tmp
module load apptainer/1.1.8
# salloc --cpus-per-task=1 --time=3:00:0 --mem-per-cpu=3600
apptainer pull ubuntu.sif docker://ubuntu
```

We already saw some of these commands:

- `apptainer shell ubuntu.sif` launches the container and opens an interactive shell inside it
- `apptainer exec ubuntu.sif <command>` launches the container and runs a command inside it
- `apptainer run ubuntu.sif` launches the container and executes the default runscript

Apptainer matches users between the container and the host. For example, if you run a container that needs
to be root, you also need to be root outside the container.

### 1. Running a single command

```sh
apptainer exec ubuntu.sif ls /
apptainer exec ubuntu.sif ls /; whoami
apptainer exec ubuntu.sif bash -c "ls /; whoami"   # probably a safer way
apptainer exec ubuntu.sif cat /etc/os-release
```

### 2. Running a default script

We've already done this! If there is no default script, Apptainer will give you the shell to type in your
commands.

### 3. Starting a shell

We've already done this!

```sh
$ apptainer shell ubuntu.sif
Apptainer> whoami   # same username as in the host system
Apptainer> groups   # tries to match groups as on the host system
```

At startup Apptainer simply copied the relevant user and group lines from the host system to files
`/etc/passwd` and `/etc/group` inside the container. Why do this? The container must ensure that you cannot
modify anything on the host system that you should not have permission to, i.e. you are restricted to the same
user permissions within the container as you are on the host system.

## Mounting external directories and copying environment

By default, Apptainer containers are read-only, so you cannot write into its directories. However, from
inside the container you can organize read-write access to your directories on the host filesystem. The
command

```sh
apptainer shell -B /home,/project,/scratch ubuntu.sif
```

will bind-mount `/home,/project,/scratch` inside the container so that these directories can be accessed for
both read and write, subject to your account's permissions, and then will run a shell. Inside the container:

```sh
pwd     # most likely your working directory
echo $USER
ls /home/$USER
ls /scratch/$USER
ls /project/def-sponsor00/$USER
```

You can mount host directories to specific paths inside the container, e.g.

```sh
apptainer shell -B /project/def-sponsor00/$USER:/myproject,/home/$USER/scratch:/myscratch ubuntu.sif
Apptainer> ls /myproject
Apptainer> ls /myscratch
```

Note that by default Apptainer typically mounts some of the host's directories. The flag `-C` will hide the
host's filesystems and environment variables, but then you need to explicitly bind-mount the needed paths (to
store results), e.g.

```sh
apptainer shell -C -B /scratch ubuntu.sif   # from the host see only /scratch
```

<!-- The reason is that it needs some space to store temporary files that get generated along the way, access some -->
<!-- host's system files, and also provide space in `/home` to store your data. -->

You can disable specific mounts, e.g. the following will start the container without a home directory:

```sh
apptainer shell --no-mount home ubuntu.sif
cd     # no such file or directory
```

Alternatively, you can disable mounting `/home` with the `--no-home` flag. And you can disable multiple mounts
with something like `--no-mount tmp,sys,dev`.

In general, without `-C`, Apptainer inherits all environment variables and default bind-mounted
filesystems. You can add the `-e` flag to remove only the host's environment variables from your container but
keep the default bind-mounted filesystems, to start in a *cleaner* environment:

```sh
apptainer shell ubuntu.sif
Apptainer> echo $USER $PYTHONPATH         # defined from the host
Apptainer> ls /home/user149               # shows my $HOME content on the host

apptainer shell -C ubuntu.sif
Apptainer> echo $USER $PYTHONPATH         # not defined
Apptainer> ls /home/user149               # nothing

apptainer shell -e ubuntu.sif
Apptainer> echo $USER $PYTHONPATH         # not defined
Apptainer> ls /home/user149               # shows my $HOME content on the host
```

On the other hand, you can pass variables to your container by prefixing their names:

```sh
$ APPTAINERENV_HI=hello apptainer shell mpi.sif
Apptainer> echo $HI
hello
```

Finally, you don't have to pass the same bind (`-B`) flags every time -- instead you can put them into a
variable (that can be stored in your `~/.bashrc` file):

```sh
export APPTAINER_BIND="/home,/project/def-sponsor00/${USER}:/project,/scratch/${USER}:/scratch"
apptainer shell ubuntu.sif
```

You can have more granular control (e.g. specifying read only) with the `--mount` flag -- for details see the
official
[Bind Paths and Mounts documentation](https://sylabs.io/guides/latest/user-guide/bind_paths_and_mounts.html).

> ### Key points
> 1. Your current directory and home directory are usually available by default in a container.
> 1. You have the same username and permissions in a container as on the host system.
> 1. You can specify additional host system directories to be available in the container.
> 1. It is a very good idea to use `-C` to hide the host's filesystems while mounting only few specific
>    directories.
