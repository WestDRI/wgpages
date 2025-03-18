+++
title = "Persistent storage on workers"
slug = "../summer/julia-09-persistent-arrays"
weight = 9
katex = true
+++

So far, our remote functions have been **stateless** in the sense that each remote function runs independently
on the assigned worker and does not retain any state between calls. In other words, there is no persistent
storage associated with the worker. Consider this example:

```jl
using Distributed
addprocs(1)       # add a worker process

@everywhere function initGrid(n)
    a = zeros(n);           # create `a` within the scope of the function
    println(typeof(a))
end
@fetchfrom 2 initGrid(10)   # From worker 2: Vector{Float64}

@everywhere function showGrid()
    println("a = ", a)
end
@fetchfrom 2 showGrid()     # error: `a` not defined in `Main` scope
```

There are several ways to allocate persistent storage on workers in between the function calls:

1. Use `global` keyword to define the variable in the main scope on worker 2, and not just in the scope of the
   remote function:

```jl
using Distributed
addprocs(1)

@everywhere function initArray()
    global a
    a = [i+1 for i in 1:10]
end
@spawnat 2 initArray()

@fetchfrom 2 a           # works

@everywhere function showArray()
    global a
    println(a)
end
@spawnat 2 showArray()   # works
```

2. Use distributed arrays (`DArray`) for distributed storage across multiple workers -- we will look into this
   option in the next section.
3. Use remote channels to access (write, read) persistent storage on a single worker.

## Tightly coupled parallel codes

For tightly coupled parallel codes, you almost always want to have persistent storage on the workers, as
allocating/deallocating/sending data from scratch at each step will become too expensive. In this workshop we
don't explore tightly coupled parallel problems, but these can be implemented using one of the 3 methods
above. *Perhaps, I should do a webinar on this topic.*

## Channels

Before we study remote channels, let's first look into Julia's Channels. A **Channel** is a data structure
that facilitates communication between tasks; they act like pipes/channels. Consider a local channel on the
control process:

```jl
ch = Channel(2)     # buffered channel of size 2; can take objects of any type
put!(ch, "hello")   # append "hello" to the channel
put!(ch, "world")   # append "world" to the channel
put!(ch, "5")       # will hang (no more space); break with Ctrl-C
ch                  # 2 items available
ch.data             # show current data in the channel
println(take!(ch))  # remove and return "hello" from the channel
println(take!(ch))  # remove and return "world" from the channel
println(take!(ch))  # will hang (no more items); break with Ctrl-C
```

You can declare Channels only  for specific data types:

```jl
ch = Channel{Vector{Float64}}(1)   # buffered channel of size 1 to hold 1D arrays of Float64's
put!(ch, 100)         # error: need Vector{Float64}, not Float64
put!(ch, zeros(20))   # this works
ch.data     # see our 1D array
take!(ch)   # remove and return the 1D array
ch.data     # no more data left in the channel
take!(ch)   # will hang (no more items); break with Ctrl-C
```

## Remote channels

A channel is local to a process; in the examples above they are local to the control process, and they be
accessed only from the control process. Similarly, if we define a channel on worker 2, the control process or
worker 3 cannot directly refer to that channel.

However, they can do this through a `RemoteChannel` that can send/fetch values to/from other workers. Consider
this example:

```jl
using Distributed
addprocs(1)
@everywhere function createPersistentArray()   # function to create a persistent array on a worker
    return RemoteChannel(() -> Channel{Vector{Float64}}(1))   # remote channel of size 1
end
r1 = @fetchfrom 2 createPersistentArray()   # create a persistent array
r2 = @fetchfrom 2 createPersistentArray()   # create another persistent array
r1.where, r2.where   # both stored on worker 2
r1.id, r2.id         # their ID's (1,2)
r1.data              # error: cannot get to the remote data this way
put!(r1, [float(i^2) for i in 1:10])        # store an array inside channel r1
put!(r1, [float(i^3) for i in 1:10])        # blocks: no space in r1
put!(r2, [float(i^3) for i in 1:10])        # store an array inside channel r2

r1          # RemoteChannel{Channel{Vector{Float64}}}(2,2,1)
fetch(r1)   # retrieve the array without removing it
take!(r1)   # fetch the array and remove it
```

To print or use a RemoteChannel's content on its host worker, you can also use `fetch()`, but now all
processing happens on worker 2:

```sh
@spawnat 2 println(fetch(r1))
```

{{<note>}}
Remote channels also let you send data directly between workers, without using the control process.
{{</note>}}




<!-- const remoteArray = remotecall(createPersistentArray, 2, 10)   # create a remote channel on worker 2 -->



    
    



<!-- const remoteArray = RemoteChannel(() -> Array{Float64}(undef, 10), 2) -->
<!-- # const remoteArray = RemoteChannel(() -> zeros(10), 2) -->

<!-- ... -->
<!-- MethodError: Cannot `convert` an object of type -->
<!-- Vector{Float64} to an object of type -->
<!-- AbstractChannel -->












<!-- using Distributed, DistributedArrays -->
<!-- addprocs(4) -->
<!-- @everywhere using DistributedArrays -->
<!-- darr = DArray(I -> zeros(length(I)), (10,)) -->
<!-- @fetchfrom 2 darr   # access it from a worker -->
