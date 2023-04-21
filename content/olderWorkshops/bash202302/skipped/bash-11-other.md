+++
title = "Other topics"
slug = "bash-11-other"
weight = 11
+++

This page covers tools that we do not normally teach in our Linux command line introduction but we would
like to mention as we find them useful.

# Fuzzy finder

Fuzzy finder `fzf` is a third-party tool, not installed by default. With basic usage, it does interactive
processing of standard input. At a more advanced level (not covered in the video below), it provides key
bindings and fuzzy completion.

**Update (2020-June-25)**: On *cassiopeia.c3.ca* `fzf` path changed; now you can load it with:

```
source ~user120/shared/fzf/.fzf.bash
```

<!-- ```sh -->
<!-- $ source /project/shared/fzf/.fzf.bash     # each user in each shell or put it into your ~/.bashrc -->
<!-- $ fzf -->
<!-- $ nano $(fzf --height 40%) -->
<!-- $ kill -9 `/bin/ps aux | fzf | awk '{print $2}'` -->
<!-- $ e `find ~/Documents/ -type f | fzf` -->
<!-- ``` -->

<!-- 11-fzf.mkv -->
{{< yt Mq6Vs9v_VAI 63 >}}

<!-- # Other advanced bash topics -->

<!-- If there is interest, we could explore some other topics: -->

<!-- <\!-- - arithmetics -\-> -->
<!-- - permissions -->
<!-- - how to control processes -->
<!-- - Homebrew if enough Macs -->
<!-- <\!-- - GNU Parallel -\-> -->
