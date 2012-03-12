#!/bin/bash

REPOS=git@github.com:DBCDK/artesis.git

CACHING_REPOS_DIR=$(dirname $0)
source $CACHING_REPOS_DIR/caching.sh

for REPO in $REPOS
do
  repo_name $REPO
  name=$RETURN
  translate_git_to_path $REPO
  path=$RETURN

  download_git $REPO $path
  BRANCHES=$(git --git-dir=$path branch | sed 's/\*//')

  for branch in $BRANCHES
  do
    git --git-dir=$path --work-tree=. checkout $branch $name.make

    if [ -f $name.make ]; then
      parse_makefile $name.make $DOWNLOADED
      DOWNLOADED="$DOWNLOADED $RETURN"
      rm -rf $name.make
    fi
  done

  REPOS_DONE="$REPOS_DONE $REPO"
done

# @todo do for the downloaded repos also
# echo Repos: $REPOS_DONE
