+++
title = "Pandas dataframes"
slug = "python-13-pandas"
weight = 13
+++

## Reading tabular data into dataframes

In this section we will be reading datasets from `data-python`. If you have not downloaded it in the previous
section, open a terminal and type:

```sh
wget http://bit.ly/pythfiles -O pfiles.zip
unzip pfiles.zip && rm pfiles.zip        # this should unpack into the directory data-python/
```

You can now close the terminal panel. Let's switch back to our Python notebook and check our location:

```py
%pwd       # run `pwd` bash command
%ls        # make sure you see data-python/
```

Pandas is a widely-used Python library for working with tabular data, borrows heavily from R's dataframes, built on top
of numpy. We will be reading the data we downloaded a minute ago into a pandas dataframe:

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



{{< question num=11f >}}
Try reading a much bigger Jeopardy dataset. First, download it with:
```sh
wget https://bit.ly/3kcsQIe -O jeopardy.csv.gz && gunzip jeopardy.csv.gz
```
and then read it into a dataframe `game`. How many lines and columns does it have?
{{< /question >}}



Use dir(data) to list all member variables and methods. Then call one of them without `()`, and if it's a
method it'll tell you, so you'll need to use `()`.

Rows are observations, and columns are the observed variables. You can add new observations at any time.

Currently the rows are indexed by number. Let's index by country:

```py
data = pd.read_csv('data-python/gapminder_gdp_oceania.csv', index_col='country')
data
data.shape     # now 12 columns
data.info()    # it's a dataframe! show row/column names, precision, memory usage
print(data.columns)   # will list all the columns
print(data.T)   # this will transpose the dataframe; curously this is a variable
data.describe()   # will print some statistics of numerical columns (very useful for 1000s of rows!)
```

{{< question num=12a >}}
Quick question: how would you list all country names?

**Hint**: try data.T.columns
{{< /question >}}

{{< question num=12b >}}
Read the data in `gapminder_gdp_americas.csv` (which should be in the same directory as `gapminder_gdp_oceania.csv`)
into a variable called `americas` and display its summary statistics.
{{< /question >}}

{{< question num=13 >}}
Write a command to display the first three rows of the `americas` data frame. What about the last three columns of this
data frame?
{{< /question >}}

{{< question num=14 >}}
The data for your current project is stored in a file called `microbes.csv`, which is located in a folder called
`field_data`. You are doing analysis in a notebook called `analysis.ipynb` in a sibling folder called `thesis`:
```txt
your_home_directory/
+-- fieldData/
  +-- microbes.csv
+-- thesis/
  +-- analysis.ipynb
```
What value(s) should you pass to `read_csv()` to read `microbes.csv` in `analysis.ipynb`?
{{< /question >}}

{{< question num=15 >}}
As well as the `read_csv()` function for reading data from a file, Pandas provides a `to_csv()` function to write data
frames to files. Applying what you've learned about reading from files, write one of your data frames to a file called
`processed.csv`. You can use help to get information on how to use `to_csv()`.
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
data.iloc[0,0]               # the very first element by position
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

{{< question num=16 >}}
Assume Pandas has been imported into your notebook and the Gapminder GDP data for Europe has been loaded:
```py
df = pd.read_csv('data-python/gapminder_gdp_europe.csv', index_col='country')
```
Write an expression to find the per capita GDP of Serbia in 2007.
{{< /question >}}

{{< question num=17 >}}
Explain what each line in the following short program does, e.g. what is in the variables `first`, `second`, ...:
```py
first = pd.read_csv('data-python/gapminder_all.csv', index_col='country')
second = first[first['continent'] == 'Americas']
third = second.drop('Puerto Rico')
fourth = third.drop('continent', axis = 1)
fourth.to_csv('result.csv')
{{< /question >}}

{{< question num=18 >}}
Explain in simple terms what `idxmin()` and `idxmax()` do in the short program below. When would you use these methods?
```py
data = pd.read_csv('data-python/gapminder_gdp_europe.csv', index_col='country')
print(data.idxmin())
print(data.idxmax())
```
{{< /question >}}

How do you create a dataframe from scratch? Many ways; the easiest by defining columns:

```py
col1 = [1,2,3]
col2 = [4,5,6]
pd.DataFrame({'a': col1, 'b': col2})       # dataframe from a dictionary
```

Let's index the rows by hand:
```py
pd.DataFrame({'a': col1, 'b': col2}, index=['a1','a2','a3'])
```



## Three solutions to a classification problem

<!-- idea from https://youtu.be/SAFmrTnEHLg -->

Let's create a simple dataframe from scratch:

```py
import pandas as pd
import numpy as np

df = pd.DataFrame()
size = 10_000
df['studentID'] = np.arange(1, size+1)
df['grade'] = np.random.choice(['A', 'B', 'C', 'D'], size)

df.head()
```

Let's built a new column with an alphabetic grade based on the numeric grade column. Let's start by processing
a row:

```py
def result(row):
    if row['grade'] == 'A':
        return 'pass'
    return 'fail'
```

We can apply this function to each row in a loop:

```py
%%timeit
for index, row in df.iterrows():
    df.loc[index, 'outcome'] = result(row)
```
<!-- => 290 ms -->

We can use `df.apply()` to apply this function to each row:

```py
%%timeit
df['outcome'] = df.apply(result, axis=1)   # axis=1 applies the function to each row
```
<!-- => 30.8 ms -->

Or we could use a mask to only assign `pass` to rows with `A`:

```py
%%timeit
df['outcome'] = 'fail'
df.loc[df['grade'] == 'A', 'outcome'] = 'pass'
```
<!-- => 473 µs -->





## Looping over data sets

Let's say we want to read several files in data-python/. We can use **for** to loop through their list:

```py
for filename in ['data-python/gapminder_gdp_africa.csv', 'data-python/gapminder_gdp_asia.csv']:
    data = pd.read_csv(filename, index_col='country')
    print(filename, data.min())   # print min for each column
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

{{< question num=19 >}}
Which of these files is not matched by the expression `glob('data/*as*.csv')`?
```txt
A. data/gapminder_gdp_africa.csv
B. data/gapminder_gdp_americas.csv
C. data/gapminder_gdp_asia.csv
D. 1 and 2 are not matched
```
{{< /question >}}

{{< question num=20 >}}
Modify this program so that it prints the number of records in the file that has the fewest records.
```py
fewest = ____
for filename in glob('data/*.csv'):
    fewest = ____
print('smallest file has', fewest, 'records')
```
{{< /question >}}

<!-- **[Exercise](./solar.md):** add a curve for New Zealand. -->
<!-- **[Exercise](./solas.md):** do a scatter plot of Australia vs. New Zealand. -->
<!-- **[Quiz 21](./solat.md):** (more difficult) plot the average GDP vs. time in each region (each file) -->
