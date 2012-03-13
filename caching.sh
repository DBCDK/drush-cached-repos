#!/bin/bash

# © 2012 DBC A/S and TING.Community
# Version 1.0.0

# Escaping special characters for grep
escape() {
  echo "$1" | sed 's/\([\.\$\*]\)/\\\1/g'
}

# Is first argument amoung rest of arguments then git repository up to date
not_up_to_date() {
  local item=$1
  shift
  ! echo " $@ " | grep -q " $(escape $item) "
}

# Find urls in make file ending which end with .git
find_git_repos() {
  RETURN=$(cat $1 | sed -e "/\.git[\"']* *$/ ! d; s/.*= *[\"']*\([^'\"]*\)[\"']* *$/\1/")
}

# Find includes in make file
find_includes() {
  RETURN=$(cat $1 | sed -e "/^includes\[/ ! d; s/^includes\[\] *= *[\"']*\(.*\)[\"']* *$/\1/")
}

# Download git repository or fetch changes
download_git() {
  local git=$1
  local destination=$2

  if [ -d $destination ]; then
    pushd $destination > /dev/null
    echo Updating mirror: $destination
    git fetch -q --all
    git update-server-info
    popd > /dev/null
  else
    git clone --mirror $git $destination
    pushd $destination > /dev/null
    git update-server-info
    popd > /dev/null
  fi
}

# Substitute :// with -
# and translate @ with - and : with /
translate_git_to_path() {
  local git=$1
  RETURN=$( echo $git | sed "s/:\/\//-/; y/@:/-\//" )
}

# Extract repository name from url
repo_name() {
  RETURN=$(echo "$1" | sed "s/.*\/\([^\/]*\)\.git$/\1/")
}

# Parse Drush makefile and included makefiles
parse_makefile() {
  local makefile=$1
  shift
  local exclude=$@
  local repos_downloaded
  find_includes $makefile
  local includes=$RETURN

  for inc in $includes
  do
    # remote make file
    if [[ $(expr "$inc" : 'ftps*://') || $(expr "$inc" : 'https*://') ]]; then
      wget -nv $inc
      dirname=$(dirname $inc)
      inc=${inc#$dirname/*}
    fi

    parse_makefile $inc $exclude $repos_downloaded
    repos_downloaded="$repos_downloaded $RETURN"

    if [ $(dirname $inc) == '.' ]; then
      rm -f $inc
    fi
  done

  find_git_repos $makefile
  local repos=$RETURN

  for repo in $repos
  do
    if not_up_to_date $repo $exclude $repos_downloaded ; then
      translate_git_to_path $repo
      local path=$RETURN
      download_git $repo $path
      repos_downloaded="$repos_downloaded $repo"
    fi
  done

  RETURN=$repos_downloaded
}

# Checkout makefile from each branch and process it
process_repo() {
  repo_name $REPO
  name=$RETURN
  translate_git_to_path $REPO
  path=$RETURN

  if [ "$1" == 'bootstrap' ]; then
    download_git $REPO $path
  fi

  BRANCHES=$(git --git-dir=$path branch | sed 's/\*//')

  for branch in $BRANCHES
  do
    git --git-dir=$path --work-tree=. checkout $branch $name.make 2> /dev/null

    if [ -f $name.make ]; then
      parse_makefile $name.make $DOWNLOADED
      DOWNLOADED="$DOWNLOADED $RETURN"
      rm -rf $name.make
    fi
  done

  REPOS_DONE="$REPOS_DONE $REPO"
}

# Bootstrap for repositories specified on command line
bootstrap() {
  for REPO in $REPOS
  do
    process_repo bootstrap
  done
}

# Traverse downloaded repositories for makefiles
recursive_makefiles() {
  for REPO in $DOWNLOADED
  do
    if not_up_to_date $REPO $REPOS_DONE ; then
      process_repo
    fi
  done
}


main() {
  REPOS="$@"
  bootstrap
  recursive_makefiles
}

main "$@"
