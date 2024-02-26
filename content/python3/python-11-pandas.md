+++
title = "Pandas dataframes"
slug = "python-11-pandas"
weight = 11
+++

## Reading CSV tabular data

Pandas is a widely-used Python library for working with tabular data, borrows heavily from R's dataframes,
built on top of NumPy. Let's try reading some public-domain data about Jeopardy questions with `pandas` (31MB
file, so it might take a while):

```py
import pandas as pd
data = pd.read_csv("https://raw.githubusercontent.com/razoumov/publish/master/jeopardy.csv")
data.shape      # shape is a member variable inside data => 216930 rows, 7 columns

print(data)
data            # this prints out the table nicely in Jupyter Notebook!

data.info()     # info is a *member method inside data*
data.head(10)   # first 10 rows
data.tail()     # last 5 rows
data.columns    # names of the columns
```

Let's download the same online data as a file into our current directory:

```py
!wget https://raw.githubusercontent.com/razoumov/publish/master/jeopardy.csv
```

This time let's read from this file naming the rows by their respective answer:

```sh
data = pd.read_csv("jeopardy.csv", index_col='Answer')
data
data.shape   # one fewer column
data.columns
data.index   # row names
```

## Subsetting

Pandas lets you subset elements using either their numerical indices or their row/column names. Long time ago
Pandas used to have a single function to do both. Now there are two separate functions, `.iloc()` and
`.loc()`. Let's print one element:

```py
data.iloc[0,5]                                    # using row/column numbers
data.loc["Sinking of the Titanic", "Question"]    # using row/column names
```

Printing a row:

```py
data.loc['Sinking of the Titanic',:]   # usual Python's slicing notation - show all columns in that row
data.loc['Sinking of the Titanic']     # exactly the same
data.loc['Sinking of the Titanic',]    # exactly the same
```

Printing a column:

```py
data.loc[:,'Category']   # show all rows in that column
data['Category']         # exactly the same; single index refers to columns
data.Category            # most compact notation; does not work with numerical-only names
```

Printing a range:
```py
data.columns
data.loc['Copernicus', 'Air Date':'Category']     # why so many lines?
data.loc['Copernicus', ['Air Date','Question']]   # print two selected columns
```

```py
data['Category']              # many different categories, truncated output ...
list(data['Category'])        # print all of categories
data['Category']=='HISTORY'   # return either True or False for each row
```

You can use the last expression as a mask to return only those rows where `Category` is "HISTORY":

```py
data.loc[data['Category']=='HISTORY']
data.loc[data['Category']=='HISTORY'].shape   # 349 matches
data.loc[data['Category']=='HISTORY'].to_csv("history.csv")   # write to a file
```

Let's take a look at the value column:

```py
list(data['Value'])   # some of these contain nan

data.shape    # original table: 216,930 rows
clean = data.dropna()
clean.shape   # after dropping rows with missing values: 213,144 rows

clean['Value']   # one column
clean['Value'].apply(lambda x: type(x))   # show the type of each element (fixed for each column)
values = clean['Value'].apply(lambda x: int(x.replace('$','').replace(',','')))
mask = values>1000
clean[mask]    # only show rows with Value > $1000
```

Let's replace the "Values" column in-place:

```py
clean.loc[:,'Value'] = clean['Value'].apply(lambda x: int(x.replace('$','').replace(',','')))
clean
```





{{< question num=11.1 >}}
Explain in simple terms what `idxmin()` and `idxmax()` do in the short program below. When would you use these
methods?
```py
clean.idxmin()
clean.idxmax()
```
**Hint**: Try running these:
```py
clean.loc["Freddie And The Dreamers"]
clean.loc["Suriname"]
```
or use help pages. This simpler example could also help:
```py
col1 = ["1","a","A"]
col2 = ["4","b","B"]
data = pd.DataFrame({'a': col1, 'b': col2})   # dataframe from a dictionary
data.idxmin()
```
{{< /question >}}

<!-- These return the row names with min and max in each column. -->






Finally, let's check what time period is covered by these data:

```py
data["Air Date"]
data["Air Date"][0][-2:]   # first row, last two digits is the year
year = data["Air Date"].apply(lambda x: x[-2:])   # last two digits of the year from all rows
year.min(); year.max()     # '00' and '99' - not very informative, wraps at the turn of the century

for y in range(100):
    twoDigits = str(y).zfill(2)
    print(twoDigits, sum(year==twoDigits))
```

This shows that this table covers years from 1984 to 2012.







## Creating a dataframe from scratch

How do you create a dataframe from scratch? There are many ways; perhaps, the easiest is by defining columns
(as you saw in the last exercise):

```py
col1 = [1,2,3]
col2 = [4,5,6]
pd.DataFrame({'a': col1, 'b': col2})       # dataframe from a dictionary
```

We can index (assign names to) the rows with this syntax:

```py
pd.DataFrame({'a': col1, 'b': col2}, index=['a1','a2','a3'])
```






## Three solutions to a classification problem

<!-- idea from https://youtu.be/SAFmrTnEHLg -->

Fizz buzz is a children's game to practice divisions. Players take turn counting out loud while replacing:
- any number divisible by 3 with the word "Fizz",
- any number divisible by 5 with the word "Buzz",
- any number divisible by both 3 and 5 with the word "FizzBuzz".

Let's implement this in pandas! First, create a simple dataframe from scratch:

```py
import pandas as pd
df = pd.DataFrame()
size = 10_000
df['number'] = np.arange(1, size+1)
```

Define for pretty printing:

```py
def show(frame):
    print(df.tail(15).to_string(index=False))   # print last 15 rows without the row index

show(df)
```

Let's built a new column `response` containing either *"Fizz"* or *"Buzz"* or *"FizzBuzz"* or the original
number, based on the `number` value in that row. Let's start by processing a row:

```py
def count(row):
    if (row['number'] % 3 == 0) and (row['number'] % 5 == 0):
        return 'FizzBuzz'
    elif row['number'] % 3 == 0:
        return 'Fizz'
    elif row['number'] % 5 == 0:
      return 'Buzz'
    else:
      return str(row['number'])
```

(1) We can apply this function to each row in a loop:

```py
%%timeit
for index, row in df.iterrows():
    df.loc[index, 'response'] = count(row)
```
413 ms ± 11.1 ms per loop (mean ± std. dev. of 7 runs, 1 loop each)
```py
show(df)
```

(2) We can use `df.apply()` to apply this function to each row:

```py
%%timeit
df['response'] = df.apply(count, axis=1)
```
69.1 ms ± 380 µs per loop (mean ± std. dev. of 7 runs, 10 loops each)
```py
show(df)
```

(3) Or we could use a mask to only assign correct responses to the corresponding rows:

```py
%%timeit
df['response'] = df['number'].astype(str)
df.loc[df['number'] % 3==0, 'response'] = 'Fizz'
df.loc[df['number'] % 5==0, 'response'] = 'Buzz'
df.loc[(df['number'] % 3==0) & (df['number'] % 5==0), 'response'] = 'FizzBuzz'
```
718 µs ± 10.6 µs per loop (mean ± std. dev. of 7 runs, 1,000 loops each)
```py
show(df)
```
