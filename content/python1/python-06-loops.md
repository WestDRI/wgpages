+++
title = "Loops"
slug = "python-06-loops"
weight = 6
+++

<!-- # For Loops -->

*For* loops are very common in Python and are similar to *for* in other languages, but one nice twist with Python is
that you can iterate over any collection, e.g., a list, a character string, etc.

```py
for number in [2, 3, 5]:    # number is the loop variable; [...] is a collection
    print(number)          # Python uses indentation to show the body of the loop
```

This is equivalent to:
```py
print(2)
print(3)
print(5)
```

What will this do:
```py
for number in [2, 3, 5]:
    print(number)
print(number)
```

* the loop variable could be called anything
* the body of a loop can contain many statements
* use range to iterate over a sequence of numbers

```py
for i in 'hello':
    print(i)
```

```py
for i in range(0,3):
    print(i)
```
	
Let's sum numbers 1 to 10:

```py
total = 0
for number in range(10):
    total = total + (number + 1)   # what's the other way to sum numbers 1 to 10? how about range(1,11)?
print(total)
```

{{< question num=3a >}}
Write a Python code to revert a string, e.g. 'computer' should become 'retupmoc'.
{{< /question >}}

<!-- **Solution 1:** -->
<!-- ```py -->
<!-- n = '' -->
<!-- for i in 'computer': -->
<!--     n = i + n -->
<!-- print(n) -->
<!-- ``` -->
<!-- **Solution 2:** -->
<!-- ```py -->
<!-- a = list('computer') -->
<!-- a.reverse() -->
<!-- ''.join(a)      # convert the list to a string -->
<!-- help(''.join)   # concatenate all strings in the iterable with the separator from the original string -->
<!-- ``` -->
<!-- **Solution 3:** -->
<!-- ```py -->
<!-- 'computer'[::-1] -->
<!-- ``` -->

{{< question num=3b >}}
Print a difference between two lists, e.g. [1, 2, 3, 4] and [1, 2, 5].
{{< /question >}}

{{< question num=3c >}}
Write a script to get the frequency of the elements in the list `a = [77, 9, 23, 67, 73, 21, 23, 9]`. You can google
this problem :)
{{< /question >}}

<!-- **Solution 1:** -->
<!-- ```py -->
<!-- a = [77, 9, 23, 67, 73, 21, 23, 9] -->
<!-- a.count(77)        # prints 1 -->
<!-- a.count(9)         # prints 2 -->
<!-- for i in a: -->
<!--     a.count(i)    # counts the frequency of 'i' in list 'a' -->
<!-- ``` -->
<!-- **Solution 2:** -->
<!-- ```py -->
<!-- a = [77, 9, 23, 67, 73, 21, 23, 9] -->
<!-- for i in set(a): -->
<!--     print(i, "is seen", a.count(i))   # no redundant output -->
<!-- ``` -->
<!-- **Solution 3:** -->
<!-- ```py -->
<!-- a = [77, 9, 23, 67, 73, 21, 23, 9] -->
<!-- import collections -->
<!-- print(collections.Counter(a)) -->

## While loops

Since we talk about loops, we should also briefly mention *while* loops, e.g.

```py
x = 2
while x > 1.:
    x /= 1.1
    print(x)
```

## More on lists in loops

You can also form a *zip* object of tuples from two lists of the same length:

```py
for i, j in zip(a,b):
    print(i,j)
```

And you can create an *enumerate* object from a list:

```py
for i, j in enumerate(b):    # creates a list of tuples with an iterator as the first element
    print(i,j)
```

<!-- **Exercise:** Write a script to sort a list in increasing order by the last element in each tuple, e.g., -->
<!-- input = [(2, 5), (1, 2), (4, 4), (2, 3), (2, 1)] should result in -->
<!-- [(2, 1), (1, 2), (2, 3), (4, 4), (2, 5)]. -->

## List comprehensions

It's a compact way to create new lists based on existing lists/collections. Let's list squares of numbers
from 1 to 10:

```py
[x**2 for x in range(1,11)]
```

Of these, list only odd squares:

```py
[x**2 for x in range(1,11) if x%2==1]
```

You can also use list comprehensions to combine information from two or more lists:

```py
week = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
weekend = ['Sat', 'Sun']
print([day for day in week])                         # the entire week
print([day for day in week if day not in weekend])   # only the weekdays
print([day for day in week if day in weekend])       # in both lists
```

The syntax is:

```py
[something(i) for i in list1 if i [not] in list2 if i [not] in list3 ...]
```

{{< question num=4a >}}
Write a one-line code to sum up the squares of numbers from 1 to 100.
{{< /question >}}

{{< question num=4b >}}
Write a script to build a list of words that are shorter than `n` from a given list of words
`['red', 'green', 'white', 'black', 'pink', 'yellow']`.
{{< /question >}}
