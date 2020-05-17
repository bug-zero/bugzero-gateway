#!/usr/bin/env bash

echo
echo "=== https://github.com/scorelab/bugzero-gateway ==="
echo

#Exit when error - first argument is the reason of the error
function exit_badly {
  echo $1
  exit 1
}

#Script is intend to run inside a ubuntu 18.04 container
[[ $(lsb_release -rs) == "18.04" ]] || exit_badly "This script is for Ubuntu 18.04 only, aborting..."

#Check root user
[[ $(id -u) -eq 0 ]] || exit_badly "Please re-run as root (e.g. sudo ./path/to/this/script)"

