#!/bin/bash
#
# bash-map
# Version: 1.0.0
# Author: Luke Davis (https://github.com/dir)
# License: MIT License

set -uo pipefail

VERSION="1.0.0"
NAME="$(basename "${BASH_SOURCE[0]}")"

map::usage() {
    cat <<EOF
$NAME $VERSION

Usage:
  source map

Functions:
  map::make <map_name> "<key1>=<value1>
                        [key2]=<value2>"   Create a new map
  map::get <map_name> <key>                Get value for a key
  map::set <map_name> <key> <value>        Set or update a key-value pair
  map::delete <map_name> <key>             Delete a key-value pair
  map::print <map_name>                    Print all key-value pairs
  map::clear <map_name>                    Clear all key-value pairs
  map::exists <map_name>                   Check if a map exists
  map::size <map_name>                     Get the number of key-value pairs
  map::values <map_name>                   Get all values
  map::keys <map_name>                     Get all keys
  map::has <map_name> <key>                Check if a key exists

Examples:
  map::make my_map "[name]=John Doe
                    [age]=30
                    [city]=New York"
  map::get my_map name
  map::set my_map job "Software Engineer"
  map::print my_map
  map::delete my_map age
  map::has my_map city

For detailed information on each function, see the individual function comments.
EOF
    exit 0
}

###########################################
# Public API functions
###########################################
map::make() {
    local name="$1"
    local input="$2"
    local data=""
    local key value pair

    while IFS='=' read -r key value || [ -n "$key" ]; do
        [ -z "$key" ] && continue
        value=${value%$'\n'}
        pair=$(map::_process_pair "$key" "$value")
        data+="${pair}${_MAP_DELIMITER}"
    done <<<"$input"

    map::_deserialize "$name" "${data%"$_MAP_DELIMITER"}"
}

map::get() {
    local name="$1"
    local key="$2"
    local data
    data=$(map::_serialize "$name")
    key=$(map::_escape "$key")

    local value
    value=$(echo -n "$data" | tr "$_MAP_DELIMITER" '\n' | grep "^${key}${_MAP_KV_SEPARATOR}" | cut -d "$_MAP_KV_SEPARATOR" -f2-)

    if [ -n "$value" ]; then
        map::_unescape "$value"
    else
        echo "Error: Key not found" >&2
        return 1
    fi
}

map::set() {
    local name="$1"
    local key="$2"
    local new_value="$3"
    local data
    data=$(map::_serialize "$name")
    pair=$(map::_process_pair "$key" "$new_value")

    local new_data
    new_data=$(echo -n "$data" | tr "$_MAP_DELIMITER" '\n' | grep -v "^$(map::_escape "$key")${_MAP_KV_SEPARATOR}" | tr '\n' "$_MAP_DELIMITER")
    new_data="${new_data}${pair}${_MAP_DELIMITER}"

    map::_deserialize "$name" "${new_data%"$_MAP_DELIMITER"}"
}

map::print() {
    local name="$1"
    local data
    data=$(map::_serialize "$name")

    if [ -z "$data" ]; then
        echo "(empty)"
    else
        echo -n "$data" |
            awk -v RS="$_MAP_DELIMITER" -v FS="$_MAP_KV_SEPARATOR" '
        NF {
            gsub(/\\/, "\\\\", $1)
            gsub(/\\/, "\\\\", $2)
            gsub(/\x1E/, ":", $1)
            gsub(/\x1E/, ":", $2)
            gsub(/\x1F/, ",", $1)
            gsub(/\x1F/, ",", $2)
            print $1 ": " $2
        }'
    fi
}

map::delete() {
    local name="$1"
    local key="$2"
    local data
    data=$(map::_serialize "$name")
    key=$(map::_escape "$key")

    local new_data
    new_data=$(echo -n "$data" | tr "$_MAP_DELIMITER" '\n' | grep -v "^${key}${_MAP_KV_SEPARATOR}" | tr '\n' "$_MAP_DELIMITER")

    map::_deserialize "$name" "${new_data%"$_MAP_DELIMITER"}"
}

map::clear() {
    map::_deserialize "$1" ""
}

map::exists() {
    [ -n "$(map::_serialize "$1")" ] && echo "true" || echo "false"
}

map::size() {
    local data
    data=$(map::_serialize "$1")
    if [ -z "$data" ]; then
        echo 0
    else
        echo -n "$data" | tr -cd "$_MAP_DELIMITER" | wc -c | tr -d ' '
    fi
}

map::values() {
    local name="$1"
    local data
    data=$(map::_serialize "$name")
    local first=true
    echo -n "$data" | tr "$_MAP_DELIMITER" '\n' | cut -d "$_MAP_KV_SEPARATOR" -f2- | while IFS= read -r value; do
        if [ "$first" = true ]; then
            first=false
        else
            echo # This adds a newline before each value except the first
        fi
        map::_unescape "$value"
    done
}

map::keys() {
    local name="$1"
    local data
    data=$(map::_serialize "$name")
    local first=true
    echo -n "$data" | tr "$_MAP_DELIMITER" '\n' | cut -d "$_MAP_KV_SEPARATOR" -f1 | while IFS= read -r key; do
        if [ "$first" = true ]; then
            first=false
        else
            echo # This adds a newline before each key except the first
        fi
        map::_unescape "$key"
    done
}

map::has() {
    local name="$1"
    local key="$2"
    local data
    data=$(map::_serialize "$name")

    [[ -z $data ]] && {
        echo "false"
        return 1
    }

    key=$(map::_escape "$key")
    echo -n "$data" | tr "$_MAP_DELIMITER" '\n' | grep -q "^${key}${_MAP_KV_SEPARATOR}" && echo "true" || echo "false"
}

###########################################
# Internal functions - Do not use directly
###########################################
_MAP_DELIMITER=$'\x1F'    # Unit Separator
_MAP_KV_SEPARATOR=$'\x1E' # Record Separator

map::_serialize() {
    local name="$1"
    eval echo -n \$"${name}_map_data"
}

map::_deserialize() {
    local name="$1"
    local data="$2"
    eval "${name}_map_data='$data'"
}

map::_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//$_MAP_DELIMITER/\\$_MAP_DELIMITER}"
    str="${str//$_MAP_KV_SEPARATOR/\\$_MAP_KV_SEPARATOR}"
    echo -n "$str"
}

map::_unescape() {
    local str="$1"
    str="${str//\\$_MAP_KV_SEPARATOR/$_MAP_KV_SEPARATOR}"
    str="${str//\\$_MAP_DELIMITER/$_MAP_DELIMITER}"
    str="${str//\\\\/\\}"
    echo -n "$str"
}

map::_trim() {
    local var="$1"
    var="${var#"${var%%[! ]*}"}"
    var="${var%"${var##*[! ]}"}"
    echo -n "$var"
}

map::_process_pair() {
    local key="$1"
    local value="$2"
    key=$(map::_trim "$key")
    value=$(map::_trim "$value")
    key=${key#[}
    key=${key%]}
    key=$(map::_escape "$key")
    value=$(map::_escape "$value")
    echo -n "${key}${_MAP_KV_SEPARATOR}${value}"
}

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f map::make map::get map::set map::print map::delete map::clear \
        map::exists map::size map::values map::keys map::has map::usage
else
    map::usage
fi
