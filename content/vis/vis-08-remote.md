+++
title = "Remote and distributed visualization"
slug = "vis-08-remote"
weight = 8
+++

## Intro to remote visualization (11 min)

This video covers various remote visualization techniques, discusses CPU vs. GPU rendering on HPC clusters, and
addresses the question of how many CPU cores you need to process and render your dataset(s).

<!-- 08a-basics.mp4 -->
{{< yt y1BoQIelm7Q 63 >}}

## Small remote visualization (10 min)

**Update**: On Compute Canada clusters load the offscreen CPU-rendering ParaView 5.8.0 module with
```
$ module load gcc/9.3.0 paraview-offscreen/5.8.0
```
and on your laptop use ParaView 5.8.x.

<!-- 08b-deep-impact.mp4 -->
{{< yt X4hItHL5JDA 63 >}}

## Large remote visualization (11 min)

**Update**: On Compute Canada clusters load the offscreen CPU-rendering ParaView 5.8.0 module with
```
$ module load gcc/9.3.0 paraview-offscreen/5.8.0
```
and on your laptop use ParaView 5.8.x.

<!-- 08c-airfoil.mp4 -->
{{< yt -o-r4SS93uU 63 >}}

## Using cluster GPUs for rendering (5 min)

**Update**: On Compute Canada clusters load the offscreen GPU-rendering ParaView 5.8.0 module with
```
$ module load gcc/9.3.0 paraview-offscreen-gpu/5.8.0
```

We have a workaround for the GPU driver bug mentioned in the video -- please check slide 48 in part 2.

<!-- 08d-gpu.mp4 -->
{{< yt FjRhoRhnao4 63 >}}
