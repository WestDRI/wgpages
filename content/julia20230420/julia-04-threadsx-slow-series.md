+++
title = "Multi-threading with ThreadsX"
slug = "julia-04-threadsx-slow-series"
weight = 4
+++

{{<note>}}
Note: the times cited in this chapter were measured on Apple's M1 Pro processor, not on the training cluster.
{{</note>}}

As you saw in the previous section, Base.Threads does not have a built-in parallel reduction. You can implement it
yourself by hand, but all solutions are somewhat awkward, and you can run into problems with thread safety and
performance (slow atomic variables, false sharing, etc) if you don't pay attention.

Enter ThreadsX, a multi-threaded Julia library that provides parallel versions of some of the Base functions. To see the
list of supported functions, use the double-TAB feature inside REPL:

```jl
using ThreadsX
ThreadsX.<TAB>
?ThreadsX.mapreduce
?mapreduce
```

As you see in this example, not all functions in ThreadsX are well-documented, but this is exactly the point: they
reproduce the functionality of their Base serial equivalents, so you can always look up help on a corresponding serial
function.

Consider this Base function:

```jl
mapreduce(x->x^2, +, 1:10)   # sum up squares of all integers from 1 to 10
```

This function allows an alternative syntax:

```jl
mapreduce(+,1:10) do i
    i^2   # plays the role of the function applied to each element
end
```

To parallelize either snippet, replace `mapreduce` with `ThreadsX.mapreduce`, assuming you are running Julia with
multiple threads. Do not time this code, as this computation is very fast, and the timing will mostly likely be
dominated by an overhead from launching and terminating multiple threads. Instead, let's parallelize and time the slow
series.

## Parallelizing the slow series with ThreadsX.mapreduce

In this and other examples we assume that you have already defined `digitsin()`. Save the following as `mapreduce.jl`:

```jl
using BenchmarkTools, ThreadsX
function slow(n::Int64, digits::Int)
    total = ThreadsX.mapreduce(+,1:n) do i
		if !digitsin(digits, i)
			1.0 / i
		else
			0.0
		end
    end
    return total
end
total = @btime slow(Int64(1e9), 9)
println("total = ", total)   # total = 14.241913010384215
```

With 8 CPU cores, I see:

```sh
$ julia mapreduce.jl        # runtime with 1 thread: 5.255 s
$ julia -t 8 mapreduce.jl   # runtime with 8 threads: 900.995 ms
```

> ### <font style="color:blue">Exercise "ThreadsX.1"</font>
> Using the compact (one-line) if-else notation, shorten this code by four lines. Time the new, shorter code
> with one and several threads.

## Parallelizing the slow series with ThreadsX.sum

```jl
?sum
?Threads.sum
```

The expression in the round brackets below is a generator. It generates a sequence on the fly without storing
individual elements, thus taking very little memory.

```jl
(i for i in 1:10)
collect(i for i in 1:10)   # construct a vector (this one takes more space)
[i for i in 1:10]          # functionally the same (vector)
```

Let's use a generator with $10^9$ elements to compute our slow series sum:

```jl
using BenchmarkTools
@btime sum(!digitsin(9, i) ? 1.0/i : 0 for i in 1:1_000_000_000)
   # serial code: 5.061 s, prints 14.2419130103833
```

It is very easy to parallelize:

```jl
using BenchmarkTools, ThreadsX
@btime ThreadsX.sum(!digitsin(9, i) ? 1.0/i : 0 for i in 1:1_000_000_000)
   # with 8 threads: 906.420 ms, prints 14.241913010381973
```

> ### <font style="color:blue">Exercise "ThreadsX.2"</font>
> The expression `[i for i in 1:10 if i%2==1]` produces an array of odd integers between 1 and 10. Using this
> syntax, remove zero terms from the last generator, i.e. write a parallel code for summing the slow series
> with a generator that contains only non-zero terms. It should run slightly faster than the code with the
> original generator.

<!-- ```jl -->
<!-- @btime ThreadsX.sum(1.0/i for i in 1:1_000_000_000 if !digitsin(9, i)) -->
<!-- ``` -->

Finally, let's rewrite our code applying a function to all integers in a range:

```jl
function numericTerm(i)
    !digitsin(9, i) ? 1.0/i : 0
end
@btime ThreadsX.sum(numericTerm, 1:Int64(1e9))            # 890.466 ms, same result
```

> ### <font style="color:blue">Exercise "ThreadsX.3"</font>
> Rewrite the last code replacing `sum` with `mapreduce`. **Hint**: look up help for `mapreduce()`.

<!-- ```jl -->
<!-- @btime ThreadsX.mapreduce(numericTerm, +, 1:Int64(1e9))   # 912.552 ms, same result -->
<!-- ``` -->

## Other parallel functions

ThreadsX provides various parallel functions for sorting. Sorting is intrinsically hard to parallelize, so do not expect
100% parallel efficiency. Let's take a look at `sort!()`:

```jl
n = Int64(1e8)
r = rand(Float32, (n));
r[1:10]      # first 20 elements, same as first(r,10)
last(r,10)   # last 10 elements

?sort              # underneath uses QuickSort (for numeric arrays) or MergeSort
@btime sort!(r);   # 1.391 s, serial sorting

r = rand(Float32, (n));
@btime ThreadsX.sort!(r);   # 586.541 ms, parallel sorting with 8 threads
?ThreadsX.sort!             # there is actually a good manual page

# similar speedup for integers
r = rand(Int32, (n));
@btime sort!(r);   # 889.817 ms

r = rand(Int32, (n));
@btime ThreadsX.sort!(r);   # 390.082 ms with 8 threads
```

Searching for extrema is much more parallel-friendly:

```jl
n = Int64(1e9)
r = rand(Int32, (n));        # make sure we have enough memory
@btime maximum(r)            # 288.200 ms
@btime ThreadsX.maximum(r)   # 31.879 ms with 8 threads
```

Finally, another useful function is `ThreadsX.map()` without reduction -- we will take a closer look at it in one of the
following sections.

To sum up this section, ThreadsX.jl provides a super easy way to parallelize some of the Base library functions. It
includes multi-threaded reduction and shows very impressive parallel performance. To list the supported functions, use
`ThreadsX.<TAB>`, and don't forget to use the built-in help pages.
