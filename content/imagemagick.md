+++
title = "Command-line image processing with ImageMagick"
slug = "imagemagick"
+++

# https://wgpages.netlify.app/imagemagick

{{<cor>}}January 9th, 2024{{</cor>}}\
{{<cor>}}Presenter: Alex Razoumov{{</cor>}}

<!-- Abstract: ImageMagick is an open-source tool for manipulating images. You can use it to convert images between -->
<!-- different formats, including JPEG, PNG, PDF, AVIF, TIFF and many others. ImageMagick can also resize, rotate, -->
<!-- crop, and transform images, adjust colours, apply special effects, and draw basic shapes. First released in -->
<!-- 1990, ImageMagick has grown to include hundreds of features. It runs on Linux, Mac, Windows, and is also -->
<!-- available on the Alliance clusters. In this webinar I will try to help you navigate ImageMagick's myriad of -->
<!-- functions by showing some command-line workflows most common in scientific research. -->

- Open-source and multi-platform
- Created by John Cristy in 1987
- Understands 200+ image file formats
- Available as a *command line tool* and *via APIs* for various languages: PythonMagick, RMagick,
  ImageMagick.jl, Magick++, and many others
  - for details see https://imagemagick.org/script/develop.php
- Latest version 7.1.1

What we are not covering today:
- APIs
- GraphicsMagick (fork of ImageMagick)
- Using ImageMagick for animations -- for that I recommend `ffmpeg`
- More complex workflows (layers, mathematical algorithms, ...)

## Installation

Binary packages for Linux/Mac/Windows are available from https://imagemagick.org/script/download.php, or you
can compile from source. On a Mac you can use `brew`:

```sh
brew install ghostscript   # Ghostscript fonts needed for ImageMagick
brew install imagemagick
```

On the Alliance clusters, as of this writing, ImageMagick 7.0.10-7 is part of gentoo/2020 (loaded by
default). I'll run a demo on Cedar at the very end of this workshop.

## Basic usage

```sh
magick tool [ {option} | {image} ... ] {output_image}
```

where `<tool>` is one of the 11 commands: `animate`, `compare`, `composite`, `conjure`, `convert`, `display`,
`identify`, `import`, `mogrify`, `montage`, `stream`. I'll show where to find this list in a few minutes.

Starting with version 6, the operators (options) will always be applied in the command line order given by the user.

```sh
magick convert ...      # full version of a command
convert ...             # shorter version of the same command
magick {options} ...    # occasionally we will use this syntax
```

Let's start with a very simple example:

```sh
convert https://images.pexels.com/photos/35600/road-sun-rays-path.jpg forest.jpg
identify forest.jpg
identify -verbose forest.jpg   # a lot more additional information
identify -format '%f %wx%h %[channels] %[bit-depth]-bit %Q\n' forest.jpg   # only specific fields
```

Here we are showing the filename (`%f`), image's width and height (`%wx%h`), colour space and the number of
channels (`%[channels]`), its bit depth(`%[bit-depth]`), and the compression quality (`%Q`). More details on
the `-format` option at https://imagemagick.org/script/escape.php

You might find it useful to define an alias:

```sh
alias size="identify -format '%f %wx%h\n'"
size forest.jpg
```

```sh
convert forest.jpg forest.png
convert -list format   # see the list of support image formats

convert forest.jpg forest.avif   # modern open-source image format released in 2019-Feb
                                 # by the Alliance for Open Media (lossless and lossy)
convert forest.jpg forest.webp   # Google's open-source format from 2011 (lossless and lossy)
```

<!-- AVIF and WEBP details at https://www.smashingmagazine.com/2021/09/modern-image-formats-avif-webp -->
<!-- https://avif.io/blog/tutorials/imagemagick -->

```sh
ls -l $(which convert)
which convert | xargs realpath | xargs dirname | xargs ls   # check tools in /opt/homebrew/Cellar/imagemagick/7.1.1-24/bin

convert https://upload.wikimedia.org/wikipedia/commons/2/2c/NZ_Landscape_from_the_van.jpg hills.avif
convert https://upload.wikimedia.org/wikipedia/commons/5/5e/Deserto_libico_-_Driving_-_panoramio.jpg desert.avif
convert https://upload.wikimedia.org/wikipedia/commons/e/e0/Clouds_over_the_Atlantic_Ocean.jpg ocean.avif

man convert   # over a 100 flags! convert + resize, blur, crop, despeckle, dither, draw on, flip, join, re-sample, and much more
```

Notice that the manual page also links to the offline (local file) HTML-formatted documentation:

```sh
open file:///opt/homebrew/Cellar/imagemagick/7.1.1-24/share/doc/ImageMagick-7/www/convert.html
```

## Resizing

```sh
convert forest.avif -resize 50% f1.avif

-resize 50%           # keep the aspect ratio
-resize 1600x1600     # convert to 1600x1067 keeping the aspect ratio, i.e. keep each side 1600 or smaller
-resize 1600x1600\!   # same and then stretch to 1600x1600
-resize 1600x         # convert to 1600x1067 (specify width)
-resize x1600         # convert to 2400x1600 (specify height)
-resize 50% -grayscale Rec709Luminance   # example of using two flags; use Rec709Luminance grayscale
```

## Cropping and regions

To crop to a single smaller image, you must specify an offset:

```sh
convert forest.avif -crop 500x500+800+1050 f1.avif   # crop a 500x500 region at a specific offset
convert forest.avif -crop +800+1050 f1.avif   # crop starting at an offset to the lower right corner
convert forest.avif -crop 2656x1254+0+0 f1.avif   # crop from the upper left corner to +2656+1254
```

{{< bigQuestion >}}
**Take-home exercise**: write a bash script to crop ten random 500x500 images out of `forest.avif`. There is a
solution somewhere [on this page](https://wgpages.netlify.app/pytables), but check it only after you write
your own script.
{{< /bigQuestion >}}

Without an offset, `crop` will segment the original image:

```sh
convert -crop 30%x100% forest.avif pieces.png    # crop the image into 30%+30%+30%+10% pieces
convert -crop 30%x100% forest.avif pieces.avif   # all four images get written to one AVIF
convert -crop 30% forest.avif pieces.avif        # will use 30%+30%+30%+10% in both dimensions => 16 images
convert -crop 512x512 forest.avif pieces.avif    # crop into 512x512 pieces => 35 images
convert -crop 512x forest.avif pieces.avif       # crop horizontally only => 7 images
```

You can apply operators to a portion of an image:

```sh
convert forest.avif -negate f1.avif   # negate the entire image
convert forest.avif -gravity Center -region 300x300 -negate f1.avif   # negate a 300x300 region
                                                             # in the center (order is important!)
                             NorthEast                       # upper right corner
convert -list gravity                                        # list all 11 options
convert forest.avif -region 300x300+1600+100 -blur 0,10 f1.avif   # specify exact position; blur {radius}x{sigma}
```

{{< bigQuestion >}}
**Question**: How do we blur an entire image?
{{< /bigQuestion >}}

## Whole-image transforms

```sh
-flip        # vertically
-flop        # horizontally
-rotate 90   # could be any number, not just 90/180/270 - will introduce borders
-transpose 	 # flip vertically + rotate 90 degrees
-transverse  # flip horizontally + rotate 270 degrees

-border 10   # surround the image with a light gray border of width=10 on all four sides
-bordercolor yellow -border 10    # same, with yellow border (order is important!)

convert Screenshot*.png -transparent white -fuzz 3% f1.avif
```

## In-place and batch processing

The command `mogrify` is similar to `convert`, but it overwrites the original image by default (in-place
processing), so it can be used on a batch of images.

```sh
mogrify -resize 80% ocean.avif        # overwrite the original
mogrify -format png -resize 1000x -depth 8 *.avif   # convert all AVIFs to 8-bit colour 1000x PNGs

cp ~/talks/2024/01a-imagemagick/hybridParallelism.svg .
mogrify -background "#d3d3d3" -format png hybridParallelism.svg   # set the background color
mogrify -transparent "#d3d3d3" hybridParallelism.png              # make the background transparent
mogrify -background none -format png hybridParallelism.svg        # PNG without a background
```

The end result is the same in both cases (`-transparent "#d3d3d3"` and `-background none`), but the image with
the transparent background has more information in it (check with `ls -l`) which is hidden by the alpha
(opacity) channel. We'll explore this when we talk about channels.

## Joining images

### Joining horizontally:

```sh
montage -geometry x1200 desert.avif forest.avif mosaic1.avif   # create a composite image from two AVIFs
convert -geometry x1200 desert.avif forest.avif +append mosaic2.avif   # same but without a gap
convert -geometry x1200 -border 30 desert.avif forest.avif +append mosaic2.avif   # add border around each image
mogrify -trim mosaic2.avif   # trim at the end (removes any edges of the same color as the corner pixels)
```

The flag `-trim` does not work very well in this two-step process. You can get better results by combining the
last two commands into one:

```sh
convert -geometry x1200 -border 30 desert.avif forest.avif +append -trim mosaic2.avif
```

Here processing happens from left to right.

### Joining vertically:

```sh
convert -geometry 1200x desert.avif forest.avif -append mosaic2.avif   # merge vertically without a gap
convert -geometry 1200x -border 10 desert.avif forest.avif -append mosaic2.avif   # merge with a border around each image
mogrify -shave 10x10 mosaic2.avif   # remove the outer border; more reliable than -trim
convert -geometry 1200x -border 10 desert.avif forest.avif -append -shave 10x10 mosaic2.avif # combine the two commands into one
```

### Automating these with bash functions

I find it difficult to remember all this syntax, so I like automating these commands with functions, e.g.


```sh
function mergeImagesVertically() {
    if [ $# == 0 ]; then
        echo Usage: mergeImagesVertically -o outputImage sharedSideSize inputImage1 inputImage2 ...
        return 1
    fi
    size=$3
    output=$2
    shift 3
    convert -geometry ${size}x $@ -append $output
}
function mergeImagesHorizontally() {
    if [ $# == 0 ]; then
        echo Usage: mergeImagesHorizontally -o outputImage sharedSideSize inputImage1 inputImage2 ...
        return 1
    fi
    size=$3
    output=$2
    shift 3
    convert -geometry x${size} $@ +append $output
}
```

Then the command

```sh
convert -geometry 1200x desert.avif forest.avif -append mosaic2.avif   # merge vertically without a gap
```

becomes

```sh
mergeImagesVertically -o mosaic2.avif 1200 desert.avif forest.avif
```

### 2D joining

Let's create a 2x2 mosaic with a gap between images:

```sh
convert -geometry 1200x -border 10 desert.avif forest.avif -append -shave 10x10 mosaic1.avif
convert -geometry 1200x -border 10 hills.avif ocean.avif -append -shave 10x10 mosaic2.avif
identify mosaic{1,2}.avif
convert -geometry x1620 -border 10 mosaic{1,2}.avif +append -shave 10x10 mosaic3.avif
```

Alternatively, you can create a 2x2 mosaic in one command with montage

```sh
montage -geometry x1200 desert.avif forest.avif hills.avif ocean.avif mosaic4.avif   # all the same height
montage -geometry 1200x desert.avif forest.avif hills.avif ocean.avif mosaic4.avif   # all the same width
montage -geometry 1200x1200 desert.avif forest.avif hills.avif ocean.avif mosaic4.avif # still all the same width; wider gaps
montage -geometry 1200x1200\! desert.avif forest.avif hills.avif ocean.avif mosaic4.avif   # all stretched to same size
```

I much prefer mosaic3.avif, as it (1) keeps all original aspect ratios and (2) does not waste space.

### Adding images to a new canvas

Let's place `desert.avif` into a new 520x300 canvas:

```sh
convert desert.avif -resize 10% -gravity center -background white -extent 520x300 overlap.avif
convert desert.avif -resize 10% -bordercolor white -border 51x37 overlap.avif   # exactly the same result
```

Now let's add a second image using \( ... \) to apply resize only to second image

```sh
convert overlap.avif \( forest.avif -resize 100x100 \) -gravity northeast -composite overlap.avif
```

Alternatively, we can start with an empty canvas and add images one-by-one:

```sh
magick -size 520x300 canvas:skyblue overlap.avif  # create an empty canvas
convert overlap.avif \( desert.avif -resize 10% \) -gravity center -composite overlap.avif
convert overlap.avif \( forest.avif -resize 100x100 \) -gravity northeast -composite overlap.avif
convert overlap.avif \( ocean.avif -resize 100x100 \) -geometry +100+220 -composite overlap.avif # use -geometry for position
convert overlap.avif hills.avif -geometry 100x100+250+220 -composite overlap.avif   # use -geometry for both size and position
```
							






## Drawing

### Basic shapes

Drawing falls into more advanced ImageMagick usage, and it can get complicated very quickly. Here I will show
just a few shorter commands. For more examples see https://imagemagick.org/Usage/draw.

In these examples `xc:<colour>` produces a window fill colour:

```sh
magick -size 500x300 xc:skyblue empty.avif   # create an empty canvas
magick -size 500x300 xc:skyblue -fill blue -stroke black -strokewidth 5 \
	   -draw "line 180,180 390,170" -draw "line 160,130 370,210" drawing.avif

magick -size 500x300 xc:skyblue -fill white -stroke black \
       -draw "                    rectangle  25,50  75,250 " \
       -draw "fill-opacity 0.8    rectangle 100,50 150,250 " \
       -draw "fill-opacity 0.6    rectangle 175,50 225,250 " \
       -draw "fill-opacity 0.4    rectangle 250,50 300,250 " \
       -draw "fill-opacity 0.2    rectangle 325,50 375,250 " \
       -draw "fill-opacity  0     rectangle 400,50 450,250 " \
       drawing.avif
  
magick -size 500x300 xc:skyblue -fill white -stroke black \
       -draw "path 'M 200,50 100,250 450,50 350,200 Z'" drawing.avif # M starts the path, Z closes it

magick -size 500x300 xc:skyblue -fill white -stroke black \
       -draw "fill-rule evenodd \
                 path 'M 200,50 100,100 350,250 Z
                       M 100,200 350,200 450,50 Z
                       M 230,270 290,60 310,250 Z'" drawing.avif
magick -list fill-rule

magick -size 500x300 xc:skyblue -fill white -draw 'circle 250,150 250,50' drawing.avif # centre and a point on the circumference
```

### Text

Now let's try adding text to images. First, check the available fonts:

```sh
convert -list font   # list all fonts, 2171 on my laptop
```

The flag `-pointsize <size>` below sets the font size. Let's pick one of the fonts:

<!-- https://imagemagick.org/Usage/text/#coloring_text -->

```sh
magick -size 700x300 xc:#71928C -draw 'text 100,200  "Hello!"' hello.avif
magick -size 700x300 xc:#71928C -pointsize 210 -font Times-New-Roman-Italic \
	   -fill white -stroke black -strokewidth 2 -draw 'text 100,200  "Hello!"' hello.avif
```

Note that the order of the flags is very important here!

We can also compare multiple fonts:

```sh
for font in AvantGarde-Book AvantGarde-BookOblique AvantGarde-Demi \
							AvantGarde-DemiOblique Bookman-Demi; do
	magick -size 1200x120 xc:lightblue  -pointsize 50 -font $font \
		   -fill black -draw "text 30,80 'Hello! with $font'" font-${font}.avif
done
convert font*.avif -append someFonts.avif

convert -list font | grep "Font:" > fonts.txt
for font in $(awk -F": " '{print $2}' fonts.txt ); do
	magick -size 1200x120 xc:lightblue  -pointsize 50 -font $font \
		   -fill black -draw "text 30,80 'Hello! with $font'" font-${font}.avif
done

magick -size 680x950 xc:#71928C -pointsize 180 -font Apple-Chancery \
      -fill white -stroke none                 -draw 'text 30,180  "Stroke -"' \
      -fill white -stroke black -strokewidth 0 -draw 'text 30,360 "Stroke 0"' \
      -fill white -stroke black -strokewidth 2 -draw 'text 30,540 "Stroke 2"' \
      -fill white -stroke black -strokewidth 4 -draw 'text 30,720 "Stroke 4"' \
      -fill white -stroke black -strokewidth 6 -draw 'text 30,900 "Stroke 6"' \
      strokes.jpg
```

How about adding text to an existing image?

```sh
identify -format '%wx%h\n' forest.avif   # get the size
convert forest.avif -pointsize 60 -fill white -font Apple-Chancery -draw "text 3100,2250 'forest road'" f1.avif
convert forest.avif -pointsize 60 -fill white -gravity southeast -annotate 0 "forest road" f1.avif # 0 is rotation in degrees
```







## Working with channels

<!-- https://imagemagick.org/Usage/color_basics -->
<!-- https://imagemagick.org/Usage/masking -->
<!-- file:///opt/homebrew/Cellar/imagemagick/7.1.1-24/share/doc/ImageMagick-7/www/compose.html -->

Start with some large text on a canvas, and add a smaller line with a different colour:

```sh
magick -size 700x300 xc:#71928C -pointsize 210 -font Times-New-Roman-Italic \
	-fill white -draw 'text 100,200 "Hello!"' hello.png
magick hello.png -pointsize 40 -fill "#71739C" -draw 'text 100,260 "This text will be hidden."' hello.png
```

Make the background transparent -- this will also apply to the smaller line:

```sh
convert -transparent "#71928C" -fuzz 10% hello.png helloTransparent.png
```

Next, we overlay over a checked background; `dst_over` means "destination is composited over the source":

```sh
composite -compose dst_over -tile pattern:checkerboard helloTransparent.png helloChecked.png   # no hidden text
```

The hidden text is still present in the transparent image, even though you cannot see it. Let's turn the alpha
channel off in the transparent image:

```sh
convert helloTransparent.png -alpha off alphaOff.png   # hidden text still there; transparency data not in alphaOff.png
convert helloTransparent.png helloTransparent.jpg    # JPG does not support transparency; so the hidden text is there
convert helloTransparent.png helloTransparent.avif && convert helloTransparent.avif -alpha off alphaOff.avif
         # AVIF supports transparency; note the AVIF compression of the hidden text!
```

Extract the alpha channel:

```sh
convert helloTransparent.png -alpha extract alphaOnly.png   # alpha channel only
                             -channel alpha -separate       # same
```

In fact, we can extract any channel from an image:

```sh
# separate the alpha+RGB channels
convert helloTransparent.png -channel alpha -separate helloAlpha.avif
convert helloTransparent.png -channel red -separate helloRed.avif
convert helloTransparent.png -channel green -separate helloGreen.avif
convert helloTransparent.png -channel blue -separate helloBlue.avif
open hello{Red,Green,Blue,Alpha}.avif
```

Now, recall `helloChecked.png` (we ran this command earlier):

```sh
composite -compose dst_over -tile pattern:checkerboard helloTransparent.png helloChecked.png

convert helloTransparent.png -channel alpha -negate h1.png   # negate the alpha channel
composite -compose dst_over -tile pattern:checkerboard h1.png helloCheckedReverse.png
```

The image `helloTransparent.png` has alpha either at 0% or 100% (only two values). Let's add 75% to alpha
(it'll truncate values over 100%):

```sh
convert helloTransparent.png -channel alpha -evaluate add 75% h2.png   # now 75% < alpha < 100%
open hello.png h2.png
composite -compose dst_over -tile pattern:checkerboard h2.png helloCheckedPartialTransparency.png
open helloChecked.png helloCheckedPartialTransparency.png

convert -list evaluate   # print all -evaluate operators

convert forest.avif -channel blue -evaluate multiply 0.1 f1.avif   # reduce blue colour by 10X
convert forest.avif -channel red -evaluate set 0 f1.avif           # remove red colour completely
```

Let's superimpose two images with 40% transparency, keeping all original colours:

```sh
convert ocean.avif -geometry 1600x1000\! -alpha set -channel A -evaluate set 40% o40.avif
convert desert.avif -geometry 1600x1000\! -alpha set -channel A -evaluate set 40% d40.avif
composite -compose dst_over o40.avif d40.avif oceanDesert.avif
```






## Replacing colours in-place

You can also modify colours without using channels.

```sh
convert -size 500x500 xc:black squares.png                         # empty image
mogrify -fill red -draw "rectangle 0,0 250,250 " squares.png       # add red quadrant
mogrify -fill green -draw "rectangle 251,0 500,250 " squares.png   # add green quadrant
mogrify -fill blue -draw "rectangle 0,251 250,500 " squares.png    # add blue quadrant
convert squares.png -fill turquoise -opaque black adjusted.png   # change "opaque" color to "fill" color
```

Let's try the same technique on an actual photo, picking `#094C9A` (deep blue) colour and changing just those
pixels:

```sh
convert ocean.avif -fill turquoise -opaque "#094C9A" o1.avif
convert ocean.avif -fuzz 10% -fill turquoise -opaque "#094C9A" o1.avif   # widen our colour match
```









## Display

On MacOS, X11 support is not built into precompiled ImageMagick, so I can't demo it for you locally on my
laptop. I can demo it on Cedar:

```sh
convert ocean.avif -resize 30% ocean.jpg
scp ocean.jpg cedar:
ssh -X cedar
display ocean.jpg   # for this you need an X11 server on your computer (XQuartz on MacOS);
                    # click on the image for menu; press Q to quit
```








## Other

```sh
convert -size 500x500 xc:white -evaluate gaussian-noise 10 noise.avif    # produce Gaussian noise
convert -size 500x500 xc:white -evaluate PoissonNoise 0.01 noise.avif    # produce Poisson noise
convert -size 500x500 xc:white -evaluate uniform-noise 1000 noise.avif   # produce uniform noise
convert -list color   # list all 678 named colours
```







<!-- ## Misc -->

<!-- merge frames -->

<!-- ```sh -->
<!-- wget https://transfer.sh/15kP5b/plotly.tar.gz -->
<!-- unpack it and cd there -->
<!-- # transp='-fuzz 10% -transparent white' -->
<!-- transp='-transparent white' -->
<!-- convert lines.png population.png combine.png citiesByPopulation.png $transp +append -geometry 1600x row1.png -->
<!-- convert network.png bubbles.png parametric.png $transp +append -geometry 1600x row2.png -->
<!-- convert contour.png orthogonal.png isosurface.png $transp +append -geometry 1600x row3.png -->
<!-- convert row{1..3}.png $transp -append thumbs.png -->
<!-- wget https://www.westgrid.ca/files/wesgrid_logo_2016.png -O logo.png -->
<!-- convert logo.png -fuzz 10% -transparent white logoTransparent.png -->
<!-- convert growth.png -fuzz 10% -transparent 'rgb(86,86,86)' growth.png -->

<!-- convert input.jpg -resize 80x80^ -gravity center -extent 80x80 icon.png -->
<!-- mogrify -format jpg -quality 85 *.png   # convert all images -->

<!-- convert $1 -channel RGB -negate $1 -->

<!-- function pdf2jpg -->

<!-- -fx expression -->
<!-- ``` -->



<!-- ## Marie's list -->

<!-- - batch processing -->
<!-- - removing background -->
<!-- - changing background colour -->
<!-- - adding background -->
<!-- - resizing -->
<!-- - pasting images side by side or in a canvas -->
<!-- - cropping -->
<!-- - changing image resolution -->
<!-- - turn pdf to png -->
<!-- - get image size -->
<!-- - add alpha layer -->







<!-- ## GraphicsMagick -->

<!-- brew install GraphicsMagick    # fork of ImageMagick -->

<!-- ```sh -->
<!-- gm               # get help on all commands -->
<!-- gm <command>     # get help on a specific command -->
<!-- wget https://images.pexels.com/photos/35600/road-sun-rays-path.jpg -->
<!-- gm convert road-sun-rays-path.jpg -resize 1600x1600 forest.png -->
<!-- gm convert forest.png forest.jpg -->
<!-- ``` -->

<!-- http://www.graphicsmagick.org/GraphicsMagick.html -->
<!-- - Resize, rotate, sharpen, color reduce, or add special effects to an image -->
<!-- - Create a montage of image thumbnails -->
<!-- - Create a transparent image suitable for use on the Web -->
<!-- - Compare two images -->
<!-- - Turn a group of images into a GIF animation sequence -->
<!-- - Create a composite image by combining several separate images -->
<!-- - Draw shapes or text on an image -->
<!-- - Decorate an image with a border or frame -->
<!-- - Describe the format and characteristics of an image -->

## Links

- http://www.imagemagick.org/Usage
- file:///opt/homebrew/Cellar/imagemagick/7.1.1-24/share/doc/ImageMagick-7/www/command-line-options.html
- https://en.wikipedia.org/wiki/ImageMagick
- https://imagemagick.org/script/command-line-tools.php
- http://www.imagemagick.org/script/command-line-options.php
- https://imagemagick.org/script/stream.php
- https://devhints.io/imagemagick
- https://github.com/yangboz/imagemagick-cheatsheet
