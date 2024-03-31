+++
title = "Part 2: distributed computing with Ray"
slug = "ray"
katex = true
+++

{{<cor>}}March 28<sup>th</sup> (Part 1) and April 4<sup>th</sup> (Part 2){{</cor>}}\
{{<cgr>}}Both days 10:00am - noon Pacific{{</cgr>}}

There is a number of high-level open-source parallel frameworks for Python that are quite popular in data
science and beyond:

- {{<a "https://www.ray.io" "Ray">}} is a unified framework for scaling AI and Python applications
- {{<a "https://www.dask.org" "Dask">}} parallelizes Python loops and graphs of functions, scales NumPy,
  pandas, and scikit-learn
- {{<a "https://spark.apache.org/docs/latest/api/python" "PySpark">}} is the Python API for Apache Spark for
  large-scale data processing in a distributed environment
- {{<a "https://mars-project.readthedocs.io" "Mars">}} is a tensor-based unified framework for large-scale
  data computation which scales NumPy, pandas, scikit-learn and many other libraries
- {{<a "https://mpi4py.readthedocs.io" "mpi4py">}} is the most popular Message Passing Interface (MPI)
  implementation for Python
- {{<a "https://ipyparallel.readthedocs.io" "IPyParallel">}} architecture for parallel and distributed
  computing
- {{<a "https://joblib.readthedocs.io/en/latest/parallel.html" "Joblib">}} for parallel for loops with
  multiprocessing

Here we'll focus on Ray, a unified framework for scaling AI and Python workflows. Since this is not a machine
learning workshop, we will not touch most of Ray's AI capabilities, but will focus on its core distributed
runtime and data libraries. We will learn several different approaches to parallelizing purely numerical (and
therefore CPU-bound) workflows, both with and without reduction. If your code is I/O-bound, you will also
benefit from this course, as I/O-bound workflows can be easily sped up with Ray.







## Initializing Ray

```py
import ray
ray.init()   # no longer necessary, will run by default when you first use it
```

However, `ray.init()` is very useful for passing options at initialization. For example, Ray is quite verbose
when you do things in it. To turn off this logging output to the terminal, you can do

```py
ray.init(configure_logging=False)   # hide ray's copious logging output
```

You can run `ray.init()` only once. If you want to re-run it, first you need to run
`ray.shutdown()`. Alternatively, you can pass the argument `ignore_reinit_error=True` to the call.

You can specify the number of cores for Ray to use, and you can combine multiple options, e.g.

```py
ray.init(num_cpus=4, configure_logging=False)
```

By default Ray will use all available CPU cores, e.g. on my laptop `ray.init()` will start 8 ray::IDLE
processes (workers), and you can monitor these in a separate shell with `htop --filter "ray::IDLE"` command.







## Ray tasks

In Ray you can execute any Python function asynchronously on separate workers. Such functions are called **Ray
remote functions**, and their asynchronous invocations are called **Ray tasks**:

```py
import ray

ray.init(configure_logging=False)   # optional

@ray.remote             # declare that we want to run this function remotely
def square(x):
    return x * x

r = square.remote(10)   # launch/schedule a remote calculation (non-blocking call)
type(r)                 # ray._raylet.ObjectRef (object reference)
ray.get(r)              # retrieve the result (=100) (blocking call)
```

The calculation may happen any time between `<function>.remote()` and `ray.get()` calls, i.e. it does not
necessarily start when you launch it. This is called **lazy execution**: the operation is often executed when
you try to access the result.


```py
a = square.remote(10)   # launch a remote calculation
ray.cancel(a)           # cancel it
ray.get(a)              # either error or 100, depending on whether the calculation
                        # has finished before cancellation
```

You can launch several Ray tasks at once, to be executed in parallel in the background, and you can retrieve
their results either individually or through the list:

```py
r = [square.remote(i) for i in range(4)]   # launch four parallel tasks (non-blocking call)
print([ray.get(r[i]) for i in range(4)])   # retrieve the results (multiple blocking calls)
print(ray.get(r))          # more compact way to do the same (single blocking call)
```







### Task output and monitoring

Consider a Dask code in which each task sleeps for 10 seconds, prints a message and returns its task ID:

```py
import ray
from time import sleep, time

ray.init(num_cpus=4, configure_logging=False)

@ray.remote
def nap():
    sleep(10)
    print("almost done")
    return ray.get_runtime_context().get_task_id()
```

Let's run it with timing on:

```py
start = time()
r = [nap.remote() for i in range(4)]
ray.get(r)
end = time()
print("Time in seconds:", round(end-start,3))
```

I get 10.013 seconds since I have enough cores to run all of them in parallel. However, most likely, I see
printout ("almost done") from only one process and a message "repeated 3x across cluster". To enable print
messages from all tasks, you need set the bash shell environment variable `export RAY_DEDUP_LOGS=0`.

Also notice that Ray task IDs are not integers but 48-character hexadecimal numbers.

Ray provides a command-line utility to monitor current and past tasks in bash:

```sh
pyenv activate hpc-env
ray summary tasks
```









### Parallelizing the slow series with Ray tasks

Let's perform our slow series calculation as a Ray task. This is our original serial implementation, now with
a Ray remote function running on one of the workers:

```py
from time import time
import ray

@ray.remote
def slow(n: int):
    total = 0
    for i in range(1,n+1):
        if not "9" in str(i):
            total += 1.0 / i
    return total

start = time()
r = slow.remote(100_000_000)
total = ray.get(r)
end = time()
print("Time in seconds:", round(end-start,3))   # 6.867 seconds
print(total)
```

We get the same timing as before (6+ seconds). You can call `ray.get()` on the previously computed result
again without having to redo the calculation:

```py
start = time()
tmp = ray.get(r)
end = time()
print("Time in seconds:", round(end-start,3))   # 0.001 seconds
print(tmp)
```

Let's speed up this calculation with parallel Ray tasks! Instead of doing the full sum over `range(1,n+1)`,
let's calculate a partial sum on each task:

```py
from time import time
import psutil, ray

ray.init(configure_logging=False)

n = 100_000_000
@ray.remote
def slow(interval):
    total = 0
    for i in range(interval[0],interval[1]+1):
        if not "9" in str(i):
            total += 1.0 / i
    return total
```

This would be a serial calculation:

```py
start = time()
r = slow.remote((1, n))   # takes in one argument
total = ray.get(r)
end = time()
print("Time in seconds:", round(end-start,3))   # 6.963
print(total)
```

To launch it in parallel, we need to subdivide the interval:

```py
ncores = psutil.cpu_count(logical=False)
size = n//ncores   # size of each batch
intervals = [(i*size+1,(i+1)*size) for i in range(ncores)]
if n > intervals[-1][1]: intervals[-1] = (intervals[-1][0], n)   # add the remainder (if any)

start = time()
r = [slow.remote(intervals[i]) for i in range(ncores)]
total = sum(ray.get(r))   # compute total sum
end = time()
print("Time in seconds:", round(end-start,3))
print(total)
```

On 8 cores I get the average runtime of 1.282 seconds -- not too bad, considering that some of the cores are
low-efficiency (slower) cores.

{{< question num=11 >}}
Increase `n` to 2_000_000_000 and run `htop --filter "ray::IDLE` in a separate shell to monitor CPU usage of
individual processes.
{{< /question >}}












### Running Numba-compiled functions as Ray tasks

We ended Part 1 with a Numba-compiled version of the slow series code that works almost as well as a
Julia/Chapel code. As you just saw, Ray itself can distribute the calculation, speeding up the code with
parallel execution, but individual tasks still run native Python code that is slow.

Wouldn't it be great if we could use Ray to distribute execution of Numba-compiled functions to workers? It
turns out *we can*, but we have to be careful with syntax. We would need to define remote compiled functions,
but neither Ray, nor Numba let you combine their decorators (@ray.remote and @numba.jit, respectively) for a
single function. You can do this in two steps:

```py
import ray
from numba import jit

ray.init(num_cpus=4, configure_logging=False)

@jit(nopython=True)
def square(x):
    return x*x

@ray.remote
def runCompiled():
    return square(5)

r = runCompiled.remote()
ray.get(r)
```

Here we "jit" the function on the main process and send it to workers for execution. Alternatively, you can
"jit" on workers:

```py
import ray
from numba import jit

ray.init(num_cpus=4, configure_logging=False)

def square(x):
    return x*x

@ray.remote
def runCompiled():
    compiledSquare = jit(square)
    return compiledSquare(5)

r = runCompiled.remote()
ray.get(r)
```

In my tests with more CPU-intensive functions, both versions produce equivalent runtimes.

{{< question num="12: combining Numba and Ray remotes for the slow series (big one!)" >}}
Write a slow series solver with Numba-compiled functions executed as Ray tasks.
1. Numba-compiled `combined(k)` that returns either 1/x or 0.
2. Numba-compiled `slow(interval)` for partial sums.
3. Ray-enabled remote function `runCompiled(interval)` to launch partial sums on workers.
4. Very important step: you must do small `runCompiled()` runs on workers to copy code over to them -- no need
   to time these runs. Without this "pre-compilation" step you will not get fast execution on workers on the
   bigger problem.
5. The rest of the code will look familiar:
```py
start = time()
r = [runCompiled.remote(intervals[i]) for i in range(ncores)]
total = sum(ray.get(r))   # compute total sum
end = time()
print("Time in seconds:", round(end-start,3))
print(total)
```
(on presenter's laptop the solution is in `slowSeriesNumbaRay.py`)
{{< /question >}}

Averaged (over three runs) times in seconds :

|   |   |   |   |   |
|---|---|---|---|---|
| ncores | 1 | 2 | 4 | 8 |
| wallclock runtime | 0.439 | 0.235 | 0.130 | 0.098 |

Using a combination of Numba and Ray tasks on 8 cores, we accelerated the calculation by ~68X.

```py
# from time import time
# import numpy as np
# import ray

# @ray.remote
# def slow():
#     n = 100_000_000
#     term = np.vectorize(lambda x: 1.0/x if "9" not in str(x) else 0.0)
#     i = np.arange(1,n+1)
#     return np.sum(term(i))

# start = time()
# r = slow.remote()
# total = ray.get(r)
# end = time()
# print("Time in seconds:", round(end-start,3))   # 15.714 15.086 14.764
# print(total)
```







### Getting partial results from Ray tasks

Consider the following code:

```py
from time import sleep
import ray, random

@ray.remote
def increment(x):
    sleep(random.randint(1,100))   # sleep random number from [1,100] seconds
    return x + 1

refs = [increment.remote(x) for x in range(1,21)]   # start 20 tasks
```

If we now call `ray.get(refs)`, that would block until all of these remote tasks finish. If we want to, let's
say, one of them to finish and then continue on the main task, we will do:

```py
ready_refs, remaining_refs = ray.wait(refs, num_returns=1, timeout=None)   # wait for one of them to finish
print(ready_refs, remaining_refs)   # print the IDs of the finished task, and the other 19 IDs
ray.get(ready_refs)                 # get finished results
```








### Multiple returns from Ray tasks

Similar to normal Python functions, Ray tasks can return tuples:

```py
import ray

@ray.remote
def threeNumbers():
    return 10, 20, 30

r = threeNumbers.remote()
print(ray.get(r)[0])        # get the result (tuple) and show its first element
```

Alternatively, you can pipe each number to a separate object ref:

```py
@ray.remote(num_returns=3)
def threeNumbers():
    return 10, 20, 30

r1, r2, r3 = threeNumbers.remote()
ray.get(r1)   # get the first result only
```

You can also create a remote generator that will return only one number at a time, to reduce memory usage:

```py
@ray.remote(num_returns=3)
def threeNumbers():
    for i in range(3):
        yield i

r1, r2, r3 = threeNumbers.remote()
ray.get(r1)   # # get the first number only
```






### Linking remote tasks

In addition to values, object refs can also be passed to remote functions. Define two functions:

```py
import ray

@ray.remote
def one():
    return 1

@ray.remote
def increment(value):
    return value + 1
```

In by-now familiar syntax:

```py
r1 = one.remote()                    # create the first Ray task
r2 = increment.remote(ray.get(r1))   # pass its result as an argument to another Ray task
print(ray.get(r2))
```

You can also shorten this syntax:

```py
r1 = one.remote()           # create the first Ray task
r2 = increment.remote(r1)   # pass its object ref as an argument to another Ray task
print(ray.get(r2))
```

As the second task depends on the output of the first task, Ray will not execute the second task until the
first task has finished.











## Ray Data

Ray Data is a parallel data processing library for ML workflows. As you will see in this section, Ray Data can
be easily used for non-ML workflows. To process large datasets, Ray Data uses **streaming/lazy execution**,
i.e. processing does not happen until you try to access ("consume" in Ray's language) the result.

<!-- https://www.anyscale.com/blog/streaming-distributed-execution-across-cpus-and-gpus -->

The core object in Ray Data is a **dataset** which is a distributed data collection. Ray datasets can store
general multidimensional array data that are too large to fit into a single machine's memory.

Ray's dataset operates over a sequence of Ray object references to blocks. Each block contains a disjoint
subset of rows, and Ray Data loads and transforms these blocks in parallel. Each row in Ray's datasets is a
dictionary.

> Recall: a Python dictionary is a collection of key-value pairs.







### Creating datasets

```py
import ray
ray.init(configure_logging=False)

ds = ray.data.range(1000)   # create a dataset from a range
ds   # Dataset(num_blocks=17, num_rows=1000, schema={id: int64})
ds.num_blocks()   # 17 blocks
ds.take(3)   # return first 3 rows as a list of dictionaries; default keys are often 'id' or 'item'
len(ds.take())   # default is 20 rows
ds.show(3)   # first 3 rows in a different format (one row per line)
ds.count()   # explicitly count the number of rows; might be expensive (to load the dataset into memory)
```

Rows can be generated from arbitrary items:

```py
ray.data.from_items([10,20,30]).take()   # [{'item': 10}, {'item': 20}, {'item': 30}]
```

Rows can have multiple key-value pairs:

```py
listOfDictionaries = [{"col1": i, "col2": i ** 2} for i in range(1000)]
ds = ray.data.from_items(listOfDictionaries)
ds.show(5)
```

A dataset can also be loaded from a file:

```py
dd = ray.data.read_csv("s3://anonymous@air-example-data/iris.csv")   # load a predefined dataset
dd
dd.show()   # might pause to read data, default is 20 rows
```








### Transforming datasets

<!-- operations: (1) transformation: takes in Dataset, outputs a new Dataset) -->
<!--             (2) consumption: produces values (not a data stream) as output (e.g. iter_batches()) -->
<!-- parallel processing at scale: (1) transformations, e.g. map_batches() -->
<!--                               (2) aggregations, e.g. min()/max()/mean() -->
<!--                               (3) grouping via groupby() -->
<!--                               (4) shuffling operations, e.g. sort(), random_shuffle(), and repartition() -->

```py
import ray
ray.init(configure_logging=False)

ds = ray.data.range(1000)   # create a dataset
ds.show(5)
```

Let's apply a function to each row in the dataset `ds`. This function *must* return a dictionary that will
form each row in the new dataset:

```py
ds.map(lambda row: row).show(3)                 # takes a row, returns the same row
a = ds.map(lambda row: {"id": str(row["id"])})  # takes a row, returns a dict with 'id' values converted to string
a   # `a` is a new dataset
a.show(5)
```

With `.map()` you can also use non-lambda (or non-anonymous) functions:

```py
def squares(row):
    return {'squares': row['id']**2}

ds.map(squares).show(5)
```

Your function can also add to existing rows, instead of returning new ones:

```py
ds = ray.data.range(1000)
def addSquares(row):
    row['square'] = row['id']**2   # add a new entry to each row
    return row                       

b = ds.map(addSquares)
ds.show(5)  # original dataset
b.show(5)   # contains both the original entries and the squares
```

You might have already noticed by now that all processing is lazy, i.e. it happens when we request results:

```py
ds = ray.data.range(10_000_000)   # define a bigger dataset
ds.map(addSquares)   # no visible calculation, just a request, not comsuming results
ds.map(addSquares).show()   # print results => start calculation
ds.map(addSquares).show()   # previous results were not stored, so this will re-run the calculation

b = ds.map(addSquares)   # this does not start calculation
b.show()                 # this starts calculation
```

Every time you print or use `b`, it'll re-do the calculation. For this reason, you can think of `b` not as a
variable with a value but as a *data stream*.

How can you do the calculation once and store the results for repeated use? You can convert `b` into a more
permanent (not a data stream) object, e.g. a list:

```py
b = ds.map(addSquares)   # this does not start calculation
c = b.take()             # fast: only first 20 elements
c = b.take(10_000_000)   # takes a couple of minutes, runs in parallel
```

This is not very efficient ... certainly, computing 10_000_000 squares should not take a couple of minutes in parallel!

Let's rewrite this problem:

```py
n = 10_000_000
n1 = n // 2
n2 = n - n1

import numpy as np
ds = ray.data.from_items([np.arange(n1), n1 + np.arange(n2)])
ds.show()

def squares(row):
    return {'squares': row['item']**2}

start = time()
b = ds.map(squares).take()
end = time()
print("Time in seconds:", round(end-start,3))
b.show()
```

Now the runtime is 0.359 seconds.







<!-- ```py -->
<!-- c.materialize()   # read all blocks into memory ... not clear -->
<!--                   # "materialize this dataset into object store memory" -->
<!-- ``` -->







### Vectorizable dataset transformations

The function `.map_batches()` will process batches (blocks) of rows, vectorizing operations on NumPy arrays
inside each batch. We won't study it here, as in practical terms it does not solve the specific problems in
this course any faster. With `.map_batches()` you are limited in terms of data types that you can use inside a
function passed to `.map_batches()` -- in general it expects vectorizable NumPy arrays. If you are not
planning to vectorize via `map_batches()`, use `map()` instead, and you will still get parallelization.

<!-- ```py -->
<!-- ds = ray.data.from_items([1]) -->
<!-- ds.show() -->
<!-- def map_fn_with_large_output(batch): -->
<!--     for i in range(3): -->
<!--         yield {"large_output": np.ones((5,5))}   # use each row of this matrix to create an entry -->
<!--                                                  # len(np.ones((5,5))) = 5 \times yield 3 times => 15 entries {'large_output': array([1., 1., 1., 1., 1.])} -->

<!-- e = ds.map_batches(map_fn_with_large_output) -->
<!-- e.show() -->
<!-- ``` -->

<!-- In general, `map_batches()` will vectorize operations on NumPy arrays inside each batch. In other words, the -->
<!-- input function should be easily vectorizable via NumPy. E.g., going to our earlier example, the following -->
<!-- won't work: -->

<!-- ```py -->
<!-- ds = ray.data.range(1000) -->
<!-- import numpy as np -->
<!-- def squares(batch): -->
<!--     return {'squares': 1}   # return an integer as a value in each row => error -->

<!-- b = ds.map_batches(squares); b.show(5)   # error -->

<!-- def squares(batch): -->
<!--     return {'squares': np.array([1])}   # return a NumPy array => vectorizable -->

<!-- b = ds.map_batches(squares); b.show(5)   # works -->

<!-- def squares(batch): -->
<!--     x = 0 -->
<!--     for i in range(batch['id']): -->
<!--         x += i -->
<!--     return {'squares': np.array([x])}   # seemingly Ok, but will break when using it, as you are trying to use -->
<!--                                         # batch['id'] as an integer, and Ray will try to vectorize it over the batch -->

<!-- b = ds.map_batches(squares); b.show(5)   # TypeError -->
<!-- ``` -->

<!-- All this is to say that you are limited in terms of types that you can use inside a function that you pass to -->
<!-- `map_batches()` -- in general it expects vectorizable NumPy arrays. -->









### Slow series with Ray Data

Let's start with a serial implementation:

```py
from time import time
import ray
ray.init(configure_logging=False)

intervals = ray.data.from_items([{"a": 1, "b": 100_000_000}])   # one item
intervals.show()

def slow(row):
    total = 0
    for i in range(row['a'], row['b']+1):
        if not "9" in str(i):
            total += 1.0 / i
    row['sum'] = total
    return row

start = time()
partial = intervals.map(slow)     # define the calculation
total = partial.take()[0]['sum']   # request the result => start the calculation on 1 CPU core
end = time()
print("Time in seconds:", round(end-start,3))
print(total)
```

I get the average runtime of 6.978 seconds. To parallelize this, you simply redefine `intervals`:

```py
intervals = ray.data.from_items([
    {"a": 1, "b": 50_000_000},
    {"a": 50_000_001, "b": 100_000_000},
])

start = time()
partial = intervals.map(slow)     # define the calculation
total = sum([p['sum'] for p in partial.take()])   # request the result => start the calculation on 2 CPU cores
end = time()
print("Time in seconds:", round(end-start,3))   # 4.322, 4.857, 4.782 and 3.852 3.812 3.823
print(total)
```

On 2 cores I get the average time of 3.765 seconds.

{{< question num=13 >}}
Parallelize this for 4 CPU cores. **Hint**: programmatically form a list of dictionaries, each containing
two key-value pairs (`a` and `b`) with the sub-intervals.
{{< /question >}}

<!-- Solution: -->
<!-- ```py -->
<!-- n = 100_000_000 -->
<!-- ncores = 2 -->
<!-- print(type(ncores)) -->
<!-- size = n // ncores -->
<!-- widths = [(i*size+1, i*size+size) for i in range(ncores)] -->
<!-- if widths[-1][1] < n: widths[-1] = (widths[-1][0],n) -->
<!-- intervals = ray.data.from_items([{'a':w[0], 'b':w[1]} for w in widths]) -->
<!-- ``` -->

On my laptop I am getting:

|   |   |   |   |   |
|---|---|---|---|---|
| ncores | 1 | 2 | 4 | 8 |
| wallclock runtime | 6.978 | 3.765 | 1.675 | 1.574 |

<!-- The entire code is: -->
<!-- ```py -->
<!-- import ray -->
<!-- from time import time -->

<!-- def slow(row): -->
<!--     total = 0 -->
<!--     for i in range(row['a'], row['b']+1): -->
<!--         if not "9" in str(i): -->
<!--             total += 1.0 / i -->
<!--     row['sum'] = total -->
<!--     return row -->

<!-- n = 100_000_000 -->
<!-- ncores = 2 -->
<!-- size = n // ncores -->
<!-- widths = [(i*size+1, i*size+size) for i in range(ncores)] -->
<!-- if widths[-1][1] < n: widths[-1] = (widths[-1][0],n) -->
<!-- intervals = ... -->

<!-- start = time() -->
<!-- partial = intervals.map(slow)     # define the calculation -->
<!-- total = sum([p['sum'] for p in partial.take()])   # request the result => start the calculation on 2 CPU cores -->
<!-- end = time() -->
<!-- print("Time in seconds:", round(end-start,3)) -->
<!-- print(total) -->
<!-- ``` -->










## Running Ray workflows on a single node

<!-- Launching a single-node ray cluster -->

Let's try running the last problem on the training cluster as a batch job. 

{{< question num=14 >}}
1. Save the entire Python code for the last problem as a file `rayPartialMap.py`
2. Modify the code to take <ncores> as a command-line argument:
```py
import sys
ncores = int(sys.argv[1])
```
and test it from the command line inside your interactive job
```sh
python rayPartialMap.py $SLURM_CPUS_PER_TASK
```
3. Quit the interactive job.
2. Back on the login node, write a Slurm job submission script, in which you launch `rayPartialMap.py` in the
   last line of the script.
3. Submit your job with `sbatch` to 1, 2, 4, 8 CPU cores, all on the same node.
{{< /question >}}

<!-- Solution: -->
<!-- ```sh -->
<!-- #!/bin/bash -->
<!-- #SBATCH --ntasks=4 --nodes=1 -->
<!-- #SBATCH --mem-per-cpu=1200 -->
<!-- #SBATCH --time=0:15:0 -->
<!-- # #SBATCH --account=... -->
<!-- cd ~/scratch/ray -->
<!-- module load StdEnv/2023 arrow/14.0.1 -->
<!-- source pythonhpc-env/bin/activate -->
<!-- python rayPartialMap.py $SLURM_CPUS_PER_TASK -->
<!-- ``` -->
<!-- ```sh -->
<!-- cass -->
<!-- cd ~/scratch/ray -->
<!-- sbatch submit.sh -->
<!-- ``` -->

Testing on the training cluster:

|   |   |   |   |   |
|---|---|---|---|---|
| ncores | 1 | 2 | 4 | 8 |
| wallclock runtime | 15.345 | 7.890 | 4.264 | 2.756 |

Testing on Cedar (averaged over 2 runs):

|   |   |   |   |   |   |   |
|---|---|---|---|---|---|---|
| ncores | 1 | 2 | 4 | 8 | 16 | 32 |
| wallclock runtime | 18.263 | 9.595 | 5.228 | 3.048 | 2.069 | 1.836 |

In our [Ray documentation](https://docs.alliancecan.ca/wiki/Ray) there are instructions for launching a
single-node Ray cluster. Strictly speaking, this is not necessary, as on a single machine (node) a call to
`ray.init()` will start a new Ray cluster and will automatically connect to it.



<!-- ```sh -->
<!-- export HEAD_NODE=$(hostname) -->
<!-- export RAY_PORT=34567 -->
<!-- ray start --head --node-ip-address=$HEAD_NODE --port=$RAY_PORT --num-cpus=$SLURM_CPUS_PER_TASK  --block & -->
<!-- sleep 10 -->
<!-- ``` -->
<!-- ```py -->
<!-- #import ray -->
<!-- #import os -->
<!-- #ray.init(address=f"{os.environ['HEAD_NODE']}:{os.environ['RAY_PORT']}",_node_ip_address=os.environ['HEAD_NODE']) -->
<!-- #print(ray.available_resources()) -->
<!-- ``` -->







## Running Ray workflows on multiple nodes

<!-- Launching a multi-node ray cluster -->

To run Ray workflows on multiple cluster nodes, you *must* create a virtual Ray cluster first. I copied this
example from our documentation at https://docs.alliancecan.ca/wiki/Ray#Multiple_Nodes. You can also read more
in the official documentation https://docs.ray.io/en/latest/cluster/getting-started.html.




abc

```sh
#!/bin/bash   # this is ray-example.sh
#SBATCH --nodes 2
#SBATCH --ntasks-per-node=1
#SBATCH --gpus-per-task=1
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=3600
#SBATCH --time=0:30:0

srun --nodes $SLURM_NNODES --ntasks $SLURM_NNODES createEnv.sh   # create a virtualenv, install Ray on all nodes
export HEAD_NODE=$(hostname)                          # head node's address
export RAY_PORT=34567                                 # a port to start Ray on the head node 

source $SLURM_TMPDIR/ENV/bin/activate

# 1. start Ray cluster head node
ray start --head --node-ip-address=$HEAD_NODE --port=$RAY_PORT --num-cpus=$SLURM_CPUS_PER_TASK --num-gpus=1 --block &
sleep 10

# 2. launch worker nodes
srun launchRay.sh &
ray_cluster_pid=$!   # get its process ID

#3. launch the calculation
python testRay.py

# 4. shut down Ray worker nodes
kill $ray_cluster_pid
```

This is `createEnv.sh`:

```sh
#!/bin/bash
module load python
virtualenv --no-download $SLURM_TMPDIR/ENV
source $SLURM_TMPDIR/ENV/bin/activate
pip install --upgrade pip --no-index
pip install ray --no-index
```

This is `launchRay.sh` to launch worker nodes on all the other nodes allocated by the job:

```sh
#!/bin/bash
source $SLURM_TMPDIR/ENV/bin/activate
module load gcc/9.3.0 arrow
if [[ "$SLURM_PROCID" -eq "0" ]]; then   # check MPI rank
        echo "Ray head node already started..."
        sleep 10
else
        ray start --address "${HEAD_NODE}:${RAY_PORT}" --num-cpus="${SLURM_CPUS_PER_TASK}" --num-gpus=1 --block
        sleep 5
        echo "ray worker started!"
fi
```

And this is the actual Python code `testRay.py` that connects to Ray cluster, checks the nodes and all
available CPUs and GPUs:

```py
import ray
import os
ray.init(address=f"{os.environ['HEAD_NODE']}:{os.environ['RAY_PORT']}",_node_ip_address=os.environ['HEAD_NODE'])
print("Nodes in the Ray cluster:")   # should see two nodes
print(ray.nodes())                   # their status should be 'Alive'
print(ray.available_resources())     # should see 12 CPUs and 2 GPUs over 2 Nodes
```












### Distributed dataset example

Run the following Python code line by line, while watching memory usage in a separate window with `htop
--filter "ray::IDLE"`:

```py
import numpy as np
import ray

ray.init(configure_logging=False)

b = ray.data.from_items([(800,800,800), (800,800,800)])   # 800**3 will take noticeable 3.81GB memory
b.show()

def initArray(row):
    nx, ny, nz = row['item']
    row['array'] = np.zeros((nx,ny,nz))
    return row

c = b.map(initArray)
c.show()
```

We'll see the two arrays being initialized in memory, on two processes, and then these blocks will be
automatically written to disk, and the memory usage goes back to zero. Ray writes ("spills") objects to
storage once they are no longer in use, as it tries to minimize the total number of "materialized" (in-memory)
blocks. On Linux and MacOS, the temporary spill folder is `/tmp/ray`, but you can customize its location
https://docs.ray.io/en/latest/ray-core/objects/object-spilling.html.

If you try to access these arrays, e.g.

```py
type(c.take()[0]['array'])   # numpy.ndarray
```

they will be loaded temporarily into memory, which you can monitor with `htop --filter "ray::IDLE"`.




<!-- Ray uses "streaming execution" 

<!-- - Ray data execution via lazy streaming https://docs.ray.io/en/latest/data/data-internals.html#streaming-execution -->

<!-- - How to distribute data by hand? -->







## Distributed data processing on Ray and I/O-bound workflows

<!-- - Reading and writing data in parallel. -->
<!-- - From 6 hours to 1.5 minutes using Ray, DynamoDB and Python -->
<!--   https://medium.com/@hagai.arad/from-6-hours-to-1-5-minutes-using-ray-dynamodb-and-python-efaa1e76f771 -->

### Pandas on Ray (Modin)

You can run many types of I/O workflows on top of Ray. One famous example is "Modin" (previously called Pandas
on Ray) which is a drop-in replacement for Pandas on top of Ray. We won't study here, but it will run all your
pandas workflows, and you don't need to modify your code, except importing the library, e.g.

```py
import pandas as pd
data = pd.read_csv("filename.csv", <other flags>)
```

will become

```py
import modin.pandas as pd
import ray
data = pd.read_csv("filename.csv", <other flags>)
```

Modin will run your workflows using Ray tasks on multiple cores, potentially speeding up large workflows. You
can find more information at https://github.com/modin-project/modin

Similarly, many other Ray Data read functions will read your data in parallel, distributing it to multiple
processes if necessary for larger processing:

```txt
>>> import ray
>>> ray.data.read_
ray.data.read_api                 ray.data.read_databricks_tables(  ray.data.read_mongo(              ray.data.read_sql(
ray.data.read_bigquery(           ray.data.read_datasource(         ray.data.read_numpy(              ray.data.read_text(
ray.data.read_binary_files(       ray.data.read_images(             ray.data.read_parquet(            ray.data.read_tfrecords(
ray.data.read_csv(                ray.data.read_json(               ray.data.read_parquet_bulk(       ray.data.read_webdataset(
```

<!-- - Mars (a tensor-based framework to scale NumPy, Pandas, and scikit-learn applications) can run on top of Ray, -->
<!-- - Dask tasks can run on top of Ray, -->






### Processing images

Here is a simple example of processing a directory with images with Ray Data. Suppose we have a $2874\times
2154$ image `tuscany.avif`. Let's crop 100 random $300\times 300$ images out of it:

```sh
ls -l tuscany.avif
mkdir -p images
width=$(identify tuscany.avif | awk '{print $3}' | awk -Fx '{print $1}')
height=$(identify tuscany.avif | awk '{print $3}' | awk -Fx '{print $2}')
for num in $(seq -w 00 99); do   # crop it into hundred 300x300 random images
    echo $num
    x=$(echo "scale=8; $RANDOM / 32767 * ($width-300)" | bc)   # $RANDOM goes from 0 to 32767
    x=$(echo $x | awk '{print int($1+0.5)}')
    y=$(echo "scale=8; $RANDOM / 32767 * ($height-300)" | bc)
    y=$(echo $y | awk '{print int($1+0.5)}')
	convert tuscany.avif -crop 300x300+$x+$y images/small$num.png
done
```

Now we will load these images into Ray Data. First, let's set `export RAY_DEDUP_LOGS=0`, and then do:

```py
import ray
ds = ray.data.read_images("images/")
ds   # 100 rows (one image per row) split into 16 blocks
ds.take(1)[0]                  # first image
type(ds.take(1)[0]["image"])   # stored as a numpy array
ds.take(1)[0]["image"].shape   # 300x300 and three channels (RGB)
ds.take(1)[0]["image"].max()   # 255 => they are stored as 8-bit images (0..255)
```

Let's print min/max values for all images:

```py
def minmax(row):
    print(row["image"].min(), row["image"].max())
    return row  # must return a dictionary, otherwise `map` will fail

b = ds.map(minmax)   # on output; we scheduled the calculation, but have not started it yet
b.materialize()      # force the calculation => now we see printouts from individual rows
```

Let's compute their negatives:

```py
def negate(row):
    return {'image': 255-row['image']}

negative = ds.map(negate)

negative.write_images("output", column='image')
```

In `output/` subdirectory you will find 100 negative images.


    





### Coding parallel I/O by hand


In Ray Data you can also write your own parallel I/O workflows by hand, defining functions to process rows
that will load certain data/file into a specific row, e.g. with something like:

```py
a = ray.data.from_items([
    {'file': '/path/to/file1'},
    {'file': '/path/to/file2'},
    {'file': '/path/to/file3'}
])
def readFileInParallel(row):
    <load data from file row['file']>
    <process these data>
    row['status'] = 'done'
    return row

b = a.map(readFileInParallel)
b.show()
```








### A problem without reduction

So far we've been working with problems where calculations from individual tasks add to form a single number
(sum of a slow series) -- this is called *reduction*. Let's now look at a problem without reduction, i.e. where
results stay distributed.

Let's compute a mathematical [Julia set](https://en.wikipedia.org/wiki/Julia_set) defined as a set of points
on the complex plane that remain bound under an infinite recursive transformation $z_{i+1}=f(z_i)$. For the
recursive function, we will use the traditional form $f(z)=z^2+c$, where $c$ is a complex constant. Here is
our algorithm:

1. pick a point $z_0\in\mathbb{C}$
1. compute iterations $z_{i+1}=z_i^2+c$ until $|z_i|>4$ (arbitrary fixed radius; here $c$ is a complex constant)
1. store the iteration number $\xi(z_0)$ at which $z_i$ reaches the circle $|z|=4$
1. limit max iterations at 255  
    4.1 if $\xi(z_0)\lt 255$, then $z_0$ is a stable point  
    4.2 the quicker a point diverges, the lower its $\xi(z_0)$ is
1. plot $\xi(z_0)$ for all $z_0$ in a rectangular region &nbsp; $-1.2<=\mathfrak{Re}(z_0)<=1.2$ &nbsp; and
   &nbsp; $-1.2<=\mathfrak{Im}(z_0)<=1.2$

We should get something conceptually similar to this figure (here $c = 0.355 + 0.355i$; we'll get drastically different
fractals for different values of $c$):

{{< figure src="/img/2000a.png" >}}

**Note**: you might want to try these values too:
- $c = 1.2e^{1.1πi}$ $~\Rightarrow~$ original textbook example
- $c = -0.4-0.59i$ and 1.5X zoom-out $~\Rightarrow~$ denser spirals
- $c = 1.34-0.45i$ and 1.8X zoom-out $~\Rightarrow~$ beans
- $c = 0.34-0.05i$ and 1.2X zoom-out $~\Rightarrow~$ connected spiral boots

As you must be accustomed by now, this calculation runs much faster when implemented in a compiled language. I
tried Julia (0.676s) and Chapel (0.489s), in both cases running the code on my laptop in serial (one CPU
core), both with exactly the same workflow and the same $2000^2$ image size.

Below is the serial implementation in Python -- let's save it as `juliaSetSerial.py`:

```py
from time import time
import numpy as np

nx = ny = 2000   # image size

def pixel(z):
    c = 0.355 + 0.355j
    for i in range(1, 256):
        z = z**2 + c
        if abs(z) >= 4:
            return i
    return 255

print("Computing Julia set ...")
stability = np.zeros((nx,ny), dtype=np.int32)

start = time()
for i in range(nx):
    for k in range(ny):
        point = 1.2*((2*(i+0.5)/nx-1) + (2*(k+0.5)/ny-1)*1j) # rescale to -1.2:1.2 in the complex plane
        stability[i,k] = pixel(point)

end = time()
print("Time in seconds:", round(end-start,3))

import netCDF4 as nc
f = nc.Dataset('test.nc', 'w', format='NETCDF4')
f.createDimension('x', nx)
f.createDimension('y', ny)
output = f.createVariable('stability', 'i4', ('x', 'y'))   # 4-byte integer
output[:,:] = stability
f.close()
```

Here we are timing purely the computational part, not saving the image to a NetCDF file. Let's run it and look
at the result in ParaView! When running this on my laptop, I get 9.097, 9.169, 9.119 seconds.

How would you parallelize this problem with `ray.data`? The main points to remember are:

1. You need to subdivide your problem into blocks -- let's do this in the `ny` (vertical) dimension.
1. You have to construct a dataset with each row containing inputs for a single task. These inputs will be the
   size of each image block and the offset (the starting row number of this block inside the image).
1. You need to write a function `computeStability(row)` that acts on each input row in the dataset. The result
   will be a NumPy array stored as a new entry `stability` in each row.
1. To write the final image to a NetCDF file, you need to merge these arrays into a single $2000\times 2000$
   array, and then write this square array to disk.

The solution is in the file `juliaSetParallel.py` on instructor's laptop. Here are the runtimes for
$2000\times 2000$ (averaged over three runs, in seconds):

|   |   |   |   |   |
|---|---|---|---|---|
| ncores | 1 | 2 | 4 | 8 |
| wallclock runtime | 9.220 | 4.869 | 2.846 | 2.210 |





















<!-- ```py -->
<!-- def add_dog_years(batch: Dict[str, np.ndarray]) -> Dict[str, np.ndarray]: -->
<!--     batch["age_in_dog_years"] = 7 * batch["age"] -->
<!--     return batch -->
<!-- do = ( -->
<!--     ray.data.from_items([ -->
<!--         {"name": "Luna", "age": 4}, -->
<!--         {"name": "Rory", "age": 14}, -->
<!--         {"name": "Scout", "age": 9}, -->
<!--     ]) -->
<!--     .map_batches(add_dog_years) -->
<!-- ) -->
<!-- do.show() -->




<!-- ds.map_batches(lambda batch: {"id": batch["id"] * 2})   -->


<!-- # Compute the maximum. -->

<!-- ds.max("id") -->
<!-- 999 -->

<!-- # Shuffle this dataset randomly. -->

<!-- ds.random_shuffle()   -->
<!-- RandomShuffle -->
<!-- +- Dataset(num_blocks=..., num_rows=1000, schema={id: int64}) -->

<!-- # Sort it back in order. -->

<!-- ds.sort("id")   -->
<!-- Sort -->
<!-- +- Dataset(num_blocks=..., num_rows=1000, schema={id: int64}) -->
<!-- ``` -->








<!-- n = 100_000_000 -->
<!-- @ray.remote -->
<!-- def slow(interval): -->
<!--     total = 0 -->
<!--     for i in range(interval[0],interval[1]+1): -->
<!--         if not "9" in str(i): -->
<!--             total += 1.0 / i -->
<!--     return total -->

<!-- ncores = psutil.cpu_count(logical=False) -->
<!-- size = n//ncores -->
<!-- intervals = [(i*size+1,(i+1)*size) for i in range(ncores)] -->
<!-- if n > intervals[-1][1]: -->
<!--     intervals[-1] = (intervals[-1][0], n) -->

<!-- # r = slow.remote((1, 12500000)) -->
<!-- # ray.get(r) -->

<!-- start = time() -->
<!-- r = [slow.remote(intervals[i]) for i in range(ncores)] -->
<!-- # ray.get(r)        # partial sums -->
<!-- total = sum(ray.get(r))   # total sum -->
<!-- end = time() -->
<!-- print("Time in seconds:", round(end-start,3))   # 3.584 3.904 3.754 -->
<!-- print(total) -->
<!-- ``` -->




<!-- {{< question num=xx >}} -->
<!-- {{< /question >}} -->




<!-- ```py -->
<!-- # start = time() -->
<!-- # ray.get([nap.remote() for i in range(4)]) -->
<!-- # end = time() -->
<!-- # print("Time in seconds:", round(end-start,3))   #  -->

<!-- # my_function.options(num_cpus=3).remote() -->

<!-- # @ray.remote(num_cpus=2) -->
<!-- # def nap(): -->
<!-- #     sleep(10) -->
<!-- #     print("almost done") -->
<!-- #     return ray.get_runtime_context().get_task_id() -->

<!-- # start = time() -->
<!-- # ray.get([nap.remote() for i in range(4)]) -->
<!-- # end = time() -->
<!-- # print("Time in seconds:", round(end-start,3))   #  -->
<!-- ``` -->
