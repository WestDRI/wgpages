+++
title = "Version control of scientific datasets with DataLad"
slug = "dataladintro"
+++

{{<ex>}}
You can find this webpage at:
{{</ex>}}
# https://wgpages.netlify.app/dataladintro

{{<cor>}}Thursday, February 23rd{{</cor>}}\
{{<cgr>}}2:30pm - 4:00pm{{</cgr>}}

**Instructors**: Alex Razoumov (SFU)

**Target audience**: general

**Level**: beginner

**Prerequisites**: ideally some previous knowledge of Git.






## What is DataLad?

DataLad is a version control system for your data. It is built on top of **Git** and **git-annex**, and is
available both as a command-line tool and as a Python API.

### Git

Git a version control system designed to keep track of software projects and their history, to merge edits from
multiple authors, to work with branches (distinct project copies) and merge them into the main projects. Since
Git was designed for version control of text files, it can also be applied to writing projects, such as
manuscripts, theses, website repositories, etc.

Git can also keep track of binary (non-text) files and/or of large data files, but putting binary and/or large
files under version control and especially modifying them will inflate the size of the repositories.

### git-annex

<!-- git annex - holding your data separately from your history (data does not need to be there when inspecting the -->
<!-- database structure and history) -->

Git-annex was built on top of Git and was designed to share and synchronize large file in a distributed
fashion. The file content is managed separately from the dataset's structure / metadata -- the latter is kept
under Git version control, while files are stored in separate directories. If you look inside a git-annex
repository, you will see that files are replaced with symbolic links, and in fact you don't have to have the
actual data stored locally, e.g. if you want to reduce the disk space usage.

### DataLad

DalaLad builds on top of Git and git-annex, retaining all their features, but adds few other functions:

1. Datasets can be nested, and most DalaLad commands have a `--recursive` option that will traverse
   subdatasets and do "the right thing".
1. DalaLad can run commands on data, and if a dataset is not present locally, DalaLad will automatically get
   the required input files from a remote repository.
1. DataLad can keep track of data provenance, e.g. `datalad download-url` will download files, add them to the
   repository, and keep a record of data origin.
1. Few other features.

As you will see in this workshop, most DataLad workflows involve running all three -- `git`, `git annex`, and
`datalad` -- commands, and we'll be using the functionality of all three layers.







## Installation

On a Mac with {{<a "https://brew.sh" "Homebrew">}} installed:

```sh
brew upgrade
brew install datalad
```

With `pip` (Python's package manager) use one of these two:

```sh
pip install datalad          # if you don't run into permission problems
pip install --user datalad   # to force installation into user space
```

With `conda`:

```sh
conda install -c conda-forge datalad
conda update -c conda-forge datalad
```

DataLad also needs Git and git-annex, if these are not installed. For mote information, visit the
{{<a "http://handbook.datalad.org/en/latest/intro/installation.html" "official installation guide">}}.

On our training cluster:

```sh
module load git-annex   # need this each time you use DalaLad
module load python
virtualenv --no-download ~/datalad-env
source ~/datalad-env/bin/activate
pip install --no-index --upgrade pip
pip install datalad
deactivate
alias datalad=$HOME/datalad-env/bin/datalad   # best to add this line to your ~/.bashrc file
```







## Initial configuration

All these settings go into `~/.gitconfig`:

```sh
git config --global --add user.name "First Last"      # your name
git config --global --add user.email name@domain.ca   # your email address
git config --global init.defaultBranch main
```






## Basics

#### Create a new dataset

> **Note**: Some files in your dataset will be stored as plain files, some files will be put in the annex,
> i.e. they will be replaced with their symbolic links and might not be even stored locally. Annexed files
> cannot be modified directly (more on this later). The command `datalad run-procedure --discover` shows
> you a list of available configurations. On my computer they are:
> - `text2git`: do not put anything that is a text file in the annex, i.e. process them with regular Git
> - `yoda`: configure a dataset according to the "yoda" principles
> - `noannex`: put everything under regular Git control

```sh
cd ~/tmp
datalad create --description "our first dataset" -c text2git test   # use `text2git` configuration
cd test
ls
git log
```

#### Add some data

Let's use some file examples from the official {{<a "http://handbook.datalad.org" "DalaLad handbook">}}:

```sh
mkdir books
wget -q https://sourceforge.net/projects/linuxcommand/files/TLCL/19.01/TLCL-19.01.pdf -O books/theLinuxCommandLine.pdf
wget -q https://homepages.uc.edu/~becktl/byte_of_python.pdf -O books/aByteOfPython.pdf
ls books
datalad status
datalad save -m "added a couple of books on Linux and Python"
ls books
git log -n 1        # check last commit
git log -n 1 -p     # check last commit in details
git one             # custom alias
git log --oneline   # a short alternative
```

Let's add another couple of books using a built-in downloading command:

```sh
datalad download-url https://github.com/progit/progit2/releases/download/2.1.154/progit.pdf \
    --dataset . -m "added a reference book about git" -O books/proGit.pdf
datalad download-url http://www.tldp.org/LDP/Bash-Beginners-Guide/Bash-Beginners-Guide.pdf \
    --dataset . -m "added bash guide for beginners" -O books/bashGuideForBeginners.pdf
ls books
tree
datalad status   # nothing to be saved
git one          # `datalad download-url` took care of that
git annex whereis books/proGit.pdf   # show the available copies (including the URL source)
git annex whereis books              # show the same for all books
```

```sh
cat << EOT > notes.txt
We have downloaded 4 books.
EOT
datalad save -m "added notes.txt"
git one -n 1      # see the last commit
git one -n 1 -p   # and its file changes
```

Notice that the text file was not annexed: there is no symbolic link. We can change it easily:

```sh
echo Text files are not in the annex.>> notes.txt
datalad save -m "edited notes.txt"
```

#### Subdatasets

Let's clone a remote dataset and store it locally as a subdataset:

> From its description: A large and highly detailed volumetric cloud data set, intended to be used for various
> purposes, including movie and game production as well as research.


```sh
datalad clone --dataset . https://github.com/datalad-datasets/machinelearning-books   # get its structure
tree
du -s machinelearning-books             # not much data there (large files were not downloaded)
cd machinelearning-books
datalad status --annex   # if all files were present: 9 annex'd files (74.4 MB recorded total size)
datalad status --annex all   # check how much data we have locally: 0.0 B/74.4 MB present/total size
datalad status --annex all A.Shashua-Introduction_to_Machine_Learning.pdf   # 683.7 KB
```

Ok, this file is not too large, so we can download it easily:

```sh
datalad get A.Shashua-Introduction_to_Machine_Learning.pdf
datalad status --annex all   # now we have 683.7 KB/74.4 MB present/total size
open A.Shashua-Introduction_to_Machine_Learning.pdf   # it should open
datalad drop A.Shashua-Introduction_to_Machine_Learning.pdf   # delete the local copy
git log    # this particular dataset's history (none of our commands show here: we did not modify it)
cd ..
```

Let's try cloning from another GitHub repository:

```sh
datalad clone --dataset . https://github.com/razoumov/sharedSnippets sharedSnippets
cd sharedSnippets
datalad status --annex all   # does not show anything, since it has no annexed files
ls
```

This one downloaded all the files, i.e. none of them are annexed. Why?

Well, this is how this new dataset is structured, and it is organized this way because it was created with the
`text2git` configuration, which keeps text files outside the annex.

#### Running scripts

```sh
cd ../machinelearning-books
git annex find --not --in=here     # show remote files
mkdir code
cat << EOT > code/titles.sh
for file in \$(git annex find --not --in=here); do
    echo \$file | sed 's/^.*-//' | sed 's/.pdf//' | sed 's/_/ /g'
done
EOT
cat code/titles.sh
datalad save -m "added a short script to write a list of book titles"
datalad run -m "create a list of books" "bash code/titles.sh > list.txt"
cat list.txt
git log   # the command run record went into the log
```

Now we will modify and rerun this script:

```sh
datalad unlock code/titles.sh   # move the script out of the annex to allow edits
cat << EOT > code/titles.sh
for file in \$(git annex find --not --in=here); do
    title=\$(echo \$file | sed 's/^.*-//' | sed 's/.pdf//' | sed 's/_/ /g')
	echo \"\$title\"
done
EOT
datalad save -m "correction: enclose titles into quotes" code/titles.sh
git one -n 5   # note the hash of the last commit
datalad rerun ba90706
more list.txt
datalad diff --from ba90706 --to f88e2ce   # show the filenames only
```

Finally, let's extract the title page from one of the books,
`A.Shashua-Introduction_to_Machine_Learning.pdf`. First, let's open the book itself:

```sh
open A.Shashua-Introduction_to_Machine_Learning.pdf   # this book is not here!
```

The book is not here ... That's not a problem for DalaLad, as it can process a file that is stored remotely
(as long as it is part of the dataset): it will automatically get the required input file.

```sh
datalad run -m "extract the title page" \
  --input "A.Shashua-Introduction_to_Machine_Learning.pdf" \
  --output "title.pdf" \
  "convert -density 300 {inputs}[0] -quality 90 {outputs}"
git log
git annex find --in=here     # show local files: it downloaded the book, extracted the first page
open title.pdf
```







## Three workflows

### Scenario 1: two users on a shared filesystem working with the same dataset

### Scenario 2: one user, one dataset spread over multiple drives, with data redundancy

Create an always-present dataset on the computer that will keep track of all data stored in its clones on
various removable USB drives:

```sh
cd ~/tmp
datalad create --description "Central location" -c text2git distributed
cd distributed
git config receive.denyCurrentBranch updateInstead   # allow clones to update this dataset
```

Create the first clone on a portable USB drive:

```sh
cd /Volumes/tiny
datalad clone --description "tiny" ~/tmp/distributed distributed
cd distributed
git remote rename origin central
mkdir books
wget -q https://sourceforge.net/projects/linuxcommand/files/TLCL/19.01/TLCL-19.01.pdf -O books/theLinuxCommandLine.pdf
wget -q https://homepages.uc.edu/~becktl/byte_of_python.pdf -O books/aByteOfPython.pdf
datalad save -m "added a couple of books"
datalad push --to central --data nothing   # push metadata to central
```

Create the second clone on another portable USB drive:

```sh
cd /Volumes/kingston
datalad clone --description "kingston" ~/tmp/distributed distributed
cd distributed
du -s .   # no actual data was copied, just the links
git remote rename origin central
cd books
wget -q https://github.com/progit/progit2/releases/download/2.1.154/progit.pdf -O proGit.pdf
wget -q http://www.tldp.org/LDP/Bash-Beginners-Guide/Bash-Beginners-Guide.pdf -O bashGuideForBeginners.pdf
datalad save -m "added two more books"
git one                          # we have history from both drives (all 4 books)
git annex find --in=here         # but only 2 books are stored here
git annex find --not --in=here   # and 2 books are stored not here
for book in $(git annex find --not --in=here); do
    git annex whereis $book      # show their location: they are on tiny
done
datalad push --to central --data nothing   # push metadata to central
```

#### Operations from the central dataset:

```sh
cd ~/tmp/distributed
git annex find --in=here           # show local files: none
git annex find --not --in=here     # show remote files: 4 books
datalad status --annex all         # check local data usage: 0 bytes
git annex find --lackingcopies 0   # show files that are stored only in one place
git annex whereis books/*          # show location
>>> mount tiny
datalad get books/theLinuxCommandLine.pdf   # try getting this book from a remote => error
... get(error): books/theLinuxCommandLine.pdf (file) [not available]
git remote    # nothing: this location does not know where the remotes are stored
datalad siblings add -d . --name tiny --url /Volumes/tiny/distributed
datalad siblings add -d . --name kingston --url /Volumes/kingston/distributed
git remote    # now it knows where to find the remotes
datalad get books/theLinuxCommandLine.pdf   # successful!
>>> unmount tiny
git annex whereis books/theLinuxCommandLine.pdf   # in 2 locations (tiny and here)
>>> read books/theLinuxCommandLine.pdf locally
datalad drop books/theLinuxCommandLine.pdf   # error: tried to check remotes for remaining physical copies
datalad drop --reckless availability books/theLinuxCommandLine.pdf   # do not check remotes (potentially dangerous)
git annex whereis books/theLinuxCommandLine.pdf   # only 1 copy left on tiny
```

Let's add a DalaLad book to the central dataset:

```sh
cd ~/tmp/distributed
datalad download-url http://handbook.datalad.org/_/downloads/en/stable/pdf/ \
    --dataset . -m "added the DataLad Handbook" -O books/datalad.pdf
```

#### Letting remotes know about central changes

The remotes know nothing about this new book. Let's push this update out! Make sure to mount one of the
drives, e.g. `/Volumes/tiny`, and then run the following:

```sh
cd /Volumes/tiny/distributed
git config receive.denyCurrentBranch updateInstead   # allow clones to update this dataset
cd ~/tmp/distributed
datalad push --to tiny --data nothing   # push metadata, but not the data
```

Alternatively, we we can update from a USB drive:

```sh
cd /Volumes/kingston/distributed
datalad update -s central --how=merge
```

Now let's check things from tiny's / kingston's perspectives:

```sh
cd /Volumes/tiny/distributed
ls books/                             # datalad is there
git annex whereis books/datalad.pdf   # it is in central only (plus on the web)

cd /Volumes/kingston/distributed
ls books/                             # datalad is there
git annex whereis books/datalad.pdf   # it is in central only (plus on the web)
```

#### Data redundancy

Now imagine we want to backup all files that are stored in a single location, and always have a copy on one of
the USB drives. Mount both drives.

```sh
cd /Volumes/tiny/distributed
git remote    # knows only about central
datalad siblings add -d . --name kingston --url /Volumes/kingston/distributed
git remote    # now knows about both central and kingston
for file in $(git annex find --lackingcopies 0); do
    datalad get $file
done
datalad push --to central --data nothing   # update the central
git annex find --lackingcopies 0           # still two files have only 1 copy
git annex find --in=here                   # but they are both here already ==> makes sense
```

Let's go to the other drive and do the same:

```sh
cd /Volumes/kingston/distributed
git remote    # knows only about central
datalad siblings add -d . --name tiny --url /Volumes/tiny/distributed
git remote    # now knows about both central and tiny
datalad update -s central --how=merge
for file in $(git annex find --lackingcopies 0); do
    datalad get $file
done
datalad push --to central --data nothing   # update the central
git annex find --lackingcopies 0           # now all files have at least two copies
git annex whereis                          # here where everything is
```

Try dropping a local file:

```sh
datalad drop books/theLinuxCommandLine.pdf   # successful!
datalad get books/theLinuxCommandLine.pdf    # get it back
```

Set the minimum number of copies and try dropping again:

```sh
git annex numcopies 2
datalad drop books/theLinuxCommandLine.pdf   # can't: need minimum 2 copies!
```















### Scenario 3: managing multiple Git repos under one dataset







<!-- subdatasets have their own history -->
<!-- cannot write directly into an annexed file -->
<!-- to make change: `git annex unlock` to move the file out of the annex -->
<!--                 update the file -->
<!--                 `datalad save` pushes it back into the annex -->
<!-- git checkout -b test_run -->
<!-- datalad run -m "description" -d dataset -i input -o output "command ..." -->
<!-- it can actually grab things (input) at runtime from the remote repo -->
<!-- datalad save -->
<!-- git merge --strategy=ours main -->
<!-- git checkout main -->
<!-- git merge test_run -->



## Links

- {{<a "http://handbook.datalad.org" "DalaLad handbook">}}
- {{<a "https://handbook.datalad.org/en/latest/basics/101-180-FAQ.html" "Frequently Asked Questions">}}
- {{<a "https://jadecci.github.io/notes/Datalad.html" "DalaLad cheatsheet">}}

<!-- {{<a "link" "text">}} -->
