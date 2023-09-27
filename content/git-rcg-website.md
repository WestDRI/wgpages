+++
title = "Using Git to contribute to the RCG website"
slug = "git-rcg"
katex = true
+++

# https://wgpages.netlify.app/git-rcg

<!-- {{<cor>}}Friday, November 4, 2022{{</cor>}}\ -->
<!-- {{<cgr>}}1:00pm - 2:30pm{{</cgr>}} -->

<!-- {{< figure src="/img/qr-formats.png" >}} -->

## Links

- RCG website https://www.rcg.sfu.ca
- Main repo https://github.sfu.ca/its/rcg-website
- Marie's excellent [Git course](https://mint.westdri.ca/git/top_intro)
- [Some reading](https://devopscube.com/set-git-upstream-respository-branch) on the GitHub's pull requests
  workflow
<!-- - my fork https://github.sfu.ca/alexeir/rcg-website.git -->

## Local Git primer

Make sure you have Git installed on the computer where you want to work, whether it's your own machine or a
remote system.

1. Set up your local Git variables
```sh
git config --global user.name "<Your Name>"
git config --global user.email "<your@email.ca>"
git config --global core.editor "nano"
git config --global core.autocrlf input   # on macOS, Linux, or WSL
git config --global core.autocrlf true    # on Windows
git config --global alias.st 'status'
git config --global alias.one "log --graph --date-order --date=short --pretty=format:'%C(cyan)%h %C(yellow)%ar %C(auto)%s%+b %C(green)%ae'"
git config --list
```
2. Create a local repository
3. Learn the `git add` + `git commit` workflow
4. Ignoring files
5. Exploring history
6. Branches
```sh
git branch            # list branches
git branch -v         # give a little bit more info on the branches
git branch -vv        # show remote branches as well
git branch test       # create a new branch called "test"
git switch test       # switch to that branch
git checkout test     # same
git switch -c dev     # create a new branch called "dev" and switch to it
git checkout -b dev   # same
>>> make some local commits in the branch
git checkout main && git merge dev && git branch -d dev   # merge dev into main and delete dev
```
7. Create a local conflict with two branches and then resolve it by hand





## Initial setup on https://github.sfu.ca

<!-- - initial setup for https://github.sfu.ca/settings/tokens -->

Set up your access token:

1. In a *private browser window* log in to SFU's GitHub https://github.sfu.ca via SFU authentication
1. Account Settings | Developer settings | Personal access tokens | Generate new token
1. Check "repo", "workflow" boxes
1. Copy the token and save it in your password manager, and use it with your SFU's GitHub username (which is
   the same as the your SFU Computing ID)






## Workflow via PRs (no direct access)

1. Fork the website repository on GitHub
1. Clone your fork to your computer
1. To keep up with the main repository, pull the changes from it through your Git upstream config
1. Edit the code, commit locally
1. Push your changes to a branch in the forked repository -- ideally a separate branch for each PR (but could
   be the main branch)
1. Create a PR to the website repository from your forked repository

Create your own fork of https://github.sfu.ca/its/rcg-website. Let's assume the fork is called
https://github.sfu.ca/username/rcg-website.git. You will have write access to your fork, but not to the main
repository.

Clone your fork to your computer:

```sh
>>> make sure you are not inside any Git repo
git clone https://github.sfu.ca/username/rcg-website.git
cd rcg-website
hugo serve   # assuming you have Hugo installed locally https://gohugo.io/installation
```

Add the website repository as an upstream:

<!-- cd /path/to/rcg-website -->
```sh
git remote -v    # shows only origin = your fork
git remote add upstream https://github.sfu.ca/its/rcg-website
git remote -v    # now shows both origin and upstream
```

When you are ready to edit the website, collect the latest changes and start editing the code. Eventually, you
can create a PR to the RCG website either from your main branch, or from a specially created branch. Let's
consider these two options.

### Working from the main branch

This is not a universally approved practice: it can break things for complex edits, and your fork's main
branch can diverge from the upstream if your PR is not approved right away and in its entirety, e.g. because
of compatibility issues or other conflicts.

```sh
git fetch upstream    # collect the latest changes from the upstream
>>> do some work and create local commits
git push              # upload to origin
```

- Open https://github.sfu.ca/its/rcg-website in your web browser
- Pull requests | New pull request | compare across forks
- Compare &nbsp; `base repository: its/rcg-website` `base:main` &nbsp; to &nbsp; `username/rcg-website` `compare:main`
- Create pull request
- Describe your changes

### Working from a branch (good practice in general)

```sh
git fetch upstream     # collect the latest changes from the upstream
git checkout -b idea   # create a new branch `idea` and switch to it
>>> do some work and create local commits in `idea` branch
git push origin idea
```

- Open https://github.sfu.ca/its/rcg-website in your web browser
- Pull requests | New pull request | compare across forks
- Compare &nbsp; `base repository: its/rcg-website` `base:main` &nbsp; to &nbsp; `username/rcg-website` `compare:idea`
- Create pull request
- Describe your changes

Back on your computer, at some point you want to merge `idea` into `main`. Rather than doing it locally, a
good practice is to wait to your PR to be approved and then pull into your fork:

```sh
git checkout main
git pull upstream main
>>> make sure your suggested edits have been merged
git branch -d idea   # delete your local branch
```

### Working directly on GitHub for small edits

Open https://github.sfu.ca/its/rcg-website in your web browser and start editing a file. Since most likely you
don't have direct write access, GitHub will automatically clone the repo and start a new branch with your
change.

- Propose change | Create a pull request
- Describe your changes
