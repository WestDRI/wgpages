+++
title = "From cloud to HPC"
slug = "cloud2hpc"
katex = true
+++

# ... building a GPU-enabled container on Arbutus





This webinar (90% ready) was scheduled for 2025-Mar-11, but then cancelled as I was sick.






## Abstract

In this beginner-friendly webinar I will walk through the steps of creating a GPU container on a virtual
machine (VM) on Arbutus that can be deployed on HPC clusters with NVIDIA GPUs. This webinar will teach you how
to:

1. create a VM on Arbutus cloud,
2. create an Apptainer sandbox from scratch in Linux,
3. install NVIDIA drivers and CUDA into the container,
4. compile GPU-enabled, single-locale Chapel in the container,
5. convert the sandbox into a SIF container,
6. compile and run Chapel codes inside the container, both on the VM and on production HPC clusters.

## Spinning up a VM with a GPU

1. https://arbutus.cloud.computecanada.ca/project/instances   # log in with CCDB credentials
1. to CCInternal-magic-castle-training project
1. Compute | Instances | Launch Instance
1. Instance Name = alex-gpu-webinar
1. Source = AlmaLinux-9.4-x64-2024-05
1. Flavor = g1-8gb-c4-22gb
1. Networks = CCInternal-magic-castle-training-network
1. Security Groups = default
1. Key Pairs = alex20240821
1. click Launch (may take a few mins)
1. Instances -> in the drop-down menu select Associate Floating IP
1. Network | Security Groups | on the ``default'' row click Manage Rules
1. Add Rule | pick SSH from the first drop-down menu | click Add

```sh
chmod 600 ~/.ssh/alex20240821.pem
ssh -i ~/.ssh/alex20240821.pem almalinux@206.12.91.229
```

```sh
sudo dnf check-update              # check which packages have pending updates
sudo dnf update -y                 # update these
sudo dnf install -y epel-release   # enable Extra Packages for Enterprise Linux (EPEL)
sudo dnf install -y git apptainer cmake bat
sudo dnf install -y htop nano wget tmux emacs-nox netcdf netcdf-devel
sudo reboot

git clone git@bitbucket.org:razoumov/synchpc.git syncHPC
/bin/rm -f ~/.bashrc && ln -s syncHPC/bashrc ~/.bashrc && source ~/.bashrc
/bin/rm -f ~/.emacs && ln -s syncHPC/emacs ~/.emacs
ln -s syncHPC/startSingleLocaleGPU.sh startSingleLocaleGPU.sh
```

Volumes | Volumes | Create a volume, name=razoumovVol, no source, empty volume, type default, 300 GB, click Create
from your instance Attach Volume: pick "razoumovVol"
Compute | Instances | Attach volume, select razoumovVol, click Attach
Compute | Instances | Volumes Attached, check which device it is attached to, e.g. /dev/vdb
```sh
ssh alma
sudo fdisk -l               # find your volume/device
sudo fdisk /dev/vdb         # type "g" to create a partition, then "w" to write and exit
sudo mkfs.ext4 /dev/vdb     # format the partition
sudo mkdir /data
sudo mount /dev/vdb /data   # mount the parition
df -hT /data                # check it
sudo mkdir /data/work
sudo chown almalinux.almalinux -R /data/work
```

"The Nouveau GPU driver is an open-source graphics driver for NVIDIA GPUs, developed as part of the Linux
kernel. It provides support for NVIDIA graphics cards without requiring NVIDIA's proprietary driver. However,
Nouveau is often slower and lacks full support for newer GPU features compared to the official NVIDIA driver."

The GPU driver details below are from https://docs.alliancecan.ca/wiki/Using_cloud_vGPUs

```sh
# prevent loading of the buggy Nouveau GPU driver when the system boots
sudo sh -c "echo 'blacklist nouveau' > /etc/modprobe.d/blacklist-nouveau.conf"
sudo sh -c "echo 'options nouveau modeset=0' >> /etc/modprobe.d/blacklist-nouveau.conf"
sudo dracut -fv --omit-drivers nouveau
sudo dnf -y update
# sudo dnf -y install epel-release   # already done
sudo reboot

# install the vGPU driver
# sudo dnf remove libglvnd-gles-1:1.3.4-1.el9.x86_64
# sudo dnf remove libglvnd-glx-1:1.3.4-1.el9.x86_64
sudo dnf -y install http://repo.arbutus.cloud.computecanada.ca/pulp/repos/alma9/Packages/a/arbutus-cloud-vgpu-repo-1.0-1.el9.noarch.rpm   # install the Arbutus vGPU Cloud repository
sudo dnf -y install nvidia-vgpu-gridd.x86_64 nvidia-vgpu-tools.x86_64 nvidia-vgpu-kmod.x86_64
nvidia-smi
```
```output
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 550.54.15              Driver Version: 550.54.15      CUDA Version: 12.4     |
|-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  GRID V100D-8C                  On  |   00000000:00:05.0 Off |                    0 |
| N/A   N/A    P0             N/A /  N/A  |       0MiB /   8192MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+
```
```sh
# install CUDA
SRC=https://developer.download.nvidia.com/compute/cuda/12.4.0/local_installers
wget $SRC/cuda-repo-rhel9-12-4-local-12.4.0_550.54.14-1.x86_64.rpm   # 4.6GB download
sudo dnf -y install cuda-repo-rhel9-12-4-local-12.4.0_550.54.14-1.x86_64.rpm
sudo dnf clean all
sudo dnf -y install cuda-toolkit-12-4
>>> do not delete cuda-repo-rhel9-12-4-local-12.4.0_550.54.14-1.x86_64.rpm (will be needed later)
```

now there is `/usr/local/cuda-12.4/bin/nvcc`

## Installing Chapel with GPU support natively

This step is optional, just to test GPU Chapel without installing it into the container.

```sh
almalinux@alex-gpu-testing
wget https://github.com/chapel-lang/chapel/releases/download/2.3.0/chapel-2.3.0.tar.gz
tar xvfz chapel-2.3.0.tar.gz
cd chapel-2.3.0
source util/setchplenv.bash
export CHPL_LLVM=bundled
export CHPL_COMM=none
export CHPL_TARGET_CPU=none   # full list https://chapel-lang.org/docs/usingchapel/chplenv.html#chpl-target-cpu
export CHPL_LOCALE_MODEL=gpu
export CHPL_GPU=nvidia
export CHPL_CUDA_PATH=/usr/local/cuda-12.4
mkdir -p ~/c1/chapel-2.3.0 && /bin/rm -rf ~/c1/chapel-2.3.0/*
./configure --chpl-home=$HOME/c1/chapel-2.3.0   # inspect the settings
make -j4
make install
```

```sh
source ~/startSingleLocaleGPU.sh
git clone git@bitbucket.org:razoumov/chapel.git ~/chapelCourse
cd ~/chapelCourse/gpu
chpl --fast probeGPU.chpl
./probeGPU
cd ../juliaSet
chpl --fast juliaSetSerial.chpl
chpl --fast juliaSetGPU.chpl
./juliaSetSerial --n=8000   # 9.28693s
./juliaSetGPU --n=8000      # 0.075753s
cd ../primeFactorization
chpl --fast primesGPU.chpl
./primesGPU --n=10_000_000   # 0.04065s; A = 4561 1428578 5000001 4894 49
```

## Building a Chapel GPU container

`--nv` does not work with `--writable`, so you can't create a writable sandbox that mounts the host's GPU
drivers and libraries, and into which you would install GPU Chapel. There are some solutions around this:

(1) You could do this via a writable overlay image, creating and then starting an immutable SIF container with
`--nv` and then installing GPU Chapel into the overlay. It works, but in my experience this is not the best
option from the performance standpoint.

(2) You can install the NVIDIA Container Toolkit:

```sh
URL=https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo
curl -s -L $URL | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo
sudo dnf install -y nvidia-container-toolkit
```
and then combine `--nv` and `--writable`:
```sh
apptainer build --sandbox almalinux.dir docker://almalinux
export NVIDIA_DRIVER_CAPABILITIES="compute,utility"
sudo apptainer shell --writable --nv --nvccli almalinux.dir
```
but I don't see `nvcc` inside the container (maybe I am missing something obvious?).

(3) You can bootstrap from an NVIDIA development image, and compile GPU Chapel in there.

(4) Install CUDA into the container and use it to compile GPU Chapel:

```sh
cd /data/work
mkdir tmp
export APPTAINER_TMPDIR=/data/work/tmp
apptainer build --sandbox almalinux.dir docker://almalinux   # sudo not yet required
mkdir almalinux.dir/source
mv ~/cuda-repo-rhel9-12-4-local-12.4.0_550.54.14-1.x86_64.rpm almalinux.dir/source/
sudo apptainer shell --writable almalinux.dir
Apptainer> dnf check-update
           dnf update -y
           dnf install -y cmake gcc g++ python3 wget
           # install CUDA inside the container
           dnf -y install /source/cuda-repo-rhel9-12-4-local-12.4.0_550.54.14-1.x86_64.rpm
           dnf clean all   # remove cached package data
           dnf -y install cuda-toolkit-12-4
		   /bin/rm /source/cuda-repo-rhel9-12-4-local-12.4.0_550.54.14-1.x86_64.rpm

mkdir almalinux.dir/c1/
cp ~/chapel-2.3.0.tar.gz almalinux.dir/source
```

```sh
sudo apptainer shell --writable almalinux.dir
Apptainer> cd /source
           tar xvfz chapel-2.3.0.tar.gz
           cd chapel-2.3.0
           source util/setchplenv.bash
           export CHPL_LLVM=bundled
           export CHPL_COMM=none
           export CHPL_TARGET_CPU=none
           export CHPL_LOCALE_MODEL=gpu
           export CHPL_GPU=nvidia
           export CHPL_CUDA_PATH=/usr/local/cuda-12.4
           mkdir -p /c1/chapel-2.3.0 && /bin/rm -rf /c1/chapel-2.3.0/*
           ./configure --chpl-home=/c1/chapel-2.3.0
           make -j4
           make install
           /bin/rm -r /source

sudo apptainer build almalinux.sif almalinux.dir
sudo apptainer shell --nv almalinux.sif
Apptainer> nvidia-smi   # should show the same info as above
```

## Testing on the VM

```sh
cd
sudo apptainer shell --nv /data/work/almalinux.sif
cd chapelCourse/gpu
source /c1/chapel-2.3.0/util/setchplenv.bash
export CHPL_GPU=nvidia
export CHPL_CUDA_PATH=/usr/local/cuda-12.4
export PATH=$CHPL_CUDA_PATH/bin:$PATH
make clean
chpl --fast probeGPU.chpl -L${CHPL_CUDA_PATH}/targets/x86_64-linux/lib/stubs
./probeGPU
cd ../juliaSet
make clean
chpl --fast juliaSetSerial.chpl -L${CHPL_CUDA_PATH}/targets/x86_64-linux/lib/stubs
chpl --fast juliaSetGPU.chpl -L${CHPL_CUDA_PATH}/targets/x86_64-linux/lib/stubs
./juliaSetSerial --n=8000   # 9.36665s
./juliaSetGPU --n=8000      # 0.06692s
cd ../primeFactorization
chpl --fast primesGPU.chpl -L${CHPL_CUDA_PATH}/targets/x86_64-linux/lib/stubs
./primesGPU --n=10_000_000   # 0.039443s; A = 4561 1428578 5000001 4894 49
```

```sh
cd /data/work
scp almalinux.sif razoumov@cedar.computecanada.ca:/project/6003910/razoumov/apptainerImages/chapelGPU202503
scp almalinux.sif razoumov@beluga.computecanada.ca:scratch
```

## Testing on Cedar

```sh
cedar
cd /project/6003910/razoumov/apptainerImages/chapelGPU202503
# salloc --time=0:30:0 --mem-per-cpu=3600 --gpus-per-node=1 --account=def-razoumov-ac
salloc --time=0:30:0 --mem-per-cpu=3600 --gpus-per-node=v100l:1 \
       --account=cc-debug --reservation=asasfu_756
nvidia-smi
module load apptainer
apptainer shell --nv -B $SLURM_TMPDIR almalinux.sif
source /c1/chapel-2.3.0/util/setchplenv.bash
export CHPL_GPU=nvidia
export CHPL_CUDA_PATH=/usr/local/cuda-12.4
export PATH=$PATH:/usr/local/cuda-12.4/bin
cp -r ~/chapelCourse $SLURM_TMPDIR
cd $SLURM_TMPDIR/chapelCourse/gpu
make clean
chpl --fast probeGPU.chpl -L${CHPL_CUDA_PATH}/targets/x86_64-linux/lib/stubs
./probeGPU
cd ../juliaSet
chpl --fast juliaSetSerial.chpl -L${CHPL_CUDA_PATH}/targets/x86_64-linux/lib/stubs
chpl --fast juliaSetGPU.chpl -L${CHPL_CUDA_PATH}/targets/x86_64-linux/lib/stubs
./juliaSetSerial --n=8000   # 12.4182s
./juliaSetGPU --n=8000      # 0.083108s
cd ../primeFactorization
chpl --fast primesGPU.chpl -L${CHPL_CUDA_PATH}/targets/x86_64-linux/lib/stubs
./primesGPU --n=10_000_000   # 0.166764s; A = 4561 1428578 5000001 4894 49
```

## Testing on Beluga

```sh
beluga
cd ~/chapelCourse/codes
salloc --time=0:30:0 --nodes=1 --cpus-per-task=1 --mem-per-cpu=3600 --gpus-per-node=1 --account=cc-debug
nvidia-smi
module load apptainer
export CDIR=~/scratch/chapelGPU20240826
apptainer shell --nv --overlay ${CDIR}/extra.img:ro ${CDIR}/almalinux.sif
source /extra/c1/chapel-2.3.0/util/setchplenv.bash
export CHPL_GPU=nvidia
export CHPL_CUDA_PATH=/usr/local/cuda-12.4
export PATH=$PATH:/usr/local/cuda-12.4/bin
cd ~/tmp/2024/
chpl --fast probeGPU.chpl -L/usr/local/cuda-12.4/targets/x86_64-linux/lib/stubs
./probeGPU
chpl --fast juliaSetGPU.chpl -L/usr/local/cuda-12.4/targets/x86_64-linux/lib/stubs
./juliaSetGPU
./juliaSetGPU --height=8000
```

## Using Grigory's 2-step build, now as a 1-step build

- multi-stage builds https://docs.sylabs.io/guides/latest/user-guide/definition_files.html#multi-stage-builds
- available containers https://catalog.ngc.nvidia.com/orgs/nvidia/containers/nvhpc/tags
- new one is nvcr.io/nvidia/nvhpc:25.1-devel-cuda_multi-ubuntu24.04
- older one nvcr.io/nvidia/nvhpc:23.11-devel-cuda_multi-ubuntu22.04

```sh
cd /data/work
export APPTAINER_TMPDIR=/data/work/tmp
apptainer build --nv test.sif docker://nvcr.io/nvidia/nvhpc:24.3-devel-cuda_multi-ubuntu22.04
sudo apptainer shell --nv test.sif
find / -name nvcc   # check if their CUDA installation includes `nvcc` (needed for GPU Chapel runtime)
```

```sh
cd /data/work
>>> create single.def
```

```txt
BootStrap: docker   # this is `single.def`
From: nvcr.io/nvidia/nvhpc:24.3-devel-cuda_multi-ubuntu22.04
Stage: build
%post
    . /.singularity.d/env/10-docker*.sh
    apt update -y
    apt install -y python3
    mkdir /source && cd /source
    wget https://github.com/chapel-lang/chapel/releases/download/2.3.0/chapel-2.3.0.tar.gz
    tar xvfz chapel-2.3.0.tar.gz
    cd chapel-2.3.0
    . util/setchplenv.sh
    export CHPL_LLVM=bundled
    export CHPL_COMM=none
    export CHPL_TARGET_CPU=none
    export CHPL_LOCALE_MODEL=gpu
    export CHPL_GPU=nvidia
    export CHPL_CUDA_PATH=/opt/nvidia/hpc_sdk/Linux_x86_64/24.3/cuda/12.3
    mkdir -p /c1/chapel-2.3.0
    ./configure --chpl-home=/c1/chapel-2.3.0
    make -j4
    make install
    /bin/rm -r /source
```

```sh
export APPTAINER_TMPDIR=/data/work/tmp
apptainer build --nv ubuntu.sif single.def
```

```sh
cd
sudo apptainer shell --nv /data/work/ubuntu.sif
cd chapelCourse/gpu
source /c1/chapel-2.3.0/util/setchplenv.bash
export CHPL_GPU=nvidia
export CHPL_CUDA_PATH=/opt/nvidia/hpc_sdk/Linux_x86_64/24.3/cuda/12.3
export PATH=$CHPL_CUDA_PATH/bin/:$PATH
make clean
chpl --fast probeGPU.chpl -L${CHPL_CUDA_PATH}/targets/x86_64-linux/lib/stubs
./probeGPU
cd ../juliaSet
make clean
chpl --fast juliaSetSerial.chpl -L${CHPL_CUDA_PATH}/targets/x86_64-linux/lib/stubs
chpl --fast juliaSetGPU.chpl -L${CHPL_CUDA_PATH}/targets/x86_64-linux/lib/stubs
./juliaSetSerial --n=8000   # 9.36665s
./juliaSetGPU --n=8000      # 0.06692s
cd ../primeFactorization
chpl --fast primesGPU.chpl -L${CHPL_CUDA_PATH}/targets/x86_64-linux/lib/stubs
./primesGPU --n=10_000_000   # 0.039443s; A = 4561 1428578 5000001 4894 49
```

```sh
cd /data/work
scp ubuntu.sif razoumov@cedar.computecanada.ca:/project/6003910/razoumov/apptainerImages/chapelGPU202503
scp ubuntu.sif razoumov@beluga.computecanada.ca:scratch
```
