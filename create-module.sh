#!/bin/sh
TOP=$(cd $(dirname $0);pwd)

FILE=$1
if [ -z $FILE ]; then
        echo "Usage: create-module.sh module"
        exit 1
fi

cp "$TOP/template.v" "$FILE.v"

sed -i "s/DATE/$(date)/g" "$FILE.v"
sed -i "s/MODULE/$FILE/g" "$FILE.v"
