+++
title = "Answering your Bash questions"
slug = "bash-questions"
katex = true
+++

{{<cor>}}December 19<sup>th</sup>, 2024{{</cor>}}\
{{<cgr>}}10:00am–noon Pacific Time{{</cgr>}}

{{<ex>}}
You can find this page at:
{{</ex>}}
# https://wgpages.netlify.app/bash-questions

<!-- While not specific to Bash, I think a large number of early career researchers struggle to use package -->
<!-- managers, virtual environments, and automate tasks using Make efficiently. Integrating these topics into a -->
<!-- Bash workshop may help folks understand how to interpret and manage their PATH environment variables and -->
<!-- better shift their workflows from their local machines to an HPC setting. -->

<!-- Bash can be made a lot more user friendly with the addition of plugins a la ohmyzsh. An issue for beginners is -->
<!-- that you need to be exact in commands and filenames, arguments, etc. But command line completion has come very -->
<!-- far in the last few years, with e.g. fuzzy finders, stochastic completion: `z repo` -\-> `cd Repositories` etc -->
<!-- This can alleviate a lot of the threshold beginners face in using HPC -->
<!-- - Marie: ohmyzsh is clunky, does not add anything, Marie turned it off -->

<!-- Learn programming in bash -->

<!-- awk and sed; redirection of stdin/stdout; use of nohup/disown/bg; maybe regular expressions (with -->
<!-- comparison/contrast of RE syntax in other languages) -->
<!-- - me, Marie: tmux solves that problem -->

<!-- I would like to learn how to write my custom bash scripts to run a specific task -->

<!-- I don't know what I don't know.  But, setting up my work environment (bash functions, alias's , command line -->
<!-- commands,...) that make my life easier to do work.  I don't know enough to have other 'valuable' input -->

**Abstract**: We host introductory bash sessions several times a year. In this workshop, we aim to cover
topics that are not typically included in our curriculum. We asked for your input on which topics should be
prioritized, and we really appreciate all your answers! The responses we got mostly fell into two categories:
topics that are already covered in our bash, introductory HPC, and beginner's Python courses, or more
specialized topics. Within this two-hour workshop, we will try to balance these suggestions while showing
tools that will be useful to a wide range of people who use our HPC clusters or command line independently on
their own computers. We will cover, among other things, aliases, scripts, functions, make, tmux, fuzzy finder,
bat, color setup for your shell, zsh plugins, and autojump. We will provide a training cluster and guest
accounts to try all these tools and will explain how to install them on production clusters.

<!-- ## Intro: what we do and do not cover here -->

## Aliases and scripts (external links)

- https://mint.westdri.ca/bash/intro_aliases
- https://mint.westdri.ca/bash/molecules/intro_script

## Functions

Functions are similar to scripts, but there are some differences. A **bash script** is an executable file
sitting at a given path. A **bash function** is defined in your shell environment. Therefore, when running a
script, you need to prepend its path to its name, whereas a function -- once defined in your environment --
can be called by its name without a need for a path. Both scripts and functions can take command-line
arguments.

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

Inside functions you can access its arguments with variables `$1` `$2` ... `$#` `$@` -- exactly the same as in
scripts. Functions are very convenient because you can define them once inside your `~/.bashrc` file and then
forget about them.

Here is our first function:

```sh
greetings() {
  echo hello
}
```

Let's write a function `combine()` that takes all the files we pass to it, moves them into a randomly-named
directory and prints that directory to the screen:

```sh
combine() {
  if [ $# -eq 0 ]; then
    echo "No arguments specified. Usage: combine file1 [file2 ...]"
    return 1        # return a non-zero error code
  fi
  dir=$RANDOM$RANDOM
  mkdir $dir
  mv $@ $dir
  echo look in the directory $dir
}
```

{{< question num="`swap file names`" >}}
Write a function to swap two file names. Add a check that both files exist, before renaming them.
{{< /question >}}

{{< question num="`archive()`" >}}
Write a function `archive()` to replace directories with their gzipped archives.
```sh
$ mkdir -p chapter{1..5} notes

$ ls -F
chapter1/  chapter2/  chapter3/  chapter4/  chapter5/  notes/
$ archive chapter* notes/
$ ls
chapter1.tar.gz  chapter2.tar.gz  notes.tar.gz
```
{{< /question >}}

I will leave it to you to write the reverse function unarchive() that replaces a gzipped tarball with a directory.

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

<!-- Here is a fun function: -->
<!-- ```sh -->
<!-- ``` -->

You can also use functions to expand existing bash commands. Here is a function I wrote recently that adds
some functionality to `git-annex <verb>` command:

```sh
function ga() {
    case $1 in
	init|status|add|sync|drop|dropunused|unannex|unused|find|whereis|info|copy|move|get)
	    git-annex $@
	    ;;
	st)
	    git-annex status
	    ;;
	locate)
	    git-annex whereis --json "${@:2}" | jq '.file + " " + (.whereis|map(.description)|join(","))' \
		| sed -e 's|\"||g'
	    ;;
	here)
	    git-annex find "${@:2}"
	    ;;
	*)
	    echo command not found ...
	    ;;
    esac
}
```

## Make

Originally, `make` command (first released in 1975) was created for automating compilations. Consider a large
software project with hundreds of dependencies. When you compile it, each source file is converted into an
object file, and then all of them are linked together to the libraries to form a final executable(s) or a
final library.

Day-to-day, you typically work on a small section of the program, e.g. debug a single function, with much of
the rest of the program unchanged. When recompiling, it would be a waste of time to recompile all hundreds of
source files every time you want to compile/run the code. You need to recompile just a single source file and
then update the final executable.

A *makefile* is a build manager to automate this process, i.e. to figure out what is up-to-date and what is
not, and only run the commands that are necessary to rebuild the final target. A *makefile* is essentially **a
tree of dependencies stored in a text file** along with the commands to create these dependencies. It ensures
that if some of the source files have been updated, we only run the steps that are necessary to create the
target with those new source files.

Makefiles can be used for any project (not just compilation) with multiple steps producing intermediate
results, when some of these steps are compute-heavy. Let's look at an example! We will store the following
text in the file `text.md`:

```md
## Part 1

In this part we cover:

- bash aliases
- bash scripts
- bash functions
- make

\newpage

## Part 2

In this part we cover:

- tmux (also in the context of process control)
- fuzzy finder
- bat
- color setup for your shell
- zsh plugins
- autojump
```

This is our workflow:

```sh
pandoc text.md -t beamer -o text.pdf

wget https://wgpages.netlify.app/img/dolphin.png
magick dolphin.png dolphin.pdf

wget https://wgpages.netlify.app/img/penguin.png
magick penguin.png penguin.pdf

gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=slides.pdf {text,dolphin,penguin}.pdf
/bin/rm -f dolphin.* penguin.* text.pdf
curl -F "file=@slides.pdf" https://temp.sh/upload && echo
```

First version of `Makefile` automates creating of `slides.pdf`:

```make
slides.pdf: text.pdf dolphin.pdf penguin.pdf
	gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=slides.pdf {text,dolphin,penguin}.pdf
text.pdf: text.md
	pandoc text.md -t beamer -o text.pdf
dolphin.pdf: dolphin.png
	magick dolphin.png dolphin.pdf
penguin.pdf: penguin.png
	magick penguin.png penguin.pdf
dolphin.png:
	wget https://wgpages.netlify.app/img/dolphin.png
penguin.png:
	wget https://wgpages.netlify.app/img/penguin.png
```

Running `make` will create the target `slides.pdf` -- how many command will it run? That depends on how many
intermediate files you have, and their timestamps.

**Test 1**: let's modify `text.md`, e.g. add a line there. The makefile will figure out what needs to be done
to update `slides.pdf`. How many command will it run?

**Test 2**: let's remove `dolphin.png`. How many commands will `make` run?

**Test 3**: let's remove both PNG files. How many commands will `make` run?

Now, add three special targets at the end:

```make
clean:
	/bin/rm -f dolphin.* penguin.* text.pdf
cleanall:
	make clean
	/bin/rm -f slides.pdf
upload: slides.pdf
	curl -F "file=@slides.pdf" https://temp.sh/upload && echo
```

Next, we can make use of make's builtin variables:

- `$@` is the "target of this rule"
- `$ˆ` is "all prerequisites of this rule"
- `$<` is "the first prerequisite of this rule"
- `$?` is "all out-of-date prerequisites of this rule"

```txt
< gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=slides.pdf {text,dolphin,penguin}.pdf
---
> gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=$@ $^
```
```txt
< pandoc text.md -t beamer -o text.pdf
---
> pandoc $^ -t beamer -o $@
```

The next simplification makes use of `make` wildcards to specify patterns:

```txt
< dolphin.pdf: dolphin.png
< 	magick dolphin.png dolphin.pdf
< penguin.pdf: penguin.png
< 	magick penguin.png penguin.pdf
---
> %.pdf: %.png
> 	magick $^ $@
```

## Process control with terminal UI

Linux features commands to pause/resume processes, send them into background, and bring them back into
foreground. We think that a better alternative to these controls is tmux, a terminal multiplexer that can
create persistent virtual terminal sessions inside which you can run background processes. Let's demo this!

Here is one exception with `fg` that I started using recently:

```sh
function e() {
    if pgrep -x "emacs" $UU > /dev/null
    then
		fg %emacs
    else
		emacs -nw $@
    fi
}
```

coupled with the following inside my `~/.emacs` file:

```txt
(global-set-key (kbd "\C-xe") 'suspend-frame)
```

## Pointers on regular expressions (external link)

- https://mint.westdri.ca/bash/intro_regexp (not teaching them here!)

## Fuzzy finder `fzf`

fzf -- stands for "fuzzy finder" -- is an interactive filter for files or for standard input. You can type
with errors and omitted characters and still get the correct results.

If we call it as is, `fzf`, it will traverse the file system under the current directory to get the list of
files. Type something and then:

- use *up*/*down* arrows or *pageup*/*pagedown* to navigate the list
- hit *return* to return the selected line
- hit *backspace* to modify your search
- hit TAB multiple times to select multiple lines
- hit Shift-TAB to deselect
- hit *escape* to exit search

It is a very quick way to find a file interactively.

You can control fzf appearance / real estate:

```sh
fzf                # by default take the entire screen
fzf --height 10%   # start below the cursor with the 10% height
fzf --tmux         # this flag is not available on clusters
```

There are many other options for formatting `fzf`'s output -- you can find them in the
[documentation](https://github.com/junegunn/fzf), so I won't cover them here.

Here is a useful function to find a file and open it in `nano`:

```sh
function nn() {
    nano $(fzf)
}
```

Here is a more sophisticated version of this function, with a couple of improvements:

1. won't open `nano` if you have an empty result (Esc or Ctrl-C)
1. can handle spaces in file names

```sh
function nn() {
	fzf --bind 'enter:become(nano {+})'
}
```

- `--bind` binds Enter key to running `nano`

A more interesting use of `fzf` is to process standard output of other commands:

```sh
history | fzf

find ~/projects/def-sponsor00/shared/ -type f | fzf
find ~/projects/def-sponsor00/shared/ -type f | fzf --preview 'more {}'
find ~/projects/def-sponsor00/shared/ -type f | fzf --preview 'head -5 {}'

git show $(git rev-list --all) | fzf   # search through file changes in all previous commits

cat ~/Documents/notes/*.md | wc -l     # 91k lines of text
cat ~/Documents/notes/*.md | fzf       # just the content (no file names)
grep . ~/Documents/notes/*.md | fzf    # if you want to see the file names as well
```

You can act on the results of search:

```sh
function playLocalMusic() {
    dir=${HOME}/Music/Music/Media.localized/Music
    player=/Applications/Tiny*Player.app/Contents/MacOS/Tiny*Player
    find $dir -type d | fzf | sed 's| |\\ |g' | xargs $player
}
```

You can use selected fields in the `fzf`'s output:

```sh
function kk() {
    kill -9 `/bin/ps ux | fzf | awk '{print $2}'`
}
```

### Auto-completion

<!-- https://thevaluable.dev/fzf-shell-integration -->

In bash, you can complete commands by pressing <TAB> once or twice. If you want to replace that with `fzf`,
i.e. if you want to use `fzf` inline inside your commands, you can enable `fzf` completion that will replace a
completion trigger (`**` by default) with the `fzf`'s output:

> Note: `fzf` in CVMFS does not seem to have been compiled with completion support. To enable it on the training
> cluster, you will need to install `fzf` into your own directory, which is fortunately very easy:
> ```sh
> git clone --depth 1 https://github.com/junegunn/fzf.git fzf
> ./fzf/install   # answer "yes" to enable fuzzy auto-completion
> export PATH=${HOME}/fzf/bin:${PATH}        # add fzf to PATH
> source ${HOME}/fzf/shell/completion.bash   # enable completion support
> ```

```sh
bat **<TAB>
bat <dir>/**<TAB>
```

It is most useful when you run it pointing to a large subdirectory, e.g.

```sh
nano ~/Documents/**<TAB>
cd ~/training/**<TAB>
```

It is context-aware:

```sh
kill -9 **<TAB>
ssh **<TAB>
unset **<TAB>
unalias **<TAB>
```

## Other tools (external links)

- https://mint.westdri.ca/bash/intro_modern (eza, bat, ripgrep, fd, autojump)
- https://mint.westdri.ca/bash/intro_zsh (useful plugins, auto-suggestions, syntax highlighting)
