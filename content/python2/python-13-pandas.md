+++
title = "Dataframes"
slug = "python-13-pandas"
weight = 4
+++

# Part 1: Pandas dataframes

## Reading tabular data

In this section we will be reading datasets from `data-python`. If you have not downloaded it in the previous
section, in the terminal run:

```sh
wget http://bit.ly/pythfiles -O pfiles.zip
unzip pfiles.zip && rm pfiles.zip        # this should unpack into the directory data-python/
```

<!-- You can now close the terminal panel. Let's switch back to our Python notebook and check our location: -->

<!-- ```py -->
<!-- %pwd       # run `pwd` bash command -->
<!-- %ls        # make sure you see data-python/ -->
<!-- ``` -->

Pandas is a widely-used Python library for working with tabular data. It borrows heavily from R's dataframes
and is built on top of NumPy. We will be reading the data we downloaded a minute ago into a pandas dataframe:

```py
import pandas as pd
data = pd.read_csv('data-python/gapminder_gdp_oceania.csv')
print(data)
data   # this prints out the table nicely in Jupyter Notebook!
```

```py
data.shape    # shape is a *member variable inside data*
data.info()   # info is a *member method inside data*
```



{{< question num=13.1 >}}
Try reading a much bigger Jeopardy dataset from
`https://raw.githubusercontent.com/razoumov/publish/master/jeopardy.csv`. There are two ways to do this:
1. you can first download it using `wget` and then read a local file, or
1. you can try doing this without downloading the file.

How many lines and columns does it have? What are the column names?
{{< /question >}}

> Use `dir(data)` to list all dataframe's variables and methods. Then call one of them without `()`, and if
> it's a method it'll tell you, so you'll need to use `()`.

You can think of rows as observations, and columns as the observed variables. You can add new observations at
any time.

Currently the rows are indexed by number. Let's index by country:

```py
data = pd.read_csv('data-python/gapminder_gdp_oceania.csv', index_col='country')
data
data.shape        # now 12 columns
data.info()       # it's a dataframe! show row/column names, precision, memory usage
print(data.columns)   # list all the columns
print(data.T)     # this will transpose the dataframe; curously this is a variable
data.describe()   # will print some statistics of numerical columns (very useful for 1000s of rows!)
```

{{< question num=13.2 >}}
Quick question: how would you list all country names?

**Hint**: try data.T.columns
{{< /question >}}

{{< question num=13.3 >}}
Read the data in `gapminder_gdp_americas.csv` (which should be in the same directory as
`gapminder_gdp_oceania.csv`) into a variable called `americas` and display its summary statistics.
{{< /question >}}

{{< question num=13.4 >}}
Write a command to display the first three rows of the `americas` data frame. What about the last three
columns of this data frame?
{{< /question >}}

{{< question num=13.5 >}}
The data for your current project is stored in a file called `microbes.csv`, which is located in a folder
called `field_data`. You are doing analysis in a notebook called `analysis.ipynb` in a sibling folder called
`thesis`:
```txt
your_home_directory
├── fieldData
│   └── microbes.csv
└── thesis
    └── analysis.ipynb
```
What value(s) should you pass to `read_csv()` to read `microbes.csv` in `analysis.ipynb`?
{{< /question >}}

{{< question num=13.6 >}}
As well as the `pd.read_csv()` function for reading data from a file, Pandas provides a `to_csv()` function to
write data frames to files. Applying what you've learned about reading from files, write one of your data
frames to a file called `processed.csv`. You can use help to get information on how to use `to_csv()`.
{{< /question >}}

## Subsetting

```py
data = pd.read_csv('data-python/gapminder_gdp_europe.csv', index_col='country')
data.head()
```

Let's rename the first column:

```py
data.rename(columns={'gdpPercap_1952': 'y1952'})   # this renames only one but does not change `data`
```

**Note**: we could also name the column '1952', but some Pandas operations don't work with purely numerical column
  names.

Let's go through all columns and assign the new names:

```py
for col in data.columns:
    print(col, col[-4:])
    data = data.rename(columns={col: 'y'+col[-4:]})

data
```

Pandas lets you subset elements using either their numerical indices or their row/column names. Long time ago Pandas
used to have a single function to do both. Now there are two separate functions, `iloc()` and `loc()`. Let's print one
element:

```py
data.iloc[0,0]                # the very first element by position
data.loc['Albania','y1952']   # exactly the same; the very first element by label
```

Printing a row:

```py
data.loc['Albania',:]   # usual Python's slicing notation - show all columns in that row
data.loc['Albania']     # exactly the same
data.loc['Albania',]    # exactly the same
```

Printing a column:

```py
data.loc[:,'y1952']   # show all rows in that column
data['y1952']         # exactly the same; single index refers to columns
data.y1952            # most compact notation; does not work with numerical-only names
```

Printing a range:

```py
data.loc['Italy':'Poland','y1952':'y1967']   # select multiple rows/columns
data.iloc[0:2,0:3]
```

Result of slicing can be used in further operations:

```py
data.loc['Italy':'Poland','y1952':'y1967'].max()   # max for each column
data.loc['Italy':'Poland','y1952':'y1967'].min()   # min for each column
```

Use comparisons to select data based on value:

```py
subset = data.loc['Italy':'Poland', 'y1962':'y1972']
print(subset)
print(subset > 1e4)
```

Use a Boolean mask to print values (meeting the condition) or NaN (not meeting the condition):

```py
mask = (subset > 1e4)
print(mask)
print(subset[mask])   # will print numerical values only if the corresponding elements in mask are True
```

NaN's are ignored by statistical operations which is handy:

```py
subset[mask].describe()
subset[mask].max()
```

{{< question num=13.7 >}}
Assume Pandas has been imported into your notebook and the Gapminder GDP data for Europe has been loaded:
```py
df = pd.read_csv('data-python/gapminder_gdp_europe.csv', index_col='country')
```
Write an expression to find the per capita GDP of Serbia in 2007.
{{< /question >}}

{{< question num=13.8 >}}
Explain what each line in the following short program does, e.g. what is in the variables `first`, `second`, ...:
```py
first = pd.read_csv('data-python/gapminder_all.csv', index_col='country')
second = first[first['continent'] == 'Americas']
third = second.drop('Puerto Rico')
fourth = third.drop('continent', axis = 1)
fourth.to_csv('result.csv')
{{< /question >}}

{{< question num=13.9 >}}
Explain in simple terms what `idxmin()` and `idxmax()` do in the short program below. When would you use these methods?
```py
data = pd.read_csv('data-python/gapminder_gdp_europe.csv', index_col='country')
print(data.idxmin())
print(data.idxmax())
```
{{< /question >}}

How do you create a dataframe from scratch? There are many ways; perhaps, the easiest is by defining columns:

```py
col1 = [1,2,3]
col2 = [4,5,6]
pd.DataFrame({'a': col1, 'b': col2})       # dataframe from a dictionary
```

We can index (assign names to) the rows with this syntax:

```py
pd.DataFrame({'a': col1, 'b': col2}, index=['a1','a2','a3'])
```







## Example with a larger dataframe

Let's try reading some public-domain data about Jeopardy questions with `pandas` (31MB file, so it might take a while):

```py
import pandas as pd
data = pd.read_csv("https://raw.githubusercontent.com/razoumov/publish/master/jeopardy.csv")
data.shape      # 216930 rows, 7 columns
data.head(10)   # first 10 rows
data.tail()     # last 5 rows
data.iloc[2:5]  # rows 2-4
data.columns    # names of the columns

data['Category']
data['Category']=='HISTORY'
data.loc[data['Category']=='HISTORY'].shape   # 349 matches
data.loc[data['Category']=='HISTORY'].to_csv("history.csv")   # write to a file
```

Let's check what time period is covered by these data:

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









## Three solutions to a classification problem

<!-- idea from https://youtu.be/SAFmrTnEHLg -->

In this section we will see that there are different techniques to process a Pandas dataframe, and some of
them are more efficient than others. However, first we need to learn how to time execution of a block of
Python code:

1. Inside a Jupyter notebook, you can use `%%timeit` to time an entire cell.
1. Inside your code, you can call `time.time()` function:
```py
import time
start = time.time()
...
end = time.time()
print("Time in seconds:", round(end-start,3))
```

Now, let's go to our computational problem. "Fizz buzz" is a children's game to practice divisions. Players
take turn counting out loud while replacing:
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
number, based on the `number` value in that row. We start by processing a row:

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

Here is how you would use this function:

```py
print(df.iloc[2])
print(count(df.iloc[2]))
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











## Looping over data sets

Let's say we want to read several files in `data-python/`. We can use **for** to loop through their list:

```py
for name in ['africa.csv', 'asia.csv']:
    data = pd.read_csv('data-python/gapminder_gdp_'+name, index_col='country')
    print(name+'\n', data.min(), sep='')   # print min for each column
```

If we have many (10s or 100s) files, we want to specify them with a pattern:

```py
from glob import glob
print('all csv files in data-python:', glob('data-python/*.csv'))    # returns a list
print('all text files in data-python:', glob('data-python/*.txt'))   # empty list
list = glob('data-python/*.csv')
len(list)
```

```py
for filename in glob('data-python/gapminder*.csv'):
    data = pd.read_csv(filename)
    print(filename, data.gdpPercap_1952.min())
```

{{< question num=`13.10` >}}
Which of these files is not matched by the expression `glob('data-python/*as*.csv')`?
```txt
A. data-python/gapminder_gdp_africa.csv
B. data-python/gapminder_gdp_americas.csv
C. data-python/gapminder_gdp_asia.csv
D. 1 and 2 are not matched
```
{{< /question >}}

{{< question num=13.11 >}}
Modify this program so that it prints the number of records in the file that has the fewest records.
```py
fewest = ____
for filename in glob('data-python/*.csv'):
    fewest = ____
print('smallest file has', fewest, 'records')
```
{{< /question >}}

<!-- ```py -->
<!-- fewest = 1e9 -->
<!-- for filename in glob('data-python/*.csv'): -->
<!--     print(pd.read_csv(filename).shape[0]) -->
<!--     fewest = min(fewest, pd.read_csv(filename).shape[0]) -->
<!-- print('smallest file has', fewest, 'records') -->
<!-- ``` -->

<!-- **[Exercise](./solar.md):** add a curve for New Zealand. -->
<!-- **[Exercise](./solas.md):** do a scatter plot of Australia vs. New Zealand. -->
<!-- **[Quiz 21](./solat.md):** (more difficult) plot the average GDP vs. time in each region (each file) -->





# Part 2: Polars dataframes

{{<a "https://mint.westdri.ca/python/hpc_polars" "External link">}}
