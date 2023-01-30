+++
title = "Dictionaries"
slug = "python-07-dictionaries"
weight = 7
+++

**Lists** in Python are ordered sets of objects that you access via their position/index. **Dictionaries** are unordered
sets in which the objects are accessed via their keys. In other words, dictionaries are unordered key-value pairs.

```py
favs = {'mary': 'orange', 'john': 'green', 'eric': 'blue'}
favs
favs['john']      # returns 'green'
favs['mary']      # returns 'orange'
list(favs.values()).index('blue')     # will return the index of the first value 'blue'
```

```py
for key in favs:
	print(key)            # will print the names (keys)
	print(favs[key])      # will print the colours (values)
for k in favs.keys():
	print(k, favs[k])     # the same as above
for v in favs.values():
	print(v)              # cycle through the values
for i, j in favs.items():
	print(i,j)            # both the names and the colours
```

Now let's see how to add items to a dictionary:

```py
concepts = {}
concepts['list'] = 'an ordered collection of values'
concepts['dictionary'] = 'a collection of key-value pairs'
concepts
```

Let's modify values:

```py
concepts['list'] = 'simple: ' + concepts['list']
concepts['dictionary'] = 'complex: ' + concepts['dictionary']
concepts
```

Deleting dictionary items:

```py
del concepts['list']       # remove the key 'list' and its value
```

Values can also be numerical:

```py
grades = {}
grades['mary'] = 5
grades['john'] = 4.5
grades
```

And so can be the keys:

```py
grades[1] = 2
grades
```

Sorting dictionary items:

```py
favs = {'mary': 'orange', 'john': 'green', 'eric': 'blue', 'jane': 'orange'}
sorted(favs)             # returns the sorted list of keys
sorted(favs.keys())      # the same
for k in sorted(favs):
	print(k, favs[k])         # full dictionary sorted by key
sorted(favs.values())         # returns the sorted list of values
```

{{< question num=4c >}}
Write a script to print the full dictionary sorted by the value.

**Hint**: create a list comprehension looping through all (key,value) pairs and then try sorting the result.
{{< /question >}}

<!-- ```py -->
<!-- sorted([(v,k) for (k,v) in favs.items()])   # notice the order-->
<!-- ``` -->

Similar to list comprehensions, we can form a dictionary comprehension:

```py
{k:'.'*k for k in range(10)}
{k:v*2 for (k,v) in zip(range(10),range(10))}
{j:c for j,c in enumerate('computer')}
```
