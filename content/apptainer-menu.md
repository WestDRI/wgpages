+++
title = "Introduction to Apptainer (Singularity) containers"
slug = "apptainer"
aliases = ["containers"]
+++

{{<cor>}}Thursday, January 25{{</cor>}}\
{{<cgr>}}10am–noon Pacific Time{{</cgr>}}

**Instructor**: Alex Razoumov (SFU)

**Target audience**: general

**Level**: beginner

**Prerequisites**: none
<!-- [Introduction to Compute Canada cloud](../cloud_cloud) course -->

This course is a hands-on introduction to working with Singularity/Apptainer containers in an HPC
environment. Apptainer/Singularity is a great tool to create custom Linux environments and run off-the-shelf
Docker containers on an HPC cluster. We will look at creating new container images, modifying existing images
and installing software into them, and -- if time permits -- running parallel codes inside a container.

<!-- We will be running Docker inside virtual machines (VMs) in Compute Canada cloud, so you must be familiar -->
<!-- with setting up a blank Ubuntu server in a cloud VM before attending this course. -->

**Software**: All attendees will need a remote secure shell (SSH) client installed on their computer in
order to participate in the course exercises. On Windows we recommend
[the free Home Edition of MobaXterm](https://mobaxterm.mobatek.net/download.html). On Mac and Linux
computers SSH is usually pre-installed (try typing `ssh` in a terminal to make sure it is there).

<!-- {{< toc >}} -->

{{<cor>}}Zoom{{</cor>}} {{<s>}} {{<cgr>}}10:00am-12:00pm Pacific{{</cgr>}} \
{{<linktitle url="../apptainer1/01-intro" text="What is Singularity / Apptainer">}} \
{{<linktitle url="../apptainer1/02-build" text="Creating container images">}} \
{{<linktitle url="../apptainer1/03-run" text="More on running containers">}} \
{{<linktitle url="../apptainer1/04-advanced" text="Advanced Singularity usage">}}

## Links

- Official {{<a "http://apptainer.org" "Apptainer website">}}
- Official {{<a "https://singularity-tutorial.github.io" "Singularity tutorial">}}
- Official {{<a "https://docs.sylabs.io/guides/3.7/user-guide/index.html" "Singularity user guide">}}
- Compute Canada / the Alliance's {{<a "https://docs.alliancecan.ca/wiki/Singularity" "Singularity wiki page">}}
- Recent webinars:
  - {{<a "https://training.westdri.ca/tools/virtual#manyFilesInOverlays" "Hiding large numbers of files in container overlays">}} by Alex Razoumov (SFU) recorded on January 17th, 2023
  - {{<a "https://www.youtube.com/watch?v=bpmrfVqBowY" "Apptainer">}} by Paul Preney (SHARCNET) recorded on
    April 6th, 2022: many best practices and a couple of complete workflows on our clusters using
    `/localscratch`, setting `$APPTAINER_CACHEDIR` and `$APPTAINER_TMPDIR` for best performance, using
    overlays for storing millions of small files
  - {{<a "https://bit.ly/3z3emYw" "Container-based approach to bioinformatics applications">}} by Tannistha
    Nandi (UofCalgary) recorded on October 13th, 2021
- Some great tutorials:
  - {{<a "https://pawseysc.github.io/sc19-containers" "Containers in HPC">}} from Pawsey Centre
  - {{<a "https://webapps.lehigh.edu/hpc/training/devtools/byos-containers.html" "Containers on HPC Resources">}} from Lehigh University
  - {{<a "https://github.com/ArangoGutierrez/Singularity-tutorial" "Creating and running software containers with Singularity">}}
	by Eduardo Arango-Gutierrez
  - {{<a "https://github.com/fasrc/User_Codes/tree/master/Singularity_Containers/MPI_Apps" "Singularity & MPI Applications">}}
	from Harvard University
  - {{<a "https://carpentries-incubator.github.io/singularity-introduction" "Carpentries incubator tutorial">}}
    -- some material here was borrowed from this tutorial
