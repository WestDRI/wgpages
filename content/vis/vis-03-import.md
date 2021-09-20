+++
title = "Importing data into ParaView"
slug = "vis-03-import"
weight = 3
+++

## File formats and reading raw binary (7 min)

<!-- 03a-raw.mp4 -->
{{< yt gcqeOSTXUTQ 63 >}}

## VTK file formats

#### Overview and legacy VTK (13 min)

<!-- 03b-vtk.mp4 -->
{{< yt IRuZ4DiiwDs 63 >}}

#### XML VTK (4 min)

<!-- 03c-xml-vtk.mp4 -->
{{< yt 3iiI7VUrgsM 63 >}}

## Scientific file formats (5 min)

<!-- 03d-netcdf-hdf5-openfoam.mp4 -->
{{< yt _kJZRbPQsBE 63 >}}






<!-- This is the only example that might not work for all of you, and in fact, most likely it will fail. There -->
<!-- are a number of reasons. First of all, ParaView 5.8 on a Mac has a bug: it will crash when you try to -->
<!-- read a raw binary. As I mentioned, I don't know if this bug is unique to Mac or exists in other operating -->
<!-- systems as well. -->

<!-- More importantly, a raw binary file is not portable across different computers and platforms. When you -->
<!-- download this file, you unzip it -- all these operations can modify some of the bits, e.g. the end of -->
<!-- line characters making some assumptions about what this characters should be. In other words, some of you -->
<!-- already have a corrupted version of this file. Also, when you read a raw binary in ParaView, you always -->
<!-- have to supply its description: how many variables, their dimensionality, spatial extent, precision, -->
<!-- little vs. biug endian, and so on. It will be extremely tedious to enter all this information, when you -->
<!-- import a file, so the bottom line is that you should never use raw binary files to store data: they are -->
<!-- not portable and they lack metadata. -->

<!-- Instead, you want to use a portable data format that you can write on one computer and read on another, -->
<!-- and do it with different applications and libraries. There are hundreds of such formats, and we will -->
<!-- cover several of them. -->
