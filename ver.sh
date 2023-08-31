#!/bin/bash

json_ver=$(curl -s "https://raw.githubusercontent.com/eko5624/nginx-nosni/master/old.json")
declare -A ver_array
while IFS="=" read -r key value; do
    ver_array[$key]=$value
done < <(echo "$json_ver" | jq -r 'to_entries | map("\(.key)=\(.value|tostring)") | .[]')

VER_BINUTILS=${ver_array[binutils]}
VER_GCC=${ver_array[GCC]}
echo $VER_BINUTILS $VER_GCC
