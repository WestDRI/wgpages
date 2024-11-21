+++
title = "Distributed file storage with git-annex"
slug = "git-annex"
katex = true
+++

{{<cor>}}November 26<sup>th</sup>, 2024{{</cor>}}\
{{<cgr>}}10:00am–11:00am Pacific Time{{</cgr>}}

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

## Running git-annex

<!-- If you have an NVIDIA GPU on your computer and run *Linux*, and have all the right GPU drivers and CUDA -->
<!-- installed, it should be fairly straightforward to compile Chapel with GPU support. Here is [what worked for me -->
<!-- in AlmaLinux 9.4](https://gist.github.com/razoumov/03cfc54cc388675389bb4343beb8a6b1). Please let me know if -->
<!-- these steps do not work for you. -->

<!-- In *Windows*, Chapel with GPU support works under the Windows Subsystem for Linux (WSL) as explained in [this -->
<!-- post](https://chapel-lang.org/blog/posts/nvidia-gpu-wsl). You *could* also run Chapel inside a [Docker -->
<!-- container](https://chapel-lang.org/install-docker.html), although you need to find a GPU-enabled Docker image. -->

## Git shortcoming for large files

## History

## Warning

Sometimes Git development gets ahead of git-annex, and things might behave weirdly. In such cases you might
want to check if a new version of git-annex is available.

## Links

- [git-annex walkthrough](http://git-annex.branchable.com/walkthrough)

### Adding binary files

1. `shuf -i 0-9 -n 5` produces 5 random digits 0-9
1. `shuf -i 0-9 -n 5 | tr -d '\n'` puts 5 random digits into a singe line
1. $RANDOM returns a pseudorandom integer in the range 0..32767

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
mkdir -p {earth,mars,venus}/annex
tree
cd earth/annex

alias ga='git-annex'

git init
ga init "earth"
# echo "* annex.numcopies=1" >> .gitattributes
populate 10

ga add .   # (1) move files to .git/annex/objects
           # (2) create symbolic links pointing to the new location
		   # (3) add these links to the index (git commit area)
git commit -m "add 10 new files"
```

It is very important to use `ga add` and not `git add` when adding files to annex, so you need to rewire your
git finger memory.

```sh
git status   # everything is clean
ga status    # everything is clean

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
ga add test50427

git status   # new file to be comitted
ga status    # added the new file

ls -l test50427
object=$(ls -l test50427 | awk '{print $11}')   # store last line
ls -l $object
```

How do we undo this `ga add` operation? We must do it in two steps.

1. put the file content back to replace the link:

```sh
ga unannex test50427
ls -l test50427   # the file is back
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
under git-annex control? Follow the same two steps and update the repository:

```sh
ga unannex test80145      # unannex one file currently under git-annex control
ga dropunused --force 1   # drop the first unused file
git commit -m "moved test80145 out of the annex"
```

Now if we do either `git status` or `ga status`, they will report that now we have a new, untracked file.

If you want to remove multiple files, e.g. an entire subdirectory `subdir`, you would do something like this:

```sh
ga unannex <subdir>
ga unused   # show all unlinked files
for i in {1..100}; do   # adjust the numbers based on the previous command's output
	ga dropunused --force $i
done
```

### Remove file completely from the drive

If you don't want to keep the file, one possible solution is:

1. replace the link with the file content: `ga unannex <filename>`
1. drop the unused object file with a combination of `ga unused` and `ga dropunused --force <number>`
1. update the repository: `git commit -m "moved <filename> out of the annex"`
1. delete the file `rm <filename>`

Another solution that we will see later is:

```sh
ga drop --force <filename>   # drop a local copy (object)
unlink  <filename>           # remove the link
ga sync                      # does git commit in the background
```

### Getting help

- `ga --help' will list all available commands
- `ga <command> --help` will give quick info about the command flags
- online help pages for individual commands https://git-annex.branchable.com/git-annex-<command>

### Remote via a clone

Let's go to another drive and clone our existing repository there:

```sh
cd ~/tmp/venus
git clone ~/tmp/earth/annex
cd annex

ls         # there are symbolic links to non-existent destinations
du -s .    # currently no objects (data files)
git log    # see the history from earth

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
  - for this part to work, the remote needs to be online
  - but the local drive does not need be online when you next do `ga sync` in the remote; in fact, `ga sync`
    can run while offline, assuming that some remotes have sync'ed to it first

Let's test this last part:

```sh
--- venus annex ---
dd if=/dev/urandom of=venus1 bs=1024 count=$(( RANDOM + 1024 ));
ga add venus1
git commit -m "add venus1"
ga sync
cd ../..
mv venus hidden    # hide it from earth

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

Let's add our original repo as a remote for this repo:

```sh
git remote add earth ~/tmp/earth/annex
ga sync   # now fails, as you have two separate histories
ga sync --allow-unrelated-histories   # should work if no file conflicts
```

If there is a conflict, you may want to either (1) create a new repository via `git clone` like in the
previous section, and then add new files by hand, or (2) try to rename the conflicting file.

### Branches

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

### Create multiple copies

This is easily one of my favourite git-annex features!

```sh
--- earth annex ---
populate 2
ga add test03985 test69314
git commit -m "add 2 files"

ga whereis test03985 test69314
ga whereis | grep -A 1 "1 copy"   # show all files with only one copy
ga whereis . | grep -A 1 "1 copy" | grep -B 2 here   # show local files with only one copy

ga sync

--- mars annex ---

ga sync
ga whereis test03985 test69314   # 1 copy
ga get --auto --numcopies=2 test03985 test69314
ga whereis test03985 test69314   # 2 copies
ga sync
```

The command `ga get --auto --numcopies=2` can work with any list of files and/or directories.

### Move files manually between remotes

```sh
ga whereis   # pick a file elsewhere
ga move <filename> --to here
```

```sh
ga find   # list all local files => pick a file
ga whereis test52930   # check its copies
ga move test52930 --to venus   # venus has to be online for this to work
```

### Drop a local copy

```sh
ga find   # list all local files => pick a file
ga drop test97806   # delete the object; keep the link
```

```sh
ga drop --auto --numcopies=1 <path>   # drop all local copies if there is a remote copy
ga drop --auto --numcopies=2 <path>   # drop all local copies if there are 2 remote copies
```

### Show disk usage across all remotes

```sh
ga info <path>   # show local+global disk usage in a directory
```

## Workflows

## SSH remotes

If you want to talk to a remote via ssh, its host server will need to have git and git-annex installed and
available via command line when you ssh to that server. However, the Alliance clusters provide git-annex as a
module. In this case you can add `module load git-annex` to your ~/.bashrc file:

```sh
user01@vis.vastcloud.org
echo module load git-annex >> .bashrc
echo alias ga=git-annex >> .bashrc
source .bashrc
git config --global init.defaultBranch main
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
ga init "vis"
git commit --allow-empty -m "first commit"   # otherwise local "ga sync" will fail to merge

--- earth annex ---
git remote remove vis
git remote add vis user01@vis.vastcloud.org:annex
ga sync --allow-unrelated-histories

--- vis annex ---
ga sync
ls   # all files from earth should be there
```

With the two repositories linked, any new change on earth can be sync'ed with the ssh remote:

```sh
--- earth annex ---
dd if=/dev/urandom of=earth3 bs=1024 count=$(( RANDOM + 1024 ));
ga add earth3
ga unannex earth1
ga sync

--- vis annex ---
ga sync
ls   # recent updates from earth should be here
ga whereis earth3   # only one copy on earth
ga whereis earth1   # no copies under git-annex control
```

How about going the other way, i.e. syncing a change from the ssh remote?

```sh
--- vis annex ---
dd if=/dev/urandom of=vis1 bs=1024 count=$(( RANDOM + 1024 ));
ga add vis1
ga sync   # cannot update the repos on my computer: they are behind the firewall;
          # plus we have not even set up the remotes!

--- earth annex ---
ga sync   # not to worry, this will sync the recent changes in the ssh remote
ls        # vis1 is now here
```

You can find another example at https://git-annex.branchable.com/walkthrough/using_ssh_remotes.











<!-- ### Daily work -->

<!-- ```sh -->
<!-- cd /Volumes/evo/annex -->

<!-- ga sync                                         # synchronize with remotes -->

<!-- copy some files here -->
<!-- ga add . -->
<!-- gitcommit -a -->
<!-- ``` -->

<!-- ```sh -->

<!-- ga whereis path/to/file -->
<!-- ga move path/to/file --to=here -->

<!-- ga whereis | grep -B 2 "\-\- laptop"   # show local files -->
<!-- ga whereis soloCamping/ | grep -B 2 "\-\- laptop"   # show local files in a directory -->
<!-- ga find movies/sf/   # show local files in a directory -->
<!-- ga find   # show all local files (might be a long list) -->


<!-- gitannex drop osakaElegy.mp4 -->

<!-- cd /Volumes/t7red/annex/movies/sf -->
<!-- ga add caprica1 theExpansegrep -B 2 "\-\- laptop" -->
<!-- git commit -m "added movies/sf on t7red" -->
<!-- ga sync -->
<!-- ``` -->

<!-- ### Creating 2nd copies -->

<!-- rosso: recordings -->
<!-- t7red: recordings -->

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














<!-- gitannex whereis | grep "1 copy" -->
<!-- gitannex whereis | grep -B 2 "\-\- here" -->

<!-- mv ../secretWorldOfArrietty.m4v . -->
<!-- gitannex add secretWorldOfArrietty.m4v     # could also do "gitannex add ." -->
<!-- gitannex sync -->

<!-- gitannex move theFinalCut.m4v iWish.m4v producers.mp4 --to boa -->
<!-- gitannex copy osakaElegy.mp4 --to boa -->

<!-- gitannex fsck     # run checksum on all local files -->

<!-- gitannex get newMovies/redCherry.m4v   # get a local copy of a file -->

<!-- gitannex dead patriotxt       # mark failed drive (so its content will stop showing in "gitannex whereis") -->
<!-- git remote remove patriotxt   # remove remote repository (do this in each repository) -->
<!-- >>> either add a new drive, create a new repository on it, and copy "single copy" files to it, -->
<!-- >>> or alternatively redistribute files in two copies among existing drives -->




## Cheat sheet

<items> could be any collection of files and/or directories
<annex> is the name of local git-annex, e.g. earth or mars or venus

ga unannex <path>
ga unused
ga dropunused --force <num>   # drop the unused file with a given index
ga drop --force <items>       # drop a local copy (object)
ga find   # list all local files
ga whereis <path>   # locate file(s) or dir(s)
ga whereis | grep -A 1 "1 copy"   # show all files with only one copy
ga whereis . | grep -A 1 "1 copy" | grep -B 2 here   # show local files with only one copy
ga copy <items> --to here
ga copy <items> --to <annex>
ga move <items> --to here
ga move <items> --to <annex>
ga get --auto --numcopies=2 <items>
