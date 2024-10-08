# bash-map

A simple map implementation in bash

## Overview

Create a new map with the given name and key-value pairs.

## Index

* [map::make](#mapmake)
* [map::get](#mapget)
* [map::set](#mapset)
* [map::print](#mapprint)
* [map::delete](#mapdelete)
* [map::clear](#mapclear)
* [map::exists](#mapexists)
* [map::size](#mapsize)
* [map::values](#mapvalues)
* [map::keys](#mapkeys)
* [map::has](#maphas)
* [map::usage](#mapusage)

### map::make

Create a new map with the given name and key-value pairs.

#### Example

```bash
map::make my_map "[name]=John Doe
                  [age]=30
                  [city]=New York"
```

#### Arguments

* **$1** (string): The name of the map to create
* **$2** (string): A multi-line string of key-value pairs

#### Exit codes

* **0**: If successful.
* **1**: If an error occurs during map creation.

#### See also

* [map::get()](#mapget)
* [map::set()](#mapset)

### map::get

Retrieve the value associated with a key in the specified map.

#### Example

```bash
map::get my_map name
```

#### Arguments

* **$1** (string): The name of the map
* **$2** (string): The key to retrieve

#### Exit codes

* **0**: If the key is found.
* **1**: If the key is not found.

#### Output on stdout

* The value associated with the key if found.

#### Output on stderr

* Error message if the key is not found.

#### See also

* [map::set()](#mapset)
* [map::has()](#maphas)

### map::set

Set or update a key-value pair in the specified map.

#### Example

```bash
map::set my_map job "Software Engineer"
```

#### Arguments

* **$1** (string): The name of the map
* **$2** (string): The key to set or update
* **$3** (string): The value to associate with the key

#### Exit codes

* **0**: If successful.

#### See also

* [map::get()](#mapget)
* [map::delete()](#mapdelete)

### map::print

Print all key-value pairs in the specified map.

#### Example

```bash
map::print my_map
```

#### Arguments

* **$1** (string): The name of the map

#### Exit codes

* **0**: If successful.

#### Output on stdout

* All key-value pairs in the map, one per line.
  Outputs "(empty)" if the map is empty.

#### See also

* [map::make()](#mapmake)
* [map::get()](#mapget)

### map::delete

Delete a key-value pair from the specified map.

#### Example

```bash
map::delete my_map age
```

#### Arguments

* **$1** (string): The name of the map
* **$2** (string): The key to delete

#### Exit codes

* **0**: If successful.

#### See also

* [map::set](#mapset)
* [map::clear](#mapclear)

### map::clear

Clear all key-value pairs from the specified map.

#### Example

```bash
map::clear my_map
```

#### Arguments

* **$1** (string): The name of the map

#### Exit codes

* **0**: If successful.

#### See also

* [map::delete()](#mapdelete)
* [map::make()](#mapmake)

### map::exists

Check if a map exists.

#### Example

```bash
map::exists my_map
```

#### Arguments

* **$1** (string): The name of the map

#### Exit codes

* **0**: If successful.

#### Output on stdout

* "true" if the map exists, "false" otherwise.

#### See also

* [map::make()](#mapmake)
* [map::clear()](#mapclear)

### map::size

Get the number of key-value pairs in the specified map.

#### Example

```bash
map::size my_map
```

#### Arguments

* **$1** (string): The name of the map

#### Exit codes

* **0**: If successful.

#### Output on stdout

* The number of key-value pairs in the map.

#### See also

* [map::make()](#mapmake)
* [map::clear()](#mapclear)

### map::values

Get all values from the specified map.

#### Example

```bash
map::values my_map
```

#### Arguments

* **$1** (string): The name of the map

#### Exit codes

* **0**: If successful.

#### Output on stdout

* All values in the map, one per line.

#### See also

* [map::keys()](#mapkeys)
* [map::print()](#mapprint)

### map::keys

Get all keys from the specified map.

#### Example

```bash
map::keys my_map
```

#### Arguments

* **$1** (string): The name of the map

#### Exit codes

* **0**: If successful.

#### Output on stdout

* All keys in the map, one per line.

#### See also

* [map::values()](#mapvalues)
* [map::print()](#mapprint)

### map::has

Check if a key exists in the specified map.

#### Example

```bash
map::has my_map city
```

#### Arguments

* **$1** (string): The name of the map
* **$2** (string): The key to check

#### Exit codes

* **0**: If the key exists.
* **1**: If the key does not exist.

#### Output on stdout

* "true" if the key exists, "false" otherwise.

#### See also

* [map::get()](#mapget)
* [map::set()](#mapset)

### map::usage

Display usage information for the map functions.

#### Example

```bash
map::usage
```

#### Exit codes

* **0**: Always exits with 0.

#### Output on stdout

* Prints usage information, including available functions and examples.

