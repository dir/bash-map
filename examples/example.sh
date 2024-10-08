#!/bin/bash

script_dir="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
source "${script_dir%/*}/src/bash-map.sh"
