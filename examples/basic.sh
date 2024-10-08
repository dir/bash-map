#!/bin/bash

script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "${script_dir%/*}/src/bash-map.sh"

# Create a new map
map::make user_info "
    [name] = John Doe
    [age]  = 30
    [city] = New York
"

# Print the map
echo "User Information:"
map::print user_info

# Get and display a specific value
name=$(map::get user_info name)
echo "Name: $name"

# Update a value
map::set user_info age 31

# Add a new key-value pair
map::set user_info job "Pinball Wizard"

# Check if a key exists
if map::has user_info email; then
    echo "Email exists"
else
    echo "Email does not exist"
fi

# Print the updated map
echo "Updated User Information:"
map::print user_info

# Get the size of the map
size=$(map::size user_info)
echo "Number of entries: $size"
