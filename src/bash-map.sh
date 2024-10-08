#!/bin/bash
# @name bash-map
# @brief Lightweight associative arrays for Bash
# @author Luke Davis (http://github.com/dir)
# @license MIT

set -uo pipefail

VERSION="1.0.0"
NAME="$(basename "${BASH_SOURCE[0]}")"

# @description Create a new map with the given name and key-value pairs.
#
# @example
#    map::make my_map "[name]=John Doe
#                      [age]=30
#                      [city]=New York"
#
# @arg $1 string The name of the map to create
# @arg $2 string A multi-line string of key-value pairs
#
# @exitcode 0 If successful.
# @exitcode 1 If an error occurs during map creation.
#
# @see map::get()
# @see map::set()
map::make() {
    local name="$1"
    local input="$2"
    local data=""
    local key value pair

    if [[ "$name" == -* ]]; then
        echo "Map name cannot start with a dash: $name" >&2
        return 1
    fi

    while IFS='=' read -r key value || [ -n "$key" ]; do
        [ -z "$key" ] && continue
        value=${value%$'\n'}
        pair=$(map::_process_pair "$key" "$value")
        data+="${pair}${_MAP_DELIMITER}"
    done <<<"$input"

    map::_deserialize "$name" "${data%"$_MAP_DELIMITER"}"
}

# @description Retrieve the value associated with a key in the specified map.
#
# @example
#    map::get my_map name
#
# @arg $1 string The name of the map
# @arg $2 string The key to retrieve
#
# @stdout The value associated with the key if found.
# @stderr Error message if the key is not found.
#
# @exitcode 0 If the key is found.
# @exitcode 1 If the key is not found.
#
# @see map::set()
# @see map::has()
map::get() {
    local map key
    map=$(map::_arg "$1") || return 1
    key=$(map::_escape "$2")

    local value
    value=$(echo -n "$map" | tr "$_MAP_DELIMITER" '\n' | grep "^${key}${_MAP_KV_SEPARATOR}" | cut -d "$_MAP_KV_SEPARATOR" -f2-)

    if [ -n "$value" ]; then
        map::_unescape "$value"
        return 0
    else
        echo "Key \"$key\" not found in $1" >&2
        return 1
    fi
}

# @description Set or update a key-value pair in the specified map.
#
# @example
#    map::set my_map job "Software Engineer"
#
# @arg $1 string The name of the map
# @arg $2 string The key to set or update
# @arg $3 string The value to associate with the key
#
# @exitcode 0 If successful.
#
# @see map::get()
# @see map::delete()
map::set() {
    local map
    map=$(map::_arg "$1") || return 1

    local data pair
    data=$(map::_serialize "$1")
    pair=$(map::_process_pair "$2" "$3")

    local new_data
    new_data=$(echo -n "$data" | tr "$_MAP_DELIMITER" '\n' | grep -v "^$(map::_escape "$2")${_MAP_KV_SEPARATOR}" | tr '\n' "$_MAP_DELIMITER")
    new_data="${new_data}${pair}${_MAP_DELIMITER}"

    map::_deserialize "$1" "${new_data%"$_MAP_DELIMITER"}"
}

# @description Print all key-value pairs in the specified map.
#
# @example
#    map::print my_map
#
# @arg $1 string The name of the map
#
# @stdout All key-value pairs in the map, one per line.
#         Outputs "(empty)" if the map is empty.
#
# @exitcode 0 If successful.
#
# @see map::make()
# @see map::get()
map::print() {
    local map
    map=$(map::_arg "$1") || return 1

    if [ -z "$map" ]; then
        echo "(empty)"
    else
        echo -n "$map" |
            awk -v RS="$_MAP_DELIMITER" -v FS="$_MAP_KV_SEPARATOR" -v OFS=": " '
            function unescape(str) {
                gsub(/\\/, "\\\\", str)
                gsub(/\x1E/, ":", str)
                gsub(/\x1F/, ",", str)
                return str
            }
            {
                if (NF == 2) {
                    print unescape($1), unescape($2)
                }
            }
        '
    fi
}

# @description Delete a key-value pair from the specified map.
#
# @example
#    map::delete my_map age
#
# @arg $1 string The name of the map
# @arg $2 string The key to delete
#
# @exitcode 0 If successful.
#
# @see map::set
# @see map::clear
map::delete() {
    local map key
    map=$(map::_arg "$1") || return 1
    key=$(map::_escape "$2")

    local new_data
    new_data=$(echo -n "$map" | tr "$_MAP_DELIMITER" '\n' | grep -v "^${key}${_MAP_KV_SEPARATOR}" | tr '\n' "$_MAP_DELIMITER")

    map::_deserialize "$1" "${new_data%"$_MAP_DELIMITER"}"
}

# @description Clear all key-value pairs from the specified map.
#
# @example
#    map::clear my_map
#
# @arg $1 string The name of the map
#
# @exitcode 0 If successful.
#
# @see map::delete()
# @see map::make()
map::clear() {
    map::_deserialize "$1" ""
}

# @description Check if a map exists.
#
# @example
#    map::exists my_map
#
# @arg $1 string The name of the map
#
# @stdout "true" if the map exists, "false" otherwise.
#
# @exitcode 0 If successful.
#
# @see map::make()
# @see map::clear()
map::exists() {
    local map
    map=$(map::_arg "$1") || return 1
    [ -n "$map" ] && return 0 || return 1
}

# @description Get the number of key-value pairs in the specified map.
#
# @example
#    map::size my_map
#
# @arg $1 string The name of the map
#
# @stdout The number of key-value pairs in the map.
#
# @exitcode 0 If successful.
#
# @see map::make()
# @see map::clear()
map::size() {
    local map
    map=$(map::_arg "$1") || return 1

    if [ -z "$map" ]; then
        echo 0
    else
        echo -n "$map" | tr -cd "$_MAP_DELIMITER" | wc -c | tr -d ' '
    fi
}

# @description Get all values from the specified map.
#
# @example
#    map::values my_map
#
# @arg $1 string The name of the map
#
# @stdout All values in the map, one per line.
#
# @exitcode 0 If successful.
#
# @see map::keys()
# @see map::print()
map::values() {
    local map
    map=$(map::_arg "$1") || return 1

    local first=true
    echo -n "$map" | tr "$_MAP_DELIMITER" '\n' | cut -d "$_MAP_KV_SEPARATOR" -f2- | while IFS= read -r value; do
        if [ "$first" = true ]; then
            first=false
        else
            echo # This adds a newline before each value except the first
        fi
        map::_unescape "$value"
    done
}

# @description Get all keys from the specified map.
#
# @example
#    map::keys my_map
#    map::keys my_map -d " "
#    map::keys my_map --delimiter="," --trailing-delimiter
#
# @arg $1 string The name of the map
# @option -d, --delimiter string The delimiter to use between keys (default: ",")
# @option -t, --trailing-delimiter Add a trailing delimiter (default: false)
#
# @stdout All keys in the map, separated by the specified delimiter.
#
# @exitcode 0 If successful.
# @exitcode 1 If invalid arguments are provided.
#
# @see map::values()
# @see map::print()
map::keys() {
    local map delimiter trailing_delimiter

    opts "
        $(opt::define "-d" "--delimiter" "," "false" "true") delimiter
        $(opt::define "-t" "--trailing-delimiter" "false" "false" "false") trailing_delimiter
    " "$@"

    map=$(map::_arg "$1") || return 1

    local first=true
    local result=""
    while IFS= read -r key; do
        key=$(map::_unescape "$key")
        if [ "$first" = true ]; then
            result="$key"
            first=false
        else
            result="$result$delimiter$key"
        fi
    done < <(echo -n "$map" | tr "$_MAP_DELIMITER" '\n' | cut -d "$_MAP_KV_SEPARATOR" -f1)

    if [[ "$trailing_delimiter" == "true" && -n "$result" ]]; then
        result="$result$delimiter"
    fi

    echo -n "$result"
}

# @description Check if a key exists in the specified map.
#
# @example
#    map::has my_map city
#
# @arg $1 string The name of the map
# @arg $2 string The key to check
#
# @stdout "true" if the key exists, "false" otherwise.
#
# @exitcode 0 If the key exists.
# @exitcode 1 If the key does not exist.
#
# @see map::get()
# @see map::set()
map::has() {
    local name="$1"
    local key="$2"
    local data
    data=$(map::_serialize "$name")

    if [[ -z $data ]]; then
        return 1
    fi

    key=$(map::_escape "$key")
    if echo -n "$data" | tr "$_MAP_DELIMITER" '\n' | grep -q "^${key}${_MAP_KV_SEPARATOR}"; then
        return 0
    else
        return 1
    fi
}

# @description Display usage information for the map functions.
#
# @example
#    map::usage
#
# @stdout Prints usage information, including available functions and examples.
#
# @exitcode 0 Always exits with 0.
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
# Internal functions - Do not use directly
###########################################
_MAP_DELIMITER=$'\x1F'    # Unit Separator
_MAP_KV_SEPARATOR=$'\x1E' # Record Separator

# @internal
map::_serialize() {
    local name="$1"
    eval echo -n \$"${name}_map_data"
}

# @internal
map::_deserialize() {
    local name="$1"
    local data="$2"
    eval "${name}_map_data='$data'"
}

# @internal
map::_escape() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//$_MAP_DELIMITER/\\$_MAP_DELIMITER}"
    str="${str//$_MAP_KV_SEPARATOR/\\$_MAP_KV_SEPARATOR}"
    echo -n "$str"
}

# @internal
map::_unescape() {
    local str="$1"
    str="${str//\\$_MAP_KV_SEPARATOR/$_MAP_KV_SEPARATOR}"
    str="${str//\\$_MAP_DELIMITER/$_MAP_DELIMITER}"
    str="${str//\\\\/\\}"
    echo -n "$str"
}

# @internal
map::_trim() {
    local var="$1"
    var="${var#"${var%%[! ]*}"}"
    var="${var%"${var##*[! ]}"}"
    echo -n "$var"
}

# @internal
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

# @internal
map::_arg() {
    if [[ $# -eq 0 || "${1:0:1}" == "-" ]]; then
        echo "Error: A map must be the first argument and cannot start with a dash" >&2
        return 1
    fi
    local map="$1"
    shift
    # Update the global argument list
    set -- "$@"

    # Perform serialization
    local data
    data=$(map::_serialize "$map")

    echo "$data"
}

opts() {
    local opts="$1"
    shift

    local option_defs=""
    local var_names=""

    # Parse the opts string
    while read -r opt_def var_name; do
        if [[ -n "$opt_def" && -n "$var_name" ]]; then
            option_defs="$option_defs$opt_def "
            var_names="$var_names$var_name "
        fi
    done <<<"$opts"

    local i=1
    while [[ $i -le $# ]]; do
        local arg
        eval "arg=\${$i}"

        if [[ "$arg" == -* && "$arg" != --* ]]; then
            # Handle stacked short options
            local stacked_opts="${arg#-}"
            for ((j = 0; j < ${#stacked_opts}; j++)); do
                local opt="${stacked_opts:$j:1}"
                local found=false
                local k=1
                for opt_def in $option_defs; do
                    if [[ "$opt_def" == "-$opt"* ]]; then
                        found=true
                        eval "local var_name=\${var_names%% *}"
                        local requires_value
                        requires_value=$(echo "$opt_def" | cut -d':' -f5)
                        if [[ "$requires_value" == "true" ]]; then
                            if [[ $j -eq $((${#stacked_opts} - 1)) && $((i + 1)) -le $# ]]; then
                                i=$((i + 1))
                                eval "local value=\${$i}"
                                eval "$var_name=\"\$value\""
                            else
                                echo "Error: Option -$opt requires a value" >&2
                                return 1
                            fi
                        else
                            eval "$var_name=\"true\""
                        fi
                        break
                    fi
                    k=$((k + 1))
                    var_names="${var_names#* }"
                done
                if [[ "$found" == "false" ]]; then
                    echo "Error: Unknown option -$opt" >&2
                    return 1
                fi
                var_names="$var_names "
            done
        else
            # Handle long options and single short options
            case "$arg" in
            --*)
                local opt="${arg#--}"
                local value
                if [[ "$opt" == *=* ]]; then
                    value="${opt#*=}"
                    opt="${opt%%=*}"
                fi
                local found=false
                local k=1
                for opt_def in $option_defs; do
                    if [[ "$opt_def" == *":--$opt:"* ]]; then
                        found=true
                        eval "local var_name=\${var_names%% *}"
                        local requires_value
                        requires_value=$(echo "$opt_def" | cut -d':' -f5)
                        if [[ "$requires_value" == "true" ]]; then
                            if [[ -n "$value" ]]; then
                                eval "$var_name=\"\$value\""
                            elif [[ $((i + 1)) -le $# ]]; then
                                i=$((i + 1))
                                eval "value=\${$i}"
                                eval "$var_name=\"\$value\""
                            else
                                echo "Error: Option --$opt requires a value" >&2
                                return 1
                            fi
                        else
                            eval "$var_name=\"true\""
                        fi
                        break
                    fi
                    k=$((k + 1))
                    var_names="${var_names#* }"
                done
                if [[ "$found" == "false" ]]; then
                    echo "Error: Unknown option --$opt" >&2
                    return 1
                fi
                var_names="$var_names "
                ;;
            -*)
                local opt="${arg#-}"
                local found=false
                local k=1
                for opt_def in $option_defs; do
                    if [[ "$opt_def" == "-$opt:"* ]]; then
                        found=true
                        eval "local var_name=\${var_names%% *}"
                        local requires_value
                        requires_value=$(echo "$opt_def" | cut -d':' -f5)
                        if [[ "$requires_value" == "true" ]]; then
                            if [[ $((i + 1)) -le $# ]]; then
                                i=$((i + 1))
                                eval "local value=\${$i}"
                                eval "$var_name=\"\$value\""
                            else
                                echo "Error: Option -$opt requires a value" >&2
                                return 1
                            fi
                        else
                            eval "$var_name=\"true\""
                        fi
                        break
                    fi
                    k=$((k + 1))
                    var_names="${var_names#* }"
                done
                if [[ "$found" == "false" ]]; then
                    echo "Error: Unknown option -$opt" >&2
                    return 1
                fi
                var_names="$var_names "
                ;;
            esac
        fi
        i=$((i + 1))
    done
}

opt::parse() {
    local -a options=()
    local expecting_value=false
    local current_option=""
    local result=""

    # Collect options
    while [[ $# -gt 0 && "$1" != "--" ]]; do
        options+=("$1")
        shift
    done
    shift # Remove "--"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        if $expecting_value; then
            result="${result}${current_option}:$1\n"
            expecting_value=false
        else
            local found=false
            if [[ "$1" =~ ^-[^-] ]]; then
                # Handle combined short options
                local combined_opts="${1#-}"
                while [[ -n "$combined_opts" ]]; do
                    local current_opt="${combined_opts:0:1}"
                    combined_opts="${combined_opts:1}"
                    for opt in "${options[@]}"; do
                        IFS=':' read -r short long default required expects_value <<<"$opt"
                        if [[ "-$current_opt" == "$short" ]]; then
                            found=true
                            current_option="${short#-}"
                            if [[ "$expects_value" == "true" ]]; then
                                if [[ -n "$combined_opts" ]]; then
                                    result="${result}${current_option}:${combined_opts}\n"
                                    combined_opts=""
                                else
                                    expecting_value=true
                                fi
                            else
                                result="${result}${current_option}:true\n"
                            fi
                            break
                        fi
                    done
                    if ! $found; then
                        echo "Error: Unknown option -$current_opt" >&2
                        return 1
                    fi
                done
            else
                # Handle long options and single short options
                for opt in "${options[@]}"; do
                    IFS=':' read -r short long default required expects_value <<<"$opt"
                    if [[ "$1" == "$short" || "$1" == "$long" ]]; then
                        found=true
                        current_option="${short#-}"
                        if [[ "$expects_value" == "true" ]]; then
                            expecting_value=true
                        else
                            result="${result}${current_option}:true\n"
                        fi
                        break
                    elif [[ "$1" == "$short="* || "$1" == "$long="* ]]; then
                        found=true
                        current_option="${short#-}"
                        value="${1#*=}"
                        result="${result}${current_option}:$value\n"
                        break
                    fi
                done
            fi
            if ! $found; then
                echo "Error: Unknown option $1" >&2
                return 1
            fi
        fi
        shift
    done

    # Check for missing required options and set defaults
    for opt in "${options[@]}"; do
        IFS=':' read -r short long default required expects_value <<<"$opt"
        if ! echo -e "$result" | grep -q "^${short#-}:"; then
            if [[ "$required" == "true" ]]; then
                echo "Error: Required option $long is missing" >&2
                return 1
            elif [[ -n "$default" ]]; then
                result="${result}${short#-}:$default\n"
            fi
        fi
    done

    echo -e "$result"
}

opt::define() {
    echo "$1:$2:$3:$4:$5"
}

opt::get_value() {
    local parsed_opts="$1"
    local option_short="$2"
    echo "$parsed_opts" | grep "^${option_short#-}:" | cut -d':' -f2
}

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    export -f map::make map::get map::set map::print map::delete map::clear \
        map::exists map::size map::values map::keys map::has map::usage
else
    map::usage
fi
