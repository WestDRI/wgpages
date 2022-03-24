+++
title = "Bash scripting for beginners"
slug = "bashscripting"
katex = true
+++

{{<cor>}}Thursday, Mar-24, 2022 {{</cor>}}\
{{<cgr>}}1:00pm - 2:30pm Pacific Time {{</cgr>}}

The command line is a quick and powerful text-based interface to Linux computers that allows us to accomplish a wide set
of tasks very efficiently. In this workshop we focus on writing and running scripts and functions in Bash. Scripts are
great for simplifying and automating your workflows on any computer with Bash installed, whether it is your own laptop
or a remote HPC cluster (where the command line is often the only available interface). You don't need to know Bash to
attend this workshop, as we will start from the basics and will slowly build up our skills using many hands-on examples.

**Software**: If you want to follow along the hands-on part of this workshop, you will need a terminal emulator. Linux
and MacOS probably already have one, and Windows users can install the free version of MobaXterm (see
https://mobaxterm.mobatek.net/download.html for installation) to connect to our remote server. With MobaXterm you can
also run a local terminal emulator, but we are not sure about the set of bash commands available there, so with Windows
we highly recommend connecting to our system (we will provide guest accounts).

## Access to the remote system

We will be connecting to a remote training cluster at 206.12.96.223. We will paste the link to the Google Doc with the
usernames into the Zoom chat.

## Simple script examples

1. `#!/bin/bash` she-bang
1. write a script `countFiles.sh` to count files in the current directory
1. setting internal variables
1. result of a bash command inside the script $~\Rightarrow~$ `echo "we found $num files"`

```sh
#!/bin/bash
num=$(find . -type f | wc -l)
echo "we found $num files"
```

## Scripts vs. functions

A **bash script** is an executable file sitting at a given path. A **bash function** is defined in your environment,
usually from your `~/.bashrc` file.

Let's convert `countFiles.sh` into a function `countFiles()` that we define inside our `~/.bashrc`. To do that, we'll
have to pass a directory name to the script.

## Processing command-line arguments

1. processing individual arguments
1. processing all arguments
1. return a usage page if there are no arguments: `if [ $# -eq 0 ]; then ... fi`
1. ask `countFiles()` to count files in all directories passed as arguments: need to loop through all arguments

```sh
function countfiles() {
    if [ $# -eq 0 ]; then
        echo "No arguments given. Usage: countfiles dir1 dir2 ..."
        return 1
    fi
    for dir in $@; do
        echo in $dir we found $(find $dir -type f | wc -l) files
    done
}
```

## Archive/unarchive scripts

**Task**: write function `archive()` that would archive all directories passed to it. For example:

```sh
mkdir intro chapter{1..3} conclusion
for i in {1..3}; do
    echo "## Chapter $i" > chapter${i}/main.md
done
archive chapter* intro conclusion
```

Mostly likely, in this exercise we will need to process strings -- this is how you can do this in bash:

```sh
$ word="hello"
$ echo $word
hello
$ echo ${word/l/L}
heLlo
$ echo ${word//l/L}
heLLo
```

function archive() {
    if [ $# -eq 0 ]; then
        echo "No arguments given. Usage: archive dir1 dir2 ..."
        return 1
    fi
    for dir in $@; do
        tar cvfz ${dir/\//}.tar.gz $dir && /bin/rm -r $dir
    done
}

**Take-home exercise**: write `unarchive()` that would do the opposite, i.e. take a set of `.tar.gz` files via arguments
  and expand each of them.

## Rename all files with a pattern

Start with a simple example with 83 files:

```sh
touch 2022-Jan-{0{1..9},{10..31}}.md
touch 2022-Feb-{0{1..9},{10..28}}.md
touch 2022-Mar-{0{1..9},{10..24}}.md
```

**Task**: convert all months in the filenames to digital months, e.g. `2022-Jan-01.md` should become `20220101.md`.

<!-- ```sh -->
<!-- for f in *Jan*md; do -->
<!--   mv $f ${f/-Jan-/01} -->
<!-- done -->
<!-- ``` -->

## Convert spaces to underscores

```sh
touch hello "first phrase" "second phrase" "good morning, everyone"
ls -l
ls *\ *
```

Let's write `takeOutSpaces()` that will scan the current directory for all files with spaces in their file names and
convert these spaces to underscores.

<!-- ```sh -->
<!-- function takeOutSpaces() { -->
<!--     for file in *\ *; do -->
<!-- 	    mv "$file" "${file// /_}" -->
<!--     done -->
<!-- } -->
<!-- ``` -->

**After we are done**: how about a recursive scan? This is trickier! E.g., count the number of `---` in the output of
  this script:

```sh
for f in "$(find . -type f -name '* *')"; do
    echo "$f ---"
done
```

## Incorporating Python into your bash script

You might want to write a bash function that processes text, e.g.

```sh
$ echo "email us at training@westgrid.ca more text some.name.here@sfu.com more text \"bob@ubc.com\"" > message.txt
$ echo "another.name@ubc.ca some text here" >> message.txt
$ extractEmails message.txt
training@westgrid.ca, some.name.here@sfu.com, bob@ubc.com, another.name@ubc.ca
```

While you can do this in bash, it is much easier to achieve this in Python which is fantastic at text processing. It
turns out that you can easily call a Python script from a bash function! Consider this:

```sh
function test() {
    cat << EOF > e9nsp0lsb1.py   # random fixed string
#!/usr/bin/python3
print("do something in Python")
EOF
    chmod u+x e9nsp0lsb1.py
    ./e9nsp0lsb1.py
    /bin/rm e9nsp0lsb1.py
}
```

Here is an example of a more complex function extracting all emails from a text file:

```sh
function extractEmails() {
    mv $1 nidhefsxzd.txt
    cat << EOF > e9nsp0lsb1.py
#!/usr/bin/python3
import re
filename = open("nidhefsxzd.txt", "r")
content = filename.readlines()
emails = []
for i, line in enumerate(content):
    email = re.findall(r'[\w.+-]+@[\w-]+\.[\w.-]+', line)
    if len(email) > 0:
        for e in email:
            emails.append(e)
print(', '.join(map(str, emails)))   # print all emails in a single line without quotes
EOF
    chmod u+x e9nsp0lsb1.py
    ./e9nsp0lsb1.py
    /bin/rm e9nsp0lsb1.py
    mv nidhefsxzd.txt $1
}
```
