+++
title = "Loops"
slug = "bash-07-loops"
weight = 7
+++

# Bash loops

```sh
$ cd ~/Desktop/data-shell/creatures
$ ls   # shows basilisk.dat unicorn.dat -- let's pretend there are several hundred files here
```

Let's say we want to rename:
- basilisk.dat &nbsp;⮕&nbsp; original-basilisk.dat
- unicorn.dat &nbsp;⮕&nbsp; original-unicorn.dat

We could try

```sh
$ mv *.dat original-*.dat   # getting an error
```

Remember if more than two arguments to mv, the last argument is the destination directory, but there is
no directory matching original-*.dat, so we are getting an error. The proper solution is to use loops.

```sh
$ for filename in basilisk.dat unicorn.dat     # filename is the loop variable here
> do
>   ls -l $filename                 # get the value of the variable by placing $ in front of it
> done
```

$filename is equivalent to ${filename}

Let's simplify the previous loop:
```sh
$ for f in *.dat
> do
>   ls -l $f
> done
```

Let's include two commands per each loop iteration:
```sh
$ for f in *.dat
> do
>   echo $f
>   head -3 $f
> done
```

Now to renaming basilisk.dat &nbsp;⮕&nbsp; original-basilisk.dat, unicorn.dat &nbsp;⮕&nbsp; original-unicorn.dat:
```sh
$ for f in *.dat
> do
> cp $f original-$f
> done
```

The general syntax is

```sh
$ for <variable> in <collection>
> do
>   commands with $variable
> done
```

where a collection could be a explicit list of items, a list produced by a wildmask, or a collection of
numbers/letters.

```sh
$ echo {1..10}    # this is called brace expansion
$ echo {1,2,5}    # very useful for loops or for including into large paths with multiple items, e.g.
$ cd ~/Desktop/data-shell/creatures
$ ls -l ../molecules/{ethane,methane,pentane}.pdb
$ echo {a..z}    # can also use letters
$ echo {a..z}{1..10}   # this will produce 260 items
$ echo {a..z}{a..z}    # this will produce 676 items
$ seq 1 2 10      # step=2, so can use: for i in $(seq 1 2 10)
$ for ((i=1; i<=5; i++)) do echo $i; done   # can use C-style loops
```

{{< question num=12 >}}
In a directory the command `ls` returns:
```sh
fructose.dat  glucose.dat  sucrose.dat  maltose.txt
```
What would be the output of the following loop?
```sh
for datafile in *.dat
do
  cat $datafile >> sugar.dat
done
```
1. All of the text from `fructose.dat`, `glucose.dat` and `sucrose.dat` would be concatenated and saved to a
   file called `sugar.dat`
2. The text from `sucrose.dat` will be saved to a file called `sugar.dat`
3. All of the text from `fructose.dat`, `glucose.dat`, `sucrose.dat`, and `maltose.txt` would be concatenated
   and saved to a file called `sugar.dat`
4. All of the text from `fructose.dat`, `glucose.dat` and `sucrose.dat` will be printed to the screen and
   saved into a file called `sugar.dat`
{{< /question >}}

{{< question num="`diff`" >}}
Using `diff` to compare files and directories.
{{< /question >}}

{{< question num="`nested braces`" >}}
Discuss brace expansion. Try nested braces. Paste an example that works.
What will this command do:
```sh
touch 2022-May-{0{1..9},{10..30}}.md
```
{{< /question >}}

{{< question num=20 >}}
Write a loop that concatenates all .pdb files in `data-shell/molecules` subdirectory into one file called
`allmolecules.txt`, prepending each fragment with the name of the corresponding .pdb file, and separating different
files with an empty line. Run the loop, make sure it works, bring it up with the &nbsp;**↑**&nbsp; key and paste into the
chat.
{{< /question >}}

{{< question num="`infinite loop`" >}}
Use Ctrl-C to kill an infinite (or very long) loop or an unfinished command.
```sh
while true
do
    echo "Press [ctrl+c] to stop"
	sleep 1
done
```
{{< /question >}}

{{< question num="`looping through a collection`" >}}
What will the loop `for i in hello 1 2 * bye; do echo $i; done` print? Try answering without running the loop.
{{< /question >}}

{{< question num="`writing to chapters`" >}}
Create a loop that writes into 10 files `chapter01.md`, `chapter02.md`, ..., `chapter10.md`. Each file should contain
chapter-specific lines, e.g. `chapter05.md` will contain exactly these lines:
```sh
## Chapter 05
This is the beginning of Chapter 05.
Content will go here.
This is the end of Chapter 05.
```
{{< /question >}}

{{< question num="`renaming with wildmask`" >}}
Why `mv *.txt *.bak` does not work? Write a loop to rename all .txt files to .bak files. There are several solutions for
changing a file extension inside a loop you know by now.
{{< /question >}}

{{< question num="`spaces to underscores`" >}}
Using knowledge from the previous question, write a loop to replace spaces to underscores in all file names in the
current directory.
```sh
touch hello "first phrase" "second phrase" "good morning, everyone"
ls -l
ls *\ *
```
{{< /question >}}

<!-- 07-loops.mkv -->
<!-- {{< yt cCunoOIksAE 63 >}} -->
You can {{<a "https://youtu.be/cCunoOIksAE" "watch a video for this topic">}} after the workshop.
