#!/bin/bash

REPOS=git@github.com:DBCDK/artesis.git

CACHING_REPOS_DIR=$(dirname $0)
source $CACHING_REPOS_DIR/caching.sh

REPOS_DONE=

for REPO in $REPOS
do
  repo_name $REPO
  name=$RETURN
  translate_git_to_path $REPO
  path=$RETURN
  
  download_git $REPO $path
  BRANCHES=$(git --git-dir=$path --work-tree=test branch)

  for branch in $BRANCHES
  do
    git --git-dir=$path --work-tree=test checkout $branch $name.make

    if [ -f $name.make ]; then
      parse_makefile $name.make
      REPOS_DONE=$REPOS_DONE $RETURN
      rm -rf $name.make
    fi
  done

done

