#!/bin/bash

script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "${script_dir%/*}/src/bash-map.sh"

# Create a new map
map::make user "
    [name] = John Doe
    [age]  = 30
    [city] = New York
"

show_profile() {
    echo "User Profile"
    map::print "$1"
    echo
}

has_email() {
    if map::has "$1" email; then
        echo "Email exists"
    else
        echo "Email does not exist"
    fi
}

show_profile user

# Get and display a specific value
name=$(map::get user name)
echo "Name: $name"

# Update a value
echo "Updating [age] to 31..."
map::set user age 31

# Add a new key-value pair
echo "Adding [job] property..."
map::set user job "Pinball Wizard"

echo
show_profile user

echo "Metadata"
# Get the keys
keys=$(map::keys user)
echo "keys: $keys"

# Get the values
values=$(map::values user)
echo "values: $values"

# Get the size of the map
size=$(map::size user)
echo "size: $size"

map::make test "
    [name] = John Doe
    [age]  = 30
    [city] = New York
    "

map::clear test
map::print test
map::keys test
map::size test
