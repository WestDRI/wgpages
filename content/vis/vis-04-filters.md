+++
title = "Working with ParaView filters"
slug = "vis-04-filters"
weight = 4
+++

## ParaView filters (11 min)

<!-- 04a-filters1.mp4 -->
{{< yt u7ui0Y4ysoE 63 >}}

## Store your visualization workflow with a state file (2 min)

<!-- 04b-state-file.mp4 -->
{{< yt r7cv1lX0Z4M 63 >}}

## Side-by-side visualization (3 min)

<!-- 04c-side-by-side.mp4 -->
{{< yt YZHSufVi0aA 63 >}}

## Visualizing vectors (6 min)

<!-- 04d-vectors.mp4 -->
{{< yt QFlKiCOFHYc 63 >}}

#### Creating better streamlines (3 min)

<!-- 04e-better-streamlines.mp4 -->
{{< yt C3WS2GajvBg 63 >}}

#### Line integral convolution (LIC) (3 min)

<!-- 04f-lic.mp4 -->
{{< yt MqqduE3EnS8 63 >}}

## Reading CSV data (6 min)

<!-- 04g-csv.mp4 -->
{{< yt 1yrGH7w0rG4 63 >}}

## Word of caution

Many visualization filters, e.g. Clip and Slice, transform stuctured grid data into unstructured
data. Since unstructured data can take several times as much memory, it is a good idea to monitor the
memory footprint of your visualization workflow. If your current memory usage is already close to the
physical memory of your computer (or the memory allocation of the cluster job running your `pvserver`),
applying such a filter will either force your computer to swap making everything very slow, or your job
on the cluster will get killed hence terminating your `pvserver`.

In ParaView it is easy to monitor your memory usage via View | Memory Inspector.

If you are running out of memory with a remote, distributed visualization (we will study this later), the
best option is to ask for more CPU cores with a fixed `--mem-per-cpu`. Not only will this give you more
total memory, it will also speed up your rendering and data reading, assuming that your file format
supports parallel I/O.
