#!/bin/bash

# escaping special characters for grep
escape() {
  echo "$1" | sed 's/\([\.\$\*]\)/\\\1/g'
}

# is first argument in rest of arguments
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
    echo Fetching into bare repository $destination
    git fetch
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

repo_name() {
  RETURN=$(echo "$1" | sed "s/.*\/\([^\/]*\)\.git$/\1/")
}

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
      wget $inc
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

main() {
  local makefiles=$@

  for makefile in $makefiles
  do
    parse_makefile $makefile
  done
}

main "$@"
