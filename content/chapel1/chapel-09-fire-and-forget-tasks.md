+++
title = "Fire-and-forget tasks"
slug = "chapel-09-fire-and-forget-tasks"
weight = 9
katex = true
+++

A Chapel program always starts as a single main thread. You can then start concurrent threads with the `begin`
statement. A thread spawned by the `begin` statement will run in a different thread while the main thread
continues its normal execution. Let's start a new code `begin.chpl` with the following lines:

```chpl
var x = 100;
writeln('This is the main thread starting first thread');
begin {
  var count = 0;
  while count < 10 {
	count += 1;
	writeln('thread 1: ', x + count);
  }
}
writeln('This is the main thread starting second thread');
begin {
  var count = 0;
  while count < 10 {
	count += 1;
	writeln('thread 2: ', x + count);
  }
}
writeln('This is the main thread, I am done ...');
```
```sh
$ chpl begin.chpl -o begin
$ sbatch shared.sh
$ cat solution.out
```
```
This is the main thread starting first thread
This is the main thread starting second thread
This is the main thread, I am done ...
thread 2: 101
thread 1: 101
thread 2: 102
thread 1: 102
thread 2: 103
thread 1: 103
thread 2: 104
...
thread 1: 109
thread 2: 109
thread 1: 110
thread 2: 110
```

As you can see the order of the output is not what we would expected, and actually it is somewhat
unpredictable. This is a well known effect of concurrent threads accessing the same shared resource at the
same time (in this case the screen); the system decides in which order the threads could write to the
screen.

> ### <font style="color:blue">Discussion</font>
>
> 1. What would happen if in the last code we move the definition of `count` into the main thread, but try to
>    assign it from threads 1 and 2?
>
>> _Answer_: we'll get an error at compilation ("cannot assign to const variable"), since then `count` would
>belong to the > main thread (would be defined within the scope of the main thread), and we could modify its
>value only in the main > thread.
>
> 2. What would happen if we try to insert a second definition `var x = 10;` inside the first `begin`
>statement?
>
>> _Answer_: that will actually work, as we'll simply create another, local instance of `x` with its own value.

> ## Key idea
> All variables have a **_scope_** in which they can be used. Variables declared inside a concurrent
> thread are accessible only by that thread. Variables declared in the main thread can be read everywhere,
> but Chapel won't allow other concurrent threads to modify them.

> ### <font style="color:blue">Discussion</font>
> Are the concurrent threads, spawned by the last code, running truly in parallel?
>
> _Answer_: it depends on the number of cores available to your job. If you have a single core, they'll
> run concurrently, with the CPU switching between the threads. If you have two cores, thread1 and thread2
> will likely run in parallel using the two cores.

> ## Key idea
> To maximize performance, start as many threads as the number of available cores.

A slightly more structured way to start concurrent threads in Chapel is by using the `cobegin` statement. Here you can
start a block of concurrent threads, **one for each statement** inside the curly brackets. Another difference between
the `begin` and `cobegin` statements is that with the `cobegin`, all the spawned threads are synchronized at the end of
the statement, i.e. the main thread won't continue its execution until all threads are done. Let's start `cobegin.chpl`:

```chpl
var x = 0;
writeln('This is the main thread, my value of x is ', x);
cobegin {
  {
	var x = 5;
	writeln('This is thread 1, my value of x is ', x);
  }
  writeln('This is thread 2, my value of x is ', x);
}
writeln('This message will not appear until all threads are done ...');
```
```sh
$ chpl cobegin.chpl -o cobegin
$ sed -i -e 's|begin|cobegin|' shared.sh
$ sbatch shared.sh
$ cat solution.out
```
```
This is the main thread, my value of x is 0
This is thread 2, my value of x is 0
This is thread 1, my value of x is 5
This message will not appear until all threads are done...
```

As you may have concluded from the Discussion exercise above, the variables declared inside a thread are
accessible only by the thread, while those variables declared in the main thread are accessible to all
threads.

Another, and one of the most useful ways to start concurrent/parallel threads in Chapel, is the `coforall`
loop. This is a combination of the for-loop and the `cobegin`statements. The general syntax is:

```chpl
coforall index in iterand
{instructions}
```

This will start **a new thread for each iteration**. Each thread will then perform all the instructions inside the curly
brackets. Each thread will have a copy of the loop variable **_index_** with the corresponding value yielded by the
iterand. This index allows us to _customize_ the set of instructions for each particular thread. Let's write
`coforall.chpl`:

```chpl
var x = 10;
config var numthreads = 2;
writeln('This is the main thread: x = ', x);
coforall threadid in 1..numthreads do {
  var count = threadid**2;
  writeln('this is thread ', threadid, ': my value of count is ', count, ' and x is ', x);
}
writeln('This message will not appear until all threads are done ...');
```
```sh
$ chpl coforall.chpl -o coforall
$ sed -i -e 's|cobegin|coforall --numthreads=5|' shared.sh
$ sbatch shared.sh
$ cat solution.out
```
```
This is the main thread: x = 10
this is thread 1: my value of c is 1 and x is 10
this is thread 2: my value of c is 4 and x is 10
this is thread 4: my value of c is 16 and x is 10
this is thread 3: my value of c is 9 and x is 10
this is thread 5: my value of c is 25 and x is 10
This message will not appear until all threads are done ...
```

Notice the random order of the print statements. And notice how, once again, the variables declared
outside the `coforall` can be read by all threads, while the variables declared inside, are available
only to the particular thread.

> ### <font style="color:blue">Exercise "Task.1"</font>
> Would it be possible to print all the messages in the right order? Modify the code in the last example as
> required and save it as `consecutive.chpl`. Hint: you can use an array of strings declared in the main
> thread, into which all the concurrent threads could write their messages in the right order. Then, at the
> end, have the main thread print all elements of the array.

> ### <font style="color:blue">Exercise "Task.2"</font>
> Consider the following code `gmax.chpl` to find the maximum array element. Complete this code, and also time
> the `coforall` loop.
> ```chpl
> use Random, Time;
> config const nelem = 1e8: int;
> var x: [1..nelem] real;
> fillRandom(x);	                   // fill array with random numbers
> var gmax = 0.0;
>
> config const numthreads = 2;       // let's pretend we have 2 cores
> const n = nelem / numthreads;      // number of elements per thread
> const r = nelem - n*numthreads;    // these elements did not fit into the last thread
> var lmax: [1..numthreads] real;    // local maxima for each thread
> coforall threadid in 1..numthreads do {
>   var start, finish: int;
>   start = ...
>   finish = ...
>   ... compute lmax for this thread ...
> }
>
> // put largest lmax into gmax
> for threadid in 1..numthreads do                        // a serial loop
>   if lmax[threadid] > gmax then gmax = lmax[threadid];
>
> writef('The maximum value in x is %14.12dr\n', gmax);   // formatted output
> writeln('It took ', watch.elapsed(), ' seconds');
> ```
> Write a parallel code to find the maximum value in the array `x`. Be careful: the number of threads should not be
> excessive. Best to use `numthreads` to organize parallel loops. For each thread compute the `start` and `finish`
> indices of its array elements and cycle through them to find the local maximum. Then in the main thread cycle through
> all local maxima to find the global maximum.

> ### <font style="color:blue">Discussion</font>
> Run the code of last Exercise using different number of threads, and different sizes of the array `x` to
> see how the execution time changes. For example:
> ```sh
> $ ./gmax --nelem=100_000_000 --numthreads=1
> ```
>
> Discuss your observations. Is there a limit on how fast the code could run?
>
>> Answer: (1) consider a small problem, increasing the number of threads => no speedup
>>         (2) consider a large problem, increasing the number of threads => speedup up to the physical
>>             number of cores

> ## Try this...
> Substitute your addition to the code to find _gmax_ in the last exercise with:
> ```chpl
> gmax = max reduce x;   // 'max' is one of the reduce operators (data parallelism example)
> ```
> Time the execution of the original code and this new one. How do they compare?
>
>> Answer: the built-in reduction operation runs in parallel utilizing all cores.

> ## Key idea
> It is always a good idea to check whether there is _built-in_ functions or methods in the used
> language, that can do what we want as efficiently (or better) than our house-made code. In this case,
> the _reduce_ statement reduces the given array to a single number using the operation `max`, and it is
> parallelized. Here is the full list of reduce operations: + &nbsp; * &nbsp; && &nbsp; || &nbsp; &
> &nbsp; | &nbsp; ^ &nbsp; min &nbsp; max.
