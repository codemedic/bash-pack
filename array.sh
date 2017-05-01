#!/bin/bash

# Lookup an element in an array
#
# It does not work on the array directly, but provides a mechanism
# to work like so. It just looks for the first argument in the
# remaining.
#
# Usage:
#   in_array <Needle> <HayStack>
#
# Example:
#   array=(1 2 3 4 5)
#   in_array 3 "${array[@]}" && echo Found || echo "Not found"
in_array() {
    local i
    for ((i=2; i<=$#; ++i)); do
        [ "${!i}" != "$1" ] || return 0
    done
    return 1
}

# Join array elements into a string using the provided glue
#
# It doesn't work on the array directly, but provides a mechanism
# to work like so. All it does is it glues all the provided
# arguments, using the first argument.
#
# Usage:
#   array_join <Glue> <ArgumentsToGlueTogether>
#
# Example:
#   array=(1 2 3 4 5)
#   array_join ',' "${array[@]}"
array_join() {
    local glue="$1"; shift;
    if [ $# -gt 0 ]; then
        echo -n "$1"; shift
        [ $# -eq 0 ] ||
            printf "${glue}%s" "$@"
    fi
}

