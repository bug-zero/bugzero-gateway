#!/usr/bin/env bash

# updateuser.sh [username to replace] [replace line] [filename]

if [[ $# -lt 3 ]]; then
    echo "Not enough commands"
    exit 1
fi

sed -i "/$1/c\\$2" $3
