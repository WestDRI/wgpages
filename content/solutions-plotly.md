## Solution to Exercise 1

```py
import plotly.graph_objs as go
from numpy import linspace, sin
x1 = linspace(0.01,1,100)
y1 = sin(1/x1)
line1 = go.Scatter(x=x1, y=y1, mode='lines+markers', name='sin(1/x)')
x2 = linspace(0.4,1,500)
y2 = 0.3*sin(0.5/(x2-0.39)) - 0.5
line2 = go.Scatter(x=x2, y=y2, mode='lines+markers', name='0.3*sin(0.5/(x2-0.39))-0.5')
fig = go.Figure([line1, line2])
fig.show()
```

Now we have two lines in the plot, each in its own colour, along with a legend in the corner!

## Solution to Exercise 2

The default mode is 'lines+markers' as you can see from the plot. You'll need to update the list to `[line1,
line2, dots]`. You can see that we don't need numpy arrays for data: `dots` just has two lists of numbers.

## Solution to Exercise 3

```py
dots = go.Scatter(x=[.2,.4,.6,.8], y=[2,1.5,2,1.2], line=dict(color=('rgb(10,205,24)'),width=4))
fig = go.Figure([line1, line2, dots])
fig.show()
```

## Solution to Exercise 3b

```py
import plotly.graph_objs as go
import numpy as np
n = 300
opacity = np.random.rand(n)
sc = go.Scatter(x=np.random.rand(n), y=np.random.rand(n), mode='markers',
                marker=dict(color='rgb(0,0,255)', opacity=(1-opacity), size=80*opacity))
fig = go.Figure(data=[sc])
fig.show()
```

## Solution to Exercise 3c

```py
heatmap = go.Heatmap(z=data, x=months, y=yticks, colorscale='Viridis')
fig = go.Figure([heatmap])
fig.show()
```

## Solution to Exercise 4

```py
data = [recordHigh[:-1], averageHigh[:-1], dailyMean[:-1], averageLow[:-1], recordLow[:-1]]
yticks = ['record high', 'aver.high', 'daily mean', 'aver.low', 'record low']
heatmap = go.Contour(z=data, x=months[:-1], y=yticks)
fig = go.Figure([heatmap])
fig.show()
```

## Solution to Exercise 5

Immediately fater reading the dataframe from the file, ad the following:

```py
df.sort_values(by='pop', ascending=False, inplace=True)
df = df.iloc[:10]
```

## Exercise 6

One possible solution is with *lambda*-functions, with
i=0..n-1, &nbsp;&nbsp;&nbsp; j=0..n-1, &nbsp;&nbsp;&nbsp; x=i/(n-1)=0..1, &nbsp;&nbsp;&nbsp;
y=j/(n-1)=0..1:

```py
import plotly.graph_objs as go
from numpy import fromfunction, sin, pi
n = 100   # plot resolution
F = fromfunction(lambda i, j: (1-j/(n-1))*sin(pi*i/(n-1)) + \
                 j/(n-1)*(sin(2*pi*i/(n-1)))**2, (n,n), dtype=float)
surface = go.Surface(z=F)
layout = go.Layout(width=1200, height=1200)
fig = go.Figure([surface], layout=layout)
fig.show()
```

If you don't like *lambda*-functions, you can replace `F = fromfunction(...)` line with:

```py
from numpy import zeros, linspace
F = zeros((n,n))
for i, x in enumerate(linspace(0,1,n)):
    for j, y in enumerate(linspace(0,1,n)):
        F[i,j] = (1-y)*sin(pi*x) + y*(sin(2*pi*x))**2
```

As a third option, you can use **array operations** to compute `f`:

```py
from numpy import linspace, meshgrid
x = linspace(0,1,n)
y = linspace(0,1,n)
Y, X = meshgrid(x, y)   # meshgrid() returns two 2D arrays storing x/y respectively at each point
F = (1-Y)*sin(pi*X) + Y*(sin(2*pi*X))**2   # array operation
```

If we want to scale the z-range, we can add `scene=go.layout.Scene(zaxis=go.ZAxis(range=[-1,2]))` inside
`go.Layout()`.
