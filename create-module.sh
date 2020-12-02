#!/bin/bash
set -e
TOP=$(cd $(dirname $0);pwd)

FILE=$(basename $1)
_PATH=$(dirname $1)

if [ -z $FILE ]; then
        echo "Usage: create-module.sh path/to/module"
        exit 1
fi

cp "$TOP/template.v" "$_PATH/$FILE.v"

sed -i "s/DATE/$(date)/g" "$_PATH/$FILE.v"
sed -i "s/MODULE/$FILE/g" "$_PATH/$FILE.v"
