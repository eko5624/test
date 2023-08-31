#!/bin/bash

declare -A ver_array

json_file=$(curl -s "https://raw.githubusercontent.com/eko5624/nginx-nosni/master/old.json")
keys_content=$(jq -r '. | keys | .[]' "$json_file")
while read -r key; do
  value=$(jq -r ".[$key]" "$json_file")
  ver_array[$key]=$value
done <<< "$keys_content"

VER_BINUTILS=${ver_array[binutils]}
VER_GCC=${ver_array[GCC]}
echo $VER_BINUTILS $VER_GCC
