+++
title = "Multi-D arrays and datasets with xarray"
slug = "python-14-xarray"
weight = 5
+++

Xarray library is built on top of numpy and pandas, and it brings the power of pandas to multidimensional arrays. There
are two main data structures in xarray:

- xarray.DataArray is a fancy, labelled version of numpy.ndarray
- xarray.Dataset is a collection of multiple xarray.DataArray's that share dimensions

## Data array: simple example from scratch

```py
import xarray as xr
import numpy as np
data = xr.DataArray(
    np.random.random(size=(4,3)),
    dims=("y","x"),  # dimension names (row,col); we want `y` to represent rows and `x` columns
    coords={"x": [10,11,12], "y": [10,20,30,40]}  # coordinate labels/values
)
data
type(data)   # <class 'xarray.core.dataarray.DataArray'>
```

We can access various attributes of this array:

```py
data.values                 # the 2D numpy array
data.values[0,0] = 0.53     # can modify in-place
data.dims                   # ('y', 'x')
data.coords                 # all coordinates
data.coords['x']            # one coordinate
data.coords['x'][1]         # a number
data.x[1]                   # the same
```

Let's add some arbitrary metadata:

```py
data.attrs = {"author": "Alex", "date": "2020-08-26"}
data.attrs["name"] = "density"
data.attrs["units"] = "g/cm^3"
data.x.attrs["units"] = "cm"
data.y.attrs["units"] = "cm"
data.attrs    # global attributes
data          # global attributes show here as well
data.x        # only `x` attributes
```

## Subsetting arrays

We can subset using the usual Python square brackets:

```py
data[0,:]     # first row
data[:,-1]    # last column
```

In addition, xarray provides these functions:

- `isel()` selects by coordinate index, could be replaced by [index1] or [index1,...]
- `sel()` selects by coordinate value
- `interp()` interpolates by coordinate value

```py
data.isel()      # same as `data`
data.isel(y=1)   # second row
data.isel(x=2)   # third column
data.isel(y=0, x=[-2,-1])   # first row, last two columns
```

```py
data.x.dtype     # it is integer
data.sel(x=10)   # certain value of `x`
data.y           # array([10, 20, 30, 40])
data.sel(y=slice(15,30))   # only values with 15<=y<=30 (two rows)
```

There are aggregate functions, e.g.

```py
meanOfEachColumn = data.mean(dim='y')    # apply mean over y
spatialMean = data.mean()
spatialMean = data.mean(dim=['x','y'])   # same
```

Finally, we can interpolate. However, this requires `scipy` library and might throw some warnings, so use at
your own risk:

```py
data.interp(x=10.5, y=10)    # first row, between 1st and 2nd columns
data.interp(x=10.5, y=15)    # between 1st and 2nd rows, between 1st and 2nd columns
?data.interp                 # can use different interpolation methods
```

## Plotting

Matplotlib is integrated directly into xarray:

```py
data.plot(size=5)                         # 2D heatmap
data.isel(x=0).plot(marker="o", size=5)   # 1D line plot
```

## Vectorized operations

You can perform element-wise operations on `xarray.DataArray` like with `numpy.ndarray`:

```py
data + 100                           # element-wise like numpy arrays
(data - data.mean()) / data.std()    # normalize the data
data - data[0,:]      # use numpy broadcasting → subtract first row from all rows
```

## Split your data into multiple independent groups

```py
data.groupby("x")       # 3 groups with labels 10, 11, 12; each column becomes a group
data.groupby("x")[10]   # specific group (first column)
data.groupby("x").map(lambda v: v-v.min())   # apply separately to each group
            # from each column (fixed x) subtract the smallest value in that column
```

## Dataset: simple example from scratch

Let's initialize two 2D arrays with the identical dimensions:

```py
coords = {"x": np.linspace(0,1,5), "y": np.linspace(0,1,5)}
temp = xr.DataArray(      # first 2D array
    20 + np.random.randn(5,5),
    dims=("y","x"),
    coords=coords
)
pres = xr.DataArray(       # second 2D array
    100 + 10*np.random.randn(5,5),
    dims=("y","x"),
    coords=coords
)
```

From these we can form a dataset:

```py
ds = xr.Dataset({"temperature": temp, "pressure": pres,
                 "bar": ("x", 200+np.arange(5)), "pi": np.pi})
ds
```

As you can see, `ds` includes two 2D arrays on the same grid, one 1D array on `x`, and one number:

```py
ds.temperature   # 2D array
ds.bar           # 1D array
ds.pi            # one element
```

Subsetting works the usual way:

```py
ds.sel(x=0)     # each 2D array becomes 1D array, the 1D array becomes a number, plus a number
ds.temperature.sel(x=0)     # 'temperature' is now a 1D array
ds.temperature.sel(x=0.25, y=0.5)     # one element of `temperature`
```

We can save this dataset to a file:

```py
%pip install netcdf4
ds.to_netcdf("test.nc")
new = xr.open_dataset("test.nc")   # try reading it
```

We can even try opening this 2D dataset in ParaView - select (y,x) and deselect Spherical.

{{< question num=14.1 >}}
Recall the 2D function we plotted when we were talking about numpy's array broadcasting. Let's scale it to a
unit square x,y∈[0,1]:
```py
x = np.linspace(0, 1, 50)
y = np.linspace(0, 1, 50).reshape(50,1)
z = np.sin(5*x)**8 + np.cos(5+25*x*y)*np.cos(5*x)
```
This is will our image at z=0. Then rotate this image 90 degrees (e.g. flip x and y), and this will be our
function at z=1. Now interpolate linearly between z=0 and z=1 to build a 3D function in the unit cube
x,y,z∈[0,1]. Check what the function looks like at intermediate z. Write out a NetCDF file with the 3D
function.
{{< /question >}}





## Time series data

In xarray you can work with time-dependent data. Xarray accepts pandas time formatting,
e.g. `pd.to_datetime("2020-09-10")` would produce a timestamp. To produce a time range, we can use:

```py
import pandas as pd
time = pd.date_range("2000-01-01", freq="D", periods=365*3+1) # 2000-Jan-01 to 2002-Dec-31 (3 full years)
time
time.shape    # 1096 days
time.month    # same length (1096), but each element is replaced by the month number
time.day      # same length (1096), but each element is replaced by the day-of-the-month
?pd.date_range
```

Using this `time` construct, let's initialize a time-dependent dataset that contains a scalar temperature variable (no
space) mimicking seasonal change. We can do this directly without initializing an xarray.DataArray first -- we just need
to specify what this temperature variable depends on:

```py
import xarray as xr
import numpy as np
ntime = len(time)
temp = 10 + 5*np.sin((250+np.arange(ntime))/365.25*2*np.pi) + 2*np.random.randn(ntime)
ds = xr.Dataset({ "temperature": ("time", temp),        # it's 1D function of time
                  "time": time })
ds.temperature.plot(size=8)
```

We can do the usual subsetting:

```py
ds.isel(time=100)   # 101st timestep
ds.sel(time="2002-12-22")
```

Time dependency in xarray allows resampling with a different timestep:

```py
ds.resample(time='7D')    # 1096 times -> 157 time groups
weekly = ds.resample(time='7D').mean()     # compute mean for each group
weekly.dims
weekly.temperature.plot(size=8)
```

Now, let's combine spatial and time dependency and construct a dataset containing two 2D variables (temperature and
pressure) varying in time. The time dependency is baked into the coordinates of these xarray.DataArray's and should come
before the spatial coordinates:

```py
time = pd.date_range("2020-01-01", freq="D", periods=91) # January - March 2020
ntime = len(time)
n = 100      # spatial resolution in each dimension
axis = np.linspace(0,1,n)
X, Y = np.meshgrid(axis,axis)   # 2D Cartesian meshes of x,y coordinates
initialState = (1-Y)*np.sin(np.pi*X) + Y*(np.sin(2*np.pi*X))**2
finalState =   (1-X)*np.sin(np.pi*Y) + X*(np.sin(2*np.pi*Y))**2
f = np.zeros((ntime,n,n))
for t in range(ntime):
    z = (t+0.5) / ntime   # dimensionless time from 0 to 1
    f[t,:,:] = (1-z)*initialState + z*finalState

coords = {"time": time, "x": axis, "y": axis}
temp = xr.DataArray(
    20 + f,       # this 2D array varies in time from initialState to finalState
    dims=("time","y","x"),
    coords=coords
)
pres = xr.DataArray(   # random 2D array
    100 + 10*np.random.randn(ntime,n,n),
    dims=("time","y","x"),
    coords=coords
)
ds = xr.Dataset({"temperature": temp, "pressure": pres})
ds.sel(time="2020-03-15").temperature.plot(size=8)   # temperature distribution on a specific date
ds.to_netcdf("evolution.nc")
```

The file `evolution.nc` should be 100^2 x 2 variables x 8 bytes x 91 steps = 14MB. We can load it into ParaView and play
back the pressure and temperature!






## Climate and forecast (CF) NetCDF convention in spherical geometry

So far we've been working with datasets in Cartesian coordinates. How about spherical geometry -- how do we
initialize and store a dataset in spherical coordinates (`lon` - `lat` - `elevation`)? It turns out this is
very easy:
1. define these coordinates and your data arrays on top of these coordinates,
1. put everything into an xarray dataset, and
1. finally specify the following units:

```py
ds.lat.attrs["units"] = "degrees_north"   # this line is important to adhere to CF convention
ds.lon.attrs["units"] = "degrees_east"    # this line is important to adhere to CF convention
```

{{< question num=14.2 >}}
Let's do it! Create a small (one-degree horizontal + some vertical resolution), stationary (no time
dependency) dataset in spherical geometry with one 3D variable and write it to `spherical.nc`. Load it into
ParaView to make sure the geometry is spherical.
{{< /question >}}












## Working with atmospheric data

Let's take a look at some real (but very low-resolution) data stored in the NetCDF-CF convention. Preparing
for this workshop, I took one of the ECCC (Environment and Climate Change Canada) historical model datasets
that contains only the near-surface air temperature and that was published on the CMIP6 Data-Archive. I
reduced its size, picking only a subset of timesteps:

```py
# FYI - here is how I created a smaller dataset
import xarray as xr
data = xr.open_dataset('/Users/razoumov/tmp/xarray/atmosphere/tas_Amon_CanESM5_historical_r1i1p2f1_gn_185001-201412.nc')
data.sel(time=slice('2001', '2020')).to_netcdf("tasReduced.nc")   # last 168 steps
```

Let's download the file `tasReduced.nc` in the terminal:

```sh
wget http://bit.ly/atmosdata -O tasReduced.nc
```

First, quickly check this dataset in ParaView (use Dimensions = (lat,lon)).

```py
data = xr.open_dataset('tasReduced.nc')
data   # this is a time-dependent 2D dataset: print out the metadata, coordinates, data variables
data.time         # time goes monthly from 2001-01-16 to 2014-12-16
data.time.shape   # there are 168 timesteps
data.tas          # metadata for the data variable (time: 168, lat: 64, lon: 128)
data.tas.shape    # (168, 64, 128) = (time, lat, lon)
data.height       # at the fixed height=2m
```

These five lines all produce the same result:

```py
data.tas[0] - 273.15   # take all values at data.time[0], convert to Celsius
data.tas[0,:] - 273.15
data.tas[0,:,:] - 273.15
data.tas.isel(time=0) - 273.15
air = data.tas.sel(time='2001-01-16') - 273.15
```

These two lines produce the same result (1D vector of temperatures as a function of longitude):

```py
data.tas[0,5]
data.tas.isel(time=0, lat=5)
```

Check temperature variation in the last timestep:

```py
air = data.tas.isel(time=-1) - 273.15   # last timestep, to celsius
air.shape    # (64, 128)
air.min(), air.max()   # -43.550903, 36.82956
```

Selecting data is slightly more difficult with approximate floating coordinates:

```py
data.tas.lat
data.tas.lat.dtype
data.tas.isel(lat=0)    # the first value lat=-87.86
data.lat[0]   # print the first latitude and try to use it below
data.tas.sel(lat=-87.86379884)    # does not work due to floating precision
data.tas.sel(lat=data.lat[0])     # this works
latSlice = data.tas.sel(lat=slice(-90,-80))    # only select data in a slice lat=[-90,-80]
latSlice.shape    # (168, 3, 128) - 3 latitudes in this slice
```

Multiple ways to select time:

```py
data.time[-10:]   # last ten times
air = data.tas.sel(time='2014-12-16') - 273.15    # last date
air = data.tas.sel(time='2014') - 273.15    # select everything in 2014
air.shape     # 12 steps
air.time
air = data.tas.sel(time='2014-01') - 273.15    # select everything in January 2014
```

Aggregate functions:

```py
meanOverTime = data.tas.mean(dim='time') - 273.15
meanOverSpace = data.tas.mean(dim=['lat','lon']) - 273.15     # mean over space for each timestep
meanOverSpace.shape     # time series (168,)
meanOverSpace.plot(marker="o", size=8)     # calls matplotlib.pyplot.plot
```

Interpolate to a specific location:

```py
victoria = data.tas.interp(lat=48.43, lon=360-123.37) - 273.15
victoria.shape                      # (168,) only time
victoria.plot(marker="o", size=8)   # simple 1D plot
victoria.sel(time=slice('2010','2020')).plot(marker="o", size=8)   # zoom in on the 2010s points
```

Let's plot in 2D:

```py
air = data.tas.isel(time=-1) - 273.15   # last timestep
air.time
air.plot(size=8)     # 2D plot, very poor resolution (lat: 64, lon: 128)
air.plot(size=8, y="lon", x="lat")     # can specify which axis is which
```

What if we have time-dependency in the plot? We put each frame into a separate panel:

```py
a = data.tas[-6:] - 273.15      # last 6 timesteps => 3D dataset => which coords to use for what?
a.plot(x="lon", y="lat", col="time", col_wrap=3)
```

Breaking into groups and applying a function to each group:

```py
len(data.time)     # 168 steps
data.tas.groupby("time")   # 168 groups
def standardize(x):
    return (x - x.mean()) / x.std()
standard = data.tas.groupby("time").map(standardize)   # apply this function to each group
standard.shape    # (1980, 64, 128) same shape as the original but now normalized over each group
```
