+++
title = "Filesystem"
slug = "bash-02-filesystem"
weight = 2
+++

## Navigating directories

**Covered topics**: `pwd`, `ls`, absolute vs. relative paths, command flags, `cd`, path shortcuts.

- pwd = Print Working Directory
- ls = LiSt everything inside the current/given directory
- cd = Change Directory


Click on a triangle to expand a question:

{{< question num=1 >}}
Relative vs. absolute paths. Using `~` as part of a longer path.
{{< /question >}}

{{< question num=2 >}}
If `pwd` displays `/users/thing`, what will `ls ../backup` display?
{{< figure src="/img/quizDirs.png" >}}
1. `../backup: No such file or directory`
2. `2012-12-01 2013-01-08 2013-01-27`
3. `2012-12-01/ 2013-01-08/ 2013-01-27/`
4. `original pnas_final pnas_sub`
{{< /question >}}

{{< question num=3 >}}
Given the same directory structure, if `pwd` displays `/users/backup`, and `-r` tells `ls` to display things
in reverse order, what command will display:
```
pnas-sub/  pnas-final/  original/
```
1. `ls pwd`
2. `ls -r -F`
3. `ls -r -F /users/backup`
4. Either #2 or #3 above, but not #1
{{< /question >}}

{{< question num=4 >}}
What does the command `cd` do if you do not pass it a directory name?
1. It has no effect
2. It changes the working directory to /
3. It changes the working directory to the user's home directory
4. It produces an error message
{{< /question >}}

{{< question num=5 >}}
Starting from `/Users/amanda/data/`, which of the following commands could Amanda use to navigate to her home directory,
which is `/Users/amanda`? Mark all correct answers.
cd.
1. `cd /`
2. `cd /home/amanda`
3. `cd ../..`
4. `cd ~`
5. `cd home`
6. `cd ~/data/..`
7. `cd`
8. `cd ..`
{{< /question >}}




<!-- {{< yt OjbecASHm2k 63 >}} -->
You can {{<a "https://youtu.be/OjbecASHm2k" "watch a video for this topic">}} after the workshop.






## Getting help

**Covered topics**: `man`, navigating manual pages, `--help` flag.

```sh
$ man ls
$ ls --help
```

{{< question num="`-h`" >}}
Check the manual page for `ls` command: what does the `-h` (`--human-readable`) option do?
{{< /question >}}





<!-- Explain tab completion in bash. -->





<!-- 02-help.mkv -->
<!-- {{< yt EAp3Xze1TZ0 63 >}} -->
You can {{<a "https://youtu.be/EAp3Xze1TZ0" "watch a video for this topic">}} after the workshop.
