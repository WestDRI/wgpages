+++
title = "Lists"
slug = "python-05-lists"
weight = 5
+++

Python has a number of built-in composite data structures: tuples, lists, sets, dictionaries. Here we take a
look at *lists* and *dictionaries*.

A *list* stores many values in a single structure.

```py
events = [267, 1332, 1772, 1994, 493, 1373, 1044, 156, 1515, 1788]  # array of years
print('events:', events)
print('length:', len(events))
```

```py
print('first item of events is', events[0])   # indexing starts witgh 0
events[2] = 1773                              # individual elements are mutable
print('events is now:', events)
```

```py
events.append(1239)   # append at the end
events.append(606)    # append at the end
print('events is now:', events)
events.pop(4)         # remove element #4
print('events is now:', events)
events.remove(267)    # remove by value (first occurrence)
```

```py
a = []   # start with an empty list
a.append('Vancouver')
a.append('Toronto')
a.append('Kelowna')
print(a)
```

```py
a[3]   # will give an error message (past the end of the array)
a[-1]   # display the last element; what's the other way?
a[:]    # will display all elements
a[1:]   # all elements starting from #1
a[:1]   # ending with but not including #1
```

Lists can be heterogeneous and nested:

```py
a = [11, 21., 3.5]
b = ['Mercury', 'Venus', 'Earth']
c = 'hello'
nestedList = [a, b, c]
print(nestedList)
```

{{< question num="2: double subsetting" >}}
How would you extract element "Earth" from `nestedList`?
{{< /question >}}

You can search inside a list:

```py
'Venus' in b                   # returns True
'Pluto' in b                   # returns False
b.index('Venus')               # returns 1 (positional index)
nestedList[1].index('Venus')   # same
```

And you sort lists alphabetically:

```py
b.sort()
b             # returns ['Earth', 'Mercury', 'Venus']
```

{{< question num=3 >}}
Write a script to find the second largest number in the list [77,9,23,67,73,21].
{{< /question >}}

<!-- ```py -->
<!-- a = [77, 9, 23, 67, 73, 21] -->
<!-- a.sort(); a[-2]                    # should print 73 -->
<!-- a.sort(reverse=True); a[1]         # should print 73 -->
<!-- sorted(a)[-2]                      # should print 73 -->
<!-- ``` -->
