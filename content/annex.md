+++
title = "Distributed file storage with git-annex"
slug = "annex"
katex = true
+++

{{<cor>}}November 26<sup>th</sup>, 2024{{</cor>}}\
{{<cgr>}}10:00am–11:00am Pacific Time{{</cgr>}}

{{<ex>}}
You can find this page at:
{{</ex>}}
# https://wgpages.netlify.app/annex

**Abstract**: git-annex is a file synchronization tool designed to simplify the management of large (typically
data-oriented) files under version control. Unlike Git, git-annex does not track file contents but rather
facilitates the organization of data across multiple locations, both online and offline, enabling the creation
of multiple copies for backup and redundancy, ensuring data safety and organization. &nbsp;&nbsp;&nbsp; In the
past, we have taught webinars on tools built upon git-annex, such as [DataLad](https://www.datalad.org). In
these tools the core functionality is typically provided by git-annex, so we believe it is crucial to
understand how to effectively organize data using git-annex itself, without the distraction of additional
features. &nbsp;&nbsp;&nbsp; Personally, I have been utilizing git-annex for several years to manage my
extensive collection of archived files across multiple drives stored on a shelf. git-annex provides built-in
redundancy, ensuring that each individual repository or drive is aware of the location of all files on other
drives, eliminating the need to power them on just to find a file. git-annex also offers online capabilities,
allowing file synchronization across multiple filesystems and clusters to help you manage your research data.

## Git shortcomings for large files

Git was designed for version control of **text files** (codes, articles, any text-based documents). One major
drawback of putting large **data files** under traditional version control is that it will double the size of
your repository. You can use a hack to alleviate this problem, e.g. instead of putting the repository into the
working directory, you can put it on a separate drive:

```sh
mkdir large && cd large
git init --separate-git-dir=/Volume/drive/repoDir
dd if=/dev/urandom of=someLargeFile bs=10240 count=$(( RANDOM + 1024 ))
git add someLargeFile
git commit -m "..."
```

In the working directory, this will create a text file `.git` containing the path to the actual
repository. Now, when you commit large files to this repository, a copy will remain in the working directory
(first drive), and another copy will go into the repository (second drive). Theoretically, you can even swap
between different repositories (i.e. different drives) by swapping the content of `.git`, so you can have a
copy of the same set of files on multiple drives.

However, if you modify/delete a binary data file from the working directory, git will keep the older version
in the repository. If this is a multi-GB data file and you no longer need it, you'll be wasting space by
keeping this file in the repository.

git-annex solves this problem by replacing data files with symbolic links. When you no longer need a file, you
simply run a `git-annex drop` command to free some disk space. In addition, git-annex provides these features:

1. It can distribute files across multiple repositories, to have a different collection of files in each
   repository. You don't use multiple bookcases to store the same set of books!
1. It can automate redundant storage, so that you can have multiple copies of files on different drives *when
   you need backups*.
1. It can work offline: you can synchronize data between drives without having to mount all of them at the
   same time. git-annex is *fully distributed*, i.e. each repository in the collection stores the full
   history, but it is often convenient to designate the main repository for syncing multiple secondary
   repositories on external drives. In addition, each repository knows about the location of all files in all
   other repositories, without having to mount the drives.

I typically buy my drives when I need more storage. Eventually I end up with a heterogeneous collection of
standalone HDDs and SSDs. git-annex helps me automate storage of a large number of files across these drives
sitting on a shelf and ensures that all my storage is redundant, i.e. I have at least two copies of *all
important* files. I can even throw into the mix a remote server with extra storage, if I want.

You can read about the history of git-annex on [Wikipedia](https://en.wikipedia.org/wiki/Git-annex).

There is a competing project [Git Large File Storage (LFS)](https://git-lfs.com), and a number of projects
built on top of git-annex.

## Installation

git-annex is open source and is available as a package in Linux, Mac, Windows. On my Mac I installed it with
`brew install git-annex`. On the Alliance clusters git-annex is provided as a module (`module load
git-annex`), so no need to install it there.

For git-annex to function, you also need Git. Sometimes Git development gets ahead of git-annex, and very
occasionally things might behave weirdly if you have newer Git and older git-annex (but I never had any data
lost). In such cases you might want to check if a new version of git-annex is available.

## Standalone workflows

### Adding binary files

For the purpose of this tutorial, let's create a bash function to quickly add new binary files to the current
directory.

1. `shuf -i 0-9 -n 5` produces 5 unique random digits 0-9
1. `shuf -i 0-9 -n 5 | tr -d '\n'` puts 5 unique random digits into a singe line
1. `$RANDOM` returns a pseudorandom integer in the range 0..32767

The following function will take a number and will produce this number of binary files (filled with random
bits) of size (1-33)MB.

```sh
function populate() {
    if [ $# -gt 0 ]; then
	for i in $(seq -w 1 $1); do
	    num=$(shuf -i 0-9 -n 5 | tr -d '\n')
	    dd if=/dev/urandom of=test"$num" bs=1024 count=$(( RANDOM + 1024 ))
	done
    fi
}
```

### Initialize annexes

```sh
cd ~/tmp
mkdir -p {earth,mars,venus}/annex   # placeholders for different drives or filesystems
tree
cd earth/annex

alias ga='git-annex'

git init
ga init "earth"

populate 10

ga add .   # (1) move files to .git/annex/objects
           # (2) create symbolic links pointing to the new location
		   # (3) add these links to the index (git staging area)
git commit -m "add 10 new files"
```

<!-- # echo "* annex.numcopies=1" >> .gitattributes -->

It is very important to use `ga add` and not `git add` when adding files to annex, so you need to rewire your
git finger memory.

To check the repository/annex current status, you can use one of these two commands -- both of them report
approximately the same information, so in practice I use one or the other:

```sh
git status   # everything is clean
ga status    # everything is clean
```

```sh
populate 5
ls   # 5 new files, 10 old links

ga add .
git commit -m "add 5 new files"
du -s .git/annex/objects   # the files are really there
```

### Undo accidental add command

Let's say we added a file by mistake, but have not committed it yet:

```sh
populate 1
ls
export testfile=test50427
ga add $testfile

git status   # new file to be comitted
ga status    # added the new file

ls -l $testfile
object=$(ls -l $testfile | awk '{print $11}')   # store last line
ls -l $object
```

How do we undo this `ga add` operation? We must do it in two steps.

1. put the file content back to replace the link:

```sh
ga unannex $testfile
ls -l $testfile   # the file is back
ls -l $object     # but the object is also still there
```

2. remove unlinked file content from the repository:

```sh
ga unused   # show all unlinked files in the repository (object store)
ga dropunused --force 1   # drop the first unused file

ls -l $object     # now the object is gone
ga unused         # no unlinked files left
```

We are now back to having our new, untracked file -- you can check that with either `git status` or `ga
status`.

### Remove files from annex control

What if we have both added and committed the file -- how do we undo that, i.e. how do we remove a file from
git-annex control? Follow the same two steps and update the repository:

```sh
ga unannex test80145      # unannex one file currently under git-annex control
ga dropunused --force 1   # drop the first unused file
git commit -m "moved test80145 out of the annex"
```

Now if we do either `git status` or `ga status`, they will report that now we have a new, untracked file.

If you want to remove multiple files, e.g. `file1`, `file2`, `file3`, or an entire subdirectory `subdir`, you
would do something like this:

```sh
ga unannex <file1> <file2> <file3>
ga unannex <subdir>
ga unused                      # show all unlinked files
ga dropunused --force {1..5}   # adjust the number based on the previous command's output
```

### Remove file completely from the drive

If you don't want to keep the data file, one possible solution is:

1. replace the link with the file content: `ga unannex <filename>`
1. drop the unused object file with a combination of `ga unused` and `ga dropunused --force <number>`
1. update the repository: `git commit -m "moved <filename> out of the annex"`
1. delete the file `rm <filename>`

An alternative solution (we'll see `ga drop` later when we work with remotes) could be:

```sh
ga drop --force <filename>   # drop a local copy (object)
unlink  <filename>           # remove the link
ga sync                      # does git commit in the background
```

### Getting help

- `ga --help' will list all available commands
- `ga <command> --help` will give quick info about the command flags
- online help pages for individual commands https://git-annex.branchable.com/git-annex-command (replace
  `command` with the actual command)

## Working with remotes

The real power of git-annex lies in its ability to distribute files across multiple annexes in a seamless
manner. This is achieved through conventional Git remotes.

### Remote via a clone

Let's go to another drive and clone our existing repository there:

```sh
ga status   # make sure everything is committed

cd ~/tmp/venus
git clone ~/tmp/earth/annex
cd annex

ls          # there are symbolic links to non-existent destinations
du -s .     # currently no objects (data files)
git log     # see the history from earth

ga whereis    # all 15 files are on earth (1 copy of each)

populate 10
ga add .
git commit -m "add 10 new files"

ga whereis   # 15 files on earth, 10 files here
```

In a separate terminal, if we go to `earth` drive:

```sh
cd ~/tmp/earth/annex
ga whereis   # shows only 15 local files

git remote add venus ~/tmp/venus/annex
ga sync
ga whereis   # 15 files here, 10 files on venus
```

So, what does `ga sync` do exactly? It performs these operations:

1. run local `git commit` with a generic message "git-annex in <annex>"
1. update the current repository with all changes made to its remotes, and
1. push any changes in the current repository to its remotes, where you need to run `ga sync` to get them

An important innovation of `ga sync` is that it can work with remotes when they are offline:

- when pulling from an offline remote, it will check its "Inbox" branch (not actual name) to see if that
  remote has sync'ed to it earlier
- when pushing to an offline remote, it will push updates to its "Outbox" branch (not actual name)

```output
in earth ---
  git-annex
* main
  synced/git-annex
  synced/main

in venus ---
  git-annex
* main
  synced/main
```

Let's test communicating with offline annexes:

```sh
--- venus annex ---
ga sync             # we made some changes to earth, need to update here
dd if=/dev/urandom of=venus1 bs=1024 count=$(( RANDOM + 1024 ));
ga add venus1
git commit -m "add venus1"
ga sync
cd ../..
mv venus hidden     # hide it from earth

--- earth annex ---
ga whereis venus1   # cannot find
ga sync             # update from the local branch
ga whereis venus1   # it is in venus

cd ~/tmp
mv hidden venus
```

### Remote from scratch

Let's move to another drive and create a new annex there from scratch with 10 new files:

```sh
cd ~/tmp/mars/annex
git init
ga init "mars"
populate 10
ga add .
git commit -m "add 10 new files"
ga status   # all clean
```

At this point we still have an isolated annex. Let's add our original repo as a remote for this repo:

```sh
git remote add earth ~/tmp/earth/annex
ga sync   # now fails, as you have two separate histories
ga sync --allow-unrelated-histories   # should work if no file conflicts
```

If there is a conflict, you may want to either (1) create a new repository via `git clone` like in the
previous section, and then add new files by hand, or (2) try to rename the conflicting file.

Finally, let's do this:

```sh
--- earth annex ---
ga sync
git remote               # mars is not its remote yet
ga whereis | grep mars   # but we can see the 10 files on mars!
```

Here we see another example of offline communication: mars pushed into earth's inbox earlier, and the last `ga
sync` received those updates, even though we cannot connect to mars directly (no such remote). Let's correct
this by adding the remote:

```sh
--- earth annex ---
git remote add mars ~/tmp/mars/annex
```

### Create multiple copies

This is easily one of my favourite git-annex features!

```sh
--- earth annex ---
populate 2
export coupleOfFiles="test03985 test69314"
ga add $coupleOfFiles
git commit -m "add 2 files"
ga whereis $coupleOfFiles
```

These files have just one copy (here). In fact, in our annexes there are many files with a single copy:

```sh
ga whereis | grep -A 1 "1 copy"   # show all files with only one copy, in earth + mars + venus
ga whereis . | grep -A 1 "1 copy" | grep -B 2 "\[here\]"   # show local files with only one copy
ga sync

--- mars annex ---
ga sync
ga whereis $coupleOfFiles   # 1 copy on earth
ga get --auto --numcopies=2 $coupleOfFiles
ga whereis $coupleOfFiles   # 2 copies
ga sync
```

The command `ga get --auto --numcopies=2` can work with any list of files and/or directories.

<!-- ```sh -->
<!-- cd /Volumes/white/annex   # 2nd copy destination -->
<!-- src=watch/soloCamping -->
<!-- ga whereis $src | grep -A 1 "1 copy"   # show files with only one copy in a given directory -->
<!-- ga whereis . | grep -A 1 "1 copy" | grep -B 2 evo   # show files with only one copy on a given drive -->
<!-- >>> make sure the source drive is mounted -->
<!-- ga get --auto --numcopies=2 $src   # get files with fewer than two copies -->
<!-- ga whereis $src -->
<!-- ga sync -->
<!-- ``` -->






### Move files manually between remotes

```sh
ga whereis   # pick a file on venus
ga move <filename> --to here   # will likely fail (venus not linked)
git remote add venus ~/tmp/venus/annex
ga move <filename> --to here   # should work
```

```sh
ga find   # list all local files => pick a file
ga whereis test52930   # check its copies
ga move test52930 --to venus   # venus has to be online for this to work
```

### Drop a local copy

```sh
ga find   # list all local files => pick a file
ga drop test97806   # delete the object; keep the link: dangerous territory!
```

Usually, git-annex will not let you delete a single copy, but you can `--force` it to permanently delete your
data.

If you still want to keep a copy elsewhere, a safer approach would be:

```sh
ga drop --auto --numcopies=1 <path>   # drop all local copies if there is a remote copy
ga drop --auto --numcopies=2 <path>   # drop all local copies if there are 2 remote copies
```

### Move a file out of the annex and drop all annexed copies

<!-- details at https://git-annex.branchable.com/forum/git-annex_unused_not_dropping_deleted_files -->

Lets' create a new file and put its content into two annexes:

```sh
--- earth annex ---
populate 1
export testfile=test05873
ga add $testfile
ga copy $testfile --to mars
ga sync
ga whereis $testfile   # two copies: on earth and mars

--- mars annex ---
ga sync
ga whereis $testfile   # two copies: on earth and mars
object=$(ls -l $testfile | awk '{print $11}')
ls -l $object          # actual file is stored here
```

Let's copy the file content back to replace the link:

```sh
ga unannex $testfile
ls              # the file replaced the link
ga unused       # shows no unlinked files
ls -l $object   # the file is still there, and it is unlinked
```

What is going on here? It turns out that "ga unused" actually works across linked annexes, and it simply says
that there is a link to this file somewhere in the other repository. To unannex this file's copy everywhere,
you need to tell `ga unused` to ignore that this file is checked out in other annexes:

```sh
ga unused --used-refspec=+master
ga dropunused --force 1
ga sync
ls -l $object   # the object is now gone locally

--- earth annex ---
ls -l $testfile   # the file is still under annex here
ga sync
ls -l $testfile   # and now it is not
ga whereis $testfile               # this file is not under annex anywhere
ga unused --used-refspec=+master   # delete its copy here as well
ga dropunused --force 1

--- mars annex ---
ls $testfile      # we have the unannexed copy (and only copy) in mars
```





### Show disk usage across all remotes

```sh
ga info <path>   # show local+global disk usage in a directory
```




### Organize links into directories

In real life you put files into folders / directories. We can do the same with git-controlled links:

```sh
--- mars annex ---
mkdir data
git mv test{0,1,2}* data/
ga sync

--- earth annex ---
ga sync
ls   # test0*,test1*,test2* should be in data/
ga get --auto --numcopies=2 data   # get files in /data with fewer than two copies
ga sync

--- mars annex ---
ga get --auto --numcopies=2 data   # get files in /data with fewer than two copies
ga whereis data                    # all files will likely have two copies now
ga sync
```






## SSH remotes

If you want to talk to a remote via ssh, its host server will need to have git and git-annex installed and
available via command line when you ssh to that server. However, the Alliance clusters provide git-annex as a
module. In this case, you can add `module load git-annex` to your ~/.bashrc file:

```sh
user01@vis.vastcloud.org
echo module load git-annex >> .bashrc
echo alias ga=git-annex >> .bashrc
source .bashrc
git config --global init.defaultBranch main   # sometimes remote git can be old
```

<!-- ```sh -->
<!-- user01@vis.vastcloud.org -->
<!-- echo export PATH="/cvmfs/soft.computecanada.ca/easybuild/software/2023/x86-64-v3/Core/git-annex/10.20231129/bin:\$PATH" >> .bashrc -->
<!-- echo alias ga=git-annex >> .bashrc -->
<!-- source .bashrc -->
<!-- git config --global init.defaultBranch main -->
<!-- ``` -->

```sh
user01@vis.vastcloud.org
mkdir annex && cd annex
git init       # --bare
ga init "cluster"
git commit --allow-empty -m "first commit"   # otherwise local "ga sync" will fail to merge

--- earth annex ---
git remote remove cluster
git remote add cluster user01@vis.vastcloud.org:annex
ga sync --allow-unrelated-histories

--- cluster annex ---
ga sync
ls        # all aliases from earth should be there
du -s .   # but there are no object files
```

With the two repositories linked, any new change on earth can be sync'ed with the SSH remote:

```sh
--- earth annex ---
dd if=/dev/urandom of=earth3 bs=1024 count=$(( RANDOM + 1024 ));
ga add earth3
ga unannex earth1
ga sync

--- cluster annex ---
ga sync
ls   # recent updates from earth should be here
ga whereis earth3   # only one copy on earth
ga whereis earth1   # no copies under git-annex control
```

How about going the other way, i.e. syncing a change from the ssh remote?

```sh
--- cluster annex ---
dd if=/dev/urandom of=cluster1 bs=1024 count=$(( RANDOM + 1024 ));
ga add cluster1
ga sync   # cannot update the repos on my computer: they are behind the firewall;
          # plus we have not even set up the remotes!

--- earth annex ---
ga sync   # not to worry, this will sync the recent changes in the ssh remote
ls        # cluster1 is now here
ga whereis cluster1
```

Note that having SSH remotes will slow down your `ga sync` commands, so personally -- even when I have them --
I prefer to temporarily remove them with `git remote remove ...`.

You can find another example at https://git-annex.branchable.com/walkthrough/using_ssh_remotes.





## Check annexed data

```sh
ga fsck     # run checksum on all local files
ga unused   # show all unlinked files in this annex
```





## When a drive fails

If a drive goes bad, you want to make sure its content is mirrored in two other places, i.e. you should
rebuild your redundant storage:

```sh
--- some other annex ---
ga whereis . | grep -A 1 "1 copy" | grep -B 2 <bad annex>    # congratulations, you lost your only copy ...
ga whereis . | grep -A 2 "2 copies" | grep -B 3 <bad annex>  # 1 copy left elsewhere
```

Back up those single copies on a third annex with something like:

```sh
--- third annex ---
ga get <items>   # get a local copy
ga get --auto --numcopies=2 <items>

--- source annex ---
ga copy <items> --to <third annex>
```

Next, you want to mark the failed drive's annex as "dead", so that its content stops showing in `gitannex
whereis`:

```sh
ga dead <bad annex>
```

and remove it from all other repositories:

```sh
git remote remove <bad annex>   # do this in each annex
```









## Print one line per file

Sometimes it is tricky to `grep` the output of `ga whereis`, as it produces a variable number of lines per
file, depending on the number of copies.

`ga whereis` has the flag `--format`, but I find its output somewhat lacking.

### Simpler, less efficient solution

The following commands

```sh
echo $(ga whereis)        | sed 's/whereis/\n/g'
echo $(ga whereis <path>) | sed 's/whereis/\n/g'
```

will print one line per file, so you can organize searches with something like:

```sh
echo $(ga whereis) | sed 's/whereis/\n/g' | grep <annex>
echo $(ga whereis) | sed 's/whereis/\n/g' | grep "1 copy"
echo $(ga whereis) | sed 's/whereis/\n/g' | grep <annex> | grep "1 copy"
```

echo $(ga whereis watch) | sed 's/whereis/\n/g' | grep "1 copy"

### Faster, more elegant solution

Perhaps, a more elegant solution is to use the `--json` flag which could be useful for sending (very complete)
JSON output to other utilities or even Python scripts. One added benefit: it'll properly process and display
Unicode in file names, e.g. if you use Chinese characters or a non-Latin alphabet.

Let's process our output with [jq](https://stedolan.github.io/jq), a command-line JSON processor.

First, let's list files with at least 2 copies:

```sh
ga whereis --copies 2
```

and use one of their names below.

```sh
ga whereis test43816               # multiple lines
ga whereis --json test43816        # one JSON line per file
ga whereis --json test43816 | jq   # show the multi-line JSON object
ga whereis --json test43816 | jq '.file'   # print the file name only

# print file name and the space-delimited list of repositories
ga whereis --json test43816 | jq '.file + " " + (.whereis|map(.description)|join(","))'
```

We can now apply this to any list of items or the entire repository:

```sh
ga whereis --json | jq '.file + " " + (.whereis|map(.description)|join(","))'
```








## Cheat sheet

- `<items>` could be any collection of files and/or directories
- `<annex>` is the name of a git-annex, e.g. earth or mars or venus

```sh
ga init <name>
ga add <items>
ga sync

ga unannex <items>            # replace the link with the actual file content
ga unused                     # show all unlinked files in the annex
ga unused --used-refspec=+master   # same, but ignore these files being checked out in other annexes
ga dropunused --force <num>   # drop the unused file with a given index
ga drop --force <items>       # drop a local copy (object)

ga find                       # list all local files
ga whereis <items>            # locate file(s) or dir(s)
ga whereis | grep -A 1 "1 copy"                          # show all files with only one copy
ga whereis | grep -A 1 "1 copy" | grep -B 2 "\[here\]"   # show local files with only one copy
echo $(ga whereis) | sed 's/whereis/\n/g'                # print one file per line
ga whereis --json | jq '.file + " " + (.whereis|map(.description)|join(","))' # print name + annex
ga info <items>               # show local + global disk usage

ga copy <items> --to here
ga copy <items> --to <annex>
ga move <items> --to here
ga move <items> --to <annex>
ga get --auto --numcopies=2 <items>
```

- [git-annex walkthrough](http://git-annex.branchable.com/walkthrough) is a good introduction to using
  git-annex from the command line.
