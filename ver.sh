#!/bin/bash

curl -OL https://github.com/eko5624/nginx-nosni/raw/master/old.json

declare -A dict
while IFS="=" read -r key value; do
    dict[$key]=$value
done < <(jq -r 'to_entries | map("\(.key)=\(.value|tostring)") | .[]' old.json)

# 示例
echo "${dict[mpv]}"

