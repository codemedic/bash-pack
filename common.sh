#!/bin/bash

# enable / disable bash-debug
enable_bash_debug() {
    [ "${bash_debug:-0}" = 0 ] ||
        set -x
}

is_bash_version() {
    (( ${BASH_VERSION%%.*} >= "$1" ))
}

to_lower() {
    if is_bash_version 4; then
        local str="$*"
        echo "${str,,}"
    else
        echo "$*" | tr '[:upper:]' '[:lower:]'
    fi
}

to_upper() {
    if is_bash_version 4; then
        local str="$*"
        echo "${str^^}"
    else
        echo "$*" | tr '[:lower:]' '[:upper:]'
    fi
}

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

pipe_to_fd() {
    # make sure fds are valid
    for ((i=1; i<=$#; ++i)); do
        { >&"${!i}"; } 2> /dev/null ||
            bail "tee_fd: Invalid fd (${!i}) given"
    done

    while true; do
        if IFS= read -r line; then
            for ((i=1; i<=$#; ++i)); do
                echo "${line}" >&"${!i}";
            done
            [ "${tee:-0}" = 0 ] ||
                echo "${line}"
        else
            break;
        fi;
    done
}

pipe_to_file() {
    while true; do
        if IFS= read -r line; then
            for ((i=1; i<=$#; ++i)); do
                echo "${line}" >>"${!i}";
            done
            [ "${tee:-0}" = 0 ] ||
                echo "${line}"
        else
            break;
        fi;
    done
}

is_fd() {
    [[ "$1" =~ ^[0-9]+$ ]] && {
        { : >&"$1"; } 2> /dev/null
    }
}

unused_fd() {
    : "${__max_fd:="$(ulimit -n)"}"
    for ((i=0; i<"$__max_fd"; ++i)); do
        is_fd "$i" || {
            echo -n "$i"
            break;
        }
    done
}

# initialise and load specified scripts; fenced by __bash_common_loaded
[ -n "${__bash_common_loaded:-}" ] || {
    __bash_common_loaded=1

    # load scripts specific to a bash version
    locate_common_script() {
        [[ ${BASH_VERSION} =~ ^([0-9]+)\.([0-9]+)\.([0-9]+) ]]
        local version_Mmp="${BASH_REMATCH[0]}" \
            version_Mm="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}" \
            version_M="${BASH_REMATCH[1]}"
        local paths=( $(printf "${COMMON_DIR}/${1}-bv%s.sh\n" "${version_Mmp}" "${version_Mm}" "${version_M}") "${COMMON_DIR}/${1}.sh" )
        local path
        for path in "${paths[@]}"; do
            if [ -f "$path" ] && [ -r "$path" ]; then
                echo -n "$path"
                return 0
            fi
        done
        return 1
    }

    COMMON_DIR="${BASH_SOURCE[0]%/*}"
    [ -d "$COMMON_DIR" ] || COMMON_DIR=.

    enable_bash_debug

    module_paths=()

    # Find files to load for any common sh files given as args
    for ((i=1; i<=$#; ++i)); do
        sh_path="$( locate_common_script "${!i}" )" || {
            echo "Could not find module: ${!i}"
            exit 1
        }
        if pre_path="$( locate_common_script "${!i}-pre" )"; then
            module_paths+=("$pre_path")
        fi
        module_paths+=( "$sh_path" )
        if post_path="$( locate_common_script "${!i}-post" )"; then
            module_paths+=("$post_path")
        fi
    done

    # once all of them are found, load them
    for path in "${module_paths[@]}"; do
        echo "Include $path"
        . "$path"
    done
}
