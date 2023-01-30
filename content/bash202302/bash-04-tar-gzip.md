+++
title = "Archiving and compressing"
slug = "bash-04-tar-gzip"
weight = 4
+++

In this section we will be working with a ZIP file that you can download and unpack with

```sh
$ wget http://bit.ly/bashfile -O bfiles.zip
$ unzip bfiles.zip
```

(alternative download link https://autumnschool2022.westdri.ca/files/bfiles.zip)

Unlike an SSD or a hard drive on your laptop, the filesystem on HPC cluster was designed to store large files,
ideally with parallel I/O. As a result, it handles any large number of small I/O requests (reads or writes)
very poorly, sometimes bringing the I/O system to a halt. For this reason, we strongly recommend that users do
not store many thousands of small files -- instead you should pack them into a small number of large
archives. This is where the archiving tool `tar` comes in handy.

## Working with `tar` and `gzip/gunzip`

**Covered topics**: `tar` and `g(un)zip`.

Let's download some files in Windows' ZIP format:

```sh
$ wget http://bit.ly/bashfile -O bfiles.zip
$ unzip bfiles.zip
$ rm bfiles.zip
$ ls
$ ls data-shell
```

ZIP is a compression format from Windows, and it is not very popular in the Unix world. Let's archive the
directory `data-shell` using Unix's native `tar` command:

```sh
$ tar cvf bfiles.tar data-shell/
$ gzip bfiles.tar
```

You can also create a gzipped TAR file in one step:

```sh
$ rm bfiles.tar.gz
$ tar cvfz bfiles.tar.gz data-shell/
```

Let's remove the directory and the original ZIP file (if still there), and extract directory from our new
archive:

```sh
$ /bin/rm -r data-shell/ bfiles.zip
$ tar xvfz bfiles.tar.gz
```

<!-- > **Exercise:** Let's create a new subdirectory `~/tmp` with 1000 files inside using `touch a{000..999}` -->
<!-- > and then gzip-archive that subdirectory. -->

<!-- 04-archives.mkv -->
<!-- {{< yt ckD5jOCnyBU 63 >}} -->
You can {{<a "https://youtu.be/ckD5jOCnyBU" "watch a video for this topic">}} after the workshop.





## Managing many files with Disk ARchiver (DAR)

`tar` is by far the most widely used archiving tool on UNIX-like systems. Since it was originally
designed for sequential write/read on magnetic tapes, it does not index data for random access to its
contents. A number of 3rd-party tools can add indexing to `tar`. However, there is a modern version of
`tar` called DAR (stands for Disk ARchiver) that has some nice features:

- each DAR archive includes an index for fast file list/restore,
- DAR supports full / differential / incremental backup,
- DAR has build-in compression on a file-by-file basis to make it more resilient against data corruption
  and to avoid compressing already compressed files such as video,
- DAR supports strong encryption,
- DAR can detect corruption in both headers and saved data and recover with minimal data loss,

and so on. Learning DAR is not part of this course. In the future, if you want to know more about working with
DAR, please watch our <a href="https://westgrid.github.io/trainingMaterials/tools/rdm" target="_blank">DAR
webinar</a> (scroll down to see it), or check our <a href="https://docs.alliancecan.ca/wiki/Dar"
target="_blank">DAR documentation page</a>.
