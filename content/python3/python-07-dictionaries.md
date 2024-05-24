+++
title = "Dictionaries"
slug = "python-07-dictionaries"
weight = 7
+++

As you just saw, Python's **lists** are ordered sets of objects that you access via their
position/index. **Dictionaries** are unordered sets in which the objects are accessed via their keys. In other
words, dictionaries are unordered key-value pairs.

Consider two lists:

```py
names = ['Mary', 'John', 'Eric', 'Jeff', 'Anne']               # people
colours = ['orange', 'green', 'turquoise', 'burgundy', 'turquoise'] # and their respective favourite colours
```

There is nothing connecting these two lists, as far as figuring a person's favourite colour goes. You could do
something like this using indices:

```py
colours[names.index('Eric')]
```

but this is a little too convoluted ... A dictionary can help you connect the two datasets directly:

```py
fav = {}  # start with an empty dictionary
for name, colour in zip(names, colours):   # go through both lists simultaneously
    fav[name] = colour

fav   # {'Mary': 'orange', 'John': 'green', 'Eric': 'turquoise', 'Jeff': 'burgundy', 'Anne': 'turquoise'}

fav['John']      # returns 'green'
fav['Mary']      # returns 'orange'
for key in fav:
    print(key, fav[key])   # will print the names (keys) and the colours (values)
```

You can also cycle using `.keys()`, `.values()` and `.items()` methods:
```py
for k in fav.keys():
	print(k, fav[k])     # the same as above

for v in fav.values():
	print(v)              # cycle through the values

for i, j in fav.items():
	print(i,j)            # both the names and the colours
```




{{< question num=7.1 >}}
Merge two Python dictionaries
```sh
f1 = {'Mary': 'orange', 'John': 'green', 'Eric': 'turquoise'}
f2 = {'Jeff': 'burgundy', 'Anne': 'turquoise'}
```
into one. There are many solutions -- you can google this problem. Start with:
```py
fav = f1.copy()   # create a copy of f1
...
```
{{< /question >}}

<!-- **Solution 1:** -->
<!-- ```py -->
<!-- fav = f1.copy() -->
<!-- for k in f2: -->
<!--     fav[k] = f2[k] -->
<!-- ``` -->
<!-- **Solution 2:** -->
<!-- ```py -->
<!-- fav = f1.copy() -->
<!-- fav.update(f2) -->
<!-- print(fav) -->
<!-- ``` -->







There are other ways to organize the same information using dictionaries. For example, you can create a list
of dictionaries, one dictionary per person:

```py
names = ['Mary', 'John', 'Eric', 'Jeff', 'Anne']   # people names
colours = ['orange', 'green', 'turquoise', 'burgundy', 'turquoise'] # and their respective favourite colours
ages = [25, 23, 27, 32, 26]                        # let's include a third attribute

data = []
for name, colour, age in zip(names, colours, ages):   # go through both lists simultaneously
    data.append({'name': name, 'colour': colour, 'age': age})

person = data[0]
print(person)
print(person["name"], person["colour"])
```

The benefit of this approach is that you can have many more attributes per person than just `name` and
`colour`, and this is a very common way to organize structured and/or hierarchical data in Python. The
downside is that -- to search for by name -- you have to do it explicitly:

```py
for person in data:
    if person["name"]=="Jeff": print(person["colour"], person["age"])
```

or in a single line:

```py
[(person["colour"], person["age"]) for person in data if person["name"]=="Jeff"]
```

Finally, if you want **performance**, you might want to consider the following approach:

```sh
for i in filter(lambda x: x%2 == 0, range(1,11)):
    print(i)
```

Here we:
1. apply the ***lambda*** (anonymous) function &nbsp;`lambda x: x%2 == 0`&nbsp; to each item in `range(1,11)`;
   it returns True or False,
2. create an ***iterator*** yielding only those items in `range(1,11)` for which the lambda function produced
   True, and
3. cycle through this iterator.

Using this approach, we can create an iterator of all people matching a name:

```py
list(filter(lambda person: person["name"] == "Jeff", data))
```

<!-- Here we apply the anonymous "lambda" function `lambda person: person["name"] == "Jeff"` to each item in the -->
<!-- collection `data` and return an *iterator* yielding only those items in `data` that evaluate to `true` when -->
<!-- applying the lambda funtion. -->

Here we:
1. apply the lambda function `lambda person: person["name"] == "Jeff"` to each item in the list `data`; it
   returns True or False,
2. create an iterator yielding only those items in `data` for which the lambda function produced True, and
3. create a list from this iterator, in this case containing only one element.






{{< question num=7.2 >}}
Write a (one-line) code to filter out all people who's favourite colour is turquoise.
{{< /question >}}

<!-- ```py -->
<!-- list(filter(lambda person: person["colour"] == "turquoise", data)) -->
<!-- ``` -->








Going back to the basics, you can see where ***dictionary*** got its name:

```py
concepts = {}
concepts['list'] = 'an ordered collection of values'
concepts['dictionary'] = 'a collection of key-value pairs'
concepts
```

Let's modify values:

```py
concepts['list'] = concepts['list'] + ' - very simple'
concepts['dictionary'] = concepts['dictionary'] + ' - used widely in Python'
concepts
```

Deleting dictionary items:

```py
concepts.pop('list')   # remove the key 'list' and its value
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

## "Sorting" dictionary items

Let's go back to our original dictionary:

```py
fav = {'Mary': 'orange', 'John': 'green', 'Eric': 'turquoise', 'Jeff': 'burgundy', 'Anne': 'turquoise'}
sorted(fav)             # returns the sorted list of keys
sorted(fav.keys())      # the same
sorted(fav.values())    # returns the sorted list of values
for k in sorted(fav):
	print(k, fav[k])    # full dictionary sorted by key
```

{{< question num=7.3 >}}
Write a script to print the full dictionary (keys and values) sorted by the value.

**Hint**: create a list comprehension looping through all (key,value) pairs and then try sorting the result.
{{< /question >}}

<!-- ```py -->
<!-- sorted([(v,k) for (k,v) in fav.items()])   # notice the order-->
<!-- ``` -->

## Dictionary comprehensions

Similar to list comprehensions, we can form a dictionary comprehension:

```py
{k:'.'*k for k in range(10)}
{k:v*2 for (k,v) in zip(range(10),range(10))}
{j:c for j,c in enumerate('computer')}
```
