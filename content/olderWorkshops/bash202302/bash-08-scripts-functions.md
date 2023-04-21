+++
title = "Scripts, functions, and variables"
slug = "bash-08-scripts-functions"
weight = 8
+++

## Shell scripts

We now know a lot of UNIX commands! Wouldn't it be great if we could save certain commands so that we
could run them later or not have to type them out again? As it turns out, this is extremely easy to
do. Saving a list of commands to a file is called a "shell script". These shell scripts can be run
whenever we want, and are a great way to automate our work.

```sh
$ cd ~/Desktop/data-shell/molecules
$ nano process.sh
	#!/bin/bash         # this is called sha-bang; can be omitted for generic (bash/csh/tcsh) commands
	echo Looking into file octane.pdb
	head -15 octane.pdb | tail -5       # what does it do?
$ bash process.sh   # the script ran!
```

Alternatively, you can change file permissions:

```sh
$ chmod u+x process.sh
$ ./process.sh
```

Let's pass an arbitrary file to it:

```sh
$ nano process.sh
	#!/bin/bash
	echo Looking into file $1       # $1 means the first argument to the script
    head -15 $1 | tail -5
$ ./process cubane.pdb
$ ./process propane.pdb
```

* head -15 "$1" | tail -5     # placing in double-quotes lets us pass filenames with spaces
* head $2 $1 | tail $3        # what will this do?
* $# holds the number of command-line arguments
* $@ means all command-lines arguments to the script (words in a string)

<!-- > **Quiz 11:** script.sh in molecules Users/nelle/molecules. -->

<!-- > **Exercise:** write a script that takes any number of filenames, e.g., "scriptName.sh cubane.pdb -->
<!-- > propane.pdb", for each file prints the number of lines and its first five lines, and separates the -->
<!-- > output from different files by an empty line. -->

{{< question num="`file permissions`" >}}
Let's talk more about file permissions.
{{< /question >}}

{{< question num=34 >}}
In the `molecules` directory (download link mentioned <a href="../bash/bash-04-tar-gzip" target="_blank">here</a>),
create a shell script called `scan.sh` containing the following:
```sh
#!/bin/bash
head -n $2 $1
tail -n $3 $1
```
While you are in that current directory, you type the following command (with space between two 1s):
```sh
./scan.sh  '*.pdb'  1  1
```
What output would you expect to see?
1. All of the lines between the first and the last lines of each file ending in `.pdb` in the current directory
2. The first and the last line of each file ending in `.pdb` in the current directory
3. The first and the last line of each file in the current directory
4. An error because of the quotes around `*.pdb`
{{< /question >}}

<!-- 08-scripts.mkv -->
<!-- {{< yt UGZI6_HDyDc 63 >}} -->
You can {{<a "https://youtu.be/UGZI6_HDyDc" "watch a video for this topic">}} after the workshop.

<!-- 08-script-molecules.mkv -->
<!-- {{< yt rNnrcqkhXQo 63 >}} -->
You can {{<a "https://youtu.be/rNnrcqkhXQo" "watch a video for this topic">}} after the workshop.







## If statements

Let's write and run the following script:

```sh
$ nano check.sh
    for f in $@
    do
      if [ -e $f ]      # make sure to have spaces around each bracket!
      then
        echo $f exists
      else
        echo $f does not exist
      fi
    done
$ chmod u+x check.sh
$ ./check.sh a b c check.sh
```

* Full syntax is:

```sh
if [ condition1 ]
then
  command 1
  command 2
  command 3
elif [ condition2 ]
then
  command 4
  command 5
else
  default command
fi
```

Some examples of conditions (**make sure to have spaces around each bracket!**):

- `[ $myvar == 'text' ]` checks if variable is equal to 'text'
- `[ $myvar == number ]` checks if variable is equal to number
- `[ -e fileOrDirName ]` checks if fileOrDirName exists
- `[ -d name ]` checks if name is a directory
- `[ -f name ]` checks if name is a file
- `[ -s name ]` checks if file name has length greater than 0


{{< question num=23 >}}
Write a script that complains when it does not receive arguments.
{{< /question >}}






## Variables

We already saw variables that were specific to scripts ($1, $@, ...) and to loops ($file). Variables can be used
outside of scripts:

```sh
$ myvar=3        # no spaces permitted around the equality sign!
$ echo myvar     # will print the string 'myvar'
$ echo $myvar    # will print the value of myvar
```

Sometimes you can see the notation:

```sh
$ export myvar=3
```

Using 'export' will make sure that all inherited processes of this shell will have access to this
variable. Try defining the variable *newvar* without/with 'export' and then running the script:

```sh
$ nano process.sh
	#!/bin/bash
    echo $newvar
```

You can assign a command's output to a variable to use in another command (this is called *command
substitution*) -- we'll see this later when we play with 'find' command.

```sh
$ printenv    # print all declared variables
$ env         # same
$ unset myvar   # unset a variable
```

{{< question num="`using a variable inside a string`" >}}
```sh
var="sun"
echo $varshine
echo ${var}shine
echo "$var"shine
```
{{< /question >}}

{{< question num="`variable manipulation`" >}}
```sh
myvar="hello"
echo $myvar
echo ${myvar:offset}
echo ${myvar:offset:length}
echo ${myvar:2:3}    # 3 characters starting from character 2
echo ${myvar/l/L}    # replace the first match of a pattern
echo ${myvar//l/L}   # replace all matches of a pattern
```
{{< /question >}}

Environment variables are those that affect the behaviour of the shell and user interface:

```sh
$ echo $HOME
$ echo $PATH
$ echo $PWD
$ echo $PS1
```

It is best to define custom environment variables inside your ~/.bashrc file. It is loaded every time you
start a new shell.

{{< question num=22 >}}
Play with variables and their values. Change the prompt, e.g. `PS1="\u@\h \w> "`.
{{< /question >}}

<!-- 08-variables.mkv -->
<!-- {{< yt nNf4Xb56yEs 63 >}} -->
You can {{<a "https://youtu.be/nNf4Xb56yEs" "watch a video for this topic">}} after the workshop.







## Functions

Functions are similar to scripts, but there are some differences. A **bash script** is an executable file sitting at a
given path. A **bash function** is defined in your environment. Therefore, when running a script, you need to prepend
its path to its name, whereas a function -- once defined in your environment -- can be called by its name without a need
for a path. Both scripts and functions can take command-line arguments.

A convenient place to put all your function definitions is `~/.bashrc` file which is run every time you
start a new shell (local or remote).

Like in any programming language, in bash a function is a block of code that you can access by its
name. The syntax is:

```sh
functionName() {
  command 1
  command 2
  ...
}
```

Inside functions you can access its arguments with variables $1 $2 ... $# $@ -- exactly the same as in
scripts. Functions are very convenient because you can define them inside your ~/.bashrc
file. Alternatively, you can place them into a file and then **source** them whenever needed:

```sh
$ source allMyFunctions.sh
```

Here is our first function:

```sh
greetings() {
  echo hello
}
```

Let's write a function 'combine()' that takes all the files we pass to it, copies them into a
randomly-named directory and prints that directory to the screen:

```sh
combine() {
  if [ $# -eq 0 ]; then
    echo "No arguments specified. Usage: combine file1 [file2 ...]"
    return 1        # return a non-zero error code
  fi
  dir=$RANDOM$RANDOM
  mkdir $dir
  cp $@ $dir
  echo look in the directory $dir
}
```

{{< question num="`swap file names`" >}}
Write a function to swap two file names. Add a check that both files exist, before
renaming them.
<!-- ```sh -->
<!-- function swap() { -->
<!--     if [ -e $1 ] && [ -e $2 ] ; then -->
<!--         /bin/mv $2 $2.bak -->
<!--         /bin/mv $1 $2 -->
<!--         /bin/mv $2.bak $1 -->
<!--     else -->
<!--         echo at least one of these files does not exist ... -->
<!--     fi -->
<!-- } -->
<!-- ``` -->
{{< /question >}}

{{< question num="`archive()`" >}}
Write a function `archive()` to replace directories with their gzipped archives.
```sh
$ ls -F
chapter1/  chapter2/  notes/
$ archive chapter* notes/
$ ls
chapter1.tar.gz  chapter2.tar.gz  notes.tar.gz
```
{{< /question >}}





<!-- > **Exercise:** write the reverse function unarchive() that replaces a gzipped tarball with a directory. -->




{{< question num="`countfiles()`" >}}
Write a function `countfiles()` to count files in all directories passed to it as arguments (need to loop through all
arguments). At the beginning add the check:
```sh
    if [ $# -eq 0 ]; then
        echo "No arguments given. Usage: countfiles dir1 dir2 ..."
        return 1
    fi
```
{{< /question >}}

<!-- {{< solution >}} -->
<!-- ```sh -->
<!-- function countfiles() { -->
<!--     if [ $# -eq 0 ]; then -->
<!--         echo "No arguments given. Usage: countfiles dir1 dir2 ..." -->
<!--         return 1 -->
<!--     fi -->
<!--     for dir in $@; do -->
<!--         echo in $dir we found $(find $dir -type f | wc -l) files -->
<!--     done -->
<!-- } -->
<!-- ``` -->
<!-- {{< /solution >}} -->





<!-- 08-functions.mkv -->
<!-- {{< yt gSCRWUG9fy4 63 >}} -->
You can {{<a "https://youtu.be/gSCRWUG9fy4" "watch a video for this topic">}} after the workshop.




## Scripts in other languages

As a side note, it possible to incorporate scripts in other languages into your bash code, e.g. consider this:

```sh
function test() {
    randomFile=${RANDOM}${RANDOM}.py
    cat << EOF > $randomFile
#!/usr/bin/python3
print("do something in Python")
EOF
    chmod u+x $randomFile
    ./$randomFile
    /bin/rm $randomFile
}
```

Here `EOF` is a random delimiter string, and `<<` tells bash to wait for the delimiter to end input. For example, try
the following:

```sh
cat << the_end
This text will be
printed in the terminal.
the_end
```
