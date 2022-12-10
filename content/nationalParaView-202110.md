+++
title = "National ParaView Workshop"
slug = "nationalparaview"
+++

{{<cor>}}October 4-5, 2021{{</cor>}}\
{{<cgr>}}Both days 10 am–1 pm Pacific{{</cgr>}} /
{{<cgr>}}1pm–4 pm Eastern Time{{</cgr>}} /
{{<cgr>}}2pm–5 pm Atlantic{{</cgr>}}

ParaView is an open source, multi-platform data analysis and visualization tool designed to run on a variety of hardware
from an individual laptop to large supercomputers. With ParaView users can interactively visualize 2D and 3D datasets
defined on structured, adaptive and unstructured meshes or particles, animate these datasets in time, and manipulate
them with a variety of filters. ParaView supports both interactive (GUI) and scripted (including offscreen)
visualization, and is an easy and fun tool to learn.

The first session of this workshop will cover some intermediate and advanced topics in 3D scientific visualization with
ParaView including (1) **scripting**, (2) **animation**, and (3) **remote and distributed visualization**. In the second
session participants will apply their newly gained knowledge of making animations on different datasets including one
from a CFD simulation of a tidal turbine. Both sessions will be presented in English, with a French version to follow in
November.

- Oct-04 (Day 1) - formal introduction to animation, scripting, and remote visualization
- Oct-05 (Day 2) - animating a turbine dataset (keyframe, camera movement, time evolution)
- **Instructors**: Alex Razoumov, Farhad Baratchi
- **Helpers**: Jarno van der Kolk, Julie Faure-Lacroix, Marie-Hélène Burle, Tyson Whitehead

## Prerequisites

Please install ParaView 5.9.1 from https://www.paraview.org/download on your computer before the workshop.

We expect participants to be somewhat familiar with the basics of ParaView: loading local datasets, interacting with
their visualizations via the GUI, applying filters, and constructing basic visualization pipelines. We ask participants
with no prior experience in ParaView to watch the following videos before attending the workshop:

- [Running ParaView (11 min)](https://youtu.be/FloAMW6niRM)
- [File formats and reading raw binary (7 min)](https://youtu.be/gcqeOSTXUTQ)
- [VTK file formats: overview and legacy VTK (13 min)](https://youtu.be/IRuZ4DiiwDs)
- [VTK file formats: XML VTK (4 min)](https://youtu.be/3iiI7VUrgsM)
- [Scientific file formats (5 min)](https://youtu.be/_kJZRbPQsBE)
- [ParaView filters (11 min)](https://youtu.be/u7ui0Y4ysoE)
- [Store your visualization workflow with a state file (2 min)](https://youtu.be/r7cv1lX0Z4M)
- [Side-by-side visualization (3 min)](https://youtu.be/YZHSufVi0aA)
- [Visualizing vectors (6 min)](https://youtu.be/QFlKiCOFHYc)
- [Creating better streamlines (3 min)](https://youtu.be/C3WS2GajvBg)
- [Line integral convolution (LIC) (3 min)](https://youtu.be/MqqduE3EnS8)
- [Reading CSV data (6 min)](https://youtu.be/1yrGH7w0rG4)
- [Putting your visualization online with ParaView Glance (5 min)](https://youtu.be/TWL2CMKSRaU)

#### Quick knowledge test -- before studying the workshop materials

Start ParaView on your computer, load the dataset `data/disk_out_ref.ex2` and try to visualize temperature with a Clip
and the velocity field with Stream Tracer With Custom Source and Glyph as shown in this image below:

{{< figure src="/img/testImage.png" >}}

## Workshop materials

The slides for Day 1 of this workshop (`slides2.pdf`) are included into the [main ZIP file](https://bit.ly/paraviewzipp)
(~23 MB), along with sample datasets and various scripts. In case of problems, check this [temporary
mirror](https://transfer.sh/I7NwUJ/paraview.zip).

Here are [the slides](../slides/HPC_and_Making_Scientific_Animations_in_ParaView.pdf) for Day 2.

For remote visualization, if you already have a CC account, you can use it today, and we have also prepared guest
accounts on Cedar - please pick an account and add your name to the line in the Goodle Doc (shared in Zoom chat) so that
no one else uses it. If you already have a CC account, please add your username to the same Google Doc so that we could
add you to the reservation.

We have two reservations on Cedar until 2021-10-05T23:59:00 (Pacific):

- 10-node CPU reservation `--account=def-training-wa_cpu --reservation=paraview-wr_cpu`
- 2-node GPU reservation `--account=def-training-wa_gpu --reservation=paraview-wr_gpu`

## Steps for partitioning the unstructured dataset for Tuesday

1. Load all `m114f105_AL_2d_tsr_5_*.vtu` files located in `/project/6052247/fbaratchi/paraview_training/unstructured`
   folder on Cedar
1. Apply Cell Data to Point Data.
1. Apply D3 filter.
1. Save data as `A_NAME.PVTU` "decomposed", write all timesteps as series, use fast compression.

NOTE: Resulting partitioned data are located in `/project/6052247/fbaratchi/paraview_training/partitioned` on Cedar.
