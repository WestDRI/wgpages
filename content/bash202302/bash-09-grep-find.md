+++
title = "Grep and find"
slug = "bash-09-grep-find"
weight = 9
+++

## Searching inside files with `grep`

```sh
$ cd ~/Desktop/data-shell/writing
$ more haiku.txt
```

First let's search for text in files:

```sh
$ grep not haiku.txt     # let's find all lines that contain the word 'not'
$ grep day haiku.txt     # now search for word 'day'
$ grep -w day haiku.txt     # search for a separate word 'day' (not 'today', etc.)
$ grep -w today haiku.txt   # search for 'today'
$ grep -w Today haiku.txt   # search for 'Today'
$ grep -i -w today haiku.txt       # both upper and lower case 'today'
$ grep -n -i -w today haiku.txt    # -n prints out numbers the matching lines
$ grep -n -i -w -v the haiku.txt   # -v searches for lines that do not contain 'the'
$ man grep
```

More than two arguments to grep:

```sh
$ grep pattern file1 file2 file3   # all argument after the first one are assumed to be filenames
$ grep pattern *.txt   # the last argument will expand to the list of *.txt files
```




{{< question num="`dissecting a haiku`" >}}
```txt
The Tao that is seen
Is not the true Tao, until
You bring fresh toner.
With searching comes loss
and the presence of absence:
"My Thesis" not found.
Yesterday it worked.
Today it is not working.
Software is like that.
```
From the above text, contained in the file `haiku.txt`, which command would result in the following output:
```txt
and the presence of absence:
```
1. `grep of haiku.txt`
2. `grep -E of haiku.txt`
3. `grep -w of haiku.txt`
{{< /question >}}





<!-- 09-grep.mkv -->
<!-- {{< yt mbZ8nB-V4zQ 63 >}} -->
You can {{<a "https://youtu.be/mbZ8nB-V4zQ" "watch a video for this topic">}} after the workshop.





## Finding files with `find`

Now on to finding files:

```sh
cd ~/Desktop/data-shell/writing
$ find . -type d     # search for directories inside current directory
$ find . -type f     # search for files inside current directory
$ find . -maxdepth 1 -type f     # depth 1 is the current directory
$ find . -mindepth 2 -type f     # current directory and one level down
$ find . -name haiku.txt      # finds specific file
$ ls data       # shows one.txt two.txt
$ find . -name *.txt      # still finds one file -- why? answer: expands *.txt to haiku.txt
$ find . -name '*.txt'    # finds all three files -- good!
```

Let's wrap the last command into $() (called *command substitution*), as if it was a variable:

```sh
$ echo $(find . -name '*.txt')   # will print ./data/one.txt ./data/two.txt ./haiku.txt
$ ls -l $(find . -name '*.txt')   # will expand to ls -l ./data/one.txt ./data/two.txt ./haiku.txt
$ wc -l $(find . -name '*.txt')   # will expand to wc -l ./data/one.txt ./data/two.txt ./haiku.txt
$ grep elegant $(find . -name '*.txt')   # will look for 'elegant' inside all *.txt files
```




{{< question num="`somewhat tricky problem`" >}}
The `-v` flag to `grep` inverts pattern matching, so that only lines that do not match the pattern are printed. Given
that, which of the following commands will find all files in `/data` whose names end in `ose.dat` (e.g., `sucrose.dat`
or `maltose.dat`), but whose names do not contain the word `temp`?
1. `find /data -name '*.dat' | grep ose | grep -v temp`
2. `find /data -name ose.dat | grep -v temp`
3. `grep -v temp $(find /data -name '*ose.dat')`
4. None of the above
{{< /question >}}






<!-- 09-find.mkv -->
<!-- {{< yt AnwsnESj82Q 63 >}} -->
You can {{<a "https://youtu.be/AnwsnESj82Q" "watch a video for this topic">}} after the workshop.






## Combining `find` and `grep`
<!-- ## Running a command on the results of `find` -->

Let's say you want to run a command on each of the files in the output of `find`. You can always do something
using command substitution like this:

```sh
$ for f in $(find . -name "*.txt")
> do
>   command on $f
> done
```

Alternatively, you can make it a one-liner:

```sh
find . -name "*.txt" -exec command {} \;       # important to have spaces
```

Another -- perhaps more elegant -- one-line alternative is to use `xargs`. In its simplest usage, `xargs`
command lets you construct a list of arguments:

```sh

find . -name "*.txt"                   # returns multiple lines
find . -name "*.txt" | xargs           # use those lines to construct a list
find . -name "*.txt" | xargs command   # pass this list as arguments to `command`
command $(find . -name "*.txt")        # command substitution, achieving the same result (this is riskier!)
command `(find . -name "*.txt")`       # alternative syntax for command substitution
```

In these examples, `xargs` achieves the same result as command substitution, but it is safer in terms of
memory usage and the length of lists you can pass.

Where would you use this? Well, consider `grep` command that takes a search stream (and not a list of files)
as its standard input:

```sh
cat filename | grep pattern
```

To pass a list of files to grep, you can use `xargs` that takes that list from its standard input and converts
it into a list of arguments that is then passed to `grep`:

```sh
find . -name "*.txt" | xargs grep pattern   # search for `pattern` inside all those files (`grep` does not take a list of files as standard input)
```

{{< question num="`recursive search`" >}}
Write a one-line command that will search for a string in all files in the current directory and all its subdirectories,
and will hide errors (e.g. due to permissions).
{{< /question >}}

{{< question num="`command substitution`" >}}
Play with command substitution using both `$(...)` and ``` `...` ``` syntax.
{{< /question >}}

<!-- 09-findgrep.mkv -->
<!-- {{< yt aFrMKkjMIHY 63 >}} -->
You can {{<a "https://youtu.be/aFrMKkjMIHY" "watch a video for this topic">}} after the workshop.
