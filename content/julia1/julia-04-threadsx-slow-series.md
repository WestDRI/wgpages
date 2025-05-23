+++
title = "Multi-threading with ThreadsX"
slug = "../summer/julia-04-threadsx-slow-series"
weight = 4
+++

<!-- {{<note>}} -->
<!-- Note: the times cited in this chapter were measured on Apple's M1 Pro processor, not on the training cluster. -->
<!-- {{</note>}} -->

As you saw in the previous section, Base.Threads does not have a built-in parallel reduction. You can implement it
yourself by hand, but all solutions are somewhat awkward, and you can run into problems with *thread safety* and
*performance* (slow atomic variables, false sharing, etc) if you don't pay close attention.

Enter **ThreadsX**, a multi-threaded Julia library that provides parallel versions of some of the Base
functions. To see the list of supported functions, use the double-TAB feature inside REPL:

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

Save the following as `mapreduce.jl`:

```jl
using BenchmarkTools, ThreadsX

function digitsin(digitSequence::Int, num)
    base = 10
    while (digitSequence ÷ base > 0); base *= 10; end
    while num > 0; (num % base) == digitSequence && return true; num ÷= 10; end
    return false
end

function slow(n::Int64, digitSequence::Int)
    total = ThreadsX.mapreduce(+,1:n) do i
		if !digitsin(digitSequence, i)
			1.0 / i
		else
			0.0
		end
    end
    return total
end

total = @btime slow(Int64(1e8), 9)
println("total = ", total)   # total = 13.277605949855294
```

With 4 CPU cores, I see:

```sh
$ julia mapreduce.jl        # runtime with 1 thread: 2.200 s
$ julia -t 4 mapreduce.jl   # runtime with 4 threads: 543.949 ms
$ julia -t 8 mapreduce.jl   # what should we expect?
```

> ### <font style="color:blue">Exercise "ThreadsX.1"</font>
> Using the compact (one-line) if-else notation, shorten this code by four lines. Time the new, shorter code
> with one and several threads.
>
> **Hint**: the syntax is `1 > 2 ? "1 is greater than 2" : "1 is not greater than 2"`

## Parallelizing the slow series with ThreadsX.sum

```jl
?sum
sum(x->x^2, 1:10)
ThreadsX.sum(x->x^2, 1:10)
ThreadsX.sum(x^2 for x in 1:10)   # alternative syntax
```

The expression in the last round brackets is a *generator*. It generates a sequence on the fly without
storing individual elements, thus taking very little memory.

```jl
(i for i in 1:10)          # generator
collect(i for i in 1:10)   # construct a vector (this one takes more space) from it
[i for i in 1:10]          # functionally the same (vector via an array comprehension)
```

Let's use a generator with $10^8$ elements to compute our slow series sum:

```jl
using BenchmarkTools
@btime sum(!digitsin(9, i) ? 1.0/i : 0 for i in 1:100_000_000)
   # serial code: 2.183 s, prints 13.277605949858103
```

It is very easy to parallelize:

```jl
using BenchmarkTools, ThreadsX
@btime ThreadsX.sum(!digitsin(9, i) ? 1.0/i : 0 for i in 1:100_000_000)
   # with 4 threads: 527.573 ms, prints 13.277605949854381
```

> ### <font style="color:blue">Exercise "ThreadsX.2"</font>
> The expression `[i for i in 1:10 if i%2==1]` produces an array of odd integers between 1 and 10. Using this
> syntax, remove zero terms from the last generator, i.e. write a parallel code for summing the slow series
> with a generator that contains only non-zero terms. It should run slightly faster than the code with the
> original generator. (I get 527.159 ms runtime.)

<!-- ```jl -->
<!-- @btime ThreadsX.sum(1.0/i for i in 1:100_000_000 if !digitsin(9, i)) -->
<!-- ``` -->

Finally, let's rewrite our code applying a function to all integers in a range:

```jl
function numericTerm(i)
    !digitsin(9, i) ? 1.0/i : 0
end
@btime ThreadsX.sum(numericTerm, 1:Int64(1e8))   # 571.915 ms, same result
```

> ### <font style="color:blue">Exercise "ThreadsX.3"</font>
> Rewrite the last code replacing `sum` with `mapreduce`. **Hint**: look up help for `mapreduce()`.

<!-- ```jl -->
<!-- @btime ThreadsX.mapreduce(numericTerm, +, 1:Int64(1e8))   # 531.850 ms, same result -->
<!-- ``` -->

## Other parallel functions

ThreadsX provides various parallel functions for sorting. Sorting is intrinsically hard to parallelize, so do not expect
100% parallel efficiency. Let's take a look at `sort()` and `sort!()`:

```jl
n = Int64(1e8)
r = rand(Float32, (n));   # random floats in [0, 1]
r[1:10]      # first 20 elements, same as first(r,10)
last(r,10)   # last 10 elements

?sort              # underneath uses QuickSort (for numeric arrays) or MergeSort
@btime sort(r);    # 10.421 s, serial sorting
@btime sort!(r);   # 1.707 s, in-place serial sorting

r = rand(Float32, (n));
@btime ThreadsX.sort(r);    # 2.950 ms, parallel sorting with 4 threads
@btime ThreadsX.sort!(r);   # 1.115 ms, in-place parallel sorting with 4 threads
?ThreadsX.sort!             # there is actually a good manual page

# similar speedup for integers
r = rand(Int32, (n));
@btime sort!(r);   # 1.065 ms in serial

r = rand(Int32, (n));
@btime ThreadsX.sort!(r);   # 1.058 ms with 4 threads
```

Searching for extrema is much more parallel-friendly:

```jl
n = Int64(1e9)
r = rand(Int32, (n));        # make sure we have enough memory
@btime maximum(r)            # 328.375 ms
@btime ThreadsX.maximum(r)   # 82.562 ms with 4 threads
```

Finally, another useful function is `ThreadsX.map()` without reduction -- we will take a closer look at it in one of the
following sections.

To sum up this section, ThreadsX.jl provides a super easy way to parallelize some of the Base library functions. It
includes multi-threaded reduction and shows very impressive parallel performance. To list the supported functions, use
`ThreadsX.<TAB>`, and don't forget to use the built-in help pages.
