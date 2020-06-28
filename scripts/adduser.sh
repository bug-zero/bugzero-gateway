#!/usr/bin/env bash


# adduser.sh username password file

if [[ $# -lt 3 ]]; then
    echo "Not enough commands"
    exit 1
fi

echo "$1 : EAP \"$2\"" >> $3
