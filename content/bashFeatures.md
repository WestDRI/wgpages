+++
title = "Lesser known but very useful Bash features"
slug = "bashfeatures"
katex = true
+++

{{<ex>}}
You can find this webpage at:
{{</ex>}}
# https://wgpages.netlify.app/bashfeatures

<!-- {{<cor>}}Friday, November 4, 2022{{</cor>}}\ -->
<!-- {{<cgr>}}1:00pm - 2:30pm{{</cgr>}} -->

<!-- <\!-- {{< figure src="/img/qr-formats.png" >}} -\-> -->

## Links

- Fall 2022 training schedule: https://bit.ly/wg2022b
- Winter/spring 2023 training schedule: https://bit.ly/wg2023a
- Training materials: https://training.westdri.ca (upcoming and archived events, ~100 recorded webinars)
- Documentation: https://docs.alliancecan.ca
- Email: training "at" westdri "dot" ca

<!-- {{<a "link" "text">}} -->

## Abstract

Knowing basic Linux commands is essential for researchers using remote systems such as HPC clusters. Bash is
the most commonly used Linux shell, which you will use by default on most Alliance hardware. Although we teach
Bash basics in various online schools and in-person workshops many times a year, there are some useful Bash
features and tricks that we never get to teach, due to our usual time constraints. Finally we can share some
of them with you in this webinar!

In this presentation, we talk about running commands in a subshell, subsetting string variables, Bash arrays,
modifying separators with IFS, running Python code from inside self-contained Bash functions, editing your
command history, running unaliased versions of commands, handy use of brace expansion, and a few other topics.

## Intro

We regularly teach bash in our summer/etc schools:

- navigating files and directories; creating, moving and copying things
- archives and compression
- transferring files and directories to/from remote computers
- wildcards, redirection, pipes, and aliases; brace expansion
- loops and variables; command substitution
- scripts and functions, briefly on conditionals
- finding things with `grep` and `find`; tying things with `xargs`
- text manipulation with `sed` and `awk`

In previous webinars we've also taught 3rd-party command-line tools such as fuzzy finder `fzf`, Git terminal
UI `lazygit`, syntax highlighter `bat`, a fast alternative to grep `ripgrep`, a really fast `find` alternative
`fd`, `autojump` replacement for `cd` that learns and adapts to your use, and so on.

Today we would like to focus on some useful built-in bash features that we rarely get to demo.

## First part (Alex)

### Subshells with ()

<!-- https://askubuntu.com/questions/606378/when-to-use-vs-in-bash -->

- can be used to avoid any side-effects in the current shell
- commands inside `()` execute in a subshell
- use directly in the shell or when defining a function

All operations inside `()` will be local to the subshell:

```sh
cd ~/Documents
(cd ~/Desktop; pwd)
pwd
```

```sh
(export greeting="hello" && echo $greeting)
echo $greeting
```

```sh
(alias ll="ls -A" && alias ll)
alias ll
```

One common use: when testing, cd temporarily into another directory and run something there, Ctrl-C will break
and take you back to the original directory. Consider a code with separate `src` and `run` subdirectories:

```sh
cd src
function run() {
  make
  /bin/cp pi ../run
  cd ../run
  ./pi
}
run
```

Breaking execution with Ctrl-C will leave you in `run` every time. You can modify your function to change
directory and run the code in a subshell so that Ctrl-C will always take you to `src`:

```sh
cd ../src
function run() {
  make
  /bin/cp pi ../run
  (cd ../run ; ./pi)
}
run
```

Another solution is to define `run(){...}` as `run()(...)` -- then the entire function will run in a subshell:

```sh
function run() (
  make
  /bin/cp pi ../run
  cd ../run ; ./pi
)
run
```

<!-- Now consider these two functions: -->

<!-- ```sh -->
<!-- function tmp() {     # function body executes in the current shell -->
<!--   cd /tmp -->
<!--   pwd                # do something in that directory -->
<!-- } -->
<!-- cd; tmp; pwd   # you'll end up in /tmp -->
<!-- ``` -->

<!-- ```sh -->
<!-- function tmp() (     # function body executes in a subshell -->
<!--   cd /tmp -->
<!--   pwd                # do something in that directory -->
<!-- ) -->
<!-- cd; tmp; pwd   # you'll end up in your home -->
<!-- ``` -->

<!-- ```sh -->
<!-- (myvar="temporary value"; echo $myvar) && echo $myvar   # myvar defined only inside the subshell -->
<!-- ``` -->

Another use case: utilize subshells for testing things, so you don't pollute the current shell with temporary
definitions.

- **pro**: very easy to use
- **con**: takes slightly longer to execute (opens a subshell) but in most use cases this is probably not an issue

### Subsetting string variables

<!-- https://devhints.io/bash -->
<!-- https://tldp.org/LDP/abs/html/string-manipulation.html -->

```sh
author="Charles Dickens"
echo $author
echo "$author was an English writer"
echo $author\'s novels     # works in this case
echo "$author"\'s novels   # safer approach
echo ${author}\'s novels   # another safer approach
echo "${author}'s novels"  # another safer approach

echo "string's length is ${#author} characters"
```

```sh
echo ${author/Charles/Ch.}   # replace the first match of a substring
echo ${author//s/S}          # replace all first matches of a substring

echo ${author/Charles }      # if no replacement string supplied, the substring will be deleted
echo ${author/Charles /}     # the same

original="Charles"             # can use a variable for the substring
short="C."                     # can use a variable for a replacement string
echo ${author/$original/$short}

echo ${author/#Ch/ch}        # replace the match only at the start (if found)
echo ${author/%ns/ns ---}    # replace the match only at the end (if found)
```

E.g. you can use this to change file extensions:

```sh
touch {a..z}{0..9}.txt   # create 260 files
for file in *.txt; do
    mv $file ${file/%txt/md}
done
```

Another solution of course:

```sh
/bin/rm ??.md
touch {a..z}{0..9}.txt   # create 260 files
for file in *.txt; do
    mv $file ${file/.txt/.md}
done
```

Question: what will this do `echo ${author/#/---}`?

```sh
echo ${author:5:2}     # display 2 characters starting from number 5 (indexing from 0)
echo ${author::2}      # display the first 2 characters
echo ${author:5:${#author}}     # display all characters starting from number 5 to the end
echo ${author:5:999}            # simpler
echo ${author:5}                # even simpler
echo ${author: -2}     # last two characters; important to have space there!
echo ${author: -5:3}   # display 3 characters starting from number -5; important to have space there!
```

**Note**: If you want to perform more granular operations with bash strings, e.g. work with patterns, you can
look into regular expressions (not covered in this webinar).


<!-- If you want to return the index of a substring match: -->
<!-- expr index "$author" "Dickens" -->




<!-- library="Charles Dickens, Edgar Allan Poe" -->

<!-- Let's look for a front substring starting with `C` and ending with ` ` (space). There are 4 possibilities: -->

<!-- 1. `Charles `Dickens, Edgar Allan Poe -->
<!-- 2. `Charles Dickens, `Edgar Allan Poe -->
<!-- 3. `Charles Dickens, Edgar `Allan Poe -->
<!-- 4. `Charles Dickens, Edgar Allan `Poe -->

<!-- ```sh -->
<!-- echo ${library#C* }    # delete the shortest match of `C* ` from the front -->
<!-- echo ${library##C* }   # delete the longest match of `C* ` from the front -->
<!-- ``` -->

<!-- There is similar syntax for deleting from the back: -->

<!-- ```sh -->
<!-- echo ${library% *}     # delete the shortest match of ` *` from the back -->
<!-- echo ${library%% *}    # delete the longest match of ` *` from the back -->
<!-- ``` -->









### Bash arrays

```sh
a=(10 20 30 hello)
echo $a              # only the first element
echo ${a[0]}         # the same
echo $a[0]           # concatenate $a (the first element) and "[0]"
echo ${a[@]}         # output all elements, i.e. @=all
for x in ${a[@]}; do
  echo $x
done

a=(10 20 30 hello "hi there")
for x in ${a[@]}; do     # will put hi,there in separate lines (6 loop iterations)
  echo $x
done
for x in "${a[@]}"; do   # proper way to iterate over bash array elements; 5 loop iterations
  echo $x
done

echo ${!a[@]}   # list of all array indices (0 1 2 3 4)
echo ${#a[@]}   # number of elements (5)

a+=(100 200)    # append 2 elements to the array
```

Let's do some timing of a Julia code:

```sh
$ julia slowSeries.jl    # will report shortest time in seconds
  0.518063834
$ julia -t 2 slowSeries.jl
  0.270241666

threads=(1 2 4 8 16)
runtime=()
for n in ${threads[@]}; do
    time=$(julia -t $n slowSeries.jl)
    runtime+=($time)    # adding one element per cycle
done
echo ${runtime[@]}

runtime=()
for n in ${threads[@]}; do
    time=$(julia -t $n slowSeries.jl)
    runtime+=("$n threads: $time")   # also adding one element per cycle, b/c of the quotes
done
echo ${#runtime[@]}
for x in "${runtime[@]}"; do
  echo $x
done
```

Using arrays in a backup script:

```sh
if [ -e /Volumes/gdrive ]; then
    BSRC=(~/Documents ~/Desktop
          ~/Downloads/{books,images})
    BDEST='/Volumes/gdrive/backups'
elif [ -e /Volumes/t7 ]; then
    BSRC=(~/Pictures ~/Music)
    BDEST='/Volumes/t7/backups'
fi
echo ${BSRC[@]}
echo backing up `echo "${BSRC[@]}" | sed -e 's|/Users/razoumov/||g'` to $BDEST
borg create --stats --list --filter='AM' --compression=lz4 --noflags $BDEST::$(date "+%Y%b%d%H%M") "${BSRC[@]}"
```

Using arrays for compilation flags:

```sh
FLAGS=(
 -DCMAKE_INSTALL_PREFIX=$HOME/paraviewcpu591
 -DVTK_OPENGL_HAS_OSMESA=ON
 -DPARAVIEW_USE_MPI=ON -DBUILD_TESTING=OFF
 -DVTK_USE_X=OFF -DPARAVIEW_USE_QT=OFF
 -DPARAVIEW_USE_PYTHON=ON
 # -DPARAVIEW_BUILD_SHARED_LIBS=ON    this is a commented flag; won't show up
 -DPARAVIEW_ENABLE_RAYTRACING=ON
)
echo "${FLAGS[@]}"
for x in "${FLAGS[@]}"; do
  echo $x
done
cmake .. "${FLAGS[@]}"
```

Command substitution to an array:

```sh
str=$(ls)              # command substitution to save `ls` output as a string
arr=($(ls))            # save `ls` output as an array of file/directory names
echo ${arr[@]:2:3}     # retrieve 3 elements starting at index 2
                       # ${a[@]:3:1} is the same as ${a[3]}
```


Array cheatsheet:

```sh
arr=()          # create an empty array
arr=(1 2 3)     # initialize array
${arr[2]}       # retrieve third element
${arr[@]}       # retrieve all elements
${!arr[@]}      # retrieve array indices
${#arr[@]}      # calculate array size
arr[0]=3        # overwrite 1st element
arr+=(40 50)    # append two elements
${arr[@]:i:j}   # retrieve j elements starting at index i
```







### Little practical example

Now let's apply this knowledge!

Here is the standard bash syntax for arguments passed to a function:

```sh
$1    # first argument
$2    # second argument
$#    # number of arguments
$@    # all arguments
```

Alternatively, we can treat all arguments as an array:

```sh
arr=($@)                  # store all arguments inside an array
num=${#arr[@]}            # the length of this array
num=$#                    # same
echo ${arr[@]:0:$num-1}   # all arguments but the last
echo ${arr[$num-1]}       # last argument
```

```sh
function move() {
    arr=($@)
    num=${#arr[@]}
    objects=${arr[@]:0:$num-1}
    last=${arr[$num-1]}
    echo MOVING $objects TO $last
    /bin/cp $objects $last && /bin/rm $objects
}
```

Why do we want to use it?
- on our HPC clusters in `/project` the 1TB (or higher) quota is applied to all files with the group ID
  `def-<PI>`
  - the `/project` quota is applied to the entire research group
  - the quota for group ID `$USER` is almost zero
- by default, all files in `/home`, `/scratch` have group ID `$USER`
- **problem**: the usual `mv` command preserves group ID &nbsp;⮕&nbsp; moving files with `mv` from
  `/home`,`/scratch` to `/project` will almost certainly exceed your quota for group ID `$USER` &nbsp;⮕&nbsp;
  trouble writing files, running jobs, etc.
- solution: use `cp` (modifies quota accordingly) followed by `rm`, i.e. replace `mv` with our new function
  `move`








### IFS to edit separators

<!-- http://redsymbol.net/articles/unofficial-bash-strict-mode -->

The IFS variable -- which stands for Internal Field Separator -- controls how Bash does word splitting.

```sh
phrase="one,two three four"
for word in $phrase; do
    echo $word
done
```

Default IFS is any of `space/newline/tab`, i.e. IFS=$'_\n\t':

```sh
export IFS     # shows an empty line ... as if it was not set
echo ${#IFS}   # there are actually three characters there: $' \n\t'
```

```sh
IFS=,
for word in $phrase; do
    echo $word
done
IFS=", "       # both characters will be used as separators
for word in $phrase; do
    echo $word
done
unset IFS      # back to default behaviour
for word in $phrase; do
    echo $word
done
```

Why is this useful? One use: IFS can help you deal with files with spaces in their names. Imagine you want to
process some files in a loop:

```sh
unset IFS
touch "my thesis.md" "first results.md"   # really bad idea, but 99% of people do it anyway
for i in *.md; do      # the wildcard gets expanded here into a string with 2 items => 2 loop iterations
    ls -l $i           # $i is a string with space; this gives an error, as `ls` sees this string as 2 names
	mv $i ${i/.md/.tex}   # this gives an error too, as `mv` sees each string as 2 names
done
```

This would be a bad way to fix this:

```sh
for i in "*.md"; do    # loop over one element (the string with *.md inside) => 1 loop iteration
    ls -l $i           # $i contains a wildcard that gets expanded here; `ls -l` over 2 items => works
	mv $i ${i/.md/.tex}   # 1st wildcat gets expanded into 2 items, 2nd wildcard does not get expanded => error
done
```

A good way to fix this:

```sh
for i in *.md; do   # the wildcard gets expanded here into a string with 2 items => 2 loop iterations
    ls -l "$i"      # `ls` acts on a string inside the quotes => works
	mv "$i" "${i/.md/.tex}"   # `mv` acts on 2 strings inside the quotes => works
done
```

Or you can do this with IFS, without having to use quotes:

```sh
/bin/rm *.tex
touch "my thesis.md" "first results.md"   # really bad idea, but 99% of people do it anyway
IFS=$'\n\t'   # more restrictive IFS
for i in *.md; do
    ls -l $i
	mv $i ${i/.md/.tex}
done
```

You can specifically use a newline character as a separator. Let's create a file and prepend each line with
the character count in that line:

```sh
echo first line > a.txt
echo second line >> a.txt
cat a.txt

unset IFS
for w in $(cat a.txt); do    # counts characters in individual words
    echo ${#w} $w
done
IFS=$'\n'
for w in $(cat a.txt); do    # counts characters in individual lines
    echo ${#w} $w
done
```

Of course, there are always alternative solutions without IFS, e.g.

```sh
cat a.txt | while read line
    do
    echo ${#line} $line
done
```





IFS can work with arrays too, but you have to be careful, as an array will always break between elements, no
matter the value of IFS. With IFS set, it will break at the IFS characters and between elements.

```sh
a=(102030 hello there "hi there")
unset IFS
for x in ${a[@]}; do     # breaks at spaces and between elements
  echo $x
done
for x in "${a[@]}"; do   # breaks between elements
  echo $x
done
IFS=$'\n\t'
for x in ${a[@]}; do     # breaks between elements
  echo $x
done
IFS="0"
for x in ${a[@]}; do     # breaks at 0 and between elements
  echo $x
done
```




### Python inside self-contained bash functions

The operator `<<` -- called *here-document* structure in bash -- is used to pass some text input along with
its ending pattern to a program, e.g.

```sh
wc -l << EOF
line 1
line 2
EOF
```

You can save this input to a file:

```sh
cat << EOF > b.txt
line 1
line 2
EOF
```

You can use this mechanism to define some Python code inside a bash function:

```sh
function pi() {
    cat << EOF > uniqueCode.py
#!/usr/bin/env python
import math as m
print(m.pi)
EOF
    chmod 700 uniqueCode.py
    ./uniqueCode.py
    /bin/rm uniqueCode.py
}
```

Here is a useful example:

```sh
function extractEmails() {
    cat << EOF > uniqueCode.py
#!/usr/bin/env python
import sys, re
filename = open(sys.argv[1], "r")
content = filename.readlines()
emails = []
for i, line in enumerate(content):
    email = re.findall(r'[\w.+-]+@[\w-]+\.[\w.-]+', line)
    if len(email) > 0 and "..." not in email[0]:
        for e in email:
            emails.append(e)
print(', '.join(map(str, emails)))   # print all emails in a single line without quotes
EOF
    chmod 700 uniqueCode.py
    ./uniqueCode.py $1
    /bin/rm uniqueCode.py
}
cat contact.txt
extractEmails contact.txt
```

## Second part (Marie)

### Fix commands

The builtin utility `fc` allows to edit previously run commands. This is particularly useful if you made a typo in a long command or a series of commands.

Without any flag, `fc` will open your default text editor with the last command in it for you to edit. After saving and exiting your editor, the edited command will run.

You can list previous commands with `fc -l` (they will be numbered), open a particular command or commands from that list with `fc <number>` or `fc <number1> <number2>`, re-execute a command with `fc -s`, or change the editor with `fc -e <editor>`.

{{<ex>}}
Examples:
{{</ex>}}

```sh
fc		     # open last command with default editor to edit, then rerun
fc -e emacs	 # open last command with Emacs to edit, then rerun

fc -l	     # list past commands (they will be numbered)
fc 34 38     # open default editor with commands number 34 to 38 to edit, then rerun

fc -s 54     # rerun command number 54 without edit
```

### Quick substitution

Still on the subject of fixing commands, if you want to rerun your last command with a substitution (e.g. you made a typo in the last command and you want to re-run it without the typo, or you are running a second command very similar to your last command), you could recall the last command with C-p and navigate to the part that needs to be changed.

But there is a much faster method: **the quick substitution of `old` by `new` simply by typing: `^old^new`.**

{{<ex>}}
**Example**

I already ran:
{{</ex>}}

```
echo This is a test
```

{{<ex>}}
Now, if I run:
{{</ex>}}

```
^test^cool test
```

{{<ex>}}
It will actually run the command:
{{</ex>}}

```
echo This is a cool test
```

### Easy access to unaliased versions of commands

If you have created aliases which use the names of Bash commands, calling those commands will call the aliases. You may however occasionally need to use the non-aliased commands.

One way to do this is to unalias your alias with `unalias <command>`. But then, you have lost your alias for the rest of your session or until you resource your .bashrc file.

Another option is to use the full path of the command (e.g. `/usr/bin/<command>`). If you don't know the path of the command, you can find it with `which <command>`.

Still, there is an even easier method: **simply prepend your alias with `\`.**

{{<ex>}}
**Example**

I have an alias called `ls` for `ls --color`. I can know this by typing any of:
{{</ex>}}

```sh
alias ls
type ls
```

{{<ex>}}
I can run the original `ls` command without loosing my alias and without bothering with the full path of `ls` with:
{{</ex>}}

```
\ls
```

### Determine file types

**The command `file` runs tests to determine the types of files** based on their content (thus independently of any extension(s)).

{{<ex>}}
Example outputs:
{{</ex>}}

```sh
directory                                                            # directory

symbolic link to </some/path>                                        # symlink

POSIX shell script, ASCII text executable                            # executable shell script
Python script, ASCII text executable                                 # executable Python script
Perl script text executable                                          # executable Perl script

ASCII text								                             # text file

empty									                             # empty file

PDF document, version 1.4                                            # .pdf
PDF document, version 1.7 (zip deflate encoded)                      # .pdf

Git index, version 2, 208 entries		                             # index in .Git repository

GNU dbm 1.x or ndbm database, little endian, 64-bit                  # .db database

Zstandard compressed data (v0.8+)                                    # .zst compressed file
gzip compressed data, was "<file>.tar", last modified: \
	 Wed Feb 28 09:25:16 2007, \
	 from FAT filesystem (MS-DOS, OS/2, NT), \
	 original size modulo 2^32 24064                                 # .tar.gz compressed archive

MPEG ADTS, layer III, v1, 128 kbps, 44.1 kHz, JntStereo	             # .mp3 sound
MPEG ADTS, layer III, v1, 128 kbps, 44.1 kHz, Stereo	             # .mp3 sound
MPEG ADTS, layer III v1, 96 kbps, 44.1 kHz, Monaural                 # .mp3 sound
FLAC audio bitstream data, 16 bit, stereo, 44.1 kHz, 7670460 samples # .flack sound
Microsoft ASF							                             # .wma sound

PNG image data, 665 x 742, 8-bit/color RGBA, non-interlaced          # .png image
GIMP XCF image data, version 011, 161 x 157, RGB Color               # .xcf GIMP file
SVG Scalable Vector Graphics image                                   # .svg image
GIF image data, version 89a, 160 x 40                                # .gif image

EPUB document                                                        # .epub book
DjVu multiple page document                                          # .djvu book
```
{{<br size="3">}}

For some file types, you get a lot more information.

{{<ex>}}
Here are two examples for .jpg:
{{</ex>}}

```sh
JPEG image data, JFIF standard 1.01, resolution (DPI), density 72x72, segment length 16, \
	 Exif Standard: [\012- TIFF image data, little-endian, direntries=6, xresolution=86, \
						   yresolution=94, resolutionunit=2, software=GIMP 2.10.14, \
						   datetime=2019:12:04 23:53:09], progressive, precision 8, 161x157, \
	 components 3

JPEG image data, JFIF standard 1.01, resolution (DPI), density 72x72, segment length 16, \
	 progressive, precision 8, 395x533, components 3
```
{{<br size="4">}}

{{<emph>}}
This is most useful for binaries from which it is harder to gather information.
{{</emph>}}
<br>
{{<ex>}}
Example of Executable and Linkable Format on Linux:
{{</ex>}}

```sh
ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked, \
	interpreter /lib64/ld-linux-x86-64.so.2, \
	BuildID[sha1]=0e291ede656cae727e7a1d056c54392452b0fc59, for GNU/Linux 4.4.0, stripped
```
{{<br size="3">}}

{{<ex>}}
Example of Windows .exe file:
{{</ex>}}

```sh
PE32+ executable (console) x86-64, for MS Windows
```
{{<br size="3">}}

{{<ex>}}
Example of object file (`.o`):
{{</ex>}}

```sh
ELF 64-bit LSB relocatable, x86-64, version 1 (SYSV), not stripped
```

### Get information on a program

To get information on a program, you can run `command -V <program>`.

{{<ex>}}
Examples (outputs in comments):
{{</ex>}}

### cp file{,.bak} and mv file.{org,txt}


### $_
```sh
command -V python  # python is /usr/bin/python
command -V pwd	   # pwd is a shell builtin
command -V ls	   # ls is aliased to `ls --color=auto' (because I have this alias)
```




{{<ex>}}
{{</ex>}}

```

{{<ex>}}
{{</ex>}}

```

{{<ex>}}
{{</ex>}}

```
