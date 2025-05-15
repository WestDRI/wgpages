+++
title = "Fire-and-forget tasks"
slug = "chapel-20-fire-and-forget-tasks"
weight = 20
katex = true
+++

Let's now talk about *task parallelism*. This is a lower-level style of programming, in which you explicitly
tell Chapel how to subdivide your computation into tasks. As this is more human-labour intensive than *data
parallelism*, here we will only outline the main concepts and pitfalls, without going into too much detail.

A Chapel program always starts as a single main task (and here we use the term "task" loosely as it could be a
thread). You can then start concurrent tasks with the `begin` statement. A task spawned by the `begin`
statement will run in a different task while the main task continues its normal execution. Let's start a new
code `begin.chpl` with the following lines:

```chpl
var x = 100;
writeln('This is the main task starting first task');
begin {
  var count = 0;
  while count < 10 {
	count += 1;
	writeln('task 1: ', x + count);
  }
}
writeln('This is the main task starting second task');
begin {
  var count = 0;
  while count < 10 {
	count += 1;
	writeln('task 2: ', x + count);
  }
}
writeln('This is the main task, I am done ...');
```
```sh
$ chpl begin.chpl -o begin
$ sbatch shared.sh
$ cat solution.out
```
```output
This is the main task starting first task
This is the main task starting second task
This is the main task, I am done ...
task 2: 101
task 1: 101
task 2: 102
task 1: 102
task 2: 103
task 1: 103
task 2: 104
...
task 1: 109
task 2: 109
task 1: 110
task 2: 110
```

As you can see the order of the output is not what we would expected, and actually it is somewhat
unpredictable. This is a well known effect of concurrent tasks accessing the same shared resource at the same
time (in this case the screen); the system decides in which order the tasks could write to the screen.

> ### <font style="color:blue">Discussion</font>
>
> 1. What would happen if in the last code we move the definition of `count` into the main task, but try to
>    assign it from tasks 1 and 2?
>
>> Answer: we'll get an error at compilation ("cannot assign to const variable"), since then `count` would
>> belong to the main task (would be defined within the scope of the main task), and we could modify its value
>> only in the main task.
>
> 2. What would happen if we try to insert a second definition `var x = 10;` inside the first `begin`
>statement?
>
>> Answer: that will actually work, as we'll simply create another, local instance of `x` with its own value.

> ## Key idea
> All variables have a **_scope_** in which they can be used. Variables declared inside a concurrent task are
> accessible only by that task. Variables declared in the main task can be read everywhere, but Chapel won't
> allow other concurrent tasks to modify them.
{.note}

> ### <font style="color:blue">Discussion</font>
> Are the concurrent tasks, spawned by the last code, running truly in parallel?
>
> Answer: it depends on the number of cores available to your job. If you have a single core, they'll run
> concurrently, with the CPU switching between the tasks. If you have two cores, task1 and task2 will likely
> run in parallel using the two cores.

> ## Key idea
> To maximize performance, start as many tasks (threads) as the number of available cores.
{.note}

A slightly more structured way to start concurrent tasks in Chapel is by using the `cobegin` statement. Here
you can start a block of concurrent tasks, **one for each statement** inside the curly brackets. Another
difference between the `begin` and `cobegin` statements is that with the `cobegin`, all the spawned tasks are
synchronized at the end of the statement, i.e. the main task won't continue its execution until all tasks are
done. Let's start `cobegin.chpl`:

```chpl
var x = 0;
writeln('This is the main task, my value of x is ', x);
cobegin {
  {
	var x = 5;
	writeln('This is task 1, my value of x is ', x);
  }
  writeln('This is task 2, my value of x is ', x);
}
writeln('This message will not appear until all tasks are done ...');
```
```sh
$ chpl cobegin.chpl -o cobegin
$ sed -i -e 's|begin|cobegin|' shared.sh
$ sbatch shared.sh
$ cat solution.out
```
```output
This is the main task, my value of x is 0
This is task 2, my value of x is 0
This is task 1, my value of x is 5
This message will not appear until all tasks are done...
```

As you may have concluded from the Discussion exercise above, the variables declared inside a task are
accessible only by the task, while those variables declared in the main task are accessible to all tasks.

Another, and one of the most useful ways to start concurrent/parallel tasks in Chapel, is the `coforall`
loop. This is a combination of the for-loop and the `cobegin`statements. The general syntax is:

```chpl
coforall index in iterand
{instructions}
```

This will start **a new task (thread) for each iteration**. Each task will then perform all the instructions
inside the curly brackets. Each task will have a copy of the loop variable **_index_** with the corresponding
value yielded by the iterand. This index allows us to _customize_ the set of instructions for each particular
task. Let's write `coforall.chpl`:

```chpl
var x = 10;
config var numtasks = 2;
writeln('This is the main task: x = ', x);
coforall taskid in 1..numtasks {
  var count = taskid**2;
  writeln('this is task ', taskid, ': my value of count is ', count, ' and x is ', x);
}
writeln('This message will not appear until all tasks are done ...');
```
```sh
$ chpl coforall.chpl -o coforall
$ sed -i -e 's|cobegin|coforall --numtasks=5|' shared.sh
$ sbatch shared.sh
$ cat solution.out
```
```output
This is the main task: x = 10
this is task 1: my value of c is 1 and x is 10
this is task 2: my value of c is 4 and x is 10
this is task 4: my value of c is 16 and x is 10
this is task 3: my value of c is 9 and x is 10
this is task 5: my value of c is 25 and x is 10
This message will not appear until all tasks are done ...
```

Notice the random order of the print statements. And notice how, once again, the variables declared
outside the `coforall` can be read by all tasks, while the variables declared inside, are available
only to the particular task.

> ### <font style="color:blue">Exercise "Task.1"</font>
> Would it be possible to print all the messages in the right order? Modify the code in the last example as
> required and save it as `consecutive.chpl`. Hint: you can use an array of strings declared in the main task,
> into which all the concurrent tasks could write their messages in the right order. Then, at the end, have
> the main task print all elements of the array.

> ### <font style="color:blue">Exercise "Task.2"</font>
> Consider the following code `gmax.chpl` to find the maximum array element. Complete this code, and also time
> the `coforall` loop.
> ```chpl
> use Random, Time;
> config const nelem = 1e8: int;
> var x: [1..nelem] int;
> fillRandom(x);	                   // fill array with random numbers
> var gmax = 0;
>
> config const numtasks = 2;       // let's pretend we have 2 cores
> const n = nelem / numtasks;      // number of elements per task
> const r = nelem - n*numtasks;    // these elements did not fit into the last task
> var lmax: [1..numtasks] int;    // local maxima for each task
> coforall taskid in 1..numtasks {
>   var start, finish: int;
>   start = ...
>   finish = ...
>   ... compute lmax for this task ...
> }
>
> // put largest lmax into gmax
> for taskid in 1..numtasks do                        // a serial loop
>   if lmax[taskid] > gmax then gmax = lmax[taskid];
>
> writef('The maximum value in x is %14.12dr\n', gmax);   // formatted output
> writeln('It took ', watch.elapsed(), ' seconds');
> ```
> Write a parallel code to find the maximum value in the array `x`. Be careful: the number of tasks should not be
> excessive. Best to use `numtasks` to organize parallel loops. For each task compute the `start` and `finish`
> indices of its array elements and cycle through them to find the local maximum. Then in the main task cycle through
> all local maxima to find the global maximum.

> ### <font style="color:blue">Discussion</font>
> Run the code of last Exercise using different number of tasks, and different sizes of the array `x` to
> see how the execution time changes. For example:
> ```sh
> $ ./gmax --nelem=100_000_000 --numtasks=1
> ```
>
> Discuss your observations. Is there a limit on how fast the code could run?
>
>> Answer: (1) consider a small problem, increasing the number of tasks => no speedup  
>>         (2) consider a large problem, increasing the number of tasks => speedup up to the physical number of cores

> ## Try this...
> Substitute your addition to the code to find _gmax_ in the last exercise with:
> ```chpl
> gmax = max reduce x;   // 'max' is one of the reduce operators (data parallelism example)
> ```
> Time the execution of the original code and this new one. How do they compare?
>
>> Answer: the built-in reduction operation runs in parallel utilizing all cores.

> ## Key idea
> It is always a good idea to check whether there is _built-in_ functions or methods in the used language,
> that can do what we want as efficiently (or better) than our house-made code. In this case, the _reduce_
> statement reduces the given array to a single number using the operation `max`, and it is parallelized. Here
> is the full list of reduce operations: `+` &nbsp; `*` &nbsp; `&&` &nbsp; `||` &nbsp; `&` &nbsp; `|` &nbsp;
> `^` &nbsp; `min` &nbsp; `max`.
{.note}
