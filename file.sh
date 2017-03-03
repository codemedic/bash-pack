#!/bin/bash

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


