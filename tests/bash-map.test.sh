#!/bin/bash

script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"

. "${script_dir%/*}/src/bash-map.sh"

# Test map::make and map::get
test_make_and_get() {
    map::make test_map "
        [key1]=value1
        [key2]=value2
        [key with spaces]=value with spaces
    "

    assertEquals "value1" "$(map::get test_map key1)"
    assertEquals "value2" "$(map::get test_map key2)"
    assertEquals "value with spaces" "$(map::get test_map "key with spaces")"
}

# Test map::set
test_set() {
    map::make test_map ""s
    map::set test_map key1 "new value"
    assertEquals "new value" "$(map::get test_map key1)"

    map::set test_map key1 "updated value"
    assertEquals "updated value" "$(map::get test_map key1)"
}

# Test map::delete
test_delete() {
    map::make test_map s"
        [key1]=value1
        [key2]=value2
    "

    map::delete test_map key1
    assertEquals 0 $?

    map::has test_map key1
    assertFalse $?

    map::has test_map key2
    assertTrue $?
}

# Test map::clear
test_clear() {
    map::make test_map "
        [key1]=value1
        [key2]=value2
    "

    map::clear test_map
    assertEquals 0 "$(map::size test_map)"
}

# Test map::exists
test_exists() {
    map::make test_map ""

    map::exists test_map
    assertFalse $?

    map::set test_map key1 value1

    map::exists test_map
    assertTrue $?
}

# Test map::size
test_size() {
    map::make test_map "
        [key1]=value1
        [key2]=value2
        [key3]=value3
    "

    assertEquals 3 "$(map::size test_map)"

    map::delete test_map key2
    assertEquals 2 "$(map::size test_map)"
}

# Test map::values
test_values() {
    map::make test_map "
        [key1]=value1
        [key2]=value2
        [key3]=value3
    "

    local values
    values=$(map::values test_map)
    assertSame "value1
value2
value3" "$values"
}

# Test map::keys
test_keys() {
    map::make test_map "
        [key1]=value1
        [key2]=value2
        [key3]=value3
    "

    assertSame "key1key2key3" "$(map::keys test_map)"
}

# Test map::has
test_has() {
    map::make test_map "
        [key1]=value1
        [key2]=value2
    "

    map::has test_map key1
    assertTrue $?

    map::has test_map key2
    assertTrue $?

    map::has test_map key3
    assertFalse $?
}

# Test escaping and unescaping
test_escaping() {
    local complex_key="key with, spaces and = signs"
    local complex_value="value with, spaces and = signs"

    map::make test_map ""
    map::set test_map "$complex_key" "$complex_value"

    assertEquals "$complex_value" "$(map::get test_map "$complex_key")"
}

# Run the tests
# shellcheck source=/dev/null
. shunit2
