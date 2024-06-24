+++
title = "Building instructions for a WRF container"
slug = "wrf-container"
+++

These instructions describe building an Apptainer image for WRF following the build script from
https://github.com/Hos128/WRF-CMAQ-Installation. 

First, log in to the cluster, create a new temporary directory and from inside it start an interactive job:

```sh
mkdir -p tmp && cd tmp
module load apptainer/1.2.4
salloc --time=3:0:0 --mem-per-cpu=3600 --cpus-per-task=4 --account=def-...
```

Download the latest Ubuntu image and build an Apptainer sandbox from it:

```
apptainer build --sandbox wrf.dir docker://ubuntu
```

Next, enter the sandbox with `--fakeroot`:

```sh
unset APPTAINER_BIND
apptainer shell -e --fakeroot --writable wrf.dir
```

Inside, create the top-level installation directory and install some packages:

```sh
mkdir -p /data && cd /data
apt-get update
apt-get -y install git make wget unzip emacs apt-utils   # answer few questions along the way
```

Download and fix the installation script:

```sh
git clone https://github.com/Hos128/WRF-CMAQ-Installation.git
cd WRF-CMAQ-Installation
sed -i.bak -e '200,214d' OfflineWRFCMAQ.sh
sed -i.bak -e 's|export HOME=`cd;pwd`|export HOME=`cd /data;pwd`|' OfflineWRFCMAQ.sh
sed -i.bak -e 's|echo $PASSWD \| sudo -S ||' OfflineWRFCMAQ.sh
sed -i.bak -e 's| python2 python2-dev||' OfflineWRFCMAQ.sh
sed -i.bak -e 's| libncurses5||' OfflineWRFCMAQ.sh
sed -i.bak -e 's| mlocate||' OfflineWRFCMAQ.sh
sed -i.bak -e 's|apt -y install python3 python3-dev|apt -y install python3 python3-dev python3-pip|' OfflineWRFCMAQ.sh
mkdir -p /root/.config/pip
cat << EOF > /root/.config/pip/pip.conf
[global]
trusted-host = pypi.org
               pypi.python.org
               pypi.org
               pypi.co
               files.pythonhosted.org
               pip.pypa.io
EOF
sed -i.bak -e 's|pip3 install python-dateutil|pip3 install --break-system-packages python-dateutil|' OfflineWRFCMAQ.sh
wget --header="Host: drive.usercontent.google.com" --header="User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36" --header="Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7" --header="Accept-Language: en-US,en;q=0.9,fa;q=0.8" --header="Connection: keep-alive" "https://drive.usercontent.google.com/download?id=1NkmRAeG7w_LLhh_HDW_X39jZwGYw8mml&export=download&authuser=2&confirm=t&uuid=a4f92a10-cbd5-4064-bb83-d79567b60537&at=APZUnTWngzWjzHFwWurVdIQsFaAL:1711680004113" -c -O 'Downloads.zip'
unzip Downloads.zip
/bin/rm -rf Downloads.zip /data/WRF
sed -i.bak '/Downloads.zip/d' OfflineWRFCMAQ.sh
sed -i.bak -e 's|mkdir $HOME/WRF|mkdir -p $HOME/WRF|' OfflineWRFCMAQ.sh
sed -i.bak -e 's|mkdir $WRF_FOLDER/MET|mkdir -p $WRF_FOLDER/MET|' OfflineWRFCMAQ.sh
awk '/Missing one or more/{for(x=NR-1;x<=NR+2;x++)d[x];}{a[NR]=$0}END{for(i=1;i<=NR;i++)if(!(i in d))print a[i]}' OfflineWRFCMAQ.sh > new.sh && mv new.sh OfflineWRFCMAQ.sh
chmod u+x OfflineWRFCMAQ.sh
```

Finally, run it (this will take a very, very long time, as it downloads and builds 47GB of software -
everything but the kitchen sink):

```sh
./OfflineWRFCMAQ.sh 2>&1 | tee OfflineWRFCMAQ.log
   Do you want to continue? - yes
   Would you like to download the WPS Geographical Input Data for Specific Applications? - no
   Would you like to download the GEOG Optional WPS Geographical Input Data? - no
/bin/rm -rf Downloads
```

One of the downloads is MPICH. Inside the script, we are installing it entirely inside the container, not
relying on the host's OpenMPI. This means that we'll be limited to MPI runs on one node.

Now exit the container and the job.

Next, start a batch job to convert the sandbox into a SIF image:

```sh
cd scratch
tar xvf wrf.tar
cat << EOF > submit.sh
#!/bin/bash
#SBATCH --time=10:0:0
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=3600
#SBATCH --account=def-...
mkdir -p \$SLURM_TMPDIR/{tmp,cache}
module load apptainer/1.2.4
export APPTAINER_TMPDIR=\$SLURM_TMPDIR/tmp
export APPTAINER_CACHEDIR=\$SLURM_TMPDIR/cache
apptainer build wrf.sif wrf.dir
EOF
sbatch submit.sh
```

The resulting image `wrf.sif` should be 8.1GB. To use it interactively from a job, do this:

```sh
cd ~/scratch
module load apptainer/1.2.4
salloc --time=1:0:0 --mem-per-cpu=3600 --account=def-...
apptainer shell wrf.sif
```
