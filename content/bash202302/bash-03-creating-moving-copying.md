+++
title = "Creating, moving, and copying"
slug = "bash-03-creating-moving-copying"
weight = 3
+++

## Creating things

**Covered topics**: creating directories with `mkdir`, using `nano` text editor, deleting with `rm` and
`rmdir`.

```sh
$ mkdir thesis
$ ls -F
$ ls -F thesis
$ cd thesis
$ nano draft.txt   # let's spend few minutes learning how to use nano; can also use other editors
$ ls
$ more draft.txt   # displays a file one page at a time
$ cd ..
$ rm thesis   # getting an error - why?
$ rmdir thesis   # again getting an error - why?
$ rm thesis/draft.txt
$ rmdir thesis
```

Also could do 'rm -r thesis' in lieu of the last two commands.

<!-- 03-creating.mkv -->
<!-- {{< yt _tJyfkG-_KA 63 >}} -->
You can {{<a "https://youtu.be/_tJyfkG-_KA" "watch a video for this topic">}} after the workshop.






## Moving and copying things

**Covered topics**: `mv` and `cp`.

```sh
$ mkdir thesis
$ nano thesis/draft.txt
$ ls thesis
$ mv thesis/draft.txt thesis/quotes.txt
$ ls thesis
$ mv thesis/quotes.txt .   # . stands for current directory
$ ls thesis
$ ls
$ ls quotes.txt
```

```sh
$ cp quotes.txt thesis/quotations.txt
$ ls quotes.txt thesis/quotations.txt
$ rm quotes.txt
$ ls quotes.txt thesis/quotations.txt
```

More than two arguments to `mv` and `cp`:

```sh
$ touch  intro.txt  methods.txt  index.txt   # create three empty files
$ ls
$ mv  intro.txt  methods.txt  index.txt  thesis   # the last argument is the destination directory
$ ls
$ ls thesis
```

{{< question num="`misspelled file`" >}}
Suppose that you created a .txt file in your current directory to contain a list of the statistical tests you will need
to do to analyze your data, and named it `statstics.txt`. After creating and saving this file, you realize you
misspelled the filename! You want to correct the mistake, which of the following commands could you use to do so?
1. `cp statstics.txt statistics.txt`
2. `mv statstics.txt statistics.txt`
3. `mv statstics.txt .`
4. `cp statstics.txt .`
{{< /question >}}

<!-- 03-moving.mkv -->
<!-- {{< yt QJGmgfwgBLk 63 >}} -->
You can {{<a "https://youtu.be/QJGmgfwgBLk" "watch a video for this topic">}} after the workshop.







## Aliases

Aliases are one-line shortcuts/abbreviations to avoid typing a longer command, e.g.

```sh
$ alias ls='ls -aFh'
$ alias pwd='pwd -P'
$ alias hi='history'
$ alias top='top -o cpu -s 10 -stats "pid,command,cpu,mem,threads,state,user"'
$ alias cedar='ssh -Y cedar.computecanada.ca'
$ alias weather='curl wttr.in/vancouver'
$ alias cal='gcal --starting-day=1'  # starts on Monday
```

Now, instead of typing `ssh -Y cedar.computecanada.ca`, you can simply type `cedar`. To see all your
defined aliases, type `alias`. To remove, e.g. the alias `cedar`, type `unalias cedar`.

You may want to put all your alias definitions into the file `~/.bashrc` which is run every time you
start a new local or remote shell.

{{< question num="`safer mv and cp`" >}}
Write simple aliases for safer `mv`, `cp` so that these do not automatically overwrite the target. Hint: use their
manual pages. Where would you store these aliases?
{{< /question >}}

{{< question num="`safer rm`" >}}
Write simple alias for safer `rm`.
{{< /question >}}

{{< question num=9 >}}
What is the output of the last `ls` command in the sequence shown below?
```sh
$ pwd
/home/jamie/data
$ ls
proteins.dat
$ mkdir recombine
$ mv proteins.dat recombine
$ cp recombine/proteins.dat ../proteins-saved.dat
$ ls
```
1. `proteins-saved.dat recombine`
2. `recombine`
3. `proteins.dat recombine`
4. `proteins-saved.dat`
{{< /question >}}
