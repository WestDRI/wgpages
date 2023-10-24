+++
title = "Synchronization of threads"
slug = "chapel-10-synchronising-threads"
weight = 10
katex = true
+++

### `sync` block

The keyword `sync` provides all sorts of mechanisms to synchronize threads in Chapel. We can simply use
`sync` to force the _parent thread_ to stop and wait until its _spawned child-thread_ ends. Consider this
`sync1.chpl`:

```chpl
var x = 0;
writeln('This is the main thread starting a synchronous thread');
sync {
  begin {
	var count = 0;
	while count < 10 {
	  count += 1;
	  writeln('thread 1: ', x + count);
	}
  }
}
writeln('The first thread is done ...');
writeln('This is the main thread starting an asynchronous thread');
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
$ chpl sync1.chpl -o sync1
$ sed -i -e 's|gmax|sync1|' shared.sh
$ sbatch shared.sh
$ cat solution.out
```
```
This is the main thread starting a synchronous thread
thread 1: 1
thread 1: 2
thread 1: 3
thread 1: 4
thread 1: 5
thread 1: 6
thread 1: 7
thread 1: 8
thread 1: 9
thread 1: 10
The first thread is done ...
This is the main thread starting an asynchronous thread
This is the main thread, I am done ...
thread 2: 1
thread 2: 2
thread 2: 3
thread 2: 4
thread 2: 5
thread 2: 6
thread 2: 7
thread 2: 8
thread 2: 9
thread 2: 10
```

> ### <font style="color:blue">Discussion</font>
> What would happen if we swap `sync` and `begin` in the first thread:
> ```chpl
> begin {
>   sync {
>     var c = 0;
>     while c < 10 {
>       c += 1;
>       writeln('thread 1: ', x + c);
>     }
>   }
> }
> writeln('The first thread is done ...');
> ```
> Discuss your observations.
>
> Answer: `sync` would have no effect on the rest of the program. We only pause the execution of the first thread, until
> all statements inside sync {} are completed -- but this does not affect the main and the second threads: they keep on
> running.

> ### <font style="color:blue">Exercise "Task.3"</font>
> Use `begin` and `sync` statements to reproduce the functionality of `cobegin` in cobegin.chpl, i.e., the
> main thread should not continue until both threads 1 and 2 are completed.

### `sync` variables

A more elaborated and powerful use of `sync` is as a type qualifier for variables. When a variable is
declared as _sync_, a state that can be **_full_** or **_empty_** is associated with it.

To assign a new value to a _sync_ variable,  its state must be _empty_ (after the assignment operation is
completed, the state will be set as _full_). On the contrary, to read a value from a _sync_ variable, its
state must be _full_ (after the read operation is completed, the state will be set as _empty_ again).

```chpl
var x: sync int;
writeln('this is the main thread launching a new thread');
begin {
  for i in 1..10 do
	writeln('this is the new thread working: ', i);
	x.writeEF(2);   // write the value, state changes from Empty to Full
  writeln('New thread finished');
}
writeln('this is the main thread after launching new thread ... I will wait until x is full');
x.readFE();         // read the value, state changes from Full to Empty
writeln('and now it is done');
```
```sh
$ chpl sync2.chpl -o sync2
$ sed -i -e 's|sync1|sync2|' shared.sh
$ sbatch shared.sh
$ cat solution.out
```
```
this is main thread launching a new thread
this is main thread after launching new thread ... I will wait until x is full
this is new thread working: 1
this is new thread working: 2
this is new thread working: 3
this is new thread working: 4
this is new thread working: 5
this is new thread working: 6
this is new thread working: 7
this is new thread working: 8
this is new thread working: 9
this is new thread working: 10
New thread finished
and now it is done
```

Here the main thread does not continue until the variable is full and can be read.

* Let's add another line `x.readFE();` -- now it is stuck since we cannot read `x` while it's empty!
* Let's add `x.writeEF(5);` right before the last `x.readFE();` -- now we set is to full again (and assigned 5),
  and it can be read again.

There are a number of methods defined for _sync_ variables. Suppose _x_ is a sync variable of a given type:

```chpl
// general methods
x.reset() - set the state as empty and the value as the default of x's type
x.isfull() - return true is the state of x is full, false if it is empty

// blocking read and write methods
x.writeEF(value) - block until the state of x is empty, then assign the value and
                   set the state to full
x.writeFF(value) - block until the state of x is full, then assign the value and
                   leave the state as full
x.readFE() - block until the state of x is full, then return x's value and set
             the state to empty
x.readFF() - block until the state of x is full, then return x's value and
             leave the state as full

// non-blocking read and write methods
x.writeXF(value) - assign the value no matter the state of x, then set the state as full
x.readXX() - return the value of x regardless its state; the state will remain unchanged
```

### Atomic variables

Chapel also implements **_atomic_** operations with variables declared as `atomic`, and this provides
another option to synchronize threads. Atomic operations run *completely independently of any other thread
or process*. This means that when several threads try to write an atomic variable, only one will succeed at
a given moment, providing implicit synchronization between them. There is a number of methods defined for
atomic variables, among them `sub()`, `add()`, `write()`, `read()`, and `waitfor()` are very useful to
establish explicit synchronization between threads, as shown in the next code `atomic.chpl`:

```chpl
var lock: atomic int;
const numthreads = 5;

lock.write(0);               // the main thread set lock to zero

coforall id in 1..numthreads {
  writeln('greetings form thread ', id, '... I am waiting for all threads to say hello');
  lock.add(1);               // thread id says hello and atomically adds 1 to lock
  lock.waitFor(numthreads);  // then it waits for lock to be equal numthreads (which will happen when all threads say hello)
  writeln('thread ', id, ' is done ...');
}
```
```sh
$ chpl atomic.chpl -o atomic
$ sed -i -e 's|sync2|atomic|' shared.sh
$ sbatch shared.sh
$ cat solution.out
```
```
greetings form thread 4... I am waiting for all threads to say hello
greetings form thread 5... I am waiting for all threads to say hello
greetings form thread 2... I am waiting for all threads to say hello
greetings form thread 3... I am waiting for all threads to say hello
greetings form thread 1... I am waiting for all threads to say hello
thread 1 is done...
thread 5 is done...
thread 2 is done...
thread 3 is done...
thread 4 is done...
```

> ## Try this...
> Comment out the line `lock.waitfor(numthreads)` in the code above to clearly observe the effect of the
> thread synchronization.

Finally, with all the material studied so far, we should be ready to parallelize our code for the simulation
of the heat transfer equation.
