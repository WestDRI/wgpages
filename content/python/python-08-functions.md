+++
title = "Writing functions"
slug = "python-08-functions"
weight = 8
+++

* functions encapsulate complexity so that we can treat it as a single thing
* functions enable re-use: write one time, use many times

First define:

```py
def greeting():
    print('Hello!')
```

and then we can run it:

```py
greeting()
```

```py
def printDate(year, month, day):
    joined = str(year) + '/' + str(month) + '/' + str(day)
    print(joined)
printDate(1871, 3, 19)
```

Every function returns something, even if it's None.

```py
a = printDate(1871, 3, 19)
print(a)
```

How do we actually return a value from a function?

```py
def average(values):   # the argument is a list
    if len(values) == 0:
        return None
    return sum(values) / len(values)
print('average of actual values:', average([1, 3, 4]))
```

Here is an example of a more complex calendar function returning an alphabetical day of the week:

```sh
def dayOfTheWeek(year, month, day):
    import datetime
    week = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
    return week[datetime.datetime(year, month, day).weekday()]
dayOfTheWeek(2022, 11, 10)   # 'Thu'
```





{{< question num=5 >}}
Write a function to convert from Fahrenheit to Celsius, e.g. typing `celsius(77)` would produce 25.
<!-- ```sh -->
<!-- def celsius(f): -->
<!--     return (f-32)*5/9 -->
<!-- ``` -->
{{< /question >}}

{{< question num=6 >}}
Write a function to convert from Celsius to Fahrenheit. Test it with celcius(), e.g. by converting Fahrenheit → Celsius
→ Fahrenheit, or Celsius → Fahrenheit → Celsius.
{{< /question >}}

{{< question num=7 >}}
Now modify celsius() to take a list of Fahrenheit temperatures, e.g., `celcius([70,80,90,100])`, to return a list of
Celsius temperatures.
<!-- ```py -->
<!-- def celsius(fs): -->
<!--     c = [] -->
<!--     for f in fs: -->
<!--         c.append((f-32.)*5./9.) -->
<!--     return c -->
<!-- ``` -->
{{< /question >}}

Function arguments in Python can take default values becoming optional:

```py
def addNumber(a, b=1):
    return a+b
print(addNumber(5))
print(addNumber(5,3))
```

With several optional arguments it is important to be able to differentiate them:

```py
def modify(a, b=1, coef=1):
    return a*coef + b
print(modify(10))
print(modify(10, 1))   # which argument did we add?
print(modify(10, coef=2))
print(modify(10, coef=2, b=5))
```

Any complex python function will have many optional arguments, for example:

```py
?print
```
