+++
title = "Setup"
slug = "julia-00-setup"
weight = 0
+++

### Linux for Windows Users

For Windows users, it is a huge advantage of having Windows Subsystem for Linux (WSL), provided by Microsoft. With a WSL running a flavour of Linux, one can access a full version of Linux on Windows.

Installing Linux with WSL is pretty straightforward. The following is a link to a complete instruction on how to enable WSL on Windows 10

&emsp;[https://docs.microsoft.com/en-us/windows/wsl/install-win10](https://docs.microsoft.com/en-us/windows/wsl/install-win10)

Or, one may just follow this 2 minute video on how to enable Windows Subsystem for Linux

&emsp;[https://www.youtube.com/watch?v=Ew_pYKGB810&t=21s](https://www.youtube.com/watch?v=Ew_pYKGB810&t=21s)

The following are the steps to enable WSL and install Linux on Windows 10.

In the Windows task bar __Type here to search__ box, type PowerShell to bring a Windows PowerShell

{{< figure src="/img//powershell.png" width=600px >}}

At the prompt. type the following command (one line)

```bash
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

Then restart the computer.

OR, in Windows search bar at the lower left corner, type keywords “Windows features”. When the __“Turn Windows features on or off”__ dialogue windows pops up, check the box for __Windows Subsystems for Linux__

{{< figure src="/img/win_features.png" width=500px >}}

Click OK, it will install changes and updates and ask you to reboot the computer.
After the reboot, the WSL is enabled. In Windows search bar, type “Microsoft store”. Search for Linux

{{< figure src="/img/ms_app_store.png" >}}

Select a Linux flavour, in the example below we choose Debian

{{< figure src="/img/ms_app_store_linux.png" >}}

And then click install to install Debian.

After it is installed, select launch. You may find it afterwards by searching Debian in Windows search bar. You may also want to make a shortcut on your Desktop or the task bar at bottom.

Now Debian will appear on your Desktop as a terminal as follows. Note the username will be your username for Windows.

{{< figure src="/img/wsl_term.png" width=600px >}}

Note, if you follow the link on Microsoft site, DO NOT proceed with “Update to WSL 2” if you are not an advanced Windows user developer. This will require you to install Windows updates and jump to the latest development build. It may take forever to finish.

### Accessing Windows File Systems from WSL

The Linux you just installed is “caged” inside Windows. In the newly installed Debian Linux terminal, if you type command ls to list files and folders, you will find nothing. You don’t have access to your files on Windows yet.

Before you proceed, make sure you have a user account for your Windows. If you don't have a user account but administrator account on Windows, it is strongly recommended that you create one. Do not use the Administrator account.

To access the Windows file systems, run the following commands

```bash
cd
sudo ln -s /mnt/c/Users/you/Documents/ Documents
sudo ln -s /mnt/c/Users/you/Downloads/ Downloads
```

replacing _you_ above with your user name for Windows’s account. 

Now you have the shortcuts Documents and Downloads created inside your Debina Linux, you can now access your Windows files.

### Installing Julia on Linux

The official Julia site strongly recommends that the official generic binaries from the downloads page be used to install Julia on Linux

&emsp;[https://julialang.org/downloads/](https://julialang.org/downloads/)

Select the build for your system, right click the link to copy the URL, e.g.

&emsp;[https://julialang-s3.julialang.org/bin/musl/x64/1.5/julia-1.5.4-musl-x86_64.tar.gz](https://julialang-s3.julialang.org/bin/musl/x64/1.5/julia-1.5.4-musl-x86_64.tar.gz)

To install the pre-built binary, proceed with the following

```bash
sudo apt update
sudo apt install wget
wget https://julialang-s3.julialang.org/bin/musl/x64/1.5/julia-1.5.4-musl-x86_64.tar.gz
sudo tar -xvf julia-1.5.0-musl-x86_64.tar.gz -C /opt
sudo ln -s /optjulia-1.5.0-musl-x86_64.tar.gz /usr/local/bin/julia
```

Note <tt>/opt</tt> should exist for most Linux distros. If not, do <tt>sudo mkdir /opt</tt> to create one.

Now you should be able to run Julia by typing <tt>julia</tt> inside a terminal.

### Advanced Installation of Packages and Julia on Linux

If you are an advanced Linux user and you want to use the Linux package manager to do a systematic installation, you can pursue the following.

On a Linux base system, before installing Julia, make sure the following are installed:

* GCC compiler (gcc and gfortran).

* OpenBLAS library, an optimized linear algebra library.

* OpenMPI library, an implementation of message passing interface (MPI) library for distributed and parallel computing.

The following refers to the commands pertaining to Ubuntu/Debian only. At the command line, do an update

```bash
sudo apt update
```

You may use the follow commands to find the packages and versions, e.g.

```
sudo apt list | grep -i gcc*
```

Then install the latest GCC, e.g. version 9 and libraries. 

```
sudo apt install gcc-9*
sudo apt install gfortran-9*
sudo apt install libopenmpi
sudo apt install libopenblas

sudo apt install julia
```

Now Julia should be ready to go. You may just type julia at the command line, you will get into the julia environment (called REPL).

### Using Julia on Mac OS X

For those using Mac OS X, if you can’t find julia installed, you might need to do the following to install or update Julia on MacOS

* Goto https://julialang.org/downloads/, double click 64-bit to download julia-1.5.0-mac64.dmg. Once download completes double click it. Drag Julia-1.5 icon into Applications folder, then execute the following commands

```bash
sudo rm -f /usr/local/bin/julia
sudo ln -s /Applications/Julia-1.5.app/Contents/Resources/julia/bin/julia /usr/local/bin/julia
julia -v

julia version 1.5.0
```

### Using Julia on Clusters

Julia is among hundreds of software packages installed on the systems. To use Julia, load the following modules first

```bash
module load gcc/9.3.0
module load julia/1.7.0
```

You may now type julia at the command line and enter the REPL environment.

