+++
title = "Plot.ly for scientific visualization"
slug = "plotly"
+++

<!-- {{< figrow >}} -->
<!--   {{< figure src="/img/plotlyQR.png" width="200px" title="https://wgpages.netlify.app/plotly" >}} -->
<!--   {{< figure src="/img/pvzipQR.png" width="200px" title="https://tinyurl.com/pvzip" >}} -->
<!-- {{< /figrow >}} -->

{{< figure src="/img/plotlyQR.png" width="200px" title="https://wgpages.netlify.app/plotly" >}}

<!-- URLs = ["", ""] -->
<!-- `~/training/paraviewWorkshop/hidden/solutions.md` on presenter's laptop -->

* Developed by a Montreal-based company https://plotly.com
* Open-source scientific plotting Python library for Python, R, MATLAB, Perl, Julia
* Front end uses JavaScript/HTML/CSS and D3.js visualization library, with Plotly JavaScript library on top
* Supports over 40 unique chart types

<!-- * files are hosted on Amazon S3 -->

<!-- Generated plots can be -->
<!-- 1. browsed online -->
<!-- 1. stored as offline html5 files -->
<!-- 1. displayed inside a Jupyter notebook -->

## Links

1. [Online gallery](https://plotly.com/python) with code examples by category
1. [Plotly Express tutorial](https://plotly.com/python/plotly-express), also plotly.express
1. [Plotly Community Forum](https://community.plotly.com)
1. [Keyword index](https://plot.ly/python/reference)
1. [Getting started guide](https://plot.ly/python/getting-started)
1. [Plotly vs matplotlib](https://www.fabi.ai/blog/plotly-vs-matplotlib-a-quick-comparison-with-visual-guides)
   (with video)
1. [Displaying Figures](https://plot.ly/python/offline) (including offscreen into a file)
1. [Saving static images (PNG, PDF, etc) ](https://plot.ly/python/static-image-export)
1. [Plotly and IPython / Jupyter notebook](https://plot.ly/ipython-notebooks) with additional plotting examples

<!-- 1. [Code examples](https://plot.ly/create) -->
<!-- 1. [Community feed with gallery](https://plot.ly/feed) -->
<!-- 1. [Creating HTML or PDF reports in Python](https://plot.ly/python/#report-generation) -->
<!-- 1. [Connecting to databases](https://plot.ly/python/#databases) -->
<!-- 1. [Creating dashboards](https://plot.ly/python/dashboard) with Dash Enterprise -->

## Installation

- You will need Python 3, along with *some* Python package manager
- Use your favourite installer:

```sh
$ pip install plotly
$ uv pip install plotly
$ conda install -c conda-forge plotly
```

- Other recommended libraries to install for today's session: `jupyter`, `numpy`, `pandas`, `networkx`,
  `scikit-image`, `kaleido`

## Displaying Plotly figures

<!-- ```sh -->
<!-- uv pip install kaleido   # to save PNG -->
<!-- ``` -->

With Plotly, you can:
1. work inside a Python shell,
2. save your script into a *.py file and then run it, or
3. run code inside a Jupyter Notebook (start a notebook with `jupyter notebook` or even better `jupyter lab`).

Plotly supports a number of renderers, and it will attempt to choose an appropriate renderer automatically (in
my experience, not very successfully). You can examine the selected default renderer with:

```py
import plotly.io as pio
pio.renderers   # show default and available renderers
```

You can overwrite the default by setting it manually inside your session or inside your code, e.g.

```py
pio.renderers.default = 'browser'    # open each plot in a new browser tab
pio.renderers.default = 'notebook'   # plot inside a Jupyter notebook
```

If you want to have this setting persistent across sessions (and not set it manually or in the code), you can
create a file `~/.plotly_startup.py` with the following:

```py
try:
    import plotly.io as pio
    pio.renderers.default = "browser"
except ImportError:
    pass

```

and set `export PYTHONSTARTUP=~/.plotly_startup.py` in your `~/.bashrc` file.

<!-- 'iframe'               Shows plot inline (only in Jupyter) -->
<!-- 'notebook_connected'   Full interactivity in Jupyter -->

<!-- png_renderer = pio.renderers["png"] -->
<!-- png_renderer.width = 500 -->
<!-- png_renderer.height = 500 -->

Let's create a simple line plot:

```py
import plotly.graph_objs as go
from numpy import linspace, sin
x = linspace(0.01,1,100)
y = sin(1/x)
line = go.Scatter(x=x, y=y, mode='lines+markers', name='sin(1/x)')
fig = go.Figure([line])
fig.show()   # should open in your browser

fig.write_image("/Users/razoumov/tmp/lines.png", scale=2)   # static, supports svg, png, jpg/jpeg, webp, pdf
fig.write_html("/Users/razoumov/tmp/lines.html")            # interactive
fig.write_json("/Users/razoumov/tmp/2007.json")             # for further editing
```

In general, use `fig.show()` when working outside of a Jupyter Notebook, or when you want to save your plot to
a file. If you want to display plots inline inside a Jupyter notebook, set `pio.renderers.default =
'notebook'` and use the command

```py
go.Figure([line])
```

that should display plots right inside the notebook, without a need for `fig.show()`.

You can find more details at https://plotly.com/python/renderers .











## Plotly Express (data exploration) library

Normally, in this workshop I would teach `plotly.graph_objs` (Graph Objects) which is the standard module in
Plotly.py -- you saw its example in the previous section.

[Plotly Express](https://plotly.com/python/plotly-express) is a higher-level interface to Plotly.py that sits
on top of Graph Objects and provides 30+ functions for creating different types of figures in a single
function call. It works with NumPy arrays, Xarrays, Pandas dataframes, basic Python iterables, etc.

<!-- video tutorial https://plotly.com/python/plotly-express -->

Here is one way to create a line plot from above in Plotly Express, using just NumPy arrays:

```py
import plotly.express as px
from numpy import linspace, sin
x = linspace(0.01,1,100)
y = sin(1/x)
fig = px.line(x=x, y=y, markers=True)
fig.show()
```

You can also use feed a dataframe into the plotting function:

```py
import plotly.express as px
from numpy import linspace, sin
import pandas as pd
x = linspace(0.01,1,100)
df = pd.DataFrame({'col1': x, 'col2': sin(1/x)})
fig = px.line(df, x='col1', y='col2', markers=True)
fig.show()
```

Or you can feed a dictionary:

```py
import plotly.express as px
from numpy import linspace, sin
x = linspace(0.01,1,100)
d = {'key1': x, 'key2': sin(1/x)}
fig = px.line(d, x='key1', y='key2', markers=True)
fig.show()
```

To see Plotly Express really shine, we should play with a slightly larger dataset containing several
variables. The module `px.data` comes with several datasets included. Let's take a look at the Gapminder data
that contains one row per country per year.

```py
import plotly.express as px
df = px.data.gapminder().query("year==2007")

px.line(df, x="gdpPercap", y="lifeExp", markers=True)   # this should be familiar
# 1. replace df with df.sort_values(by='gdpPercap')
# 2. add log_x=True
# 3. change line to scatter, remove markers=True
# 4. don't actually need to sort now, with no markers
# 5. add hover_name="country"
# 6. add size="pop"
# 7. add size_max=60
# 8. add color="continent" - can now turn continents off/on

px.strip(df, x="lifeExp")   # single-axis scatter plot
# 1. add hover_name="country"
# 2. add color="continent"
# 3. change strip to histogram
# 4. can turn continents off/on in the legend
# 5. add marginal="rug" to show countries in a rug plot
# 6. add y="pop" to switch from country count to population along the vertical axis
# 7. add facet_col="continent" to break continents into facet columns

px.bar(df, color="lifeExp", x="pop", y="continent", hover_name="country")

px.sunburst(df, color="lifeExp", values="pop", path=["continent", "country"],
            hover_name="country", height=800)

px.treemap(df, color="lifeExp", values="pop", path=["continent", "country"],
           hover_name="country", height=500)

px.choropleth(df, color="lifeExp", locations="iso_alpha", hover_name="country", height=580)
```





<!-- - gridded data => heatmaps -->
<!-- - polar plots -->
<!-- - multivariate or categorical => parallel coordinates plot -->
<!-- - ternary plots (below) -->
<!-- - 3D data -->

Here is an ternary plot example with Montreal elections data (58 electoral districts, 3 candidates):

```py
df = px.data.election()
px.scatter_ternary(df, a="Joly", b="Coderre", c="Bergeron", color="winner",
                   size="total", hover_name="district", size_max=15,
                   color_discrete_map={"Joly": "blue", "Bergeron": "green", "Coderre": "red"})
```













## Plotting via Graph Objects

While Plotly Express is excellent for quick data exploration, it has some limitations: it supports fewer plot
types and does not allow combining different plot types directly in a single figure. Plotly Graph Objects, on
the other hand, is a lower-level library that offers greater functionality and customization with layouts. In
this section, we'll explore Graph Objects, starting with 2D plots.

Graph Objects supports many plot types:

```py
import plotly.graph_objs as go
dir(go)
```
```txt
['AngularAxis', 'Annotation', 'Annotations', 'Bar', 'Barpolar', 'Box', 'Candlestick', 'Carpet', 'Choropleth', 'Choroplethmap', 'Choroplethmapbox', 'ColorBar', 'Cone', 'Contour', 'Contourcarpet', 'Contours', 'Data', 'Densitymap', 'Densitymapbox', 'ErrorX', 'ErrorY', 'ErrorZ', 'Figure', 'FigureWidget', 'Font', 'Frame', 'Frames', 'Funnel', 'Funnelarea', 'Heatmap', 'Histogram', 'Histogram2d', 'Histogram2dContour', 'Histogram2dcontour', 'Icicle', 'Image', 'Indicator', 'Isosurface', 'Layout', 'Legend', 'Line', 'Margin', 'Marker', 'Mesh3d', 'Ohlc', 'Parcats', 'Parcoords', 'Pie', 'RadialAxis', 'Sankey', 'Scatter', 'Scatter3d', 'Scattercarpet', 'Scattergeo', 'Scattergl', 'Scattermap', 'Scattermapbox', 'Scatterpolar', 'Scatterpolargl', 'Scattersmith', 'Scatterternary', 'Scene', 'Splom', 'Stream', 'Streamtube', 'Sunburst', 'Surface', 'Table', 'Trace', 'Treemap', 'Violin', 'Volume', 'Waterfall', 'XAxis', 'XBins', 'YAxis', 'YBins', 'ZAxis', 'bar', 'barpolar', 'box', 'candlestick', 'carpet', 'choropleth', 'choroplethmap', 'choroplethmapbox', 'cone', 'contour', 'contourcarpet', 'densitymap', 'densitymapbox', 'funnel', 'funnelarea', 'heatmap', 'histogram', 'histogram2d', 'histogram2dcontour', 'icicle', 'image', 'indicator', 'isosurface', 'layout', 'mesh3d', 'ohlc', 'parcats', 'parcoords', 'pie', 'sankey', 'scatter', 'scatter3d', 'scattercarpet', 'scattergeo', 'scattergl', 'scattermap', 'scattermapbox', 'scatterpolar', 'scatterpolargl', 'scattersmith', 'scatterternary', 'splom', 'streamtube', 'sunburst', 'surface', 'table', 'treemap', 'violin', 'volume', 'waterfall']
```

### Scatter plots

We already saw an example of a Scatter plot with Graph Objects:

```py
import plotly.graph_objs as go
from numpy import linspace, sin
x = linspace(0.01,1,100)
y = sin(1/x)
line = go.Scatter(x=x, y=y, mode='lines+markers', name='sin(1/x)')
go.Figure([line])

```

Let's print the dataset `line`:

```py
type(line)
print(line)
```

It is a plotly object which is actually a Python dictionary, with all elements clearly identified (plot type,
x numpy array, y numpy array, line type, legend line name). So, `go.Scatter` simply creates a dictionary with
the corresponding `type` element. **This variable/dataset `line` completely describes our plot!*** Then we
create a list of such objects and pass it to the plotting routine.

{{< question num="`Exercise 1`" >}}
Pass a list of two objects the plotting routine with `data = [line1,line2]`. Let the second dataset `line2`
contain another mathematical function. The idea is to have multiple objects in the plot.
{{< /question >}}

{{<note>}}
Hovering over each data point will reveal their coordinates. Use the toolbar at the top. Double-clicking on
the plot will reset it.
{{</note>}}

{{< question num="`Exercise 2`" >}}
Add a bunch of dots to the plot with `dots = go.Scatter(x=[.2,.4,.6,.8], y=[2,1.5,2,1.2])`. What is
default scatter mode?
{{< /question >}}

{{< question num="`Exercise 3`" >}}
Change line colour and width by adding the dictionary `line=dict(color=('rgb(10,205,24)'),width=4)` to `dots`.
{{< /question >}}

{{< question num="`Exercise 3b`" >}}
Create a scatter plot of 300 random filled blue circles inside a unit square. Their random opacity must
anti-correlate with their size (bigger circles should be more transparent) -- see the plot below.
{{< /question >}}

### Bar plots

Let's try a Bar plot, constructing `data` directly in one line from the dictionary:

```py
import plotly.graph_objs as go
bar = go.Bar(x=['Vancouver', 'Calgary', 'Toronto', 'Montreal', 'Halifax'],
               y=[2463431, 1392609, 5928040, 4098927, 403131])
fig = go.Figure(data=[bar])
fig.show()
```

Let's plot inner city population vs. greater metro area for each city:

```py
import plotly.graph_objs as go
cities = ['Vancouver', 'Calgary', 'Toronto', 'Montreal', 'Halifax']
proper = [662_248, 1_306_784, 2_794_356, 1_762_949, 439_819]
metro = [3_108_926, 1_688_000, 6_491_000, 4_615_154, 530_167]
bar1 = go.Bar(x=cities, y=proper, name='inner city')
bar2 = go.Bar(x=cities, y=metro, name='greater area')
fig = go.Figure(data=[bar1,bar2])
fig.show()
```

Let's now do a stacked plot, with *outer city* population on top of *inner city* population:

```py
outside = [m-p for p,m in zip(proper,metro)]   # need to subtract
bar1 = go.Bar(x=cities, y=proper, name='inner city')
bar2 = go.Bar(x=cities, y=outside, name='outer city')
fig = go.Figure(data=[bar1,bar2], layout=go.Layout(barmode='stack'))   # new element!
fig.show()
```

What else can we modify in the layout?

```py
help(go.Layout)
```

There are many attributes!

### Heatmaps

* go.Area() for plotting **wind rose charts**
* go.Box() for **basic box plots**

Let's plot a heatmap of monthly temperatures at the South Pole:

```py
import plotly.graph_objs as go
months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec', 'Year']
recordHigh = [-14.4,-20.6,-26.7,-27.8,-25.1,-28.8,-33.9,-32.8,-29.3,-25.1,-18.9,-12.3,-12.3]
averageHigh = [-26.0,-37.9,-49.6,-53.0,-53.6,-54.5,-55.2,-54.9,-54.4,-48.4,-36.2,-26.3,-45.8]
dailyMean = [-28.4,-40.9,-53.7,-57.8,-58.0,-58.9,-59.8,-59.7,-59.1,-51.6,-38.2,-28.0,-49.5]
averageLow = [-29.6,-43.1,-56.8,-60.9,-61.5,-62.8,-63.4,-63.2,-61.7,-54.3,-40.1,-29.1,-52.2]
recordLow = [-41.1,-58.9,-71.1,-75.0,-78.3,-82.8,-80.6,-79.3,-79.4,-72.0,-55.0,-41.1,-82.8]
data = [recordHigh, averageHigh, dailyMean, averageLow, recordLow]
yticks = ['record high', 'aver.high', 'daily mean', 'aver.low', 'record low']
heatmap = go.Heatmap(z=data, x=months, y=yticks)
fig = go.Figure([heatmap])
fig.show()
```

{{< question num="`Exercise 3c`" >}}
Try a few different colourmaps, e.g. 'Viridis', 'Jet', 'Rainbow'. What colourmaps are available?
{{< /question >}}

### Contour maps

{{< question num="`Exercise 4`" >}}
Pretend that our heatmap is defined over a 2D domain and plot the same temperature data as a contour
map. Remove the `Year` data (last column) and use `go.Contour` to plot the 2D contour map.
{{< /question >}}

### Download data

Open a terminal window inside Jupyter (New-Terminal) and run these commands:

```sh
wget https://tinyurl.com/pvzip -O paraview.zip
unzip paraview.zip
mv data/*.{csv,nc} .
```

### Geographical scatterplot

Go back to your Python Jupyter Notebook. Now let's do a scatterplot on top of a geographical map:

```py
import plotly.graph_objs as go
import pandas as pd
from math import log10
df = pd.read_csv('cities.csv')   # lists name,pop,lat,lon for 254 Canadian cities and towns
df['text'] = df['name'] + '<br>Population ' + \
             (df['pop']/1e6).astype(str) +' million' # add new column for mouse-over

largest, smallest = df['pop'].max(), df['pop'].min()
def normalize(x):
    return log10(x/smallest)/log10(largest/smallest)   # x scaled into [0,1]

df['logsize'] = round(df['pop'].apply(normalize)*255)   # new column
cities = go.Scattergeo(
    lon = df['lon'], lat = df['lat'], text = df['text'],
    marker = dict(
        size = df['pop']/5000,
        color = df['logsize'],
        colorscale = 'Viridis',
        showscale = True,   # show the colourbar
        line = dict(width=0.5, color='rgb(40,40,40)'),
        sizemode = 'area'))
layout = go.Layout(title = 'City populations',
                       showlegend = False,   # do not show legend for first plot
                       geo = dict(
                           scope = 'north america',
                           resolution = 50,   # base layer resolution of km/mm
                           lonaxis = dict(range=[-130,-55]), lataxis = dict(range=[44,70]), # plot range
                           showland = True, landcolor = 'rgb(217,217,217)',
                           showrivers = True, rivercolor = 'rgb(153,204,255)',
                           showlakes = True, lakecolor = 'rgb(153,204,255)',
                           subunitwidth = 1, subunitcolor = "rgb(255,255,255)",   # province border
						   countrywidth = 2, countrycolor = "rgb(255,255,255)"))  # country border
fig = go.Figure(data=[cities], layout=layout)
fig.show()
```

{{< question num="`Exercise 5`" >}}
Modify the code to display only 10 largest cities.
{{< /question >}}

Recall how we combined several scatter plots in one figure before. You can combine several plots on top
of a single map -- let's **combine scattergeo + choropleth**:

```py
import plotly.graph_objs as go
import pandas as pd
df = pd.read_csv('cities.csv')
df['text'] = df['name'] + '<br>Population ' + \
             (df['pop']/1e6).astype(str)+' million' # add new column for mouse-over
cities = go.Scattergeo(lon = df['lon'],
                       lat = df['lat'],
                       text = df['text'],
                       marker = dict(
                           size = df['pop']/5000,
                           color = "lightblue",
                           line = dict(width=0.5, color='rgb(40,40,40)'),
                           sizemode = 'area'))
gdp = pd.read_csv('gdp.csv')   # read name, gdp, code for 222 countries
c1 = [0,"rgb(5, 10, 172)"]     # define colourbar from top (0) to bottom (1)
c2, c3 = [0.35,"rgb(40, 60, 190)"], [0.5,"rgb(70, 100, 245)"]
c4, c5 = [0.6,"rgb(90, 120, 245)"], [0.7,"rgb(106, 137, 247)"]
c6 = [1,"rgb(220, 220, 220)"]
countries = go.Choropleth(locations = gdp['CODE'],
                          z = gdp['GDP (BILLIONS)'],
                          text = gdp['COUNTRY'],
                          colorscale = [c1,c2,c3,c4,c5,c6],
                          autocolorscale = False,
                          reversescale = True,
                          marker = dict(line = dict(color='rgb(180,180,180)',width = 0.5)),
                          zmin = 0,
                          colorbar = dict(tickprefix = '$',title = 'GDP<br>Billions US$'))
layout = go.Layout(hovermode = "x", showlegend = False)  # do not show legend for first plot
fig = go.Figure(data=[cities,countries], layout=layout)
fig.show()
```

### 3D Topographic elevation

Let's plot some tabulated topographic elevation data:

```py
import plotly.graph_objs as go
import pandas as pd
table = pd.read_csv('mt_bruno_elevation.csv')
surface = go.Surface(z=table.values)  # use 2D numpy array format
layout = go.Layout(title='Mt Bruno Elevation',
                   width=1200, height=1200,    # image size
                   margin=dict(l=65, r=10, b=65, t=90))   # margins around the plot
fig = go.Figure([surface], layout=layout)
fig.show()
```

{{< question num="`Exercise 6`" >}}
Plot a 2D function f(x,y) = (1−y) sin(πx) + y sin^2(2πx), where x,y ∈ [0,1] on a 100^2 grid.
{{< /question >}}

### Elevated 2D functions

Let's define a different colourmap by adding `colorscale='Viridis'` inside `go.Surface()`. This is our
current code:

```py
import plotly.graph_objs as go
from numpy import *
n = 100   # plot resolution
x = linspace(0,1,n)
y = linspace(0,1,n)
Y, X = meshgrid(x, y)   # meshgrid() returns two 2D arrays storing x/y respectively at each mesh point
F = (1-Y)*sin(pi*X) + Y*(sin(2*pi*X))**2   # array operation
data = go.Surface(z=F, colorscale='Viridis')
layout = go.Layout(width=1000, height=1000, scene=go.layout.Scene(zaxis=go.layout.scene.ZAxis(range=[-1,2])));
fig = go.Figure(data=[data], layout=layout)
fig.show()
```

### Lighting control

Let's change the default light in the room by adding `lighting=dict(ambient=0.1)` inside `go.Surface()`. Now
our plot is much darker!

* `ambient` controls the light in the room (default = 0.8)
* `roughness` controls amount of light scattered (default = 0.5)
* `diffuse` controls the reflection angle width (default = 0.8)
* `fresnel` controls light washout (default = 0.2)
* `specular` induces bright spots (default = 0.05)

Let's try `lighting=dict(ambient=0.1,specular=0.3)` -- now we have lots of specular light!

### 3D parametric plots

In plotly documentation you can find quite a lot of
[different 3D plot types](https://plot.ly/python/3d-charts). Here is something visually very different,
but it still uses `go.Surface(x,y,z)`:

```py
import plotly.graph_objs as go
from numpy import pi, sin, cos, mgrid
dphi, dtheta = pi/250, pi/250    # 0.72 degrees
[phi, theta] = mgrid[0:pi+dphi*1.5:dphi, 0:2*pi+dtheta*1.5:dtheta]
        # define two 2D grids: both phi and theta are (252,502) numpy arrays
r = sin(4*phi)**3 + cos(2*phi)**3 + sin(6*theta)**2 + cos(6*theta)**4
x = r*sin(phi)*cos(theta)   # x is also (252,502)
y = r*cos(phi)              # y is also (252,502)
z = r*sin(phi)*sin(theta)   # z is also (252,502)
surface = go.Surface(x=x, y=y, z=z, colorscale='Viridis')
layout = go.Layout(title='parametric plot')
fig = go.Figure(data=[surface], layout=layout)
fig.show()
```

### 3D scatter plots

Let's take a look at a 3D scatter plot using the `country index` data from http://www.prosperity.com for 142 countries:

```py
import plotly.graph_objs as go
import pandas as pd
df = pd.read_csv('legatum2015.csv')
spheres = go.Scatter3d(x=df.economy,
                       y=df.entrepreneurshipOpportunity,
                       z=df.governance,
                       text=df.country,
                       mode='markers',
                       marker=dict(
                           sizemode = 'diameter',
                           sizeref = 0.3,   # max(safetySecurity+5.5) / 32
                           size = df.safetySecurity+5.5,
                           color = df.education,
                           colorscale = 'Viridis',
                           colorbar = dict(title = 'Education'),
                           line = dict(color='rgb(140, 140, 170)')))   # sphere edge
layout = go.Layout(height=900, width=900,
                   title='Each sphere is a country sized by safetySecurity',
                   scene = dict(xaxis=dict(title='economy'),
                                yaxis=dict(title='entrepreneurshipOpportunity'),
                                zaxis=dict(title='governance')))
fig = go.Figure(data=[spheres], layout=layout)
fig.show()
```

### 3D graphs

We can plot 3D graphs. Consider a Dorogovtsev-Goltsev-Mendes graph: *in each subsequent generation, every
edge from the previous generation yields a new node, and the new graph can be made by connecting together
three previous-generation graphs*.

```py
import plotly.graph_objs as go
import networkx as nx
import sys
generation = 5
H = nx.dorogovtsev_goltsev_mendes_graph(generation)
print(H.number_of_nodes(), 'nodes and', H.number_of_edges(), 'edges')
# Force Atlas 2 graph layout from https://github.com/tpoisot/nxfa2.git
pos = nx.spectral_layout(H,scale=1,dim=3)
Xn = [pos[i][0] for i in pos]   # x-coordinates of all nodes
Yn = [pos[i][1] for i in pos]   # y-coordinates of all nodes
Zn = [pos[i][2] for i in pos]   # z-coordinates of all nodes
Xe, Ye, Ze = [], [], []
for edge in H.edges():
    Xe += [pos[edge[0]][0], pos[edge[1]][0], None]   # x-coordinates of all edge ends
    Ye += [pos[edge[0]][1], pos[edge[1]][1], None]   # y-coordinates of all edge ends
    Ze += [pos[edge[0]][2], pos[edge[1]][2], None]   # z-coordinates of all edge ends

degree = [deg[1] for deg in H.degree()]   # list of degrees of all nodes
labels = [str(i) for i in range(H.number_of_nodes())]
edges = go.Scatter3d(x=Xe, y=Ye, z=Ze,
                     mode='lines',
                     marker=dict(size=12,line=dict(color='rgba(217, 217, 217, 0.14)',width=0.5)),
                     hoverinfo='none')
nodes = go.Scatter3d(x=Xn, y=Yn, z=Zn,
                     mode='markers',
                     marker=dict(sizemode = 'area',
                                 sizeref = 0.01, size=degree,
                                 color=degree, colorscale='Viridis',
                                 line=dict(color='rgb(50,50,50)', width=0.5)),
                     text=labels, hoverinfo='text')

axis = dict(showline=False, zeroline=False, showgrid=False, showticklabels=False, title='')
layout = go.Layout(
    title = str(generation) + "-generation Dorogovtsev-Goltsev-Mendes graph",
    width=1000, height=1000,
    showlegend=False,
    scene=dict(xaxis=go.layout.scene.XAxis(axis),
               yaxis=go.layout.scene.YAxis(axis),
               zaxis=go.layout.scene.ZAxis(axis)),
    margin=go.layout.Margin(t=100))
fig = go.Figure(data=[edges,nodes], layout=layout)
fig.show()
```

### 3D functions

Let's create an isosurface of a `decoCube` function at f=0.03. Isosurfaces are returned as a list of
polygons, and for plotting polygons in plotly we need to use `plotly.figure_factory.create_trisurf()`
which replaces `plotly.graph_objs.Figure()`:

```py
from plotly import figure_factory as FF
from numpy import mgrid
from skimage import measure
X,Y,Z = mgrid[-1.2:1.2:30j, -1.2:1.2:30j, -1.2:1.2:30j] # three 30^3 grids, each side [-1.2,1.2] in 30 steps
F = ((X*X+Y*Y-0.64)**2 + (Z*Z-1)**2) * \
    ((Y*Y+Z*Z-0.64)**2 + (X*X-1)**2) * \
    ((Z*Z+X*X-0.64)**2 + (Y*Y-1)**2)
vertices, triangles, normals, values = measure.marching_cubes(F, 0.03)  # create an isosurface
x,y,z = zip(*vertices)   # zip(*...) is opposite of zip(...): unzips a list of tuples
fig = FF.create_trisurf(x=x, y=y, z=z, plot_edges=False,
                        simplices=triangles, title="Isosurface", height=1200, width=1200)
fig.show()
```

Try switching `plot_edges=False` to `plot_edges=True` -- you'll see individual polygons!

<!-- ### NetCDF data -->
<!-- #### 2D slices through a 3D dataset -->

<!-- How about processing real data? -->

<!-- ```py -->
<!-- import plotly.offline as py -->
<!-- py.init_notebook_mode(connected=True) -->
<!-- import plotly.graph_objs as go -->
<!-- from netCDF4 import Dataset    # Note: need netCDF4 installed -->
<!-- dataset = Dataset('sineEnvelope.nc') -->
<!-- name = list(dataset.variables.keys())[0]   # variable name -->
<!-- print(name) -->
<!-- var = dataset.variables[name] -->
<!-- print(var.shape) -->
<!-- image = go.Heatmap(z=var[:,:,49])   # use layer 50 (in the middle) -->
<!-- layout = go.Layout(width=800, height=800, margin=dict(l=65,r=10,b=65,t=90)) -->
<!-- fig = go.Figure(data=[image], layout=layout) -->
<!-- py.iplot(fig,auto_open=False) -->
<!-- ``` -->

<!-- > ## Exercise 7 -->
<!-- > Use the last two codes to plot an isosurface of `sineEnvelope.nc` dataset at f=0.5. -->

<!-- #### Orthogonal 2D slices -->

<!-- Let's do three orthogonal slices through our dataset: -->

<!-- ```py -->
<!-- import numpy as np -->
<!-- import plotly.offline as py -->
<!-- py.init_notebook_mode(connected=True) -->
<!-- import plotly.graph_objs as go -->
<!-- from netCDF4 import Dataset -->
<!-- dataset = Dataset('sineEnvelope.nc') -->
<!-- name = list(dataset.variables.keys())[0]   # variable name -->
<!-- var = dataset.variables[name]   # dataset variable -->
<!-- vmin, vmax = np.min(var), np.max(var)   # global dataset min/max -->
<!-- x, y, z = np.linspace(0.005,0.995,100), np.linspace(0.005,0.995,100), np.linspace(0.005,0.995,100) -->
<!-- slicePosition = [0,0,0]   # indices 0..99 -->
<!-- print('slices through the point', x[slicePosition[0]], y[slicePosition[1]], z[slicePosition[2]]) -->

<!-- # --- create the XY-slice -->
<!-- X, Y = np.meshgrid(x,y)   # each is a 100x100 mesh covering [0,1] in each dimension -->
<!-- Z = z[slicePosition[2]] * np.ones((100,100))   # 100x100 array of constant value -->
<!-- surfz = var[:,:,slicePosition[2]]   # 100x100 array of function values -->
<!-- slicez = go.Surface(x=X, y=Y, z=Z, surfacecolor=surfz, cmin=vmin, cmax=vmax, showscale=False) -->

<!-- # --- create the YZ-slice -->
<!-- Y, Z = np.meshgrid(y,z)   # each is a 100x100 mesh covering [0,1] in each dimension -->
<!-- X = x[slicePosition[0]] * np.ones((100,100))   # 100x100 array of constant value -->
<!-- surfx = var[slicePosition[0],:,:]   # 100x100 array of function values -->
<!-- slicex = go.Surface(x=X, y=Y, z=Z, surfacecolor=surfx, cmin=vmin, cmax=vmax, showscale=True) -->

<!-- # --- create the XZ-slice -->
<!-- X, Z = np.meshgrid(x,z) -->
<!-- Y = y[slicePosition[1]] * np.ones((100,100))   # 100x100 array of constant value -->
<!-- surfy = var[:,slicePosition[1],:] -->
<!-- slicey = go.Surface(x=X, y=Y, z=Z, surfacecolor=surfy, cmin=vmin, cmax=vmax, showscale=False) -->

<!-- # --- plot the three slices -->
<!-- axis = dict(showbackground=True,  backgroundcolor="rgb(230, 230,230)", -->
<!--             gridcolor="rgb(255, 255, 255)", zerolinecolor="rgb(255, 255, 255)") -->
<!-- layout = go.Layout(title='Orthogonal slices through volumetric data',  -->
<!--                    width=900, height=900, -->
<!--                    scene=go.Scene(xaxis=go.XAxis(axis), -->
<!--                                yaxis=go.YAxis(axis),  -->
<!--                                zaxis=go.ZAxis(axis),  -->
<!--                                aspectratio=dict(x=1, y=1, z=1))) -->
<!-- fig = go.Figure(data=[slicez,slicey,slicex], layout=layout) -->
<!-- py.iplot(fig,auto_open=False) -->
<!-- ``` -->

<!-- ## Animation -->

<!-- For animations, you need to pass the third (`frames`) argument to `go.Figure()`: -->

<!-- ```py -->
<!-- import plotly.offline as py -->
<!-- py.init_notebook_mode(connected=True) -->
<!-- import plotly.graph_objs as go -->
<!-- import numpy as np -->
<!-- t = np.linspace(0,10,100) -->
<!-- x, y = t/3*np.cos(t), t/3*np.sin(t) -->
<!-- line1 = go.Scatter(x=x, y=y, mode='lines', line=dict(width=10, color='blue')) -->
<!-- line2 = go.Scatter(x=x, y=y, mode='lines', line=dict(width=2, color='blue')) -->
<!-- layout = go.Layout(title='Moving dot', -->
<!--                    xaxis=dict(range=[-10,10]), -->
<!--                    yaxis=dict(scaleanchor="x", scaleratio=1),   # 1:1 aspect ratio -->
<!--                    showlegend = False, -->
<!--                    updatemenus= [{'type': 'buttons', -->
<!--                                   'buttons': [{'label': 'Replay', -->
<!--                                                'method': 'animate', -->
<!--                                                'args': [None]}]}]) -->
<!-- nframes = 20 -->
<!-- s = np.linspace(0,10,nframes) -->
<!-- xdot, ydot = s/3*np.cos(s), s/3*np.sin(s) -->
<!-- frames = [dict(data=[go.Scatter(x=[xdot[k]], y=[ydot[k]], -->
<!--                                 mode='markers', marker=dict(color='red', size=30))]) -->
<!--           for k in range(nframes)] -->
<!-- # line1 will be shown before the first frame, line2 will be shown in each frame -->
<!-- fig = go.Figure(data=[line1,line2], layout=layout, frames=frames) -->
<!-- py.iplot(fig,auto_open=False) -->
<!-- ``` -->

<!-- I could not find how to control the animation speed. Obviously, it should be via a keyword to either -->
<!-- `go.Figure()` or `py.iplot`. -->










## Dash library for making interactive web applications

[Plotly Dash](https://github.com/plotly/dash) library is a framework for making interactive data applications.

1. Dash Python User Guide https://dash.plotly.com
1. https://dash.gallery/Portal has ~100 app examples



- can create a dropdown to select data to plot
- can enter a value into a box to select or interpolate data to plot
- selection in one plot shows in the other plot
- mix and match these into a single web app
- can create different tabs inside the app, with the render switching between them
- can make entire website with user guides, plots, code examples, etc.

<!-- video tutorial https://plotly.com/python/plotly-express -->

&nbsp;
