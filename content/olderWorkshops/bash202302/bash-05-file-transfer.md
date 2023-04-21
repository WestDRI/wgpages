+++
title = "File transfer"
slug = "bash-05-file-transfer"
weight = 5
+++

## Transferring files and folders with `scp`

To copy a single file to/from the cluster, we can use `scp`:

```sh
[local]$ scp /path/to/local/file.txt userXXX@bobthewren.c3.ca:/path/on/remote/computer
[local]$ scp local-file.txt userXXX@bobthewren.c3.ca:   # will put into your remote home
[local]$ scp userXXX@bobthewren.c3.ca:/path/on/remote/computer/file.txt /path/to/local/
```
To recursively copy a directory, we just add the `-r` (recursive) flag:

```sh
[local]$ scp -r some-local-folder/ userXXX@bobthewren.c3.ca:target-directory/
```

You can also use wildcards to transfer multiple files:

```sh
[local]$ scp centos@bobthewren.c3.ca:start*.sh .
```

With MobaXterm in Windows, you can actually copy files by dragging them between your desktop and the left
pane when you are logged into the cluster (no need to type any commands), or you can click the
download/upload buttons.

<!-- 05-scp.mkv -->
<!-- {{< yt 6iqwJWGJ6es 63 >}} -->
You can {{<a "https://youtu.be/6iqwJWGJ6es" "watch a video for this topic">}} after the workshop.







## Transferring files interactively with `sftp`

`scp` is useful, but what if we don't know the exact location of what we want to transfer? Or perhaps
we're simply not sure which files we want to transfer yet. `sftp` is an interactive way of downloading
and uploading files. Let's connect to a cluster with `sftp`:

```sh
[local]$ sftp userXXX@bobthewren.c3.ca
```

This will start what appears to be a shell with the prompt `sftp>`. However, we only have access to a
limited number of commands. We can see which commands are available with `help`:

```sh
sftp> help
Available commands:
bye                                Quit sftp
cd path                            Change remote directory to 'path'
chgrp grp path                     Change group of file 'path' to 'grp'
chmod mode path                    Change permissions of file 'path' to 'mode'
chown own path                     Change owner of file 'path' to 'own'
df [-hi] [path]                    Display statistics for current directory or
                                   filesystem containing 'path'
exit                               Quit sftp
get [-afPpRr] remote [local]       Download file
reget [-fPpRr] remote [local]      Resume download file
reput [-fPpRr] [local] remote      Resume upload file
help                               Display this help text
lcd path                           Change local directory to 'path'
lls [ls-options [path]]            Display local directory listing
lmkdir path                        Create local directory
ln [-s] oldpath newpath            Link remote file (-s for symlink)
lpwd                               Print local working directory
ls [-1afhlnrSt] [path]             Display remote directory listing
...
```

Notice the presence of multiple commands that make mention of local and remote. We are actually browsing
two filesystems at once, with two working directories!

```sh
sftp> pwd    # show our remote working directory
sftp> lpwd   # show our local working directory
sftp> ls     # show the contents of our remote directory
sftp> lls    # show the contents of our local directory
sftp> cd     # change the remote directory
sftp> lcd    # change the local directory
sftp> put localFile    # upload a file
sftp> get remoteFile   # download a file
```

And we can recursively put/get files by just adding `-r`. Note that the directory needs to be present
beforehand:

```sh
sftp> mkdir content
sftp> put -r content/
```

To quit, type `exit` or `bye`. 

> **Exercise:** Using one of the above methods, try transferring files to and from the cluster. For
> example, you can download bfiles.tar.gz to your laptop. Which method do you like best?

**Note on Windows line endings**:
* When you transfer files to from a Windows system to a Unix system (Mac, Linux, BSD, Solaris, etc.) this can
  cause problems. Windows encodes its files slightly different than Unix, and adds an extra character to every
  line. On a Unix system, every line in a file ends with a `\n` (newline), whereas on Windows every line in a
  file ends with a `\r\n` (carriage return + newline). This causes problems sometimes.
* In some *bash* implementations, you can identify if a file with Windows line endings with `cat -A
  filename`. A file with Windows line endings will have `^M$` at the end of every line. A file with Unix line
  endings will have `$` at the end of a line.
* Though most modern programming languages and software handle this correctly, in some rare instances you may
  run into an issue. The solution is to convert a file from Windows to Unix encoding with the `dos2unix
  filename` command. Conversely, to convert back to Windows format, you can run `unix2dos filename`.

**Note on syncing**: there also a command `rsync` for synching two directories. It is super useful,
especially for work in progress. For example, you can use it the download all the latest PNG images from
your working directory on the cluster.

{{< question num="`scp and sftp`" >}}
Copy a file to/from the training cluster using either `scp` or `sftp`.
{{< /question >}}

{{< question num="`rsync`" >}}
Bring up the manual page on `rsync`, then use it to synchronize a directory from the training cluster.
{{< /question >}}
