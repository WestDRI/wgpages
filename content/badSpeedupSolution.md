+++
title = "Fixing poor parallel scaling in the Julia set"
slug = "bad-speedup-solution"
+++

False sharing has no effect in this problem, as for most part individual threads are writing into array elements that
are well separated in memory.

The row-major vs. column-major order does not matter in the Julia set problem, as it is dominated by computation of
individual pixels: computing a single pixel on average takes much longer than writing to a random array element. The
timings are virtually identical for row-major vs. column-major, whether in serial or in parallel with @threads. If you
were to fill in these elements without computing, then the order would matter, e.g. consider this code:

```jl
using BenchmarkTools
function testOrder(n::Int, order::Bool)
    stability = zeros(Int32, n, n)
    for i in 1:n
        for j in 1:n
            order ? stability[i,j] = i+j : stability[j,i] = i+j
        end
    end
    return stability
end
@btime testOrder(30_000, true);    # 2.753 s
@btime testOrder(30_000, false);   # 721.484 ms
@btime testOrder(1000, true);    # 714.958 μs
@btime testOrder(1000, false);   # 681.333 μs
```

The real culprit in the Julia set's bad parallel scaling is the problem's less-than-perfect load balancing. We know that
@threads subdivides the large outer loop equally between the threads. However, some threads have fewer iterations to
compute and finish faster, but they have to wait for the threads with more iterations in their pixels. If you modify the
code in such a way that all pixels do the same large number of iterations, you will see perfect linear speedup with
multi-threading.

With the unbalanced load, it is possible to improve performance somewhat with dynamic scheduling using either channels
(not covered in our workshop) or Threads.@spawn but it'll make the code a little bit more complex.

The following asynchronous solution written by Jeremiah O'Neil (University of Ottawa)

```jl
function juliaSet(height, width)
    stability = zeros(Int32, height, width)
    c = Channel{Int64}(nthreads()) do chnl
        for i in 1:height
            put!(chnl, i)
        end
    end
    Threads.foreach(c) do i
        for j in 1:width
            point = (2*(j-0.5)/width-1) + (2*(i-0.5)/height-1)im
            stability[i,j] = pixel(point)
        end
    end
    return stability
end
```

shows better (but still less than linear) speedup.
