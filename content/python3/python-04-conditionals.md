+++
title = "Conditionals"
slug = "python-04-conditionals"
weight = 4
+++

Python implements conditionals via `if`, `elif` (short for "else if") and `else`. Use an `if` statement to
control whether some block of code is executed or not. Let's consider the boundary between the Antiquity and
the Middle Ages:

```py
year = 830
if year > 476:
    print('year', year, 'falls into the medieval era')
```

Let's modify the year:

```py
year = 205
if year > 476:
    print('year', year, 'falls into the medieval era')
```

Add an `else` statement:

```py
year = 205
if year > 476:
    print('year', year, 'falls into the medieval era')
else:
    print('year', year, 'falls into the classical antiquity period')
```

Add an `elif` statement:

```py
year = 1500
if year > 1450:
    print('year', year, 'falls into the modern era')
elif year > 476:
    print('year', year, 'falls into the medieval era')
else:
    print('year', year, 'falls into the classical antiquity period')
```

<!-- ```py -->
<!-- x = 5 -->
<!-- if x > 0: -->
<!--     print(x, 'is positive') -->
<!-- elif x < 0: -->
<!--     print(x, 'is negative') -->
<!-- else: -->
<!--     print(x, 'is zero') -->
<!-- ``` -->

What is the problem with the following code?

```py
grade = 85
if grade >= 70:
    print('grade is C')
elif grade >= 80:
    print('grade is B')
elif grade >= 90:
    print('grade is A')
```
