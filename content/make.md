+++
title = "Introduction to makefiles"
slug = "make"
katex = true
+++

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
## Design

Makefiles can be used for automating any multiple-step workflow
when there is a need to update only some targets, as opposed to
running the entire workflow from start to finish.

\newpage

## Make's builtin variables

- `$@` is the "target of this rule"
- `$ˆ` is "all prerequisites of this rule"
- `$<` is "the first prerequisite of this rule"
- `$?` is "all out-of-date prerequisites of this rule"
```

This is our workflow to automate:

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
