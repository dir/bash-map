#!/bin/bash

script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "${script_dir%/*}/src/bash-map.sh"

map::make items "
    [apple]  = 0.65
    [banana] = 2.79
    [orange] = 1.99
    [grape]  = 3.99
"

# Create a map for a shopping cart
map::make cart "
    [apple]  = 3
    [orange] = 4
    [banana] = 2
"

# Function to add an item to the cart
add_to_cart() {
    local item="$1"
    local quantity="$2"

    if map::has cart "$item"; then
        local current_quantity
        current_quantity=$(map::get cart "$item")
        quantity=$((current_quantity + quantity))
    fi

    map::set cart "$item" "$quantity"
    echo "Added $quantity $item(s) to the cart"
}

# Function to remove an item from the cart
remove_from_cart() {
    local item="$1"

    if map::has cart "$item"; then
        map::delete cart "$item"
        echo "Removed $item from the cart"
    else
        echo "$item is not in the cart"
    fi
}

echo "Cart Item Qtys:"
map::keys cart -d ','

echo
echo "Cart Items:"
map::print cart

# Add items to the cart
add_to_cart "grape" 2
add_to_cart "apple" 1

# Remove an item
remove_from_cart "orange"

# Print the cart contents
echo "Cart contents:"
map::print cart

# Calculate total items
total_items=0
while IFS= read -r quantity; do
    total_items=$((total_items + quantity))
done < <(map::values cart)

echo "Total items in cart: $total_items"

# List all items
echo "Items in cart:"
map::keys cart
