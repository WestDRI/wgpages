+++
title = "Tapping the power of Unix"
slug = "bash-06-wildcards-redirection-pipes"
weight = 6
+++

## Wildcards, redirection to files, and pipes

**Covered topics**: working with multiple files using wildmasks, standard output redirection to a file,
constructing complex commands with Unix pipes.

1. open http://bit.ly/bashfile in your browser, it'll download the file `bfiles.zip`
2. unpack `bfiles.zip` to your home directory; you should see `~/data-shell`

```sh
$ cd <parentDirectoryOf`data-shell`>
$ ls data-shell
$ cd data-shell/molecules
$ ls
$ ls p*   # this is a Unix wildcard; bash will expand it to 'ls pentane.pdb propane.pdb'
$ ls *.pdb      # another wildcard, will expand to "ls cubane.pdb ethane.pdb ...'
$ wc -l *.pdb   # list number of lines in each file
$ wc -l *.pdb > lengths.txt   # redirect the output of the last command into a file
$ more lengths.txt
$ sort -n lengths.txt   # sort numerically, i.e. 2 will go before 10, and 6 before 22
$ sort -n lengths.txt > sorted.txt
$ head -1 sorted.txt    # show the length of the shortest (number of lines) file
$ wc -l *.pdb | sort -n | head -1   # three commands can be shortened to one - this is called Unix pipe
```

Standard input of a process. Standard output of a process. Pipes connect the two.

<!-- > **Exercise:** Try to explain the difference between these two commands: -->
<!-- > ```sh -->
<!-- > echo hello > test.txt -->
<!-- > echo hello >> test.txt -->
<!-- > ~~~ -->

{{< question num=10 >}}
Running `ls -F` in `~/Desktop/Shell/Users/nelle/sugars` results in:
```sh
analyzed/  glucose.dat  mannose.dat  sucrose.dat  fructose.dat  maltose.dat  raw/
```
What code would you use to move all the `.dat` files into the analyzed sub-directory?
{{< /question >}}

{{< question num=11 >}}
In a directory we want to find the 3 files that have the least number of lines. Which command would work for
this?
1. `wc -l * > sort -n > head -3`
2. `wc -l * | sort -n | head 1-3`
3. `wc -l * | head -3 | sort -n`
4. `wc -l * | sort -n | head -3`
{{< /question >}}

{{< question num="`ps`" >}}
Use `ps` command to see how many processes you are running on the training cluster. Explore its flags.
{{< /question >}}

{{< question num=18 >}}
Using Unix pipes, write a one-line command to show the name of the longest `.pdb` file (by the number of lines). Paste
your answer into the chat.
{{< /question >}}

{{< question num=19 >}}
Combine `ls` and `head` and/or `tail` into a one-line command to show three largest files (by the number of bytes) in a
given directory. Paste your answer into the chat.
{{< /question >}}

{{< question num="`echo with wildcards`" >}}
What will the command `echo directoryName/*` do? Try answering without running it. How is this output different from `ls
directoryName` and `ls directoryName/*`?
{{< /question >}}

{{< question num="`redirection`" >}}
Redirection `1>` and `2>` and `/dev/null`
{{< /question >}}

{{< question num="`command separators`" >}}
`;` vs. `&&` separators, e.g. `mkdirr tmp; cd tmp`
{{< /question >}}

<!-- 06-pipes.mkv -->
<!-- {{< yt lueQ-KxLFYI 63 >}} -->
You can {{<a "https://youtu.be/lueQ-KxLFYI" "watch a video for this topic">}} after the workshop.
