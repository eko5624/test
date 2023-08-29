#!/bin/bash

curl -o https://github.com/eko5624/nginx-nosni/raw/master/old.json
# 定义关联数组
declare -A data

# 将 JSON 内容解析为关联数组
eval $(echo data=$(cat old.json | jq -r 'to_entries | map("\(.key)=\(.value|tostring)") | join(" ")'))

# 打印关联数组
for key in "${!data[@]}"; do
  echo "$key: ${data[$key]}"
done
