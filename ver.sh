#!/bin/bash

json_ver=$(curl -s "https://raw.githubusercontent.com/eko5624/nginx-nosni/master/old.json")
declare -A dict
while IFS="=" read -r key value; do
    dict[$key]=$value
done < <(echo "$json_ver" | jq -r 'to_entries | map("\(.key)=\(.value|tostring)") | .[]')

# 示例
echo "${dict[mpv]}"

