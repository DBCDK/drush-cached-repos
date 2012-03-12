#!/bin/bash

# Find urls in make file ending which end with .git
find_git_repos() {
  RETURN=$( cat $1 | sed -e "/\.git[\"']* *$/ ! d; s/.*= *[\"']*\([^'\"]*\)[\"']* *$/\1/" )
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

main() {
  local makefiles=$@

  for makefile in $makefiles
  do
    find_git_repos $makefile
    local repos=$RETURN

    for repo in $repos
    do
      translate_git_to_path $repo
      local path=$RETURN
      download_git $repo $path
    done

  done

}

main "$@"
