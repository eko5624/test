#!/bin/bash

# 定义关联数组
declare -A assoc_array

# 读取JSON字典内容
json_data='{"key1": "value1", "key2": "value2", "key3": "value3"}'

# 使用jq工具解析JSON数据
parsed_json=$(echo "$json_data" | jq -r 'to_entries | map("\(.key)=\(.value)") | join(",")')

# 将解析后的JSON数据存储到关联数组中
eval "assoc_array=($parsed_json)"

# 打印关联数组的内容
echo "关联数组的内容："
for key in "${!assoc_array[@]}"; do
    echo "$key => ${assoc_array[$key]}"
done
