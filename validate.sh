#!/bin/bash

# Check if a string is fully qualified domain name
is_fqdn() {
    echo "$1" | grep -qP '(?=^.{4,253}$)(^(?:[a-zA-Z](?:(?:[a-zA-Z0-9\-]){,61}[a-zA-Z])?\.)+[a-zA-Z]{2,}$)'
}

# Check if a string is integer
is_integer() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

# is a number (not just integer)
is_number() {
    [ "$1" -eq "$1" ] 2>/dev/null
}

