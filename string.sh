#!/bin/bash

# to lower case
to_lower() {
    if is_bash_version 4; then
        local str="$*"
        echo "${str,,}"
    else
        echo "$*" | tr '[:upper:]' '[:lower:]'
    fi
}

# to upper case
to_upper() {
    if is_bash_version 4; then
        local str="$*"
        echo "${str^^}"
    else
        echo "$*" | tr '[:lower:]' '[:upper:]'
    fi
}

# prefix each line
prefix_filter() {
    local prefix line
    [ $# -eq 0 ] || prefix="$*"
    while true; do
        if IFS= read -r line; then
            echo "${prefix}${line}" >&"${out_fd:-1}";
        else
            break;
        fi;
    done
}

# Replace token with value, takes more than one token-value pair
#
# Usage:
#    replace_string Token1 Value1 [ [Token2 Value2] ... ]
replace_all() {
    { [ $# -gt 0 ] && [ "$(($#%2))" -eq 0 ]; } || {
        bail "replace_string: invalid invocation; variable name and values should be in pairs"
    }

    local input; input="$(</dev/stdin)"

    while [ $# -gt 0 ]; do
        # consume a variable-name and value pair and formulate sed pattern
        local var="$1" val="$2"; shift 2
        input="${input//"$var"/"$val"}"
    done

    echo -n "$input"
}

# Escape sed match pattern
sed_escape_pattern() {
    echo "$1" | sed -e 's/\([[\/.*]\|\]\)/\\&/g'
}

# Escape sed replace pattern
sed_escape_replace() {
    echo "$1" | sed -e 's/[\/&]/\\&/g'
}

# sed_escape* function usage example
# sed "s/$(sed_escape_pattern "$var")/$(sed_escape_replace "$val")/g"
