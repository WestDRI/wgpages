+++
title = "SFU training / user support team"
slug = "sfu"
katex = true
+++

This page lists some topics that we would like to discuss at DRI Connect but could not fit into the program.

## Lossy compression of 3D scalar fields

Recently we started looking into lossy compression of 3D scalar fields (watch our [webinar on this
topic](https://training.westdri.ca/tools/rdm/#lossy)). In a nutshell, with lossy compression you can reliably
compress typical 3D scalar fields by ~20-30X without any visible degradation, and in many practical cases by
100-200X.

<!-- This is huge for long-term storage of research data: what would previously requite 1 -->
<!-- Petabyte of storage (an impossibly large allocation with us), can now easily fit on a portable SSD. In some -->
<!-- cases we can achieve 1000X compression, when removing components that are not needed for analysis or -->
<!-- visualization. This is really a big deal and has been completely unexplored by anyone in the Federation until -->
<!-- now. -->

{{< figure src="/img/99X.png" caption="Original deep asteroid impact dataset (left) and its TTK-compressed version (right), both at 500^3 in double precision. Note the ~100X compression." >}}

- two ready-to-use methods ([ZFP](https://computing.llnl.gov/projects/zfp) and [topological
  compression](https://topology-tool-kit.github.io/examples/persistenceDrivenCompression))
- **zfp**: bindings for C, C++, Fortran, Python, Julia, built into 63+ projects (including HDF5), very fast (2GB/s
  per CPU core, can run on GPUs), use in one of three ways (number of bits per floating number, number of bit
  planes, max point-wise tolerance) in each case specifying one parameter
- **topological compression**: essentially one implementation (provided by
  [TTK](https://topology-tool-kit.github.io)), can use via ParaView's GUI or *pvpython*, or via C++/VTK; much
  slower (~30s both to compress and decompress in the example above) but more control (two parameters) and
  nicer looking artifacts
- both methods are comparable in terms of quality vs. file size, and you can combine both as they act on
  different bits
- could work very well for long-term storage of 3D research data: what would previously requite 1PB (an
  impossibly large allocation with us), can now fit on a portable drive
- in some cases we can achieve 1000X compression, when removing components that are not needed for analysis or
  visualization
- compression works not on files but on 1D/2D/3D arrays discretized on Cartesian meshes
- topological compression should be able to compress AMR (multi-resolution) data in one go, as it does not
  rely on spatial wavelengths, although this would require some effort
- cannot use these as a black box: need to understand the trade-off and write a custom implementation for each
  particular case





## National visualization team

Did you know that the Visualization National Team has a [website for users](https://ccvis.netlify.app)?  We
use it regularly to show users the types of visualizations one could create from their datasets.

{{< figure src="/img/ccvisGallery.png" caption="Several visualization examples from the website gallery." >}}

If you want to add your own rendering to the gallery, or have any comments, please get in touch with Alex at
*alex dot razoumov at westdri dot ca*.





## RDM in HPC training

We've been providing training on RDM-in-HPC tools for ~10 years. You can find dozens of recorded webinars on
these two pages:

- [Data management tools](https://training.westdri.ca/tools/rdm) - data compression, version control for large
  files, hierarchical datasets with pytables, SQL databases, backing up, xarray, managing many files, DAR, and
  many others
- [Visualization resources](https://training.westdri.ca/tools/visualization) - working with large datasets,
  in-situ processing, remote and distributed rendering, Cinema science, topological data analysis, web-based
  vis, programmable filters, and many others

Each webinar tries to dive into a new, advanced topic that is typically not addressed in our existing
documentation or training courses.





<!-- ## Lack of consortium branding in the West -->
## Webinar and course programs

Following the demise of WestGrid in April 2022, the SFU training team (Marie and Alex, both formerly of
WestGrid) took on the task of running a course program and a webinar program for Western Canadian researchers
from BC to Manitoba that were formerly trained by WestGrid. In practice this means that 2 people develop and
deliver ~100 training events each year. For webinars we have 1-2 guests each semester, but the majority of
webinars are developed and delivered by Marie and Alex.

<!-- One of the major limiting factors (besides the obvious preparation time) is the lack of regional consortium -->
<!-- branding in the West. We tried to use "WestDRI" but received very negative response from a couple of -->
<!-- institutions. The problem: why would researchers subscribe to and attend "training by SFU" if they are from -->
<!-- other institutions? Lack of branding makes it very difficult to advertise and communicate our training. -->

<!-- The second problem is analysts' participation. In WestGrid days, we've been lucky to host many webinars by -->
<!-- ARC/HPC analysts in the past, but -- without an umbrella consortium or any inter-university agreements -- we -->
<!-- cannot "volunteer" webinar speakers. -->

We are looking for long-term collaborators on the webinar program, both for improved branding (recall: no
WestGrid) and communication to researchers, additional expertise, and to share the workload.





## Teaching parallel programming

Over the past 10 years we switched from teaching MPI and OpenMP (which are still discussed in our Intro to HPC
course) to teaching parallel programming using higher-level frameworks in Julia, Chapel, Python, and R. In
each case/language the objective is different, but in general we walk students through typical pitfalls and
bottlenecks they would encounter both with multi-threading and multi-processing.



## Teaching machine learning

Describe all approaches.





## Previous/future work on Visualize This and Seeing Big

We ran the national *"Visualize This!"* contests in 2016, 2017, 2018, 2019, 2021 (this year internationally
with IEEE Vis), and 2023. In each competition we provided a dataset (or two) and asked participants to come
with their best visualizations that would answer some specific questions. The number of submissions varied
from 0 to 10 per contest, and we were really blown away by the quality of some of the submissions.

<!-- You can find the details and links to individual years [here](https://ccvis.netlify.app/contests). -->

- {{<a "https://scivis2021.netlify.app/2016" "2016:">}} Visualizing multiple variables in a global ocean model
- {{<a "https://scivis2021.netlify.app/2017" "2017:">}} Airflow around counter-rotating wind turbines
- {{<a "https://scivis2021.netlify.app/2018" "2018:">}} Interaction of a large protein structure with a cell's
  membrane <ins>and</ins> Linked humanities data
- {{<a "https://scivis2021.netlify.app/2019" "2019:">}} Incompressible transitional air flow over a wind turbine
  section <ins>or</ins> bring your own data
- {{<a "https://scivis2021.netlify.app" "2020-2021:">}} Earth's Mantle Convection
- {{<a "https://visualizethis.netlify.app" "2023:">}} Halloween storm over Eastern Canada and the Normalized
  difference vegetation index

{{< figure src="/img/ieee2021.png" caption="In 2020-2021 we partnered with IEEE to host the international SciVis Contest." >}}

These contests have three goals:

1. promote and teach visualization tools and techniques to researchers,
1. advertise our services and support, and
1. (most exciting for us) crowdsource novel visualization ideas: we know the tools, but using them effectively
   could be an art in itself.

We ran the *"Seeing Big showcase"* at HPCS in 2015 (48m video), 2016 (25m video), and 2017 (12m video). Few
weeks prior to each event, we asked researchers across the country to contribute their scientific
visualizations, either high-resolution images or videos that would showcase their work to a wider
audience. From these visualizations we assembled 4K videos that were shown in a loop on a big screen in the
conference lobby for the entire duration of the conference.

We would love to discuss how we could make these two outreach programs work better in the future, and ways to
collaborate on them.






<!-- Tessa: "Yes, that's a little tricky being able to communicate at DRI Connect - other than I'd say putting -->
<!-- something in the Slack channel right at the beginning and inviting people to talk to. Unfortunately the -->
<!-- program is full - and we did have to reject some sessions to fit the schedule in 2 days so we can't really -->
<!-- rework it now." -->



<!-- {{<a "link" "text">}} -->
