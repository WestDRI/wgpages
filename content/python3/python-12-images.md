+++
title = "Image manipulation, hierarchical data, time"
slug = "python-12-images"
weight = 12
+++

## Image manipulation with `scikit-image`

<!-- pip install scikit-image matplotlib -->

Several image-processing libraries use numpy data structures underneath, e.g. `Pillow` and `skimage.io`. Let's
take a look at the latter.

```py
from skimage import io   # scikit-image is a collection of algorithms for image processing
image = io.imread(fname="https://raw.githubusercontent.com/razoumov/publish/master/grids.png")
type(image)   # numpy array
image.shape   # 1024^2 image, with three colour (RGB) channels
```

Let's plot this image using matplotlib:

```py
io.imshow(image)
# io.show()   # only if working in a terminal
# io.imsave("tmp.png", image)
```

Using numpy, you can easily manipulate pixels, e.g.

```py
image[:,:,2] = 255 - image[:,:,2]
```

and then plot it again.






## Hierarchical data formats

<!-- show hierarchical data structures and how to save them to disk -->

We already saw Python dictionaries. You can save them in a file using a variety of techniques. One of the most
popular techniques, especially among web developers, is JSON (JavaScript Object Notation), as its internal
mapping is similar to that of a Python dictionary, with key-value pairs. In the file all data are stored as
human-readable text, including any non-ASCII (Unicode) characters.

```py
import json
x = {
  "name": "John",
  "age": 30,
  "married": True,
  "children": ("Ann","Billy"),
  "pets": None,
  "cars": [
    {"model": "BMW 230", "mpg": 27.5},
    {"model": "Ford Edge", "mpg": 24.1}
  ]
}
len(x)     # 6 key-value pairs
x.keys()   # here are the keys

filename = open("personal.json", "w")
json.dump(x, filename, indent = 2)   # serialize `x` as a JSON-formatted stream to `filename`
                  # `indent` sets field offsets in the file (for human readability)
filename.close()

...

import json
filename = open("personal.json", "r")
data = json.load(filename)   # read into a new dictionary
filename.close()
for k in data:
    print(k, data[k])
```

If you want to read larger and/or binary data, there is BSON format. Going step further, there are popular
scientific data formats such as NetCDF and HDF5 for storing large multi-dimensional arrays and/or large
hierarchical datasets, but we won't study them here.






## Working with time

In its standard library Python has high-level functions to work with time and dates:

```py
from time import *
gmtime(0)   # show the starting epoch on my system (typically 1970-Jan-01 on Unix-like systems)
time()      # number of seconds since then = current time
ctime(time())   # convert that to human-readable time
ctime()         # same = current time

local = localtime()   # convert current date/time to a structure
local.tm_year, local.tm_mon, local.tm_mday
local.tm_hour, local.tm_min, local.tm_sec
local.tm_zone     # my time zone
local.tm_isdst    # Daylight Saving Time 1=on or 0=off
```

You can find many more examples {{<a "https://realpython.com/python-time-module" "here">}}.

<!-- could also cover Pendulum library https://pendulum.eustace.io -->
