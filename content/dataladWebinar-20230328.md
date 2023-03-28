+++
title = "Distributed datasets with DataLad"
slug = "datalad"
+++

{{<ex>}}
You can find this webpage at:
{{</ex>}}
# https://wgpages.netlify.app/datalad

## What is DataLad?

DataLad is a version control system for your data. It is built on top of **Git** and **git-annex**, and is
available both as a command-line tool and as a Python API.

### Git

Git a version control system designed to keep track of software projects and their history, to merge edits from
multiple authors, to work with branches (distinct project copies) and merge them into the main projects. Since
Git was designed for version control of text files, it can also be applied to writing projects, such as
manuscripts, theses, website repositories, etc.

> I assume that most attendees are familiar with Git, but we can certainly do a quick command-line Git demo.

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
`datalad` -- commands, so we'll be using the functionality of all three layers.







## Installation

On a Mac with {{<a "https://brew.sh" "Homebrew">}} installed:

```sh
brew upgrade
brew install git-annex
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

DataLad also needs **Git** and **git-annex**, if these are not installed. For mote information, visit the
{{<a "http://handbook.datalad.org/en/latest/intro/installation.html" "official installation guide">}}.

On a cluster you can install DataLad into your $HOME directory:

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

Alternatively, you can install DalaLad into your group's `/project` directory:

```sh
module load git-annex   # need this each time you use DalaLad
module load python
cd ~/projects/def-sponsor00/shared
virtualenv --no-download datalad-env
source datalad-env/bin/activate
pip install --no-index --upgrade pip
pip install datalad
deactivate
chmod -R og+rX datalad-env
```

Then everyone in the group can activate DalaLad with:

```sh
module load git-annex   # need this each time you use DalaLad
alias datalad=/project/def-sponsor00/shared/datalad-env/bin/datalad   # best to add this line to your ~/.bashrc file
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
> - `yoda`: configure a dataset according to the {{<a "https://handbook.datalad.org/en/latest/basics/101-127-yoda.html" "yoda principles">}}
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
git config --global alias.one "log --graph --date-order --date=short --pretty=format:'%C(cyan)%h %C(yellow)%ar %C(auto)%s%+b %C(green)%ae'"
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
git log          # `datalad download-url` took care of that
git annex whereis books/proGit.pdf   # show the available copies (including the URL source)
git annex whereis books              # show the same for all books
```

Create and commit a short text file:

```sh
cat << EOT > notes.txt
We have downloaded 4 books.
EOT
datalad save -m "added notes.txt"
git log -n 1      # see the last commit
git log -n 1 -p   # and its file changes
```

Notice that the text file was not annexed: there is no symbolic link. This means that we can modify it easily:

```sh
echo Text files are not in the annex.>> notes.txt
datalad save -m "edited notes.txt"
```

#### Subdatasets

Let's clone a remote dataset and store it locally as a subdataset:

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

<!-- Let's try cloning from another GitHub repository: -->

<!-- ```sh -->
<!-- datalad clone --dataset . https://github.com/razoumov/sharedSnippets sharedSnippets -->
<!-- cd sharedSnippets -->
<!-- datalad status --annex all   # does not show anything, since it has no annexed files -->
<!-- ls -->
<!-- ``` -->

<!-- This one downloaded all the files, i.e. none of them are annexed. Why? -->

<!-- Well, this is how this new dataset is structured, and it is organized this way because it was created with the -->
<!-- `text2git` configuration too, keeping all text files outside the annex. -->

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
git log -n 5   # note the hash of the last commit
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
(as long as it is part of the dataset) &nbsp;🡲&nbsp; it will automatically get the required input file.

```sh
datalad run -m "extract the title page" \
  --input "A.Shashua-Introduction_to_Machine_Learning.pdf" \
  --output "title.pdf" \
  "convert -density 300 {inputs}[0] -quality 90 {outputs}"
git log
git annex find --in=here     # show local files: it downloaded the book, extracted the first page
open title.pdf
```










## Five workflows

1. two users on a shared cluster filesystem working with the same dataset,
2. one user, one dataset spread over multiple drives, with data redundancy,
3. publish a dataset on GitHub with annexed files in a special private remote,
4. publish a dataset on GitHub with publicly-accessible annexed files on Nextcloud, and
5. (if we have time) managing multiple Git repos under one dataset

### Workflow 1: two users on a shared cluster filesystem working with the same dataset

For simplicity, let's assume both users share the same GID (group ID), i.e. they are from the same research
group. Extending this workflow to multiple users with different GISs can be done via
{{<a "https://docs.alliancecan.ca/wiki/Sharing_data#Access_control_lists_(ACLs)" "Access control lists (ACLs)">}}.

#### Start with Git

First, let's consider a shared Git-only (no git-annex, no DalaLad) repository in `/project`, and how the two
users can both push to it.

<!-- # newgrp def-sponsor00   # switch my default group to the group with which I want to share -->

```sh
user001
git config --global user.name "First User"
git config --global user.email "user001@westdri.ca"
git config --global init.defaultBranch main
cd /project/def-sponsor00
git init --bare --shared collab
ls -l | grep collab   # note the group permissions and the SGID (recursive)

cd
git clone /project/def-sponsor00/collab
cd collab
dd if=/dev/urandom of=test1 bs=1024 count=$(( RANDOM + 1024 ))
dd if=/dev/urandom of=test2 bs=1024 count=$(( RANDOM + 1024 ))
dd if=/dev/urandom of=test3 bs=1024 count=$(( RANDOM + 1024 ))
git add test*
git commit -m "added test{1..3}"
git push

user002
git config --global user.name "Second User"
git config --global user.email "user002@westdri.ca"
git clone /project/def-sponsor00/collab
cd collab
echo "making some changes" > readme.txt
git add readme.txt
git commit -m "added readme.txt"
git push
```

<!-- There are other things that would go into this webinar: doing the same with ACLs (user outside your research -->
<!-- group), and extending this to DataLad. -->

#### Add DataLad datasets

<!-- # newgrp def-sponsor00   # switch my default group to the group with which I want to share -->

```sh
user001
module load git-annex   # need this each time you use DalaLad
alias datalad=/project/def-sponsor00/shared/datalad-env/bin/datalad   # best to add this line to your ~/.bashrc file

chmod -R u+wX ~/collab
/bin/rm -rf /project/def-sponsor00/collab ~/collab

cd /project/def-sponsor00
git init --bare --shared collab
ls -l | grep collab   # note the group permissions and the SGID (recursive)

cd
datalad create --description "my collab" -c text2git collab   # create a dataset using `text2git` template
cd collab
dd if=/dev/urandom of=test1 bs=1024 count=$(( RANDOM + 1024 ))
dd if=/dev/urandom of=test2 bs=1024 count=$(( RANDOM + 1024 ))
dd if=/dev/urandom of=test3 bs=1024 count=$(( RANDOM + 1024 ))
datalad save -m "added test1,2,3"
git remote add origin /project/def-sponsor00/collab
# git push --set-upstream origin main      # if we were using Git only
datalad push --to origin --data anything   # transfer all annexed content
git annex whereis test1                    # 1 copy
datalad push --to origin --data anything   # I find that I need to run it twice to actually transfer annexed data
git annex whereis test1                    # 2 copies (here and origin)
du -s /project/def-sponsor00/collab
```

After making sure there is a remote copy, you can drop a local copy:

```sh
datalad drop test1
git annex whereis test1                    # 1 copy
```

To get this file at any time in the future, you would run:

```sh
datalad get test1
```

Let's actually drop all files for which there is a remote copy, to save on local disk space:

```sh
for file in $(git annex find --in=origin); do
    datalad drop $file
done
git annex whereis test*      # only remote copies left
datalad status --annex all   # check local data usage
du -s .
```

<!-- ```sh -->
<!-- datalad update            # update from origin -->
<!-- git annex whereis test1   # 2 copies (origin and second copy) -->

<!-- cd ~/collab2 -->
<!-- echo "some description of my dataset" > readme.txt -->
<!-- datalad save -m "added readme.txt" -->
<!-- datalad status -->
<!-- git log -->
<!-- datalad push --to origin --data anything   # push readme.txt to origin -->

<!-- cd ~/collab -->
<!-- datalad update --how merge       # download readme.txt -->
<!-- ``` -->

To allow other users to write to the DalaLad repo, setting `git init --shared ...` on
`/project/def-sponsor00/collab` is not sufficient, as it does not set proper permissions for
`/project/def-sponsor00/collab/annex`. We have to do it manually:

```sh
cd /project/def-sponsor00/collab
chmod -R g+ws annex   # so that user002 could push with datalad
```

```sh
user002
module load git-annex   # need this each time you use DalaLad
alias datalad=/project/def-sponsor00/shared/datalad-env/bin/datalad   # best to add this line to your ~/.bashrc file

git config --global --add safe.directory /project/60105/collab           # allow git to work with files from other users
git config --global --add safe.directory /project/def-sponsor00/collab   # do the same for the linked version

/bin/rm -rf collab
datalad clone --description "user002's copy" /project/def-sponsor00/collab collab
cd collab
du -s .
git annex find --in=here   # show local files (none at the moment)

datalad get test1     # download the file
dd if=/dev/urandom of=test4 bs=1024 count=$(( RANDOM + 1024 ))
datalad save -m "added test4"
git log
git remote -v    # our remote is origin
datalad push --to origin --data anything
git annex find --in=origin     # test4 now in both places

echo "I started working with this dataset as well" > notes.txt
git add notes.txt
git commit -m "added notes.txt"
datalad push
```

Now user001 can see the two new files:

```sh
user001
module load git-annex   # need this each time you use DalaLad
alias datalad=/project/def-sponsor00/shared/datalad-env/bin/datalad   # best to add this line to your ~/.bashrc file

cd ~/collab
datalad update --how merge   # download most recent data from origin
cat notes.txt                # it is here
git annex find --in=here     # none of the annexed content (e.g. test4) is here

datalad get test4            # but we can get it easily
git annex find --in=here

datalad status --annex all         # check how much data we have locally: present/total space
git annex find --lackingcopies 0   # show files that are stored only in one place
git annex whereis test*            # show location for all files
```

You also see information about what is stored in "user002's copy". However, you should take it with a grain of
salt. For example, if user002 drops some files locally and does not run `datalad push`, origin (and hence
user001) will have no knowledge of that fact.



<!-- ```sh -->
<!-- dd if=/dev/urandom of=test5 bs=1024 count=$(( RANDOM + 1024 )) -->
<!-- datalad save -m "added test5" -->
<!-- datalad push --to origin --data anything -->

<!-- user002 -->
<!-- cd ~/collab -->
<!-- datalad update --how merge   # download user002's data -->
<!-- dd if=/dev/urandom of=test6 bs=1024 count=$(( RANDOM + 1024 )) -->
<!-- datalad save -m "added test6" -->
<!-- datalad push --to origin --data anything -->

<!-- user001 -->
<!-- cd ~/collab -->
<!-- datalad drop test*               # remove all local data -->
<!-- git annex whereis test*          # show data location; none of the data is here -->
<!-- datalad status --annex all       # check local data usage -->
<!-- git annex find --not --in=here   # show files that are not here -->
<!-- git annex find --lackingcopies 0   # show files that are stored only in one place -->
<!-- datalad get test{2,3,5}          # download those files -->
<!-- git annex find --in=here         # show files that are here -->
<!-- ``` -->











### Workflow 2: one user, one dataset spread over multiple drives, with data redundancy

Initially I created this scenario with two external USB drives. In the interest of time, I simplified it to a
single external drive, but it can easily be extended to any number of drives.

First, let's create an always-present dataset on the computer that will also keep track of all data stored in
its clone on a removable USB drive:

```sh
cd ~/tmp
datalad create --description "Central location" -c text2git distributed
cd distributed
git config receive.denyCurrentBranch updateInstead   # allow clones to update this dataset
mkdir books
wget -q https://sourceforge.net/projects/linuxcommand/files/TLCL/19.01/TLCL-19.01.pdf -O books/theLinuxCommandLine.pdf
wget -q https://homepages.uc.edu/~becktl/byte_of_python.pdf -O books/aByteOfPython.pdf
datalad save -m "added a couple of books"
ls books
du -s .   # 4.9M stored here
```

<!-- Create the first clone on a portable USB drive: -->
<!-- ```sh -->
<!-- cd /Volumes/tiny -->
<!-- datalad clone --description "tiny" ~/tmp/distributed distributed -->
<!-- cd distributed -->
<!-- git remote rename origin central -->
<!-- datalad push --to central --data nothing   # push metadata to central -->
<!-- ``` -->

Create a clone on a portable USB drive:

```sh
cd /Volumes/t7
datalad clone --description "t7" ~/tmp/distributed distributed
cd distributed
du -s .   # no actual data was copied, just the links
git remote rename origin central
cd books
wget -q https://github.com/progit/progit2/releases/download/2.1.154/progit.pdf -O proGit.pdf
wget -q http://www.tldp.org/LDP/Bash-Beginners-Guide/Bash-Beginners-Guide.pdf -O bashGuideForBeginners.pdf
datalad save -m "added two more books"
git log                          # we have history from both drives (all 4 books)
git annex find --in=here         # but only 2 books are stored here
git annex find --not --in=here   # and 2 books are stored not here
for book in $(git annex find --not --in=here); do
    git annex whereis $book      # show their location: they are in central
done
datalad push --to central --data nothing   # push metadata to central
```

#### Operations from the central dataset:

```sh
cd ~/tmp/distributed
git annex find --in=here           # show local files: 2 books
git annex find --not --in=here     # show remote files: 2 books
datalad status --annex all         # check local data usage: 4.6 MB/17.6 MB present/total size
git annex find --lackingcopies 0   # show files that are stored only in one place
git annex whereis books/*          # show location
```

Let's mount t7 and get one of its books:

```sh
datalad get books/bashGuideForBeginners.pdf   # try getting this book from a remote => error
... get(error): books/bashGuideForBeginners.pdf (file) [not available]

git remote    # nothing: central does not know where the remotes are stored
datalad siblings add -d . --name t7 --url /Volumes/t7/distributed
git remote    # now it knows where to find the remotes
datalad get books/bashGuideForBeginners.pdf   # successful!
```

Now unmount t7.

```sh
git annex whereis books/bashGuideForBeginners.pdf   # 2 copies (here and t7)
open books/bashGuideForBeginners.pdf
```

Let's remove this the local copy of this book:

```sh
datalad drop books/bashGuideForBeginners.pdf   # error: tried to t7 for remaining physical copies
datalad drop --reckless availability books/bashGuideForBeginners.pdf   # do not check remotes (potentially dangerous)
git annex whereis books/bashGuideForBeginners.pdf   # only 1 copy left on t7
```

#### Letting remotes know about central changes

Let's add a DalaLad book to central:

```sh
cd ~/tmp/distributed
datalad download-url http://handbook.datalad.org/_/downloads/en/stable/pdf/ \
    --dataset . -m "added the DataLad Handbook" -O books/datalad.pdf
```

The remote knows nothing about this new book. Let's push this update out! Make sure to mount t7 and then run
the following:

```sh
cd /Volumes/t7/distributed
git config receive.denyCurrentBranch updateInstead   # allow clones to update this dataset
cd ~/tmp/distributed
datalad push --to t7 --data nothing                  # push metadata, but not the data
```

Alternatively, we could update from the USB drive:

```sh
cd /Volumes/t7/distributed
datalad update -s central --how=merge
```

Now let's check things from t7's perspective:

```sh
cd /Volumes/t7/distributed
ls books/                             # datalad.pdf is there
git annex whereis books/datalad.pdf   # it is in central only (plus on the web)
```

#### Data redundancy

Now imagine that we want to backup all files that are stored in a single location, and always have a second
copy on the other drive.

<!-- git remote    # knows only about central -->
<!-- datalad siblings add -d . --name t7 --url /Volumes/t7/distributed -->
<!-- git remote    # now knows about both central and t7 -->

```sh
cd /Volumes/t7/distributed
for file in $(git annex find --lackingcopies 0); do
    datalad get $file
done
datalad push --to central --data nothing   # update the central
git annex find --lackingcopies 0           # still two files have only 1 copy
git annex find --in=here                   # but they are both here already ==> makes sense
```

Let's go to central and do the same:

<!-- git remote    # knows only about central -->
<!-- datalad siblings add -d . --name tiny --url /Volumes/tiny/distributed -->
<!-- git remote    # now knows about both central and tiny -->

```sh
cd ~/tmp/distributed
for file in $(git annex find --lackingcopies 0); do
    datalad get $file
done
git annex find --lackingcopies 0   # none: now all files have at least two copies
git annex whereis                  # here where everything is
```

The file `books/datalad.pdf` is in two locations, although one of them is the web. You can correct that
manually: go to t7 and run `get` there.

Try dropping a local file:

```sh
datalad drop books/theLinuxCommandLine.pdf   # successful, since t7 is also mounted
datalad get books/theLinuxCommandLine.pdf    # get it back
```

Set the minimum number of copies and try dropping again:

```sh
git annex numcopies 2
datalad drop books/theLinuxCommandLine.pdf   # can't: need minimum 2 copies!
```














### Workflow 3: publish a dataset on GitHub with annexed files in a special private remote

At some stage, you might want to publish a dataset on GitHub that contains some annexed data. The problem is
that annexed data could be large, and you can quickly run into problems with GitHub's storage/bandwidth
limitations. Moreover, free accounts on GitHub do not support working with annexed data.

With DalaLad, however, you can host large/annexed files elsewhere and still have the dataset published on
GitHub. This is done with so-called *special remotes*. The published dataset on GitHub stores the information
about where to obtain the annexed file contents when you run `datalad get`.

Special remotes can point to Amazon S3, Dropbox, Google Drive, WebDAV, sftp servers, etc.

Let's create a small dataset with an annexed file:

```sh
cd ~/tmp
chmod -R u+wX publish && /bin/rm -r publish

datalad create --description "published dataset" -c text2git publish
cd publish
dd if=/dev/urandom of=test1 bs=1024 count=$(( RANDOM + 1024 ))
datalad save -m "added test1"
```

Next, we can set up a special remote on the Alliance's Nextcloud service. DataLad talks to special remotes via
`rclone` protocol, so we need to install it (along with `git-annex-remote-rclone` utility) and then configure
an `rclone` remote of type WebDAV:

```sh
brew install rclone
brew install git-annex-remote-rclone
rclone config
  new remote
  Name: nextcloud
  Type of storage: 46 / WebDAV
  URL: https://nextcloud.computecanada.ca/remote.php/webdav/
  Vendor: 1 / Nextcloud
  User name: razoumov
  Password: type and confirm your password
  no bearer_token
  no advanced config
  keep this remote
  quit
```

Inside our dataset we set a `nextcloud` remote on which we'll write into the directory `annexedData`:

```sh
git annex initremote nextcloud type=external externaltype=rclone encryption=none target=nextcloud prefix=annexedData
git remote -v
datalad siblings
datalad push --to nextcloud --data anything
```

If you want to share your `annexedData` folder with another CCDB user, log in to
https://nextcloud.computecanada.ca with your CC credentials, click "share" on `annexedData`, then optionally
type in the name/username of the user to share with.

Next, we publish on dataset on GitHub. The following command creates an empty repository called `testPublish`
on GitHub and sets a publication dependency: all new annexed content will automatically go to Nextcloud when
we push to GitHub.

```sh
datalad create-sibling-github -d . testPublish --publish-depends nextcloud
datalad siblings   # +/- indicates the presence/absence of a remote data annex at this remote
datalad push --to github
```

```sh
dd if=/dev/urandom of=test2 bs=1024 count=$(( RANDOM + 1024 ))
datalad save -m "added test2"
datalad push --to github   # automatically pushes test2 to nextcloud!
```

Imagine we are another user trying to download the dataset. In this demo I will use the same credentials, but
in principle this could be another researcher (at least for **reading only**):

```sh
user001
module load git-annex   # need this each time you use DalaLad
alias datalad=/project/def-sponsor00/shared/datalad-env/bin/datalad   # best to add this line to your ~/.bashrc file
datalad clone https://github.com/razoumov/testPublish.git publish     # note that access to nextcloud is not enabled yet
cd publish
du -s .                       # the annexed file is not here
git annex whereis --in=here   # no annexed file stored locally
git annex whereis test*       # two copies: "published dataset" and nextcloud
datalad update --how merge    # if you need to update the local copy (analogue of `git pull`)

rclone config   # set up exactly the same configuration as before
datalad siblings -d . enable --name nextcloud   # enable access to this special remote
datalad siblings                                # should now see nextcloud
datalad get test1
git annex whereis --in=here                     # now we have a local copy

dd if=/dev/urandom of=test3 bs=1024 count=$(( RANDOM + 1024 ))
datalad save -m "added test3"
datalad push --to origin              # push non-annexed files to GitHub

datalad push --to nextcloud           # push annexed files
datalad push --to origin              # update GitHub of this
```

Back in the original "published dataset" on my laptop:

```sh
datalad update --how merge
ls                        # now can see test3
datalad get test3
git annex whereis test3   # it is here
```








### Workflow 4: publish a dataset on GitHub with publicly-accessible annexed files on Nextcloud

Starting from scratch, let's push some files to 

```sh
cd ~/tmp
chmod -R u+wX publish && /bin/rm -r publish

dd if=/dev/urandom of=test1 bs=1024 count=$(( RANDOM + 1024 ))
rclone copy test1 nextcloud:    # works since we've already set up the `nextcloud` remote in rclone
```

Log in to https://nextcloud.computecanada.ca with your CC credentials, on `test1` click "share" followed by
"share link" and "copy link". Add `/download` to the copied link to form something like
`https://nextcloud.computecanada.ca/index.php/s/YeyNrjJfpQQ7WTq/download`.

```sh
datalad create --description "published dataset" -c text2git publish
cd publish

cat << EOF > list.csv
file,link
test1,https://nextcloud.computecanada.ca/index.php/s/YeyNrjJfpQQ7WTq/download
EOF

datalad addurls --fast list.csv '{link}' '{file}'   # --fast means do not download, just add URL
git annex whereis test1   # one copy (web)
```

Later, when needed, we can download this file with `datalad get test1`.

```sh
datalad create-sibling-github -d . testPublish2   # create am empty repo on GitHub
datalad siblings   # +/- indicates the presence/absence of a remote data annex at this remote
datalad push --to github

user001
module load git-annex   # need this each time you use DalaLad
alias datalad=/project/def-sponsor00/shared/datalad-env/bin/datalad   # best to add this line to your ~/.bashrc file
chmod -R u+wX publish && /bin/rm -r publish
datalad clone https://github.com/razoumov/testPublish2.git publish    # "remote origin not usable by git-annex"
cd publish
git annex whereis test1   # one copy (web)
datalad get test1
git annex whereis test1   # now we have a local copy
```









### Workflow 5: (if we have time) managing multiple Git repos under one dataset

Create a new dataset and inside clone a couple of *subdatasets*:

```sh
cd ~/tmp
datalad create -c text2git envelope
cd envelope
 # let's clobe few regular Git (not DataLad!) repos
datalad clone --dataset . https://github.com/razoumov/radiativeTransfer.git projects/radiativeTransfer
datalad clone --dataset . https://github.com/razoumov/sharedSnippets projects/sharedSnippets
git log   # can see those two new subdatasets
```

Go into one of these subdatasets, modify a file, and commit it to GitHub:

<!-- #   datalad create -f   # convert this Git repo to a dataset -->

```sh
cd projects/sharedSnippets
>>> add an empty line to mpiContainer.md
git status
git add mpiContainer.md
git commit -m "added another line to mpiContainer.md"
git push
```

This directory is still a pure GitHub repository, i.e. there no DalaLad files.

Let's clone out entire dataset to another location:

```sh
cd ~/tmp
datalad install --description "copy of envelope" -r -s envelope copy   # `clone` has no recursive option
cd copy
cd projects/sharedSnippets
git log   # cloned as of the moment of that dataset's creation; no recent update there yet
```

Recursively update all child Git repositories:

```sh
git remote -v     # remote is origin = GitHub
cd ../..          # to ~/tmp/copy
git remote -v     # remote is origin = ../envelope
 # pull recent changes from "proper origin" for each subdataset
datalad update -s origin --how=merge --recursive
cd projects/sharedSnippets
git log
```





<!-- git reset --hard HEAD~1 -->
<!-- git push --force -->








<!-- datalad create-sibling -->
<!-- datalad publish -->







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
