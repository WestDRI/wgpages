+++
title = "Text manipulation"
slug = "bash-10-text-manipulation"
weight = 10
+++

## Text manipulation
<!-- (DH part: the invisible man) -->

(This example was kindly provided by John Simpson.)

In this section we'll use two tools for text manipulation: *sed* and *tr*. Our goal is to calculate the
frequency of all dictionary words in the novel "The Invisible Man" by Herbert Wells (public
domain). First, let's apply our knowledge of grep to this text:

```sh
$ cd ~/Desktop/data-shell
$ ls   # shows wellsInvisibleMan.txt
$ wc wellsInvisibleMan.txt                          # number of lines, words, characters
$ grep invisible wellsInvisibleMan.txt              # see the invisible man
$ grep invisible wellsInvisibleMan.txt | wc -l      # returns 60; adding -w gives the same count
$ grep -i invisible wellsInvisibleMan.txt | wc -l   # returns 176 (includes: invisible Invisible INVISIBLE)
```

Let's sidetrack for a second and see how we can use the "stream editor" `sed`:

```sh
$ sed 's/[iI]nvisible/supervisible/g' wellsInvisibleMan.txt > visibleMan.txt   # make him visible
$ cat wellsInvisibleMan.txt | sed 's/[iI]nvisible/supervisible/g' > visibleMan.txt   # this also works (standard input)
$ grep supervisible visibleMan.txt   # see what happened to the now visible man
$ grep -i invisible visibleMan.txt   # see what was not converted
$ man sed
```

Now let's remove punctuation from the original file using "tr" (translate) command:

```sh
$ cat wellsInvisibleMan.txt | tr -d "[:punct:]" > invisibleNoPunct.txt    # tr only takes standard input
$ tail wellsInvisibleMan.txt
$ tail invisibleNoPunct.txt
```

Next convert all upper case to lower case:

```sh
$ cat invisibleNoPunct.txt | tr '[:upper:]' '[:lower:]' > invisibleClean.txt
$ tail invisibleClean.txt
```

Next replace spaces with new lines:

```sh
$ cat invisibleClean.txt | sed 's/ /\'$'\n/g' > invisibleList.txt   # \'$'\n is a shortcut for a new line
$ more invisibleList.txt
```

Next remove empty lines:

```sh
$ sed '/^$/d' invisibleList.txt  > invisibleCompact.txt
```

Next sort the list alphabetically, count each word's occurrence, and remove duplicate words:

```sh
$ cat invisibleCompact.txt | sort | uniq -c > invisibleWords.txt
$ more invisibleWords.txt
```

Next sort the list into most frequent words:

```sh
$ cat invisibleWords.txt | sort -gr > invisibleFrequencyList.txt   # use 'man sort'
$ more invisibleFrequencyList.txt
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

cat wellsInvisibleMan.txt | tr -d "[:punct:]" > invisibleNoPunct.txt       # remove punctuation; tr only takes standard input
cat invisibleNoPunct.txt | tr '[:upper:]' '[:lower:]' > invisibleClean.txt # convert all upper case to lower case:
cat invisibleClean.txt | sed 's/ /\'$'\n/g' > invisibleList.txt            # replace spaces with new lines;
                                                                           # \'$'\n is a shortcut for a new line
sed '/^$/d' invisibleList.txt  > invisibleCompact.txt   # remove empty lines
cat invisibleCompact.txt | sort | uniq -c > invisibleWords.txt   # sort the list alphabetically, count each word's occurrence
cat invisibleWords.txt | sort -gr > invisibleFrequencyList.txt   # sort the list into most frequent words
```

{{< question num=39a >}}
Write a script that takes an English-language file and print the list of its 100 most common words, along with the word
count. Hint: use the workflow from the text manipulation video. Finally, convert this script into a bash function. (no
need to type any answer)
{{< /question >}}







## Column-based text processing with `awk` scripting language

```sh
cd .../data-shell/writing
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

> **Exercise:** write a awk script to process `cities.csv` to print only town/city names and their
> population and store it in a separate file `populations.csv`. Try to do everything in a single-line
> command.

**Quick reference:**
```sh
ls -l | awk 'NR>3 {print $5 "  " $9}'   # print 5th and 9th columns starting with line 4
awk 'NR>1 && NR < 5' haiku.txt          # print lines 2-4
awk '/Yesterday|Today/' haiku.txt       # print lines that contain Yesterday or Today
```

{{< question num=41a >}}
Write a one-line command that finds 5 largest files in the current directory and prints only their names and file sizes
in the human-readable format (indicating bytes, kB, MB, GB, ...) in the decreasing file-size order. Hint: use `find`,
`xargs`, and `awk`.
{{< /question >}}

{{< question num=42 >}}
Let's study together these commands:
```sh
$ source ~/projects/def-sponsor00/shared/fzf/.fzf.bash
$ kill -9 `/bin/ps aux | fzf | awk '{print $2}'`
```
{{< /question >}}




<!-- 10-awk.mkv -->
<!-- {{< yt BMrL7zoyJH8 63 >}} -->
You can {{<a "https://youtu.be/BMrL7zoyJH8" "watch a video for this topic">}} after the workshop.
