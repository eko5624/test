json_ver=$(curl -s "https://raw.githubusercontent.com/eko5624/nginx-nosni/master/old.json")
declare -A ver_array
while IFS="=" read -r key value; do
  ver_array[$key]=$value
done < <(echo "$json_ver" | jq -r 'to_entries | map("\(.key)=\(.value|tostring)") | .[]')
for key in "${!ver_array[@]}"; do
  echo "$key => ${ver_array[$key]}"
done
