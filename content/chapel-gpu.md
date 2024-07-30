+++
title = "GPU computing with Chapel"
slug = "chapelgpu"
katex = true
+++

<!-- {{<cor>}}June 7<sup>th</sup>{{</cor>}}\ -->
<!-- {{<cgr>}}9:30am–12:30pm (Part 1) and 1:30pm-4:30pm (Part 2) Pacific Time{{</cgr>}} -->

Useful built-in variables
GPUs = sublocales
can cycles through locales, then through GPUs
Idea: run a code block on device, parallel lines inside will launch kernels
same code can run on CPU and GPU
jacobi.chpl: benchmarking the same function, counting kernel launches
@assertOnGpu to verify if a block can run on a GPU
Copying data to/from GPUs
timing on the CPU
timing on the GPU
