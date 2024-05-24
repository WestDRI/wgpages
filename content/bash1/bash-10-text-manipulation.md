+++
title = "Text manipulation"
slug = "../bash/bash-10-text-manipulation"
weight = 10
+++

## Text manipulation
<!-- (DH part: the invisible man) -->

(This example was kindly provided by John Simpson.)

In this section we'll use two tools for text manipulation: *sed* and *tr*. Our goal is to calculate the
frequency of all dictionary words in the novel "The Invisible Man" by Herbert Wells (public
domain). First, let's apply our knowledge of grep to this text:

```sh
$ cd /path/to/data-shell
$ ls   # shows wellsInvisibleMan.txt
$ wc wellsInvisibleMan.txt                          # number of lines, words, characters
$ grep invisible wellsInvisibleMan.txt              # see the invisible man
$ grep invisible wellsInvisibleMan.txt | wc -l      # returns 60; adding -w gives the same count
$ grep -i invisible wellsInvisibleMan.txt | wc -l   # returns 176 (includes: invisible Invisible INVISIBLE)
```

Let's sidetrack for a second and see how we can use the "stream editor" `sed`:

```sh
$ sed 's/[iI]nvisible/visible/g' wellsInvisibleMan.txt > visible.txt   # make him visible
$ cat wellsInvisibleMan.txt | sed 's/[iI]nvisible/visible/g' > visible.txt   # this also works (standard input)
$ grep -i invisible visible.txt   # see what was not converted
$ man sed
```

Now let's remove punctuation from the original file using "tr" (translate) command:

```sh
$ cat wellsInvisibleMan.txt | tr -d "[:punct:]" > nopunct.txt    # tr only takes standard input
$ tail wellsInvisibleMan.txt
$ tail nopunct.txt
```

Next, convert all upper case to lower case:

```sh
$ cat nopunct.txt | tr '[:upper:]' '[:lower:]' > lower.txt
$ tail lower.txt
```

Next, replace spaces with new lines:

```sh
$ cat lower.txt | sed 's/ /\'$'\n/g' > words.txt   # \'$'\n is a shortcut for a new line
$ more words.txt
```

Next, remove empty lines:

```sh
$ sed '/^$/d' words.txt  > compact.txt
```

Next, sort the list alphabetically, count each word's occurrence, and remove duplicate words:

```sh
$ cat compact.txt | sort | uniq -c > dictionary.txt
$ more dictionary.txt
```

Next, sort the list into most frequent words:

```sh
$ cat dictionary.txt | sort -gr > frequency.txt   # use 'man sort'
$ more frequency.txt
```

<!-- > **Exercise:** write a script 'countWords.sh' that takes a text file name as an argument, and returns -->
<!-- > the list of its 100 most common words, i.e. the script should be used as `./countWords.sh -->
<!-- > wellsInvisibleMan.txt`. The script should not leave any intermediate files. Or even better, write a -->
<!-- > function 'countWords()' taking a text file name as an argument. -->

<!-- 10-textManipulation.mkv -->
<!-- {{< yt 4IkHY84uUss 63 >}} -->
You can {{<a "https://youtu.be/4IkHY84uUss" "watch a video for this topic">}} after the workshop.

**Quick reference:**
```sh
sed 's/pattern1/pattern2/' filename    # replace pattern1 with pattern2, one per line
sed 's/pattern1/pattern2/g' filename   # same but multiple per line
sed 's|pattern1|pattern2|g' filename   # same

cat wellsInvisibleMan.txt | tr -d "[:punct:]" > nopunct.txt # remove punctuation; tr only takes standard input
cat nopunct.txt | tr '[:upper:]' '[:lower:]' > lower.txt    # convert all upper case to lower case
cat lower.txt | sed 's/ /\'$'\n/g' > words.txt              # replace spaces with new lines
sed '/^$/d' words.txt  > compact.txt                # remove empty lines
cat compact.txt | sort | uniq -c > dictionary.txt   # sort the list alphabetically, count each word's occurrence
cat dictionary.txt | sort -gr > frequency.txt       # sort the list into most frequent words
```



{{< question num=10.1 >}}
Can you shorten our novel-manipulation workflow putting it into a single line using pipes?
{{< /question >}}

<!-- ```sh -->
<!-- cat wellsInvisibleMan.txt | tr -d "[:punct:]" | tr '[:upper:]' '[:lower:]' | \ -->
<!--   sed 's/ /\'$'\n/g' | sed '/^$/d' | sort | uniq -c | sort -gr > frequency.txt -->
<!-- ``` -->



{{< question num=10.2 >}}
Write a script that takes an English-language file and print the list of its 100 most common words, along with
the word count. Hint: use the workflow we just studied. Next, convert this script into a bash function.
{{< /question >}}







## Column-based text processing with `awk` scripting language

```sh
cd /path/to/data-shell/writing
cat haiku.txt   # 11 lines
```

You can define inline awk scripts with braces surrounded by single quotation:

```sh
awk '{print $1}' haiku.txt       # $1 is the first field (word) in each line => processing columns
awk '{print $0}' haiku.txt       # $0 is the whole line
awk '{print}' haiku.txt          # the whole line is the default action
awk -Fa '{print $1}' haiku.txt   # can specify another separator with -F ("a" in this case)
```

You can use multiple commands inside your awk script:

```sh
echo Hello Tom > hello.txt
echo Hello John >> hello.txt
awk '{$2="Adam"; print $0}' hello.txt   # we replaced the second word in each line with "Adam"
```

Most common `awk` usage is to postprocess output of other commands:

```sh
/bin/ps aux    # display all running processes as multi-column output
/bin/ps aux | awk '{print $2 " " $11}'   # print only the process number and the command
```

Awk also takes patterns in addition to scripts:

```sh
awk '/Yesterday|Today/' haiku.txt   # print the lines that contain the words Yesterday or Today
```

And then you act on these patterns: if the pattern evaluates to True, then run the script:

```sh
awk '/Yesterday|Today/{print $3}' haiku.txt
awk '/Yesterday|Today/' haiku.txt | awk '{print $3}'   # same as previous line
```

Awk has a number of built-in variables; the most commonly used is NR:

```sh
awk 'NR>1' haiku.txt    # if NumberRecord >1 then print it (default action), i.e. skip the first line
awk 'NR>1{print $0}' haiku.txt   # last command expanded
awk 'NR>1 && NR < 5' haiku.txt   # print lines 2-4
```

{{< question num=10.3 >}}
Write an awk script to process `cities.csv` to print only town/city names and their
population and store it in a separate file `populations.csv`. Try to do everything in a single-line
command.
{{< /question >}}

{{< question num=10.4 >}}
Write an awk script that prints every 10th line from `cities.csv` starting from line 2. **Hint**: use `NR`
variable.
{{< /question >}}

{{< question num="`copy every 10th file`" >}}
Imagine that the directory `/project/def-sponsor00/shared/toyModel` contains results from a numerical
simulation. Write a command to copy every 10th file (starting from `yB31_oneblock_00000.vti`)
from this directory to one of your own directories. **Hint**:
create an alphabetically sorted list of files in that directory and then use awk's `NR` variable.
{{< /question >}}

<!-- ```sh -->
<!-- find /project/def-sponsor00/shared/toyModel -type f | sort | awk 'NR%10==0' -->
<!-- ``` -->

{{< question num="`archive every 20th file`" >}}
Similarly to the previous exercise, write a command to create a tar archive that includes every 20th file
from the simulation directory `/project/def-sponsor00/shared/toyModel`. Is it possible to do this in one
command? Why does it remove leading '/' from file paths?
{{< /question >}}

<!-- There are many solutions: -->
<!-- ```sh -->
<!-- # the downside of this solution is that it'll include paths (without the leading /) into the arhive -->
<!-- tar cvf toy.tar $(find /project/def-sponsor00/shared/toyModel -type f | sort | awk 'NR%20==0') -->

<!-- cd /project/def-sponsor00/shared/toyModel   # if you are allowed to cd into that directory -->
<!-- tar cvf ~/tmp/toy.tar $(find . -type f | sort | awk 'NR%20==0') -->
<!-- cd - -->

<!-- find /project/def-sponsor00/shared/toyModel -type f | sort | awk 'NR%20==0' > list.txt -->
<!-- tar cfz toy.tar --files-from=list.txt -->
<!-- /bin/rm list.txt -->
<!-- ``` -->

**Quick reference:**
```sh
ls -l | awk 'NR>3 {print $5 "  " $9}'     # print 5th and 9th columns starting with line 4
awk 'NR>1 && NR < 5' haiku.txt            # print lines 2-4
awk 'NR>1 && NR < 5 {print $1}' haiku.txt # print lines 2-4, column 1
awk '/Yesterday|Today/' haiku.txt         # print lines that contain Yesterday or Today
```

{{< question num=10.7 >}}
Write a one-line command that finds 5 largest files in the current directory and prints only their names and file sizes
in the human-readable format (indicating bytes, kB, MB, GB, ...) in the decreasing file-size order. Hint: use `find`,
`xargs`, and `awk`.
{{< /question >}}

{{< question num="`ps`" >}}
Use `ps` command to see how many processes you are running on the training cluster. Explore its flags. Write
commands to reduce `ps` output to a few essential columns.
{{< /question >}}




<!-- 10-awk.mkv -->
<!-- {{< yt BMrL7zoyJH8 63 >}} -->
You can {{<a "https://youtu.be/BMrL7zoyJH8" "watch a video for this topic">}} after the workshop.
